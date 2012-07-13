//
//  Locations.m
//  Network Commuting
//
//  Created by John Canfield on 2/10/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Locations.h"
#import "UtilityFunctions.h"

// Internal variables and methods

@interface Locations () 
{
    NSArray *sortedMatchingFromLocations; // All from locations that somehow match the typedFromString
    int matchingFromRowCount;  // Count of from locations (including frequency=0) that match the typedFromString
    NSArray *sortedMatchingToLocations;
    int matchingToRowCount;
    NSArray *sortedFromLocations;  // All locations sorted by from frequency
    NSArray *sortedToLocations;    // All locations sorted by to frequency
    NSFetchRequest *locationsFetchRequest;
    Location* oldSelectedFromLocation; // This stores the previous selectedFromLocation when a new one is entered
    Location* oldSelectedToLocation; // This stores the previous selectedToLocation when a new one is entere

}
- (void)updateWithSelectedLocationIsFrom:(BOOL)isFrom selectedLocation:(Location *)selectedLocation oldSelectedLocation:(Location *)oldSelectedLocation;
- (void)updateInternalCache;

@end


@implementation Locations

@synthesize typedFromString;
@synthesize typedToString;
@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize rkGeoMgr;
@synthesize selectedFromLocation;
@synthesize selectedToLocation;
@synthesize areLocationsChanged;
@synthesize areMatchingLocationsChanged;

@synthesize rawAddressTo,rawAddressFrom;
@synthesize geoRespTo,geoRespFrom;
@synthesize geoRespTimeTo,geoRespTimeFrom;
@synthesize isFromGeo,isToGeo;
@synthesize isLocationServiceEnable;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkGeoMgr:(RKObjectManager *)rkG
{
    self = [super init];
    if (self) {
        managedObjectContext = moc;
        managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
        rkGeoMgr = rkG;
        // Set the static variable for Location class
        [Location setLocations:self];
        
        areLocationsChanged = YES;  // Force cache stale upon start-up so it gets properly loaded
    }

    return self;
}

- (void)preLoadIfNeededFromFile:(NSString *)filename latestVersionNumber:(NSDecimalNumber *)newVersion
{
    // Check there version number against the the PRELOAD_TEST_ADDRESS to see if we need to open the file
    NSString* formattedAddr = PRELOAD_TEST_ADDRESS;
    NSArray* preloadTestLocs = [self locationsWithFormattedAddress:formattedAddr];
    
    // If there are matching locations for that station, 
    BOOL isNewerVersion;  // true if we have a new version that needs loading
    if ([preloadTestLocs count] > 0) {
        NSDecimalNumber* currentVersion = [[preloadTestLocs objectAtIndex:0] preloadVersion];
        if (currentVersion) {
            isNewerVersion = ([currentVersion compare:newVersion] ==  NSOrderedAscending);
        } 
        else { // if no currentVersion set, then always update with newer version
            isNewerVersion = YES;
        }
    }
        
    // If that station has not been loaded, or if there is a newer version, pre-load the remaining stations
    if (([preloadTestLocs count] == 0) || isNewerVersion) {
        
        // Code adapted from http://stackoverflow.com/questions/10305535/iphone-restkit-how-to-load-a-local-json-file-and-map-it-to-a-core-data-entity and https://github.com/RestKit/RestKit/wiki/Object-mapping (bottom of page)
        NSStringEncoding encoding;
        NSError* error = nil;
        NSString* preloadPath = [[NSBundle mainBundle] pathForResource:filename ofType:nil]; 
        NSString *jsonText = [NSString stringWithContentsOfFile:preloadPath usedEncoding:&encoding error:&error];
        if (jsonText && !error) {
            
            id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
            id parsedData = [parser objectFromString:jsonText error:&error];
            if (parsedData == nil && error) {
                NSLog(@"Parser error %@", error);
            }
            
            RKObjectMappingProvider* mappingProvider = rkGeoMgr.mappingProvider;
            RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
            RKObjectMappingResult* result = [mapper performMapping];
            if (result) {
                NSArray* resultArray = [result asCollection];
                for (int i=0; i < [resultArray count]; i++) {
                    Location* loc = [resultArray objectAtIndex:i];
                    // See if there is a matching Location already in CoreData
                    NSArray* matchingLocations = [self locationsWithFormattedAddress:[loc formattedAddress]];
                    BOOL areAnyMatchesNewerOrEqual = FALSE;
                    for (Location* matchingLocation in matchingLocations) {
                        // If newVersion is indeed newer (or if matchingLocation does not have a version)
                        if (matchingLocation != loc) {
                            if (![matchingLocation preloadVersion] 
                                || [[matchingLocation preloadVersion] compare:newVersion] == NSOrderedAscending) {
                                // cancel out previous preload frequencies below 2.0 so they can be replaced
                                // with the new matching frequency
                                if ([matchingLocation toFrequencyFloat] < 2.0) {
                                    [matchingLocation setToFrequencyFloat:0.0];
                                }
                                if ([matchingLocation fromFrequencyFloat] < 2.0) {
                                    [matchingLocation setFromFrequencyFloat:0.0];
                                }
                            }
                            else {
                                areAnyMatchesNewerOrEqual = TRUE;
                            }
                        }
                    }
                    if (!areAnyMatchesNewerOrEqual) {
                        // Consolidate with any duplicates already in Core Data, keeping this version
                        loc = [self consolidateWithMatchingLocations:loc keepThisLocation:YES];
                        NSLog(@"Preload loc: %@, toFreq=%f, fromFreq=%f", 
                              [loc shortFormattedAddress], [loc toFrequencyFloat], 
                              [loc fromFrequencyFloat]);
                        [loc setPreloadVersion:newVersion]; 
                    }
                    else { // if loc is not newer version than matching, delete loc
                        [self removeLocation:loc];
                    }
                }
                saveContext([self managedObjectContext]);
            }
            else {
                NSLog(@"No results back from loading file at path %@", preloadPath);
            }
        }
        else {
            NSLog(@"Could not load file %@ at path %@", filename, preloadPath);
        }
    }
}

