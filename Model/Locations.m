//
//  Locations.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/10/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Locations.h"
#import "UtilityFunctions.h"
#import "Plan.h"
#import "StationListElement.h"
#import "nc_AppDelegate.h"
#import "LocationFromLocalSearch.h"

// Internal variables and methods

@interface Locations ()
{
    NSArray *sortedMatchingFromLocations; // All from locations that somehow match the typedFromString
    NSArray *sortedMatchingToLocations;
    NSArray *sortedFromLocations;  // All locations with fromFrequency > TOFROM_FREQUENCY_VISIBILITY_CUTOFF sorted by from frequency
    NSArray *sortedToLocations;    // All locations with toFrequency > TOFROM_FREQUENCY_VISIBILITY_CUTOFF sorted by to frequency
    NSFetchRequest *fetchRequestFromFreqThreshold;
    NSFetchRequest *fetchRequestToFreqThreshold;
    NSFetchRequest *fetchReqSearchableGoogleFromLocations;
    NSFetchRequest *fetchReqSearchableIosFromLocations;

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
    
    MKLocalSearchRequest *localSearchRequest; //MKLocalSearchRequest Object
    MKCoordinateRegion mpRegion;  // Supported Region For MKLocalSearch
    BOOL useExistingMpRegion;  // True if you can re-use the existing value of mpRegion.  Reset every now and then so that it will incorporate a new current location.
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
@synthesize tempSelectedFromLocation;
@synthesize tempSelectedToLocation;
@synthesize isLocationSelected;
@synthesize sortedMatchingFromLocations;
@synthesize sortedMatchingToLocations;
@synthesize matchingFromRowCount;
@synthesize matchingToRowCount;

@synthesize searchableFromLocations;
@synthesize searchableToLocations;

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
        
        // Create MKLocalSearchRequest Instance
        localSearchRequest = [[MKLocalSearchRequest alloc] init];
        
    }

    return self;
}

