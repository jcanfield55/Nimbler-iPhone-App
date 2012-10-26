//
//  Locations.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/10/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Locations.h"
#import "LocationFromGoogle.h"
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

    NSString *geoURLResource;   // URL resource sent to geocoder for last raw address
    GeocodeRequestParameters* geoRequestParameters;  // parameters used for last geocoder request
    id <LocationsGeocodeResultsDelegate> geoCallbackDelegate;   // delegate to call when we have geocoder results
    NSString *reverseGeoURLResource;   // URL resource sent to reverse geocoder for last raw address
    GeocodeRequestParameters* reverseGeoRequestParameters;  // parameters used for last reverse geocoder request
    id <LocationsGeocodeResultsDelegate> reverseGeoCallbackDelegate;   // delegate to call when we have reverse geocoder results
    NSDate* lastIOSGeocodeTime;  // time last geocode request (forward or backward) was made
    
    CLGeocoder* clGeocoder;  // IOS Geocoder object
    
}
- (void)updateWithSelectedLocationIsFrom:(BOOL)isFrom selectedLocation:(Location *)selectedLocation oldSelectedLocation:(Location *)oldSelectedLocation;
- (void)updateInternalCache;
- (void)forwardGeocodeUsingGoogleWithParameters:(GeocodeRequestParameters *)parameters callBack:(id <LocationsGeocodeResultsDelegate>)delegate;
- (void)reverseGeocodeUsingGoogleWithParameters:(GeocodeRequestParameters *)parameters callBack:(id <LocationsGeocodeResultsDelegate>)delegate;
- (void)forwardGeocodeUsingIosWithParameters:(GeocodeRequestParameters *)parameters callback:(id <LocationsGeocodeResultsDelegate>)delegate;
- (void)reverseGeocodeUsingIosWithParameters:(GeocodeRequestParameters *)parameters callback:(id <LocationsGeocodeResultsDelegate>)delegate;
- (void)handleIosGeocodeWithParameters:(GeocodeRequestParameters *)parameters
                              response:(NSArray *)placemarks
                                 error:(NSError *)error
                              callback:(id <LocationsGeocodeResultsDelegate>)delegate;
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