// Updates to selected location methods to update sorting

// Convenience method for updated either the To or From selected location
- (void)updateSelectedLocation:(Location *)sL isFrom:(BOOL)isFrom
{
    if (isFrom) {
        [self setSelectedFromLocation:sL];
    } else {
        [self setSelectedToLocation:sL];
    }
}
- (void)setSelectedFromLocation:(Location *)sFL
{
    selectedFromLocation = sFL;
    [self updateWithSelectedLocationIsFrom:TRUE selectedLocation:selectedFromLocation oldSelectedLocation:oldSelectedFromLocation];
    oldSelectedFromLocation = selectedFromLocation;
}

-(void)setSelectedToLocation:(Location *)sTL
{
    selectedToLocation = sTL;
    [self updateWithSelectedLocationIsFrom:FALSE selectedLocation:selectedToLocation oldSelectedLocation:oldSelectedToLocation];
    oldSelectedToLocation = selectedToLocation;
}

// Called after there has been a significant update to a Location so that cache is invalidated
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self setAreLocationsChanged:YES];  // mark cache for refresh
}

- (Location *)newEmptyLocation 
{
    Location *l = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
    [self setAreLocationsChanged:YES]; // DE30 fix (2 of 2)
    return l;
}

// Utility function used by setTypedFromString & setTypedToString.  On hold for now
/* void updateFromTyping(NSString *typedXStr0, NSString **typedXString, NSArray **sortedMatchingXLocations, 
                      int *matchingXRowCount)
 */

// Custom setter for updated typedFromString that recomputes the sortedMatchingFromLocations and row count
- (void)setTypedFromString:(NSString *)typedFromStr0
{
    areMatchingLocationsChanged = NO;
    // updateFromTyping(typedFromStr0, &typedFromString, &sortedMatchingFromLocations, &matchingFromRowCount);
    if (!typedFromStr0 || [typedFromStr0 length] == 0) { // if sorted string = 0
        sortedMatchingFromLocations = sortedFromLocations;
        typedFromString = typedFromStr0;  
        areMatchingLocationsChanged = YES;

        // Calculate the count, up to the first location with frequency below threshold (excluding the selectedLocation)
        NSLog(@"sortedMatchingFromLocations count = %d", [sortedMatchingFromLocations count]);
        int i;
        for (i=0; (i < [sortedMatchingFromLocations count]) && 
             ((selectedFromLocation == [sortedMatchingFromLocations objectAtIndex:i]) ||
              [[sortedMatchingFromLocations objectAtIndex:i] fromFrequencyFloat] > TOFROM_FREQUENCY_VISIBILITY_CUTOFF); i++);
        matchingFromRowCount = i;
        NSLog(@"MatchingFromRowCount = %d", matchingFromRowCount);
    }
    else {
        NSArray *startArray = nil;
        if (typedFromString && [typedFromString length]>0 && [typedFromStr0 hasPrefix:typedFromString]) { // if new string is an extension of the previous one...
            startArray = sortedMatchingFromLocations;  // start with the last array of matches, and narrow from there
        }
        else {
            startArray = sortedFromLocations;    // otherwise, start fresh with all from locations
        }
        typedFromString = typedFromStr0;   
        NSMutableArray *newArray = [NSMutableArray array];   
        for (Location *loc in startArray) {
            if ([loc isMatchingTypedString:typedFromString]) {  // if loc matches the new string
                [newArray addObject:loc];  //  add loc to the new array
            }
        }
        NSArray *finalNewArray = [NSArray arrayWithArray:newArray];  // makes a non-mutable copy
        if (![finalNewArray isEqualToArray:sortedMatchingFromLocations]) { // if there is a change
            sortedMatchingFromLocations = finalNewArray;
            areMatchingLocationsChanged = YES;   // mark for refreshing the table
        }
        matchingFromRowCount = [sortedMatchingFromLocations count];  // cases that match typing are included even if they have frequency=0
    }
}