// Returns true if a preLoad from file was executed, otherwise returns false
- (BOOL)preLoadIfNeededFromFile:(NSString *)filename latestVersionNumber:(NSDecimalNumber *)newVersion testAddress:(NSString *)testAddress
{
    BOOL returnValue = false;
    
    @try {
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
    @catch (NSException *exception) {
        logException(@"Locations->preLoadIfNeededFromFile",
                     [NSString stringWithFormat:@"filename = %@, newVersionNumber = %@, testAddress = %@",
                      filename, newVersion, testAddress], exception);
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
    if(sFL){
        tempSelectedFromLocation = sFL;
    }
    selectedFromLocation = sFL;
    [self updateWithSelectedLocationIsFrom:TRUE selectedLocation:selectedFromLocation oldSelectedLocation:oldSelectedFromLocation];
    oldSelectedFromLocation = selectedFromLocation;
    useExistingMpRegion = false;
}

-(void)setSelectedToLocation:(Location *)sTL
{
    if(sTL){
        tempSelectedToLocation = sTL;
    }
    selectedToLocation = sTL;
    [self updateWithSelectedLocationIsFrom:FALSE selectedLocation:selectedToLocation oldSelectedLocation:oldSelectedToLocation];
    oldSelectedToLocation = selectedToLocation;
    useExistingMpRegion = false; 
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

- (LocationFromGoogle *)newEmptyLocationFromGoogle
{
    LocationFromGoogle *l = [NSEntityDescription insertNewObjectForEntityForName:@"LocationFromGoogle" inManagedObjectContext:managedObjectContext];
    NSMutableArray *searchableLocations = [[NSMutableArray alloc] initWithArray:searchableFromLocations];
    BOOL containsLocation = false;
    for(int i=0;i<[searchableLocations count];i++){
        Location *tempLoc = [searchableLocations objectAtIndex:i];
        if([tempLoc.formattedAddress isEqualToString:l.formattedAddress]){
            containsLocation = true;
            break;
        }
    }
    if(!containsLocation && searchableFromLocations){
        [searchableLocations addObject:l];
        searchableFromLocations = searchableLocations;
    }
    
    NSMutableArray *searchabletoLocations = [[NSMutableArray alloc] initWithArray:searchableToLocations];
    BOOL containsLocations = false;
       for(int i=0;i<[searchabletoLocations count];i++){
          Location *tempLoc = [searchabletoLocations objectAtIndex:i];
           if([tempLoc.formattedAddress isEqualToString:l.formattedAddress]){
               containsLocations = true;
                break;
            }
       }
    if(!containsLocations && searchableToLocations){
        [searchabletoLocations addObject:l];
        searchableToLocations = searchabletoLocations;
    }
    
    [self setAreLocationsChanged:YES]; // DE30 fix (2 of 2)
    return l;
}

- (LocationFromIOS *)newLocationFromIOSWithPlacemark:(CLPlacemark *)placemark error:(NSError *)error
{
    ToFromViewController *toFromVC = [nc_AppDelegate sharedInstance].toFromViewController;
    if(!searchableFromLocations|| !searchableToLocations){
        if(toFromVC.editMode != NO_EDIT){
            [self fetchSearchableLocations];
        }
    }
    
    LocationFromIOS *loc = [NSEntityDescription insertNewObjectForEntityForName:@"LocationFromIOS" inManagedObjectContext:managedObjectContext];
    [loc initWithPlacemark:placemark error:error];
    NSMutableArray *searchableLocations = [[NSMutableArray alloc] initWithArray:searchableFromLocations];
    BOOL containsLocation = false;
    for(int i=0;i<[searchableLocations count];i++){
        Location *tempLoc = [searchableLocations objectAtIndex:i];
        if([tempLoc.formattedAddress isEqualToString:loc.formattedAddress]){
            containsLocation = true;
            break;
        }
    }
    if(!containsLocation && searchableFromLocations){
        [searchableLocations addObject:loc];
        searchableFromLocations = searchableLocations;
    }
    
    NSMutableArray *searchabletoLocations = [[NSMutableArray alloc] initWithArray:searchableToLocations];
    BOOL containsLocations = false;
     for(int i=0;i<[searchabletoLocations count];i++){
        Location *tempLoc = [searchabletoLocations objectAtIndex:i];
            if([tempLoc.formattedAddress isEqualToString:loc.formattedAddress]){
                containsLocations = true;
                break;
            }
        }
        if(!containsLocations && searchableToLocations){
          [searchabletoLocations addObject:loc];
          searchableToLocations = searchabletoLocations;
        }
    [self setAreLocationsChanged:YES];
    return loc;
}

// Create new LocationFromIos object from MkLocalSearchResponse
- (LocationFromLocalSearch *)newLocationFromIOSWithPlacemark:(CLPlacemark *)placemark error:(NSError *)error IsLocalSearchResult:(BOOL) isLocalSearchResult locationName:(NSString *)locationName
{
    LocationFromLocalSearch *locFromLocalSearch = [[LocationFromLocalSearch alloc] init];
    locFromLocalSearch.locationName = locationName;
    [locFromLocalSearch initWithPlacemark:placemark error:error];
    return locFromLocalSearch;
}

//Add selected Local Search Result to Location and remove from LocationFromLocalSearch
-(LocationFromIOS *)selectedLocationOfLocalSearchWithLocation:(LocationFromLocalSearch *)localSearchLocation IsFrom:(BOOL)isFrom error:(NSError *)error
{
    LocationFromIOS *loc = [NSEntityDescription insertNewObjectForEntityForName:@"LocationFromIOS" inManagedObjectContext:managedObjectContext];
    //loc.placeName = localSearchLocation.placeName;
    [loc initWithPlacemark:localSearchLocation.placemark error:error];
    loc.formattedAddress = localSearchLocation.formattedAddress;
    [loc setExcludeFromSearch:[NSNumber numberWithBool:false]];
    [loc setLocationName:localSearchLocation.locationName];
    NSMutableArray *localSearchArr;
    if(isFrom){
        if([tempSelectedFromLocation.lat doubleValue] == [loc.lat doubleValue] && [tempSelectedFromLocation.lng doubleValue] == [loc.lng doubleValue]){
            [managedObjectContext deleteObject:loc];
            return (LocationFromIOS *)tempSelectedFromLocation;
        }
        localSearchArr = [[NSMutableArray alloc] initWithArray:sortedMatchingFromLocations];
        [localSearchArr removeObject:localSearchLocation];
        sortedMatchingFromLocations = localSearchArr;
        matchingFromRowCount = [sortedMatchingFromLocations count];
        
        for(int i=0;i<[sortedFromLocations count];i++){
            Location *locForRemoveObj = [sortedFromLocations objectAtIndex:i];
            if([locForRemoveObj.lat doubleValue] == [loc.lat doubleValue] && [locForRemoveObj.lng doubleValue] == [loc.lng doubleValue]){
                [managedObjectContext deleteObject:loc];
                return (LocationFromIOS *)locForRemoveObj;
            }
        }
    }
    else{
        if([tempSelectedToLocation.lat doubleValue] == [loc.lat doubleValue] && [tempSelectedToLocation.lng doubleValue] == [loc.lng doubleValue]){
            [managedObjectContext deleteObject:loc];
            return (LocationFromIOS *)tempSelectedToLocation;
        }
        localSearchArr = [[NSMutableArray alloc] initWithArray:sortedMatchingToLocations];
        [localSearchArr removeObject:localSearchLocation];
        sortedMatchingToLocations = localSearchArr;
        matchingToRowCount = [sortedMatchingToLocations count];
        
        for(int i=0;i<[sortedToLocations count];i++){
            Location *locForRemoveObj = [sortedToLocations objectAtIndex:i];
            if([locForRemoveObj.lat doubleValue] == [loc.lat doubleValue] && [locForRemoveObj.lng doubleValue] == [loc.lng doubleValue]){
                [managedObjectContext deleteObject:loc];
                return (LocationFromIOS *)locForRemoveObj;
            }
        }
    }
    areMatchingLocationsChanged = YES;
    [self setAreLocationsChanged:NO];
    return loc;
}

// John note:  This code is currently unused (3/1/2013)
// Returns an array of Location objects that are created based on matches to PreloadStations
// A pre-load station matches when each typed token has a substring match with the preloadStation name
- (NSArray *) preloadStationLocationsMatchingTypedAddress:(NSString *)string{
    NSString *newString = [self rawAddressWithOutAgencyName:[string lowercaseString] SearchStringArray:SEARCH_STRINGS_ARRAY];
    newString = [newString stringByReplacingOccurrencesOfString:@"," withString:@" "];
    NSString *tempString = [newString substringFromIndex:[newString length] - 1];
    if([tempString rangeOfString:@" "].location != NSNotFound){
        newString = [newString substringToIndex:[newString length] - 1];
    }
        
    NSArray *tokens = [newString componentsSeparatedByString:@" "];
    NSMutableArray *predicates = [[NSMutableArray alloc] init];
    for(int i=0;i<[tokens count];i++){
        NSPredicate *resultPredicate = [NSPredicate
                                        predicateWithFormat:@"self.stop.formattedAddress CONTAINS[cd] %@",[tokens objectAtIndex:i]];
        [predicates addObject:resultPredicate];
    }
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    NSFetchRequest * fetchStationListElement = [[NSFetchRequest alloc] init];
    [fetchStationListElement setEntity:[NSEntityDescription entityForName:@"StationListElement" inManagedObjectContext:managedObjectContext]];
    [fetchStationListElement setPredicate:predicate];
    
    NSArray * arrayStationListElement = [managedObjectContext executeFetchRequest:fetchStationListElement error:nil];
    NSMutableArray *arrLocations = [[NSMutableArray alloc] init];
    for(int i=0;i<[arrayStationListElement count];i++){
        StationListElement *listElement = [arrayStationListElement objectAtIndex:i];
         if(listElement.stop){
            Location *loc = [[nc_AppDelegate sharedInstance].stations createNewLocationObjectFromGtfsStop:listElement.stop :listElement];
            Location* newLoc = [self consolidateWithMatchingLocations:loc keepThisLocation:NO];
             if (loc == newLoc) {
                 [arrLocations addObject:newLoc];  // only add to list if loc is not a duplicate of an existing Location object
             }
        }
    }
    return arrLocations;
}

// John note:  This code is currently unused (3/1/2013)
// Returns an array of Location objects that are matches typedString
// Searches from Locations in startArray if size < LOCATIONS_THRESHOLD_TO_SEARCH_USING_COREDATA, otherwise searches full database using a coredata
// Sorts using sortDescArray when retrieving from CoreData
- (NSArray *)locationsMatchingTypedAddress:(NSString *)typedString fromArray:(NSArray *)startArray sortDescArray:(NSArray *)sortDescArray
{
    NSMutableArray* newArray = [NSMutableArray arrayWithCapacity:([startArray count]/8)];
    // If startArray is small enough, figure out the matches the old-fashioned way
    if ([startArray count] >=LOCATIONS_THRESHOLD_TO_SEARCH_USING_COREDATA) {
        // TODO:  Get a new startArray containing all Locations not equal to LocationsFromGoogle
    }
    
    if ([startArray count] < LOCATIONS_THRESHOLD_TO_SEARCH_USING_COREDATA) {
        for (Location *loc in startArray) {
            if ([loc isMatchingTypedString:typedString]) {  // if loc matches the new string
                [newArray addObject:loc];  //  add loc to the new array
            }
        }
    }
    
    NSString *newString = [self rawAddressWithOutAgencyName:[typedString lowercaseString] SearchStringArray:SEARCH_STRINGS_ARRAY];
    newString = [newString stringByReplacingOccurrencesOfString:@"," withString:@" "];
    NSString *tempString = [newString substringFromIndex:[newString length] - 1];
    if([tempString rangeOfString:@" "].location != NSNotFound){
        newString = [newString substringToIndex:[newString length] - 1];
    }
    
    NSArray *tokens = [newString componentsSeparatedByString:@" "];
    NSMutableArray *predicates = [[NSMutableArray alloc] init];
    for(int i=0;i<[tokens count];i++){
        NSPredicate *resultPredicate = [NSPredicate
                                        predicateWithFormat:@"ANY addressComponents.longName BEGINSWITH[cd] %@",[tokens objectAtIndex:i]];
        [predicates addObject:resultPredicate];
    }
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    NSFetchRequest * fetchStationListElement = [[NSFetchRequest alloc] init];
    [fetchStationListElement setEntity:[NSEntityDescription entityForName:@"LocationFromGoogle" inManagedObjectContext:managedObjectContext]];
    [fetchStationListElement setPredicate:predicate];
    if (sortDescArray && sortDescArray.count>0) {
        [fetchStationListElement setSortDescriptors:sortDescArray];
    }
    
    NSError* error;
    NSArray * arrLocations = [managedObjectContext executeFetchRequest:fetchStationListElement error:&error];
    if (!arrLocations) {
        logError(@"Locations -> locationsMatchingTypedAddress", [NSString stringWithFormat:@"CoreData fetch error: %@", error]);
        return [NSArray array];
    }
    
    return arrLocations;
}


// Custom setter for updated typedFromString that recomputes the sortedMatchingFromLocations and row count
- (void)setTypedFromString:(NSString *)typedFromStr0
{
    ToFromViewController *toFromVC = [nc_AppDelegate sharedInstance].toFromViewController;
     if(!searchableFromLocations|| !searchableToLocations){
       if(toFromVC.editMode != NO_EDIT){
          [self fetchSearchableLocations];
       }
     }
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
        if (typedFromString && [typedFromString length]>0 && [typedFromStr0 hasPrefix:typedFromString]) { // if new string is an extension of the previoeus one...
            startArray = sortedMatchingFromLocations;  // start with the last array of matches, and narrow from there
        }
        else {
            startArray = searchableFromLocations;    // otherwise, start fresh with all searchable from locations
        }
        typedFromString = typedFromStr0;

//        NIMLOG_PERF2(@"Start Locations search");
//        NSArray *newArray = [self locationsMatchingTypedAddress:typedFromString
//                                                      fromArray:startArray
//                                                  sortDescArray:[NSArray arrayWithObjects:sd1,sd2,nil]];
        NSMutableArray *newArray = [NSMutableArray array];
        NIMLOG_PERF2(@"Start finding typed string matches, count=%d", [startArray count]);
        for (Location *loc in startArray) {
            if([loc isKindOfClass:[LocationFromLocalSearch class]]){
                
                    [newArray addObject:loc];
            }
            else if ([loc isMatchingTypedString:typedFromString]) {  // if loc matches the new string
                [newArray addObject:loc];  //  add loc to the new array
            }
        }
        NIMLOG_PERF2(@"Finished finding typed string matches, newArray count=%d", [newArray count]);
//        NIMLOG_PERF2(@"Finished.  Count = %d", [newArray count]);
        // Merge the results of typed string with newarray.
//        if(typedFromString.length >= 3){
//            NSArray *arrLocations = [self preloadStationLocationsMatchingTypedAddress:typedFromString];
//            [newArray addObjectsFromArray:arrLocations];
//        }
        if (![newArray isEqualToArray:sortedMatchingFromLocations]) { // if there is a change
            sortedMatchingFromLocations = newArray;
            areMatchingLocationsChanged = YES;   // mark for refreshing the table
        }
        matchingFromRowCount = [sortedMatchingFromLocations count];  // cases that match typing are included even if they have frequency=0
//        if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= IOS_LOCALSEARCH_VER) {
//            [self setTypedFromStringForLocalSearch:[self typedFromString]];
//        }
    }
}

// Custom setter for updated typedToString that recomputes the sortedMatchingToLocations and row count
- (void)setTypedToString:(NSString *)typedToStr0
{
    ToFromViewController *toFromVC = [nc_AppDelegate sharedInstance].toFromViewController;
    if(!searchableFromLocations|| !searchableToLocations){
      if(toFromVC.editMode != NO_EDIT){
         [self fetchSearchableLocations];
      }
    }
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
            startArray = searchableToLocations;    // otherwise, start fresh with all searchable To locations
        }
        typedToString = typedToStr0;   
        NSMutableArray *newArray = [NSMutableArray array];
        for (Location *loc in startArray) {
            if([loc isKindOfClass:[LocationFromLocalSearch class]]){
                [newArray addObject:loc];
            }
            else if ([loc isMatchingTypedString:typedToStr0]) {  // if loc matches the new string
                [newArray addObject:loc];  //  add loc to the new array
            }
        }
//        for (Location *loc in startArray) {
//                if ([loc isMatchingTypedString:typedToString]) {  // if loc matches the new string
//                    [newArray addObject:loc];  //  add loc to the new array
//                }
//        }
        // Merge the results of typed string with newarray.
//        if(typedToString.length >= 3){
//            NSArray *arrLocations = [self preloadStationLocationsMatchingTypedAddress:typedToString];
//            [newArray addObjectsFromArray:arrLocations];
//        }
        if (![newArray isEqualToArray:sortedMatchingToLocations]) { // if there is a change
            sortedMatchingToLocations = newArray;
            areMatchingLocationsChanged = YES;   // mark for refreshing the table
        }
        matchingToRowCount = [sortedMatchingToLocations count];  // cases that match typing are included even if they have frequency=0
    }
}