// Returns true if a preLoad from file was executed, otherwise returns false
- (BOOL)preLoadIfNeededFromFile:(NSString *)filename latestVersionNumber:(NSDecimalNumber *)newVersion testAddress:(NSString *)testAddress
{
    BOOL returnValue = false;
    
    // Check there version number against the the PRELOAD_TEST_ADDRESS to see if we need to open the file
    NSArray* preloadTestLocs = [self locationsWithFormattedAddress:testAddress];
    
    // If there are matching locations for that station, 
    BOOL isNewerVersion = NO;  // true if we have a new version that needs loading
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
        returnValue = true;
        
        // Temporary, one-time code to reduce the frequency of current location by 100 - 7.0 (the new default)
        // Only do the one and only time we load Caltrain pre-load file version 1.100
        // This code can be removed by 12/2012
        if ([testAddress isEqualToString:CALTRAIN_PRELOAD_TEST_ADDRESS] &&
            [newVersion isEqualToNumber:[NSDecimalNumber decimalNumberWithString:@"1.100"]]) {
            NSArray* dbCurrentLocationArray = [self locationsWithFormattedAddress:CURRENT_LOCATION];
            if (dbCurrentLocationArray && [dbCurrentLocationArray count]>0) {
                Location* dbCurrentLoc = [dbCurrentLocationArray objectAtIndex:0];
                if ([dbCurrentLoc fromFrequencyFloat] >= 100.0) {
                    [dbCurrentLoc setFromFrequencyFloat:([dbCurrentLoc fromFrequencyFloat] - 100.0 + CURRENT_LOCATION_STARTING_FROM_FREQUENCY)];
                }
            }
        }
        // end of temporary code
        
        
        // Code adapted from http://stackoverflow.com/questions/10305535/iphone-restkit-how-to-load-a-local-json-file-and-map-it-to-a-core-data-entity and https://github.com/RestKit/RestKit/wiki/Object-mapping (bottom of page)
        NSStringEncoding encoding;
        NSError* error = nil;
        NSString* preloadPath = [[NSBundle mainBundle] pathForResource:filename ofType:nil]; 
        NSString *jsonText = [NSString stringWithContentsOfFile:preloadPath usedEncoding:&encoding error:&error];
        if (jsonText && !error) {
            
            id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
            id parsedData = [parser objectFromString:jsonText error:&error];
            if (parsedData == nil && error) {
                logError(@"Locations->preLoadIfNeededFromFile", [NSString stringWithFormat:@"Parsing error: %@", error]);
                return false;
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
                    for (LocationFromGoogle* matchingLocation in matchingLocations) {
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
                        NIMLOG_EVENT1(@"Preload loc: %@, toFreq=%f, fromFreq=%f", 
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
                logError(@"No results back from loading file at path:", preloadPath);
            }
        }
        else {
            logError(@"Could not load pre-load file",
                     [NSString stringWithFormat:@"file %@ at path %@, error: %@", filename, preloadPath, [error localizedDescription]]);
                      
        }
    }
    if (returnValue) {
        logEvent(FLURRY_PRELOADED_FILE, FLURRY_PRELOADED_FILE_NAME, filename, nil, nil, nil, nil, nil, nil);
    }
    return returnValue;
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

- (LocationFromIOS *)newLocationFromIOSWithPlacemark:(CLPlacemark *)placemark error:(NSError *)error;
{
    LocationFromIOS *loc = [NSEntityDescription insertNewObjectForEntityForName:@"LocationFromIOS" inManagedObjectContext:managedObjectContext];
    [loc initWithPlacemark:placemark error:error];
    [self setAreLocationsChanged:YES]; 
    return loc;
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
        NIMLOG_PERF1(@"sortedMatchingFromLocations count = %d", [sortedMatchingFromLocations count]);
        int i;
        for (i=0; (i < [sortedMatchingFromLocations count]) && 
             ((selectedFromLocation == [sortedMatchingFromLocations objectAtIndex:i]) ||
              [[sortedMatchingFromLocations objectAtIndex:i] fromFrequencyFloat] > TOFROM_FREQUENCY_VISIBILITY_CUTOFF); i++);
        matchingFromRowCount = i;
        NIMLOG_PERF1(@"MatchingFromRowCount = %d", matchingFromRowCount);
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
        NIMLOG_PERF1(@"sortedMatchingToLocations count = %d", [sortedMatchingToLocations count]);
        int i;
        for (i=0; (i < [sortedMatchingToLocations count]) && 
             ((selectedToLocation == [sortedMatchingToLocations objectAtIndex:i]) ||
             [[sortedMatchingToLocations objectAtIndex:i] toFrequencyFloat] > TOFROM_FREQUENCY_VISIBILITY_CUTOFF); i++);
        matchingToRowCount = i;
        NIMLOG_PERF1(@"matchingToRowCount = %d", matchingToRowCount);
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
    NIMLOG_PERF1(@"Entering updateInternal Cache");
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
    NIMLOG_PERF1(@"Now fetching sortedToLocations");
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
    NIMLOG_PERF1(@"Done updating Locations cache");
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
    if (!matches || [matches count]==0) {
        return loc0;  
    }
    else {
        Location* returnLoc; // the location object we will return
        if (keepThisLocation) {
            returnLoc = loc0;
        }
        for (Location *loc1 in matches) {
            if (loc0 != loc1) {  // if this is actually a different object
                Location* deleteLoc;  // the location object we will consolidate and delete
                if (!returnLoc) {
                    returnLoc = loc1;  // if no returnLoc has been set, make this loc1 the returnLoc
                    deleteLoc = loc0;  // and delete loc0 (just for this one time)
                } else {
                    deleteLoc = loc1;  // else if returnLoc is already set, then this loc1 must be deleted
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
            }
        }
        if (returnLoc) {
            return returnLoc;
        } else {
            return loc0;
        }
    }
}

// Remove location from Core Data
- (void)removeLocation:(Location *)loc0
{
    [managedObjectContext deleteObject:loc0];
}

- (void)forwardGeocodeWithParameters:(GeocodeRequestParameters *)parameters callBack:(id <LocationsGeocodeResultsDelegate>)delegate;
{
    if (parameters.apiType == GOOGLE_GEOCODER) {
        [self forwardGeocodeUsingGoogleWithParameters:parameters callBack:delegate];
    } else if (parameters.apiType == IOS_GEOCODER) {
            [self forwardGeocodeUsingIosWithParameters:parameters callback:delegate];
    }
    else {
        logError(@"Locations->forwardGeocodeWithParameters", @"Unknown apiType");
    }
    
}

- (void)forwardGeocodeUsingGoogleWithParameters:(GeocodeRequestParameters *)parameters callBack:(id <LocationsGeocodeResultsDelegate>)delegate;
{
    // Save the parameters and callBack object for when objectLoader called
    geoRequestParameters = parameters;
    geoCallbackDelegate = delegate;
    
    // Calculate the supportedRegionGeocodeString
    NSString* supportedRegionGeocodeString = [NSString stringWithFormat:@"%@,%@|%@,%@",
                                              [[parameters.supportedRegion minLatitude] stringValue],
                                              [[parameters.supportedRegion minLongitude] stringValue],
                                              [[parameters.supportedRegion maxLatitude] stringValue],
                                              [[parameters.supportedRegion maxLongitude] stringValue]];
    // Build the parameters into a resource string
    // US108 implementation (using "bounds" parameter)
    NSDictionary *googleParameters = [NSDictionary dictionaryWithKeysAndObjects: @"address", parameters.rawAddress,
                                      @"bounds", supportedRegionGeocodeString, @"sensor", @"true", nil];
    geoURLResource = [@"json" appendQueryParams:googleParameters];
    
    [rkGeoMgr loadObjectsAtResourcePath:geoURLResource delegate:self];
    
    NIMLOG_EVENT1(@"Geocode Parameter String = %@", geoURLResource);
}

- (void)reverseGeocodeWithParameters:(GeocodeRequestParameters *)parameters callBack:(id <LocationsGeocodeResultsDelegate>)delegate
{
    if (parameters.apiType == GOOGLE_GEOCODER) {
        [self reverseGeocodeUsingGoogleWithParameters:parameters callBack:delegate];
    }
    else if (parameters.apiType == IOS_GEOCODER) {
        [self reverseGeocodeUsingIosWithParameters:parameters callback:delegate];
    }
    else {
        logError(@"Locations->reverseGeocodeWithParameters", @"Unknown apiType");
    }
}

- (void)reverseGeocodeUsingGoogleWithParameters:(GeocodeRequestParameters *)parameters callBack:(id <LocationsGeocodeResultsDelegate>)delegate
{
    @try {
        // Save the parameters and callBack object for when objectLoader called
        reverseGeoRequestParameters = parameters;
        reverseGeoCallbackDelegate = delegate;
        
        NSString* latLngString = [NSString stringWithFormat:@"%f,%f",[parameters lat], [parameters lng]];
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                                @"latlng", latLngString,
                                @"sensor", @"true", nil];
        reverseGeoURLResource = [@"json" appendQueryParams:params];
        [rkGeoMgr loadObjectsAtResourcePath:reverseGeoURLResource delegate:self]; // Call the reverse Geocoder
    }
    @catch (NSException *exception) {
        logException(@"Locations->reverseGeocodeUsingGoogleWithParameters", @"", exception);
    }

}

// Object Loader for Google Geocoder
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects
{
    NSString* urlResource;
    GeocodeRequestParameters* parameters;
    id <LocationsGeocodeResultsDelegate> callback;
    BOOL isForwardGeocode; 
    @try {
        // Figure out which request this is from
        if ([[objectLoader resourcePath] isEqualToString:geoURLResource]) {
            urlResource = geoURLResource;
            parameters = geoRequestParameters;
            callback = geoCallbackDelegate;
            isForwardGeocode = YES;
            geoURLResource = nil;  // Reset this now that we have received this request
        }
        else if ([[objectLoader resourcePath] isEqualToString:reverseGeoURLResource]) {
            urlResource = reverseGeoURLResource;
            parameters = reverseGeoRequestParameters;
            callback = reverseGeoCallbackDelegate;
            isForwardGeocode = NO;
            reverseGeoURLResource = nil;  // Reset this now that we have received this request
        }
        else {
            // if this does not match the latest existing call, ignore it
            return;
        }
        NSString* isFromString = ([parameters isFrom] ? @"fromTable" : @"toTable");
        NSString* rawAddress = (isForwardGeocode ? [parameters rawAddress] : @"Reverse Geocode");
        
        // Get the status string the hard way by parsing the response string
        NSString* response = [[objectLoader response] bodyAsString];
        
        NSRange range = [response rangeOfString:@"\"status\""];
        if (range.location != NSNotFound) {
            NSString* responseStartingFromStatus = [response substringFromIndex:(range.location+range.length)];
            
            NSArray* atoms = [responseStartingFromStatus componentsSeparatedByString:@"\""];
            NSString* geocodeStatus = [atoms objectAtIndex:1]; // status string is second atom (first after the first quote)
            NIMLOG_EVENT1(@"Status: %@", geocodeStatus);
            
            if ([geocodeStatus compare:@"OK" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                NIMLOG_EVENT1(@"Returned Objects = %d", [objects count]);
                
                // Go through the returned objects and see which are in supportedRegion
                // DE18 new fix
                NSMutableArray* validLocations = [NSMutableArray arrayWithArray:objects];
                for (Location* loc in objects) {
                    if ([[parameters supportedRegion] isInRegionLat:[loc latFloat] Lng:[loc lngFloat]]) {
                        [loc setGeoCoderStatus:geocodeStatus];
                    } else {
                        // if a location not in supported region,
                        [validLocations removeObject:loc]; // take off the array
                        [self removeLocation:loc]; // and out of Core Data
                    }
                }
                NIMLOG_EVENT1(@"Geocode valid Locations = %d", [validLocations count]);
                if ([validLocations count]==0) {
                    logEvent(FLURRY_GEOCODE_RESULTS_NONE_IN_REGION,
                             FLURRY_TOFROM_WHICH_TABLE, isFromString,
                             FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                             nil, nil, nil, nil);
                }
                else if ([validLocations count]==1) {
                    logEvent(FLURRY_GEOCODE_RESULTS_ONE,
                             FLURRY_TOFROM_WHICH_TABLE, isFromString,
                             FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                             FLURRY_FORMATTED_ADDRESS, [[validLocations objectAtIndex:0] shortFormattedAddress],
                             nil, nil);
                } else {
                    logEvent(FLURRY_GEOCODE_RESULTS_MULTIPLE,
                             FLURRY_TOFROM_WHICH_TABLE, isFromString,
                             FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                             FLURRY_NUMBER_OF_GEOCODES, [NSString stringWithFormat:@"%d", [validLocations count]],
                             nil, nil);
                }
                
                [callback newGeocodeResults:validLocations
                                            withStatus:GEOCODE_STATUS_OK
                                            parameters:parameters];  // Callback delegate with results
            }
            
            else if ([geocodeStatus compare:@"ZERO_RESULTS" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                logEvent(FLURRY_GEOCODE_RESULTS_NONE,
                         FLURRY_TOFROM_WHICH_TABLE, isFromString,
                         FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                         nil, nil, nil, nil);
                NIMLOG_EVENT1(@"Zero results geocoding address");
                [callback newGeocodeResults:nil withStatus:GEOCODE_ZERO_RESULTS parameters:parameters];
            }
            else if ([geocodeStatus compare:@"OVER_QUERY_LIMIT" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                logEvent(FLURRY_GEOCODE_OVER_GOOGLE_QUOTA,
                         FLURRY_TOFROM_WHICH_TABLE, isFromString,
                         FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                         nil, nil, nil, nil);
                NIMLOG_ERR1(@"Geocode over query limit.  Status = %@", geocodeStatus);
                // If google geocoder unavailable, try iOS geocoder
                [parameters setApiType:IOS_GEOCODER];
                if (parameters.rawAddress) {
                    [self forwardGeocodeWithParameters:parameters callBack:callback];
                } else {
                    [self reverseGeocodeWithParameters:parameters callBack:callback];
                }
            }
            else if ([geocodeStatus compare:@"REQUEST_DENIED" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                logEvent(FLURRY_GEOCODE_OTHER_ERROR,
                         FLURRY_TOFROM_WHICH_TABLE, isFromString,
                         FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                         FLURRY_GEOCODE_ERROR, geocodeStatus,
                         nil, nil);
                NIMLOG_ERR1(@"Geocode request rejected, status= %@", geocodeStatus);
                // If google geocoder unavailable, try iOS geocoder
                [parameters setApiType:IOS_GEOCODER];
                if (parameters.rawAddress) {
                    [self forwardGeocodeWithParameters:parameters callBack:callback];
                } else {
                    [self reverseGeocodeWithParameters:parameters callBack:callback];
                }
            }
        }
        else { // geocoder did not come back with a status
            logEvent(FLURRY_GEOCODE_OTHER_ERROR,
                     FLURRY_TOFROM_WHICH_TABLE, isFromString,
                     FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                     FLURRY_GEOCODE_ERROR,
                     [NSString stringWithFormat:@"No status found.  Start of response: %@",[response substringToIndex:100U]],
                     nil, nil);
            // If google geocoder unavailable, try iOS geocoder
            [parameters setApiType:IOS_GEOCODER];
            if (parameters.rawAddress) {
                [self forwardGeocodeWithParameters:parameters callBack:callback];
            } else {
                [self reverseGeocodeWithParameters:parameters callBack:callback];
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"ToFromTableViewController->didLoadObjects", @"processing geocode response", exception);
        [callback newGeocodeResults:nil withStatus:GEOCODE_GENERIC_ERROR parameters:parameters];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    NIMLOG_ERR1(@"Error received from RKObjectManager: %@", error);
    NSString* urlResource;
    GeocodeRequestParameters* parameters;
    id <LocationsGeocodeResultsDelegate> callback;
    BOOL isForwardGeocode;
    
    // Figure out which request this is from (simply by which variable is not nil
    if (geoURLResource) {
        urlResource = geoURLResource;
        parameters = geoRequestParameters;
        callback = geoCallbackDelegate;
        isForwardGeocode = YES;
        geoURLResource = nil;  // Reset this now that we have received this request
    }
    else {
        urlResource = reverseGeoURLResource;
        parameters = reverseGeoRequestParameters;
        callback = reverseGeoCallbackDelegate;
        isForwardGeocode = NO;
        reverseGeoURLResource = nil;  // Reset this now that we have received this request
    }
    
    NSString* isFromString = ([parameters isFrom] ? @"fromTable" : @"toTable");
    NSString* rawAddress = [parameters rawAddress];
    
    if ([[error localizedDescription] rangeOfString:@"client is unable to contact the resource"].location != NSNotFound) {

        logEvent(FLURRY_GEOCODE_NO_NETWORK,
                 FLURRY_TOFROM_WHICH_TABLE, isFromString,
                 FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                 FLURRY_GEOCODE_ERROR, [error localizedDescription],
                 nil, nil);
        [callback newGeocodeResults:nil withStatus:GEOCODE_NO_NETWORK parameters:parameters];
    }
    else {
        logEvent(FLURRY_GEOCODE_OTHER_ERROR,
                 FLURRY_TOFROM_WHICH_TABLE, isFromString,
                 FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                 FLURRY_GEOCODE_ERROR, [error localizedDescription],
                 nil, nil);
        [callback newGeocodeResults:nil withStatus:GEOCODE_GENERIC_ERROR parameters:parameters];
    }
}

- (void)forwardGeocodeUsingIosWithParameters:(GeocodeRequestParameters *)parameters callback:(id <LocationsGeocodeResultsDelegate>)delegate
{
    if (!clGeocoder) {
        clGeocoder = [[CLGeocoder alloc] init];
    }
    if ([clGeocoder isGeocoding]) { // if already geocoding
        if ([lastIOSGeocodeTime timeIntervalSinceNow] < -5) { // if more than 7 seconds since last geocode
            [clGeocoder cancelGeocode];  // cancel previous geocode and let this one go thru
        } else {
            logError(@"Locations->forwardGeocodeUsingIosWithParameters",
                     @"Geocode already in progress");
            return;
        }
    }
    lastIOSGeocodeTime = [NSDate date];
    [clGeocoder geocodeAddressString:[parameters rawAddress]
                            inRegion:[[parameters supportedRegion] encirclingCLRegion]
                   completionHandler:^(NSArray *placemark, NSError *error) {
                       [self handleIosGeocodeWithParameters:parameters
                                                   response:placemark
                                                      error:error
                                                   callback:delegate];
                   }];
}

- (void)reverseGeocodeUsingIosWithParameters:(GeocodeRequestParameters *)parameters callback:(id <LocationsGeocodeResultsDelegate>)delegate
{
    if (!clGeocoder) {
        clGeocoder = [[CLGeocoder alloc] init];
    }
    if ([clGeocoder isGeocoding]) { // if already geocoding
        if ([lastIOSGeocodeTime timeIntervalSinceNow] < -5) { // if more than 5 seconds since last geocode
            [clGeocoder cancelGeocode];  // cancel previous geocode and let this one go thru
        } else {
            logError(@"Locations->forwardGeocodeUsingIosWithParameters",
                     @"Geocode already in progress");
            return;
        }
    }
    lastIOSGeocodeTime = [NSDate date];
    CLLocation* clLocation = [[CLLocation alloc] initWithLatitude:[parameters lat] longitude:[parameters lng]];
    [clGeocoder reverseGeocodeLocation:clLocation completionHandler:^(NSArray *placemark, NSError *error) {
                       [self handleIosGeocodeWithParameters:parameters
                                                   response:placemark
                                                      error:error
                                                   callback:delegate];
                   }];
}

// Callback routine for IOS forward and reverse geocoding 
- (void)handleIosGeocodeWithParameters:(GeocodeRequestParameters *)parameters
                              response:(NSArray *)placemarks
                                 error:(NSError *)error
                              callback:(id <LocationsGeocodeResultsDelegate>)callback
{
    BOOL isForwardGeocode = (parameters.rawAddress != nil);  // Forward Geocoding if there is a rawAddress

    NSString* isFromString = ([parameters isFrom] ? @"fromTable" : @"toTable");
    NSString* rawAddress = (isForwardGeocode ? [parameters rawAddress] : @"Reverse Geocode");;

    if (error) {
        // kCLErrorNetwork case
        if (error.code == kCLErrorNetwork) {
            logEvent(FLURRY_GEOCODE_NO_NETWORK,
                     FLURRY_TOFROM_WHICH_TABLE, isFromString,
                     FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                     FLURRY_GEOCODE_ERROR, [error localizedDescription],
                     nil, nil);
            [callback newGeocodeResults:nil withStatus:GEOCODE_NO_NETWORK parameters:parameters];
            return;
        }
        
        // kCLErrorGeocodeFoundNoResult case
        else if (error.code == kCLErrorGeocodeFoundNoResult) {
            logEvent(FLURRY_GEOCODE_RESULTS_NONE,
                     FLURRY_TOFROM_WHICH_TABLE, isFromString,
                     FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                     nil, nil, nil, nil);
            NIMLOG_EVENT1(@"Zero results geocoding address, error: %@", [error localizedDescription]);
            [callback newGeocodeResults:nil withStatus:GEOCODE_ZERO_RESULTS parameters:parameters];
            return;
        }
        
        // kCLErrorGeocodeFoundPartialResult case
        else if (error.code==kCLErrorGeocodeFoundPartialResult) {
            if (!placemarks) {
                logEvent(FLURRY_GEOCODE_IOS_PARTIAL_RESULTS_NONE,
                         FLURRY_TOFROM_WHICH_TABLE, isFromString,
                         FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                         FLURRY_GEOCODE_ERROR, [error localizedDescription], nil, nil);
                [callback newGeocodeResults:nil withStatus:GEOCODE_ZERO_RESULTS parameters:parameters];
                return;
            }
            // else if there are placemarks, process them as you would a full result (below)
        }
        
        // kCLErrorGeocodeCanceled case
        else if (error.code == kCLErrorGeocodeCanceled) {
            logError(@"Locations->handleIosGeocodeWithParameters",
                     [NSString stringWithFormat:@"Geocode canceled with error: %@", [error localizedDescription]]);
            return;  // don't callback, notify the user or do anything else
        }
        
        // Unknown error case
        else {
            logError(@"Locations->handleIosGeocodeWithParameters",
                     [NSString stringWithFormat:@"Geocode unknown error code, error: %@", [error localizedDescription]]);
            [callback newGeocodeResults:nil withStatus:GEOCODE_GENERIC_ERROR parameters:parameters];
            return;
        }

    }
    if (placemarks) { // if we have geolocations
        NIMLOG_EVENT1(@"Returned Objects = %d", [placemarks count]);
        
        // Go through the returned objects and see which are in supportedRegion
        // DE18 new fix
        NSMutableArray* validLocations = [NSMutableArray arrayWithCapacity:[placemarks count]];
        for (CLPlacemark* placemark in placemarks) {
            LocationFromIOS* loc = [self newLocationFromIOSWithPlacemark:placemark error:error];
            if ([[parameters supportedRegion] isInRegionLat:[loc latFloat] Lng:[loc lngFloat]]) {
                [validLocations addObject:loc];
            } else {
                // if a location not in supported region,
                [self removeLocation:loc]; // and out of Core Data
            }
        }
        NIMLOG_EVENT1(@"Geocode valid Locations = %d", [validLocations count]);

        if ([validLocations count]==0) {
            logEvent(FLURRY_GEOCODE_RESULTS_NONE_IN_REGION,
                     FLURRY_TOFROM_WHICH_TABLE, isFromString,
                     FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                     nil, nil, nil, nil);
        }
        else if ([validLocations count]==1) {
            logEvent(FLURRY_GEOCODE_RESULTS_ONE,
                     FLURRY_TOFROM_WHICH_TABLE, isFromString,
                     FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                     FLURRY_FORMATTED_ADDRESS, [[validLocations objectAtIndex:0] shortFormattedAddress],
                     nil, nil);
        } else {
            logEvent(FLURRY_GEOCODE_RESULTS_MULTIPLE,
                     FLURRY_TOFROM_WHICH_TABLE, isFromString,
                     FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                     FLURRY_NUMBER_OF_GEOCODES, [NSString stringWithFormat:@"%d", [validLocations count]],
                     nil, nil);
        }
        
        [callback newGeocodeResults:validLocations
                         withStatus:GEOCODE_STATUS_OK
                         parameters:parameters];  // Callback delegate with results
    }
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