// Custom setter for updated typedToString that recomputes the sortedMatchingToLocations and row count
- (void)setTypedToString:(NSString *)typedToStr0
{
    areMatchingLocationsChanged = NO;
    // updateToTyping(typedToStr0, &typedToString, &sortedMatchingToLocations, &matchingToRowCount);
    if (!typedToStr0 || [typedToStr0 length] == 0) { // if sorted string = 0
        sortedMatchingToLocations = sortedToLocations;
        typedToString = typedToStr0;
        areMatchingLocationsChanged = YES;

        // Calculate the count, up to the first location with frequency below threshold (excluding the selected Location)
        NSLog(@"sortedMatchingToLocations count = %d", [sortedMatchingToLocations count]);
        int i;
        for (i=0; (i < [sortedMatchingToLocations count]) && 
             ((selectedToLocation == [sortedMatchingToLocations objectAtIndex:i]) ||
             [[sortedMatchingToLocations objectAtIndex:i] toFrequencyFloat] > TOFROM_FREQUENCY_VISIBILITY_CUTOFF); i++);
        matchingToRowCount = i;
        NSLog(@"matchingToRowCount = %d", matchingToRowCount);
    }
    else {
        NSArray *startArray = nil;
        if (typedToString && [typedToString length]>0 && [typedToStr0 hasPrefix:typedToString]) { // if new string is an extension of the previous one...
            startArray = sortedMatchingToLocations;  // start with the last array of matches, and narrow from there
        }
        else {
            startArray = sortedToLocations;    // otherwise, start fresh with all To locations
        }
        typedToString = typedToStr0;   
        NSMutableArray *newArray = [NSMutableArray array];   
        for (Location *loc in startArray) {
            if ([loc isMatchingTypedString:typedToString]) {  // if loc matches the new string
                [newArray addObject:loc];  //  add loc to the new array
            }
        }
        NSArray *finalNewArray = [NSArray arrayWithArray:newArray];  // makes a non-mutable copy
        if (![finalNewArray isEqualToArray:sortedMatchingToLocations]) { // if there is a change
            sortedMatchingToLocations = finalNewArray;
            areMatchingLocationsChanged = YES;   // mark for refreshing the table
        }
        matchingToRowCount = [sortedMatchingToLocations count];  // cases that match typing are included even if they have frequency=0
    }
}


// Returns the number of locations to show in the to or from table.  isFrom = true if it is the from table.
// Implementation only counts locations with frequency>0.   
- (int)numberOfLocations:(BOOL)isFrom {

    if (areLocationsChanged) { // if cache outdated, then query & update the internal memory array
        [self updateInternalCache];
    }
    // Now that the internal variables are updated, return the row value
    if (isFrom) {
        return matchingFromRowCount;
    }
    else {
        return matchingToRowCount;
    }
}

// Returns the Location from the sorted array at the specified index.  isFrom = true if it is the from table. 
- (Location *)locationAtIndex:(int)index isFrom:(BOOL)isFrom {

    if (areLocationsChanged) { // if cache outdated, then query & update the internal memory array
        [self updateInternalCache];
    }
    // Now that the internal variables are updated, return the row value
    if (isFrom) {
        return [sortedMatchingFromLocations objectAtIndex:index];
    }
    else {
        return [sortedMatchingToLocations objectAtIndex:index];
    }
}