// Set Region For MKLocalSearch
-(MKCoordinateRegion)setRegionForMKLocalSeach{
    if (useExistingMpRegion) {
        return mpRegion;
    }
    SupportedRegion *supportedRegion = [[nc_AppDelegate sharedInstance].toFromViewController supportedRegion];
    CLLocation* currentCLLocation = [[nc_AppDelegate sharedInstance] locationFromlocManager];
    CLLocationCoordinate2D coordinate = [currentCLLocation coordinate];
    if (currentCLLocation && [supportedRegion isInRegionLat:coordinate.latitude Lng:coordinate.longitude]) {
        // If current location is in supportedRegion, then center region around coordinate (DE367 fix)
        mpRegion =  MKCoordinateRegionMakeWithDistance(coordinate, MK_LOCAL_SEARCH_SPAN, MK_LOCAL_SEARCH_SPAN);
    }
    else {
        // Otherwise just return the supportedRegion (DE367 fix)
        mpRegion = [supportedRegion equivalentMKCoordinateRegion];
    }
    useExistingMpRegion = true;
    return mpRegion;
}

- (NSArray *) locationsWithLat:(double)lat Lng:(double)lng FromArray:(NSArray *)array{
   NSMutableArray *mutableLocations = [[NSMutableArray alloc] init];
    for(int i=0;i<[array count];i++){
        Location *loc = [array objectAtIndex:i];
        if([loc.lat doubleValue] == lat && [loc.lng doubleValue] == lng){
            [mutableLocations addObject:loc];
        }
    }
    return mutableLocations;
}

- (NSArray *) locationsWithLat:(double)lat Lng:(double)lng{
    NSFetchRequest * fetchLocations = [[NSFetchRequest alloc] init];
    [fetchLocations setEntity:[NSEntityDescription entityForName:@"Location"  inManagedObjectContext:managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lat=%lf && lng=%lf",lat,lng];
    [fetchLocations setPredicate:predicate];
    NSArray * arrayAgencies = [managedObjectContext executeFetchRequest:fetchLocations error:nil];
    return arrayAgencies;
}
// Local Search that recomputes the sortedMatchingFromLocations and row count
- (void)setTypedFromStringForLocalSearch:(NSString *)typedFromStr0
{
   NSMutableArray *localSearchFromLocations = [[NSMutableArray alloc] initWithArray:sortedMatchingFromLocations];
    for(int i=0;i<[localSearchFromLocations count];i++){
        LocationFromLocalSearch *loc = [localSearchFromLocations objectAtIndex:i];
        if([loc isKindOfClass:[LocationFromLocalSearch class ]]){
                [localSearchFromLocations removeObject:loc];
                i =i -1;
        }
    }
    
    if([typedFromStr0 length]>=3){
        // Perform a new search.
        localSearchRequest.naturalLanguageQuery = typedFromStr0;
        localSearchRequest.region = [self setRegionForMKLocalSeach];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        MKLocalSearch  *localSearch = [[MKLocalSearch alloc] initWithRequest:localSearchRequest];
       
        [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error){
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            if (error != nil) {
                NIMLOG_ERR1(@"MKLocalSearch Error = %@/%d",[error localizedDescription],[response.mapItems count]);
                return;
            }
            
            if ([response.mapItems count] == 0) {
                return;
                
            }
    
//           if(isLocationSelected){ No need in LatestUI
//             return;
//               
//           }
         for(int i=0;i<[response.mapItems count];i++){
             NSError *error = nil;
            
             MKMapItem *mapItem = [response.mapItems objectAtIndex:i];
             
             if ([[[nc_AppDelegate sharedInstance].toFromViewController supportedRegion] isInRegionLat:mapItem.placemark.location.coordinate.latitude Lng:mapItem.placemark.location.coordinate.longitude]) {
                     LocationFromLocalSearch *loc = [self newLocationFromIOSWithPlacemark:mapItem.placemark error:error IsLocalSearchResult:true locationName:mapItem.name];

                 NSArray *locations = [self locationsWithLat:[loc.lat doubleValue] Lng:[loc.lng doubleValue] FromArray:searchableFromLocations];
                 if(![localSearchFromLocations containsObject:loc] && [locations count] == 0){
                    [localSearchFromLocations addObject:loc];
                 }
             }
             
         }
          sortedMatchingFromLocations = localSearchFromLocations;
          matchingFromRowCount = [sortedMatchingFromLocations count];
          areMatchingLocationsChanged = YES;
            
        [[nc_AppDelegate sharedInstance].toFromViewController.fromTableVC reloadLocationWithLocalSearch];
           
        }];
        
    }
    else {
        sortedMatchingFromLocations = localSearchFromLocations;
        matchingFromRowCount = [sortedMatchingFromLocations count];
        areMatchingLocationsChanged = YES;
        [[nc_AppDelegate sharedInstance].toFromViewController.fromTableVC reloadLocationWithLocalSearch];
    }
}

// Local Search that recomputes the sortedMatchingToLocations and row count
- (void)setTypedToStringForLocalSearch:(NSString *)typedToStr0
{
    NSMutableArray *localSearchToLocations = [[NSMutableArray alloc] initWithArray:sortedMatchingToLocations];
    for(int i=0;i<[localSearchToLocations count];i++){
        LocationFromLocalSearch *loc = [localSearchToLocations objectAtIndex:i];
       if([loc isKindOfClass:[LocationFromLocalSearch class ]]){
            [localSearchToLocations removeObject:loc];
            i =i -1;
           
        }
    }
    if([typedToStr0 length]>=3){
        // Perform a new search.
        
        localSearchRequest.naturalLanguageQuery = typedToStr0;
        localSearchRequest.region = [self setRegionForMKLocalSeach];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        MKLocalSearch  *localSearch = [[MKLocalSearch alloc] initWithRequest:localSearchRequest];
        
        [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error){
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            if (error != nil) {
                
                NIMLOG_ERR1(@"MKLocalSearch Error = %@",[error localizedDescription]);
                return;
            }
            
            if ([response.mapItems count] == 0) {
                return;
                
            }
            
//            if(isLocationSelected){ No need in LatestUI
//                return;
//                
//            }
            for(int i=0;i<[response.mapItems count];i++){
                NSError *error = nil;
                MKMapItem *mapItem = [response.mapItems objectAtIndex:i];
                if ([[[nc_AppDelegate sharedInstance].toFromViewController supportedRegion] isInRegionLat:mapItem.placemark.location.coordinate.latitude Lng:mapItem.placemark.location.coordinate.longitude]) {
                    
                    LocationFromLocalSearch *loc = [self newLocationFromIOSWithPlacemark:mapItem.placemark error:error IsLocalSearchResult:true locationName:mapItem.name];
                    
                     NSArray *locations = [self locationsWithLat:[loc.lat doubleValue] Lng:[loc.lng doubleValue] FromArray:searchableToLocations]; 
                    if(![localSearchToLocations containsObject:loc] && [locations count] == 0){
                        [localSearchToLocations addObject:loc];
                    }
                    
                  }
            }
                
            NIMLOG_PERF1(@"LocalSearch Count == %d",[localSearchToLocations count]);
            
            sortedMatchingToLocations = localSearchToLocations;
            matchingToRowCount = [sortedMatchingToLocations count];
            areMatchingLocationsChanged = YES; 
           
        [[nc_AppDelegate sharedInstance].toFromViewController.toTableVC reloadLocationWithLocalSearch];
         
        }];
    }
    else{
        sortedMatchingToLocations = localSearchToLocations;
        matchingToRowCount = [sortedMatchingToLocations count];
        areMatchingLocationsChanged = YES;
        [[nc_AppDelegate sharedInstance].toFromViewController.toTableVC reloadLocationWithLocalSearch];
        
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

// Fetch searchable locations from database if necessary.
- (void) fetchSearchableLocations{
    NSSortDescriptor *sdFrom = [NSSortDescriptor sortDescriptorWithKey:@"fromFrequency"
                                                             ascending:NO];
    NSSortDescriptor *sdDate = [NSSortDescriptor sortDescriptorWithKey:@"dateLastUsed"
                                                             ascending:NO];
    NSSortDescriptor *sdTo = [NSSortDescriptor sortDescriptorWithKey:@"toFrequency"
                                                           ascending:NO];
    NSArray* fromSortDesc = [NSArray arrayWithObjects:sdFrom,sdDate,nil];
    NSArray* toSortDesc = [NSArray arrayWithObjects:sdTo,sdDate,nil];
    
    if (!fetchReqSearchableGoogleFromLocations) { // create the fetch request if we have not already done so
        fetchReqSearchableGoogleFromLocations = [[managedObjectModel fetchRequestTemplateForName:@"LocationFromGoogleSearchable"] copy];
        fetchReqSearchableIosFromLocations = [[managedObjectModel fetchRequestTemplateForName:@"LocationFromIosSearchable"] copy];
        [fetchRequestFromFreqThreshold setSortDescriptors:fromSortDesc];
        [fetchReqSearchableGoogleFromLocations setSortDescriptors:fromSortDesc];
        [fetchReqSearchableIosFromLocations setSortDescriptors:fromSortDesc];
        NSArray* preFetchArray = [NSArray arrayWithObject:LOCATION_ADDRESS_COMPONENT];
        [fetchReqSearchableGoogleFromLocations setRelationshipKeyPathsForPrefetching:preFetchArray];
        [fetchReqSearchableGoogleFromLocations setReturnsObjectsAsFaults:NO];
        [fetchReqSearchableIosFromLocations setReturnsObjectsAsFaults:NO];
    }
    NSError *error2, *error3;
    NIMLOG_PERF2(@"Fetching searchableFromLocations");
    if(!searchableFromLocations){
        NSArray* locsFromGoogle = [managedObjectContext executeFetchRequest:fetchReqSearchableGoogleFromLocations
                                                                      error:&error2];
        NSArray* locsFromIos;
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5) {
            locsFromIos = [managedObjectContext executeFetchRequest:fetchReqSearchableIosFromLocations error:&error3];
        } else {
            // If < iOS4, then there will be no locations from iOS. DE300 fix
            locsFromIos = [NSArray array];
        }
        searchableFromLocations = [[locsFromGoogle arrayByAddingObjectsFromArray:locsFromIos]
                                   sortedArrayUsingDescriptors:fromSortDesc]; // Combine the iOS and Google locations
        
        NIMLOG_PERF2(@"Done fetching searchableFromLocations");
    }
    else{
        NSArray *locs = [NSArray arrayWithArray:searchableFromLocations];
        searchableFromLocations = [locs
                                   sortedArrayUsingDescriptors:fromSortDesc]; // Combine the iOS and Google locations
    }
    
    // Now resort for sortedToLocations & searchableFromLocations arrays
    
    searchableToLocations = [searchableFromLocations sortedArrayUsingDescriptors:toSortDesc];
    
    NIMLOG_PERF2(@"Done with searchableToLocations");
    // Force recomputation of the selectedLocations
    [self updateWithSelectedLocationIsFrom:TRUE selectedLocation:selectedFromLocation oldSelectedLocation:oldSelectedFromLocation];
    [self updateWithSelectedLocationIsFrom:FALSE selectedLocation:selectedToLocation oldSelectedLocation:oldSelectedToLocation];
    
    // Force the recomputation of the sortedMatchedLocations arrays
    [self setTypedToString:[self typedToString]];
    [self setTypedFromString:[self typedFromString]];
    [self setAreLocationsChanged:NO]; // reset again
}

// Internal method for updating cache after locations have changed
// Only include those locations with frequency >= 1 in the row count
- (void)updateInternalCache
{
    // Fetch the sortedFromLocations & searchableFromLocations arrays
    NSSortDescriptor *sdFrom = [NSSortDescriptor sortDescriptorWithKey:@"fromFrequency"
                                                             ascending:NO];
    NSSortDescriptor *sdDate = [NSSortDescriptor sortDescriptorWithKey:@"dateLastUsed"
                                                             ascending:NO];
    NSSortDescriptor *sdTo = [NSSortDescriptor sortDescriptorWithKey:@"toFrequency"
                                                           ascending:NO];
    NSArray* fromSortDesc = [NSArray arrayWithObjects:sdFrom,sdDate,nil];
    NSArray* toSortDesc = [NSArray arrayWithObjects:sdTo,sdDate,nil];
    
    if (!fetchRequestFromFreqThreshold) { // create the fetch request if we have not already done so
        fetchRequestFromFreqThreshold = [managedObjectModel fetchRequestFromTemplateWithName:@"LocationByFromFrequency"
                                                                       substitutionVariables:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:TOFROM_FREQUENCY_VISIBILITY_CUTOFF] forKey:@"THRESHOLD"]];
        [fetchRequestFromFreqThreshold setSortDescriptors:fromSortDesc];
    }
    NSError *error1;
    sortedFromLocations = [managedObjectContext executeFetchRequest:fetchRequestFromFreqThreshold
                                                              error:&error1];
    // Now resort for sortedToLocations & searchableFromLocations arrays
    
    if (!fetchRequestToFreqThreshold) { // create the fetch request if we have not already done so
        fetchRequestToFreqThreshold = [managedObjectModel fetchRequestFromTemplateWithName:@"LocationByToFrequency"
                                                                     substitutionVariables:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:TOFROM_FREQUENCY_VISIBILITY_CUTOFF] forKey:@"THRESHOLD"]];
        [fetchRequestToFreqThreshold setSortDescriptors:toSortDesc];
    }
    sortedToLocations = [managedObjectContext executeFetchRequest:fetchRequestToFreqThreshold
                                                            error:&error1];
    if (!sortedToLocations) {
        [NSException raise:@"Locations -> updateInternalCache Fetch failed" format:@"Reason: %@", error1];
    }
    // Force recomputation of the selectedLocations
    [self updateWithSelectedLocationIsFrom:TRUE selectedLocation:selectedFromLocation oldSelectedLocation:oldSelectedFromLocation];
    [self updateWithSelectedLocationIsFrom:FALSE selectedLocation:selectedToLocation oldSelectedLocation:oldSelectedToLocation];
    
    // Force the recomputation of the sortedMatchedLocations arrays
    [self setTypedToString:[self typedToString]];
    [self setTypedFromString:[self typedFromString]];
    [self setAreLocationsChanged:NO]; // reset again
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
    if (selectedLocation) { // if there is a non-nil selectedLocation, then move it to the top
        [newArray removeObject:selectedLocation];  // remove selected object from current location
        [newArray insertObject:selectedLocation atIndex:0];
        // inserts it at the front of the object
    }