// Internal method for updating cache after locations have changed
// Only include those locations with frequency >= 1 in the row count
- (void)updateInternalCache
{
    if (!locationsFetchRequest) {  // create the fetch request if we have not already done so
        locationsFetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *e = [[managedObjectModel entitiesByName] objectForKey:@"Location"];
        [locationsFetchRequest setEntity:e];
        NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:@"fromFrequency" 
                                                              ascending:NO];
        NSSortDescriptor *sd2 = [NSSortDescriptor sortDescriptorWithKey:@"dateLastUsed"
                                                              ascending:NO];
        [locationsFetchRequest setSortDescriptors:[NSArray arrayWithObjects:sd1,sd2,nil]];
    }
    
    // Fetch the sortedFromLocations array
    NSError *error;
    sortedFromLocations = [managedObjectContext executeFetchRequest:locationsFetchRequest
                                                              error:&error];
    if (!sortedFromLocations) {
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]];
    }
    
    // Now create a different array with the sorted To descriptors
    NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:@"toFrequency" 
                                                          ascending:NO];
    NSSortDescriptor *sd2 = [NSSortDescriptor sortDescriptorWithKey:@"dateLastUsed"
                                                          ascending:NO];
    sortedToLocations = [sortedFromLocations sortedArrayUsingDescriptors:
                         [NSArray arrayWithObjects:sd1,sd2,nil]];

    // Force recomputation of the selectedLocations
    [self updateWithSelectedLocationIsFrom:TRUE selectedLocation:selectedFromLocation oldSelectedLocation:oldSelectedFromLocation];
    [self updateWithSelectedLocationIsFrom:FALSE selectedLocation:selectedToLocation oldSelectedLocation:oldSelectedToLocation];
    
    // Force the recomputation of the sortedMatchedLocations arrays
    [self setTypedToString:[self typedToString]];
    [self setTypedFromString:[self typedFromString]];
    
    [self setAreLocationsChanged:NO];  // reset again
}

// Updates sortedToLocations or sortedFromLocations to put the selectedLocation at the top of the list
// Note: this does not update the sortedMatchingLocations array, so this method should only be used when
// typing field is already cleared
- (void)updateWithSelectedLocationIsFrom:(BOOL)isFrom selectedLocation:(Location *)selectedLocation oldSelectedLocation:(Location *)oldSelectedLocation
{
    NSMutableArray* newArray;
    if (isFrom) {
        newArray = [[NSMutableArray alloc] initWithArray:sortedFromLocations];
    } else {
        newArray = [[NSMutableArray alloc] initWithArray:sortedToLocations];
    }
    if (oldSelectedLocation && (oldSelectedLocation != selectedLocation)) { // if there was a non-nil oldSelectedLocation, and this is a new request, then re-sort
        NSSortDescriptor *sd1 = [NSSortDescriptor 
                                 sortDescriptorWithKey:(isFrom ? @"fromFrequency" : @"toFrequency")
                                                              ascending:NO];
        NSSortDescriptor *sd2 = [NSSortDescriptor sortDescriptorWithKey:@"dateLastUsed"
                                                              ascending:NO];
        [newArray sortUsingDescriptors:[NSArray arrayWithObjects:sd1,sd2, nil]];
    }
    if (selectedLocation) { // if there is a non-nil selectedLocation, then move it to the top
        [newArray removeObject:selectedLocation];  // remove selected object from current location
        [newArray insertObject:selectedLocation atIndex:0];  // inserts it at the front of the object
    }
    
    // Write newArray back into the appropriate sorted array
    if (isFrom) {
        sortedFromLocations = [NSArray arrayWithArray:newArray];
    } else {
        sortedToLocations = [NSArray arrayWithArray:newArray];
    }
}

// Returns an array of Location objects that have an exact match for formattedAddress 
// (could be empty if no matches)
- (NSArray *)locationsWithFormattedAddress:(NSString *)formattedAddress
{
    if (!formattedAddress) {
        return nil;
    }
    NSFetchRequest *request = [managedObjectModel fetchRequestFromTemplateWithName:@"LocationByFormattedAddress" substitutionVariables:[NSDictionary dictionaryWithObject:formattedAddress forKey:@"ADDRESS2"]];
    
    NSError *error; 
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error]; 
    if (!result) { 
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]]; 
    } 
    return result;  // Return the array of matches (could be empty)
}

// Returns first location that has an exact match for a rawAddress
- (Location *)locationWithRawAddress:(NSString *)rawAddress
{
    if (!rawAddress) {
        return nil;
    }
    // Fetch all RawAddress objects that match the string
    NSFetchRequest *request = [managedObjectModel fetchRequestFromTemplateWithName:@"RawAddressByString" substitutionVariables:[NSDictionary dictionaryWithObject:rawAddress forKey:@"ADDRESS"]];
    
    NSError *error; 
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error]; 
    if (!result) { 
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]]; 
    }
    if ([result count]>=1) {            // if there is a match
        // Return the Location that corresponds to that RawAddress
        RawAddress *rawAddrObj = [result objectAtIndex:0];
        return [rawAddrObj location];  
    }
    else {
        return nil;   // return nil if no matching Location
    }    
}