//    if (oldSelectedLocation && (oldSelectedLocation != selectedLocation)) { // if there was a non-nil oldSelectedLocation, and this is a new request, then re-sort
//        
        NSSortDescriptor *sd1 = [NSSortDescriptor
                                 sortDescriptorWithKey:(@"fromFrequency")
                                                              ascending:NO];
        NSSortDescriptor *sd2 = [NSSortDescriptor sortDescriptorWithKey:@"dateLastUsed"
                                                              ascending:NO];
        [newArray sortUsingDescriptors:[NSArray arrayWithObjects:sd1,sd2, nil]];
   // }
    
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
        [NSException raise:[NSString stringWithFormat:@"Locations -> locationsWithFormattedAddress: Fetch failed for address %@",
                            formattedAddress]
                    format:@"Error message: %@", error];
    } 
    return result;  // Return the array of matches (could be empty)
}
- (NSArray *)locationsWithLocationName:(NSString *)locationName
{
    if (!locationName) {
        return nil;
    }
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:managedObjectContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"locationName=%@",locationName];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error];
    if (!result) {
        [NSException raise:[NSString stringWithFormat:@"Locations -> locationsWithLocationName: Fetch failed for locationName %@",
                            locationName]
                    format:@"Error message: %@", error];
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
        [NSException raise:[NSString stringWithFormat:@"Locations -> locationWithRawAddress: Fetch failed for address %@",
                            rawAddress]
                    format:@"Error message: %@", error];
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
        [NSException raise:[NSString stringWithFormat:@"Locations -> locationsMembersOfList: Fetch failed for list prefix %@",
                            listNamePrefix]
                    format:@"Error message: %@", error];
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
    @try {
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
                
                // Before deleting deleteLoc, delete any plans from the cache that are associated with it
                // This is to make sure we don't have cached plans going to a different location (also DE241 fix)
                NSSet* deletePlanSet = [deleteLoc plan];
                for (Plan* deletePlan in deletePlanSet) {
                    [managedObjectContext deleteObject:deletePlan];
                }
                
                // Delete deleteLoc
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
    @catch (NSException *exception) {
        logException(@"Locations->consolidateWithMatchingLocations",
                     [NSString stringWithFormat:@"loc0 formattedAddr = %@, keepThisLocation = %d, loc0 = %@",
                      [loc0 formattedAddress], keepThisLocation, loc0],
                     exception);
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
#if AUTOMATED_TESTING_SKIP_NCAPPDELEGATE
    googleParameters = [NSDictionary dictionaryWithKeysAndObjects: @"address", parameters.rawAddress,
                        @"bounds", supportedRegionGeocodeString, @"sensor", @"true", 
                        DEVICE_TOKEN,[[nc_AppDelegate sharedInstance] deviceTokenString], nil];
#endif
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
                // If google geocoder unavailable, try iOS geocoder if iOS v 5.0+
                if([[[UIDevice currentDevice] systemVersion] intValue] >= 5) {
                    [parameters setApiType:IOS_GEOCODER];
                    if (parameters.rawAddress) {
                        [self forwardGeocodeWithParameters:parameters callBack:callback];
                    } else {
                        [self reverseGeocodeWithParameters:parameters callBack:callback];
                    }
                } else {
                    // if iOS4, return over query message
                    [callback newGeocodeResults:nil withStatus:GEOCODE_OVER_QUERY_LIMIT parameters:parameters];
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
        NSMutableArray *placemarkArray = [[NSMutableArray alloc] initWithArray:placemarks];
        for (int i=0;i<[placemarkArray count];i++) {
            for(int j=i+1;j<[placemarkArray count];i++){
                MKPlacemark *placemark1 = [placemarkArray objectAtIndex:i];
                MKPlacemark *placemark2 = [placemarkArray objectAtIndex:j];
                if([placemark1.addressDictionary isEqual:placemark2.addressDictionary]){
                    [placemarkArray removeObject:placemark1];
                    // Fixed DE-328
                    i = i - 1;
                    break;
                }
                
            }
        }
        for (CLPlacemark* placemark in placemarkArray) {
            NSArray *fetchedLocations = [self locationsWithLat:placemark.location.coordinate.latitude Lng:placemark.location.coordinate.longitude];
            if([fetchedLocations count] > 0){
                [validLocations addObjectsFromArray:fetchedLocations];
            }
            else{
                LocationFromIOS* loc = [self newLocationFromIOSWithPlacemark:placemark error:error];
                if ([[parameters supportedRegion] isInRegionLat:[loc latFloat] Lng:[loc lngFloat]]) {
                    [validLocations addObject:loc];
                } else {
                    // if a location not in supported region,
                    [self removeLocation:loc]; // and out of Core Data
                }
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

- (NSString *) replaceString:(NSString *)string FromString:(NSString *)originalString{
    NSString *strPattern1 = [NSString stringWithFormat:@" %@ ",string];
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:strPattern1 options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *modifiedString1 = [regex1 stringByReplacingMatchesInString:originalString options:0 range:NSMakeRange(0, [originalString length]) withTemplate:@" "];
    
    NSString *strPattern2 = [NSString stringWithFormat:@" %@$|^%@ ",string,string];
    NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:strPattern2 options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *modifiedString2 = [regex2 stringByReplacingMatchesInString:modifiedString1 options:0 range:NSMakeRange(0, [modifiedString1 length]) withTemplate:@""];
    return modifiedString2;
}

// Station Search From Json Files.
- (NSString *) rawAddressWithOutAgencyName:(NSString *)address SearchStringArray:(NSArray *)searchStringArray{
    for(int i=0;i<[searchStringArray count];i++){
        address = [self replaceString:[searchStringArray objectAtIndex:i] FromString:address];
    }
    return address;
}

- (NSString *)rawAddressWithOutAgencyName:(NSArray *)searchStringsArray
                      replaceStringsArray:(NSArray *)replaceStringsArray
                                  address:(NSString *)address
{
    for(int i=0;i<[searchStringsArray count];i++){
        NSRange range;
        if ([address rangeOfString:[searchStringsArray objectAtIndex:i] options:NSCaseInsensitiveSearch].location != NSNotFound){
            range = [address rangeOfString:[searchStringsArray objectAtIndex:i]];
            NSMutableString *strMutableRawAddress =  (NSMutableString *)address;
            [strMutableRawAddress replaceCharactersInRange:range withString:[replaceStringsArray objectAtIndex:i]];
            address = strMutableRawAddress;
        }
    }
    return address;
}

//- (NSArray *)searchedStationsFromRawAddress:(NSString *)address
//                         searchStringsArray:(NSArray *)searchStringsArray
//                        replaceStringsArray:(NSArray *)replaceStringsArray
//                     agencyNameNotToInclude:(NSString *)agencyNameNotToInclude
//{
//    NSMutableArray *arrMultiPleStationList = [[NSMutableArray alloc] init];
//    NSMutableArray *arrUnFilteredStationList = [[NSMutableArray alloc] init];
//    NSMutableArray *arrDistance = [[NSMutableArray alloc] init];
//    NSManagedObjectContext * context = [self managedObjectContext];
//    NSFetchRequest * fetchPlanRequestChunk = [[NSFetchRequest alloc] init];
//    [fetchPlanRequestChunk setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:context]];
//    NSArray * arrayLocations = [context executeFetchRequest:fetchPlanRequestChunk error:nil];
//    for (id location in arrayLocations){
//        NSString *strshortFormattedAddress = [[location shortFormattedAddress]lowercaseString];
//        NSMutableString *strMutableShortFormattedAddress = [[NSMutableString alloc] init];
//        // Added To Handle Station Without Caltrain
//        if([strshortFormattedAddress isEqualToString:@"san jose diridon station"]){
//            [strMutableShortFormattedAddress appendString:strshortFormattedAddress];
//            [strMutableShortFormattedAddress appendString:@"caltrain"];
//            strshortFormattedAddress = strMutableShortFormattedAddress;
//        }
//        if([strshortFormattedAddress rangeOfString:agencyNameNotToInclude options:NSCaseInsensitiveSearch].location == NSNotFound && ![address isEqualToString:@"current location"] && ![address isEqualToString:@"caltrain station list"] && ![address isEqualToString:@"bart station list"]){
//            [arrUnFilteredStationList addObject:location];
//        }
//    }
//    for (int i=0;i<[arrUnFilteredStationList count];i++){
//        Location *location = [arrUnFilteredStationList objectAtIndex:i];
//        NSString *strshortFormattedAddress = [[location shortFormattedAddress]lowercaseString];
//        strshortFormattedAddress = [self rawAddressWithOutAgencyName:searchStringsArray
//                                                 replaceStringsArray:replaceStringsArray
//                                                             address:strshortFormattedAddress];
//        if([address isEqualToString:strshortFormattedAddress]){
//            //[self markAndUpdateSelectedLocation:location];
//            return [NSArray arrayWithObject:location];
//        }
//        float distance = calculateLevenshteinDistance(strshortFormattedAddress, address);
//        float finalDistance = distance + address.length - strshortFormattedAddress.length;
//        [arrUnFilteredStationList replaceObjectAtIndex:i withObject:[arrUnFilteredStationList objectAtIndex:i]];
//        [arrDistance addObject:[NSString stringWithFormat:@"%f",finalDistance]];
//    }
//    if([arrUnFilteredStationList count] > 1){
//        int minDistance, nTempDistance,min1;
//        NSString *tempStationName;
//        int i,j;
//        for (i = 0; i < [arrDistance count]-1; i++){
//            minDistance = i;
//            min1 = i;
//            for (j = i+1; j < [arrDistance count]; j++){
//                if ([[arrDistance objectAtIndex:j] intValue] < [[arrDistance objectAtIndex:minDistance] intValue])
//                    minDistance = j;
//                min1 = j;
//            }
//            nTempDistance = [[arrDistance objectAtIndex:i] intValue];
//            tempStationName = [arrUnFilteredStationList objectAtIndex:i];
//            [arrDistance replaceObjectAtIndex:i withObject:[arrDistance objectAtIndex:minDistance]];
//            [arrUnFilteredStationList replaceObjectAtIndex:i withObject:[arrUnFilteredStationList objectAtIndex:minDistance]];
//            [arrDistance replaceObjectAtIndex:minDistance withObject:[NSString stringWithFormat:@"%d",nTempDistance]];
//            [arrUnFilteredStationList replaceObjectAtIndex:minDistance withObject:tempStationName];
//        }
//    }
//    int nVariation = address.length/3;
//    if(nVariation == 0){
//        nVariation = 1;
//    }
//    for (int i=0;i<[arrUnFilteredStationList count];i++){
//        int finalDistance = [[arrDistance objectAtIndex:i] intValue];
//        if((finalDistance < 2.0 || (finalDistance <= nVariation && [arrMultiPleStationList count] < 3)) && finalDistance < address.length){
//            [arrMultiPleStationList addObject:[arrUnFilteredStationList objectAtIndex:i]];
//        }
//    }
//    if([arrMultiPleStationList count] > 1){
//        return arrMultiPleStationList;
//    }
//    return nil;
//}
@end