// Returns a sorted array of all locations whose memberOfList field starts with listNamePrefix.  
// Array is sorted in alphabetical order by the memberOfList field (i.e. by everything after the prefix)
// If no matches, returns an empty array.  If listNamePrefix is nil, returns nil
- (NSArray *)locationsMembersOfList:(NSString *)listNamePrefix
{
    if (!listNamePrefix) {
        return nil;
    }
    NSFetchRequest *request = [managedObjectModel fetchRequestFromTemplateWithName:@"LocationByMemberOfList" substitutionVariables:[NSDictionary dictionaryWithObject:listNamePrefix forKey:@"LIST_PREFIX"]];
    
    NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:@"memberOfList" 
                                                          ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sd1,nil]];
    NSError *error; 
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error]; 
    if (!result) { 
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]]; 
    } 
    return result;  // Return the array of matches (could be empty)
}

// Takes loc0 (typically a newly geocoded location) and see if there are any equivalent locations
// already in the Location store.  If so, then consolidate the two locations so there is only one left.
// If keepThisLocation is true, keeps loc0 and deletes the duplicate in the database, otherwise keeps
// the one in the database and deletes loc0.  
// To consolidate, combines the rawAddress strings and adds the to&from frequencies.    
// Returns a location -- either the original loc0 if there is no matching location, or 
// the consolidated matching location if there is one.
// Searches for equivalent matching locations simply looking for exact matches of Formatted Address.
// (this could be expanded in the future)
- (Location *)consolidateWithMatchingLocations:(Location *)loc0 keepThisLocation:(BOOL)keepThisLocation
{
    NSArray *matches = [self locationsWithFormattedAddress:[loc0 formattedAddress]];
    if (!matches) {   
        return loc0;  
    }
    else {  
        for (Location *loc1 in matches) {
            if (loc0 != loc1) {  // if this is actually a different object
                Location* returnLoc; // the location object we will return
                Location* deleteLoc;  // the location object we will consolidate and delete
                if (keepThisLocation) {
                    returnLoc = loc0;
                    deleteLoc = loc1;
                } else {
                    returnLoc = loc1;  
                    deleteLoc = loc0;
                }
                
                // consolidate from deleteLoc into returnLoc
                // loop thru and add each deleteLoc RawAddress and add to returnLoc
                for (RawAddress *deleteLocRawAddr in [deleteLoc rawAddresses]) {
                    [returnLoc addRawAddressString:[deleteLocRawAddr rawAddressString]];
                }
                // Add from and to frequency from deleteLoc into returnLoc
                [returnLoc setToFrequencyFloat:([returnLoc toFrequencyFloat] + [deleteLoc toFrequencyFloat])];
                [returnLoc setFromFrequencyFloat:([returnLoc fromFrequencyFloat] + [deleteLoc fromFrequencyFloat])];
                
                // Delete deleteLoc & return returnLoc
                [managedObjectContext deleteObject:deleteLoc];
                return returnLoc;
            }
        }
    }
    return loc0;  // return loc0 if no different matches were found
}

// Remove location from Core Data
- (void)removeLocation:(Location *)loc0
{
    [managedObjectContext deleteObject:loc0];
}

/*
 Implement by Sitanshu Joshi.
 Methods set values for save trip inTPServer.
 */
-(void)setRawAddressTo:(NSString *)rawAddr {
    rawAddressTo = rawAddr;
}

-(void)setRawAddressFrom:(NSString *)rawAddrFrom {
    rawAddressFrom = rawAddrFrom;
}

-(void)setGeoRespTo:(NSString *)geoResTo {
    geoRespTo = geoResTo;
}

-(void)setGeoRespFrom:(NSString *)geoResFrom {
    geoRespFrom = geoResFrom;
}

-(void)setGeoRespTimeTo:(NSString *)geoResTimeTo {
    geoRespTimeTo = geoResTimeTo;
}

-(void)setGeoRespTimeFrom:(NSString *)geoResTimeFrom {
    geoRespTimeFrom = geoResTimeFrom;
}

-(void)setIsFromGeo:(BOOL)isFromsGeo {
    isFromGeo = isFromsGeo;
}

-(void)setIsToGeo:(BOOL)isTosGeo {
    isToGeo = isTosGeo;
}


-(void)setIsLocationServiceEnable:(BOOL)isLocationServicesEnable
{
    isLocationServiceEnable = isLocationServicesEnable;
}
@end
