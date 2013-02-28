//
//  RealTimeServerStubTest.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 1/26/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "RealTimeServerStubTest.h"
#import "LocationFromGoogle.h"
#import "LocationFromIOS.h"
#import "Constants.h"
#import "Logging.h"
#import "PlanRequestParameters.h"
#import "RouteOptionsViewController.h"
#import "RouteExcludeSetting.h"
#import "RealTimeManager.h"
#import "PlanStore.h"
#import "nc_AppDelegate.h"
#import "GtfsStopTimes.h"
#import "RealTimeManager.h"
#import "GtfsAgency.h"
#import "GtfsRoutes.h"
#import "GtfsCalendar.h"
#import "GtfsCalendarDates.h"
#import "GtfsStop.h"
#import "KeyObjectStore.h"

@implementation RealTimeServerStubTest

- (void)setUp
{
    [super setUp];
    
    // Configure the RestKit RKClient object for Geocoding and trip planning
    RKLogConfigureByName("RestKit", CUSTOM_RK_LOG_LEVELS);
    RKLogConfigureByName("RestKit/Network/Cache", CUSTOM_RK_LOG_LEVELS);
    RKLogConfigureByName("RestKit/Network/Reachability", CUSTOM_RK_LOG_LEVELS);
    
    // Set-up RKManagedObjectStore per https://groups.google.com/forum/?fromgroups=#!topic/restkit/6_iu2mLOgTo
    // This avoids "Can't merge models with two different entities named" error
    
    if (!rkMOS) {
        NSString *modelPath = nil;
        for (NSBundle* bundle in [NSBundle allBundles])
        {
            modelPath = [bundle pathForResource:@"Network_Commuting" ofType:@"momd"];
            if (modelPath)
                break;
        }
        STAssertTrue(modelPath != nil, @"Could not find managed object model.");
        NSManagedObjectModel* mom = [[NSManagedObjectModel alloc]
                                     initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
        
        
        rkMOS = [RKManagedObjectStore objectStoreWithStoreFilename:TEST_COREDATA_DB_FILENAME
                                             usingSeedDatabaseName:nil
                                                managedObjectModel:mom
                                                          delegate:nil];
    }

    [rkMOS deletePersistantStoreUsingSeedDatabaseName:nil];  // Make sure data store is cleared to start with
    
    // Set up the ManagedObjectContect and RKObjectManager
    if (!rkPlanMgr) {
        rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:TEST_TRIP_PROCESS_URL];
        [rkPlanMgr setObjectStore:rkMOS];
    }
    
    // Get the NSManagedObjectContext from restkit
    managedObjectContext = [rkMOS managedObjectContext];
    int storeCount = [[[managedObjectContext persistentStoreCoordinator] persistentStores] count];
    if (storeCount > 0) {
        NIMLOG_AUTOTEST(@"managedObjectContext Store URL = %@", [[[[managedObjectContext persistentStoreCoordinator] persistentStores] objectAtIndex:0] URL]);
    }
    
    if (!rkTpClient) {
        rkTpClient = [RKClient clientWithBaseURL:TEST_TRIP_PROCESS_URL];
    }

    // Set up the planStore
    planStore = [[PlanStore alloc] initWithManagedObjectContext:managedObjectContext rkPlanMgr:rkPlanMgr];
    
    // Set up KeyObjectStore
    [KeyObjectStore setUpWithManagedObjectContext:managedObjectContext];
    [RouteExcludeSettings clearLatestUserSettings];  
    [RouteExcludeSettings setManagedObjectContext:managedObjectContext];

    // Set up RealTimeManager
    [[RealTimeManager realTimeManager] setRkTpClient:rkTpClient];
    
    // Initialize The GtfsParser and transitCalendar
    gtfsParser = [[GtfsParser alloc] initWithManagedObjectContext:managedObjectContext
                                                       rkTpClient:rkTpClient];
    [[nc_AppDelegate sharedInstance] setGtfsParser:gtfsParser];
    [[TransitCalendar transitCalendar] setRkTpClient:rkTpClient];
    [[TransitCalendar transitCalendar] updateFromServer];
    
    // Set up Locations wrapper object pointing at the test Managed Object Context
    if (!rkGeoMgr) {
        rkGeoMgr = [RKObjectManager objectManagerWithBaseURL:TEST_GEO_RESPONSE_URL];
        [rkGeoMgr setObjectStore:rkMOS];
    }
    locations = [[Locations alloc] initWithManagedObjectContext:managedObjectContext rkGeoMgr:rkGeoMgr];

    // Set up UserPreferance
    userPreferance = [UserPreferance userPreferance];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy hh:mm a"];
    
    // Create initial view controller
    toFromViewController = [[ToFromViewController alloc] initWithNibName:@"ToFromViewController" bundle:nil];
    [toFromViewController setRkGeoMgr:rkGeoMgr];    // Pass the geocoding RK object
    [toFromViewController setRkPlanMgr:rkPlanMgr];    // Pass the planning RK object
    [toFromViewController setLocations:locations];
    [toFromViewController setPlanStore:planStore];
    
    // Set up tabViewController and make it visible
    [[nc_AppDelegate sharedInstance] setToFromViewController:toFromViewController];
    [[nc_AppDelegate sharedInstance] setUpTabViewController];
    [nc_AppDelegate sharedInstance].window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [[[nc_AppDelegate sharedInstance] window] setRootViewController:[nc_AppDelegate sharedInstance].tabBarController];
    [[nc_AppDelegate sharedInstance].window makeKeyAndVisible];
    
}



- (void)tearDown
{
    // Tear-down code here.
    
    // Delete Core Data persistent store
    [rkMOS deletePersistantStoreUsingSeedDatabaseName:nil];
    NIMLOG_AUTOTEST(@"tearDown: PersistentStore cleared");
    
    [super tearDown];
}

- (void)newGeocodeResults:(NSArray *)locationArray withStatus:(GeocodeRequestStatus)status parameters:(GeocodeRequestParameters *)parameters
{
    STAssertEquals(status, GEOCODE_STATUS_OK, @"Did not get OK geocoder status");
    STAssertTrue([locationArray count] > 0, @"Did not get a Location");
    if ([locationArray count] > 0) {
        if (parameters.isFrom) {
            fromLocation = [locationArray objectAtIndex:0];
        } else {
            toLocation = [locationArray objectAtIndex:0];
        }
    }
}

// Loops up to 5 seconds waiting for *value to become true.  When it does turn true, return true.  If it times out, return false
- (bool)waitForNonNullValueOfBlock:(BOOL(^)(void))block
{
    int i;
    for (i=0; i<25; i++) {
        if (block()) {
            return true;
        } else {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        }
    }
    return false;  
}

- (void)testPlanRetrieval{
    //
    // Test The GtfsAgency Data Parsing and DB Insertion with some test data.
    //
    
    [gtfsParser requestAgencyDataFromServer];
    STAssertTrue([self waitForNonNullValueOfBlock:^(void){BOOL result=gtfsParser.loadedInitialData; return result;}], @"Timed out waiting for gtfsParser");
    
    NSFetchRequest * fetchAgency = [[NSFetchRequest alloc] init];
    [fetchAgency setEntity:[NSEntityDescription entityForName:@"GtfsAgency" inManagedObjectContext:managedObjectContext]];
    NSArray* arrayAgency = [managedObjectContext executeFetchRequest:fetchAgency error:nil];
    STAssertTrue([arrayAgency count] == 11, @"");
    
    bool test1 = false;
    bool test2 = false;
    bool test3 = false;
    bool test4 = false;
    bool test5 = false;
    bool test6 = false;
    bool test7 = false;
    bool test8 = false;
    bool test9 = false;
    bool test10 = false;
    
    for (GtfsAgency* agency in arrayAgency) {
        if ([agency.agencyID isEqualToString:@"caltrain-ca-us"]) {
            test1 = ([agency.agencyName isEqualToString:@"Caltrain"]);
            test2 = ([agency.agencyURL isEqualToString:@"http://www.caltrain.com"]);
        }
        else if ([agency.agencyID isEqualToString:@"AirBART"]) {
            test3 = ([agency.agencyName isEqualToString:@"AirBART"]);
            test4 = ([agency.agencyURL isEqualToString:@"http://www.bart.gov/guide/airport/inbound_oak.aspx"]);
        }
        else if ([agency.agencyID isEqualToString:@"BART"]) {
            test5 = ([agency.agencyName isEqualToString:@"Bay Area Rapid Transit"]);
            test6 = ([agency.agencyURL isEqualToString:@"http://www.bart.gov"]);
        }
        else if ([agency.agencyID isEqualToString:@"SFMTA"]) {
            test7 = ([agency.agencyName isEqualToString:@"San Francisco Municipal Transportation Agency"]);
            test8 = ([agency.agencyURL isEqualToString:@"http://www.sfmta.com"]);
        }
        else if ([agency.agencyName isEqualToString:@"AC Transit"]){
            test9 = ([agency.agencyID isEqualToString:@""]);
            test10 = ([agency.agencyURL isEqualToString:@"http://www.actransit.org"]);
        }
    }
    
    STAssertTrue(test1, @"Agency test1");
    STAssertTrue(test2, @"Agency test2");
    STAssertTrue(test3, @"Agency test3");
    STAssertTrue(test4, @"Agency test4");
    STAssertTrue(test5, @"Agency test5");
    STAssertTrue(test6, @"Agency test6");
    STAssertTrue(test7, @"Agency test7");
    STAssertTrue(test8, @"Agency test8");
    STAssertTrue(test9, @"Agency test9");
    STAssertTrue(test10, @"Agency test10");
    
    // Calendar DataParsing and DB Insertion Testing
    bool testCalendar1 = false;
    bool testCalendar2 = false;
    bool testCalendar3 = false;
    
    NSFetchRequest * fetchCalendar = [[NSFetchRequest alloc] init];
    [fetchCalendar setEntity:[NSEntityDescription entityForName:@"GtfsCalendar" inManagedObjectContext:managedObjectContext]];
    NSArray* arrayCalendar = [managedObjectContext executeFetchRequest:fetchCalendar error:nil];
    
    for (GtfsCalendar* calendar in arrayCalendar) {
        if ([calendar.serviceID isEqualToString:@"WE_20121001"]) {
            testCalendar1 = (calendar.monday.integerValue == 0);
            testCalendar2 = (calendar.saturday.integerValue == 1);
        }
        else if ([calendar.serviceID isEqualToString:@"WKDY"]) {
            testCalendar3 = (calendar.wednesday.integerValue == 1);
        }
    }
    STAssertTrue(testCalendar1, @"Calendar testCalendar1");
    STAssertTrue(testCalendar2, @"Calendar testCalendar2");
    STAssertTrue(testCalendar3, @"Calendar testCalendar3");
    
    
    // Routes DataParsing and DB Insertion Testing
    
    bool testRoutes1 = false;
    bool testRoutes2 = false;
    bool testRoutes3 = false;
    bool testRoutes4 = false;
    bool testRoutes5 = false;
    bool testRoutes6 = false;
    
    NSFetchRequest * fetchRoutes = [[NSFetchRequest alloc] init];
    [fetchRoutes setEntity:[NSEntityDescription entityForName:@"GtfsRoutes" inManagedObjectContext:managedObjectContext]];
    NSArray* arrayRoutes = [managedObjectContext executeFetchRequest:fetchRoutes error:nil];
    
    for (GtfsRoutes* routes in arrayRoutes) {
        if ([routes.routeID isEqualToString:@"ct_bullet_20120701"]) {
            testRoutes1 = ([routes.routeShortName isEqualToString:@""]);
            testRoutes2 = ([routes.routeLongname isEqualToString:@"Bullet"]);
        }
        else if ([routes.routeID isEqualToString:@"03"]) {
            testRoutes3 = ([routes.routeShortName isEqualToString:@""]);
            testRoutes4 = ([routes.routeLongname isEqualToString:@"FREMONT - RICHMOND"]);
        }
        else if ([routes.routeID isEqualToString:@"7928"]) {
            testRoutes5 = ([routes.routeShortName isEqualToString:@"1"]);
            testRoutes6 = ([routes.routeLongname isEqualToString:@"CALIFORNIA"]);
        }
    }
    STAssertTrue(testRoutes1, @"Routes testRoutes1");
    STAssertTrue(testRoutes2, @"Routes testRoutes2");
    STAssertTrue(testRoutes3, @"Routes testRoutes3");
    STAssertTrue(testRoutes4, @"Routes testRoutes4");
    STAssertTrue(testRoutes5, @"Routes testRoutes5");
    STAssertTrue(testRoutes6, @"Routes testRoutes6");
    
    
    // Stops DataParsing and DB Insertion Testing
    
    bool testStops1 = false;
    bool testStops2 = false;
    bool testStops3 = false;
    bool testStops7 = false;
    bool testStops8 = false;
    bool testStops9 = false;
    bool testStops10 = false;
    bool testStops11 = false;
    bool testStops12 = false;
    
    NSFetchRequest * fetchStops = [[NSFetchRequest alloc] init];
    [fetchStops setEntity:[NSEntityDescription entityForName:@"GtfsStop" inManagedObjectContext:managedObjectContext]];
    NSArray* arrayStops = [managedObjectContext executeFetchRequest:fetchStops error:nil];
    
    for (GtfsStop* stops in arrayStops) {
        if ([stops.stopID isEqualToString:@"22nd Street Caltrain"]) {
            testStops1 = ([stops.stopName isEqualToString:@"22nd Street Caltrain Station"]);
            testStops2 = ([stops.stopLat doubleValue] ==  37.757674);
            testStops3 = ([stops.stopLon doubleValue] ==  -122.392636);
        }
        else if ([stops.stopID isEqualToString:@"DALY"]) {
            testStops7 = ([stops.stopName isEqualToString:@"Daly City"]);
            testStops8 = ([stops.stopLat doubleValue] ==  37.70612055);
            testStops9 = ([stops.stopLon doubleValue] ==  -122.4690807);
        }
        else if ([stops.stopID isEqualToString:@"0100460"]) {
            testStops10 = ([stops.stopName isEqualToString:@"Broadway:Santa Clara Av"]);
            testStops11 = ([stops.stopLat doubleValue] ==  37.763832);
            testStops12 = ([stops.stopLon doubleValue] ==  -122.237946);
        }
    }
    
    STAssertTrue(testStops1, @"Stops testStops1");
    STAssertTrue(testStops2, @"Stops testStops2");
    STAssertTrue(testStops3, @"Stops testStops3");
    STAssertTrue(testStops7, @"Stops testStops7");
    STAssertTrue(testStops8, @"Stops testStops8");
    STAssertTrue(testStops9, @"Stops testStops9");
    STAssertTrue(testStops10, @"Stops testStops10");
    STAssertTrue(testStops11, @"Stops testStops11");
    STAssertTrue(testStops12, @"Stops testStops12");
    
    
    // Calendar Dates DataParsing and DB Insertion Testing
    bool testCalendarDates1 = false;
    bool testCalendarDates2 = false;
    bool testCalendarDates3 = false;
    
    NSFetchRequest * fetchCalendarDates = [[NSFetchRequest alloc] init];
    [fetchCalendarDates setEntity:[NSEntityDescription entityForName:@"GtfsCalendarDates" inManagedObjectContext:managedObjectContext]];
    NSArray* arrayCalendarDates = [managedObjectContext executeFetchRequest:fetchCalendarDates error:nil];
    
    NSDateFormatter *formtter = [[NSDateFormatter alloc] init];
    [formtter setDateFormat:@"yyyyMMdd"];
    NSDate *targetDate1 = [formtter dateFromString:@"20120704"];
    NSDate *targetDate2 = [formtter dateFromString:@"20121122"];
    NSDate *targetDate3 = [formtter dateFromString:@"20120528"];
    for (GtfsCalendarDates* calendarDates in arrayCalendarDates) {
        if ([calendarDates.serviceID isEqualToString:@"WE_20120701"] &&
            [calendarDates.date isEqualToDate:targetDate1] &&
            [calendarDates.exceptionType isEqualToString:@"1"]){
            testCalendarDates1 = true;
        }
        else if ([calendarDates.serviceID isEqualToString:@"SUNAB"] &&
                 [calendarDates.date isEqualToDate:targetDate2] &&
                 [calendarDates.exceptionType isEqualToString:@"1"]) {
            testCalendarDates2 = true;
        }
        if ([calendarDates.serviceID isEqualToString:@"12SPNG-DBDB1-Weekday-01"] &&
            [calendarDates.date isEqualToDate:targetDate3] &&
            [calendarDates.exceptionType isEqualToString:@"2"]) {
            testCalendarDates3 = true;
        }
    }
    STAssertTrue(testCalendarDates1, @"");
    STAssertTrue(testCalendarDates2, @"");
    STAssertTrue(testCalendarDates3, @"");
    
    
    //
    // Test geolocation pull from server
    //

    
    // Pull fromLocation from geocoder
    fromLocation = nil;
    GeocodeRequestParameters* geoParam = [[GeocodeRequestParameters alloc] init];
    geoParam.supportedRegion = [[SupportedRegion alloc] initWithDefault];
    geoParam.rawAddress = @"75 Hawthorne St, San Francisco, CA";
    geoParam.apiType = GOOGLE_GEOCODER;
    geoParam.isFrom = true;
    [[NSUserDefaults standardUserDefaults] setObject:@"75HawthorneGeo.json" forKey:DEVICE_TOKEN];  // Tells StubTestTPServer which test file to pull
    [locations forwardGeocodeWithParameters:geoParam callBack:self];
    STAssertTrue([self waitForNonNullValueOfBlock:^(void){BOOL result=(fromLocation!=nil); return result;}], @"Timed out waiting for fromLocation");
    STAssertTrue([[fromLocation formattedAddress] isEqualToString:@"75 Hawthorne Street, San Francisco, CA 94105, USA"], @"");
    
    // toLocation
    toLocation = nil;
    geoParam.rawAddress = @"1350 Hull Drive, San Carlos, CA 94070";
    geoParam.apiType = GOOGLE_GEOCODER;
    geoParam.isFrom = false;
    [[NSUserDefaults standardUserDefaults] setObject:@"1350HullGeo.json" forKey:DEVICE_TOKEN];  // Tells StubTestTPServer which test file to pull
    [locations forwardGeocodeWithParameters:geoParam callBack:self];
    STAssertTrue([self waitForNonNullValueOfBlock:^(void){BOOL result = (toLocation!=nil); return result;}], @"Timed out waiting for toLocation");
    STAssertTrue([[toLocation formattedAddress] isEqualToString:@"1350 Hull Drive, San Carlos, CA 94070, USA"], @"");


    //
    // Test plan pull from server using PlanStore
    //
    
    PlanRequestParameters* parameters = [[PlanRequestParameters alloc] init];
    parameters.fromLocation = fromLocation;
    parameters.toLocation = toLocation;
    NSDate* tripDate = [dateFormatter dateFromString:@"02/11/2013 05:30 pm"];
    NSDate* tripDate2 = [dateFormatter dateFromString:@"02/12/2013 04:00 pm"];
    NSDate* tripDate3 = [dateFormatter dateFromString:@"02/14/2013 06:00 am"];
    parameters.originalTripDate = tripDate;
    parameters.thisRequestTripDate = tripDate;
    parameters.routeExcludeSettings = [RouteExcludeSettings latestUserSettings];
    parameters.departOrArrive = DEPART;
    parameters.maxWalkDistance = (int)([userPreferance walkDistance]*1609.544);
    parameters.planDestination = toFromViewController;
    
    parameters.formattedAddressTO = [toLocation formattedAddress];
    parameters.formattedAddressFROM = [fromLocation formattedAddress];
    parameters.latitudeTO = (NSString *)[toLocation lat];
    parameters.longitudeTO = (NSString *)[toLocation lng];
    parameters.latitudeFROM = (NSString *)[fromLocation lat];
    parameters.longitudeFROM = (NSString *)[fromLocation lng];
    if ([locations isFromGeo]) {
        parameters.fromType = GEO_FROM;
        parameters.rawAddressFROM = [fromLocation formattedAddress];
        parameters.timeFROM = [locations geoRespTimeFrom];
    } else if ([locations isToGeo]) {
        parameters.toType = GEO_TO;
        parameters.rawAddressFROM = [fromLocation formattedAddress] ;
        parameters.timeTO = [locations geoRespTimeTo];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@"Hawthorne2Hull1.json" forKey:DEVICE_TOKEN];  // Tells StubTestTPServer which test file to pull
    
    [planStore requestPlanWithParameters:parameters];
    STAssertTrue([self waitForNonNullValueOfBlock:^(void){BOOL result=(toFromViewController.plan!=nil); return result;}], @"Timed out waiting for plan");
    
    Plan* plan = [toFromViewController plan];
    
    // Check resulting plan versus what is in Hawthorne2Hull1.json file
    STAssertEquals(plan.itineraries.count, 4u, @"");
    Leg* leg0_1 = [[[[plan sortedItineraries] objectAtIndex:0] sortedLegs] objectAtIndex:1];
    STAssertTrue([[leg0_1 route] isEqualToString:@"10"], @"");
    Leg* leg0_3 = [[[[plan sortedItineraries] objectAtIndex:0] sortedLegs] objectAtIndex:3];
    NSString* stopIdSFCaltrain = [[leg0_3 from] stopId];
    
    STAssertEquals([[[[plan sortedItineraries] objectAtIndex:2] sortedLegs] count], 6u,@"");
    Leg* leg2_4 = [[[[plan sortedItineraries] objectAtIndex:2] sortedLegs] objectAtIndex:4];
    NSString* stopIdSCarlosCalTr = [[leg2_4 to] stopId];
    
    STAssertTrue([[[leg2_4 from] name] isEqualToString:@"San Mateo Caltrain Station"], @"");
    
    // Test uniqueItineraries
    STAssertEquals([[plan uniqueItineraries] count], 4u, @"");  // each of the dataset is a unique itinerary
    
    // Test [plan fetchItinerariesFromTimeOnly ...]
    NSArray* fetchItinArray = [plan fetchItinerariesFromTimeOnly:[[plan.sortedItineraries objectAtIndex:1] startTimeOnly]
                                                      toTimeOnly:[[plan.sortedItineraries objectAtIndex:2] startTimeOnly]];
    STAssertEquals([fetchItinArray count], 2u, @"");
    STAssertEquals([fetchItinArray objectAtIndex:0], [plan.sortedItineraries objectAtIndex:1], @"");
    STAssertEquals([fetchItinArray objectAtIndex:1], [plan.sortedItineraries objectAtIndex:2], @"");
    
    //
    // US202 Gtfs itinerary generation
    //
    
    // Wait until GtfsStopTimes have been loaded for this plan
    STAssertTrue([self waitForNonNullValueOfBlock:^(void){
        NSArray* stopPairs = [gtfsParser getStopTimes:stopIdSCarlosCalTr
                                        strFromStopID:stopIdSFCaltrain
                                            startDate:tripDate
                                         timeInterval:(7*60*60)
                                               TripId:@""];
        if ([stopPairs count] > 0) {
            return YES;
        }
        return NO;}], @"Timed out waiting for GtfsStopTimes");
    NSArray* stopPairs = [gtfsParser getStopTimes:stopIdSCarlosCalTr
                                    strFromStopID:stopIdSFCaltrain
                                        startDate:tripDate
                                     timeInterval:(7*60*60)
                                           TripId:@""];
    STAssertEquals([stopPairs count], 6u, @"");
    STAssertTrue([[[[stopPairs objectAtIndex:0] objectAtIndex:0] tripID] isEqualToString:@"282_20121001"], @"");
    
    // Generate itineraries using just the pattern that goes Muni -> SF Caltrain -> San Carlos Caltrain.
    Itinerary* uniqueItin3 = [[plan sortedItineraries] objectAtIndex:3];
    [plan generateMoreGtfsItinsIfNeededFor:uniqueItin3
                               requestDate:tripDate
                     intervalBeforeRequest:(3*60+1)
                      intervalAfterRequest:(6*60*60)
                            departOrArrive:DEPART];
    STAssertEquals([[plan uniqueItineraries] count], 4u, @"");  // Still same # of unique itineraries
    STAssertEquals([[plan requestChunks] count], 2u, @"");  // One requestChunk for newly generated itineraries
    STAssertEquals([[uniqueItin3 requestChunksCreatedByThisPattern] count], 1u, @"");
    STAssertEquals([[[[uniqueItin3 requestChunksCreatedByThisPattern] anyObject] sortedItineraries] count], 3u, @"");  // 3 generated itineraries
    [plan sortItineraries];   // Sort all itineraries
    
    // Check resulting itineraries
    STAssertEquals([[plan sortedItineraries] count], 7u, @"");
    
    // itin0, from OTP, Muni bus leaves 5:42, transfer at RWC
    STAssertEquals([[[[plan sortedItineraries] objectAtIndex:0] sortedLegs] count],6u, @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:0] sortedLegs] objectAtIndex:1] startTime],
                         [dateFormatter dateFromString:@"02/11/2013 05:42 pm"],@"");
    STAssertEqualObjects([[[[[[plan sortedItineraries] objectAtIndex:0] sortedLegs] objectAtIndex:3] to] name],
                         @"Redwood City Caltrain Station",@"");
    STAssertTrue([[[plan sortedItineraries] objectAtIndex:0] isOTPItinerary], @"");
    
    // itin1, from GTFS, Muni bus leaves 6:02, straight to San Carlos
    STAssertEquals([[[[plan sortedItineraries] objectAtIndex:1] sortedLegs] count],5u, @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:1] sortedLegs] objectAtIndex:1] startTime],
                         [dateFormatter dateFromString:@"02/11/2013 06:02 pm"],@"");
    STAssertEqualObjects([[[[[[plan sortedItineraries] objectAtIndex:1] sortedLegs] objectAtIndex:3] to] name],
                         @"San Carlos Caltrain Station",@"");
    STAssertFalse([[[plan sortedItineraries] objectAtIndex:1] isOTPItinerary], @"");
    
    // itin4, from GTFS, Muni bus leaves 7:19pm, straight to San Carlos
    STAssertEquals([[[[plan sortedItineraries] objectAtIndex:4] sortedLegs] count],5u, @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:4] sortedLegs] objectAtIndex:1] startTime],
                         [dateFormatter dateFromString:@"02/11/2013 07:19 pm"],@"");
    STAssertEqualObjects([[[[[[plan sortedItineraries] objectAtIndex:4] sortedLegs] objectAtIndex:3] to] name],
                         @"San Carlos Caltrain Station",@"");
    STAssertFalse([[[plan sortedItineraries] objectAtIndex:4] isOTPItinerary], @"");
    
    // itin6, from GTFS, Muni bus leaves 7:35pm, straight to San Carlos
    STAssertEquals([[[[plan sortedItineraries] objectAtIndex:6] sortedLegs] count],5u, @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:6] sortedLegs] objectAtIndex:1] startTime],
                         [dateFormatter dateFromString:@"02/11/2013 07:38 pm"],@"");
    STAssertEqualObjects([[[[[[plan sortedItineraries] objectAtIndex:6] sortedLegs] objectAtIndex:3] to] name],
                         @"San Carlos Caltrain Station",@"");
    STAssertFalse([[[plan sortedItineraries] objectAtIndex:6] isOTPItinerary], @"");
    
    [[toFromViewController routeOptionsVC] newPlanAvailable:plan status:PLAN_STATUS_OK RequestParameter:parameters];
    
    //
    // Test generateMoreGtfsItinsIfNeededFor and management of requestChunks
    //
    // Try a new trip date (2/12 vs 2/11) and an overlapping trip time 4:00pm vs 5:30pm
    parameters.originalTripDate = tripDate2;
    [plan generateMoreGtfsItinsIfNeededFor:uniqueItin3
                               requestDate:tripDate2
                     intervalBeforeRequest:(3*60+1)
                      intervalAfterRequest:(6*60*60)
                            departOrArrive:DEPART];
    [plan sortItineraries];   // do a raw sort
    
    // First itinerary connects to Caltrain #272 at 5:20pm
    // (We do not leave early enough to catch buses to catch #262 and #264)
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:0] sortedLegs] objectAtIndex:3] tripId], @"272_20121001", @"");
    STAssertEqualObjects([[[plan sortedItineraries] objectAtIndex:0] startTimeOfFirstLeg],
                         [dateFormatter dateFromString:@"02/12/2013 04:59 pm"], @"");
    // Second itinerary connects to Caltrain #274 at 5:27pm
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:1] sortedLegs] objectAtIndex:3] tripId], @"274_20121001", @"");
    STAssertEqualObjects([[[plan sortedItineraries] objectAtIndex:1] startTimeOfFirstLeg],
                         [dateFormatter dateFromString:@"02/12/2013 05:07 pm"], @"");
    // Third itinerary connects to Caltrain #282 at 6:20pm.  This itinerary is sub-optimal, but was generated
    // because more Caltrain stopTimes pairs were generated than Muni (due to the cutoff)
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:2] sortedLegs] objectAtIndex:3] tripId], @"282_20121001", @"");
    STAssertEqualObjects([[[plan sortedItineraries] objectAtIndex:2] startTimeOfFirstLeg],
                         [dateFormatter dateFromString:@"02/12/2013 05:19 pm"], @"");
    
    // Check the requestChunk
    STAssertEquals([[plan requestChunks] count], 2u, @"");
    STAssertEquals([[[[plan sortedItineraries] objectAtIndex:0] planRequestChunks] count], 1u, @"");
    PlanRequestChunk* reqChunkFromGTFS2 = [[[[plan sortedItineraries] objectAtIndex:0] planRequestChunks] anyObject];
    STAssertEquals([[reqChunkFromGTFS2 itineraries] count], 6u, @"");
    STAssertEqualObjects([reqChunkFromGTFS2 earliestTimeFor:DEPART],
                   timeOnlyFromDate([tripDate2 dateByAddingTimeInterval:(-(3*60+1))]), @"");
    STAssertEqualObjects([reqChunkFromGTFS2 latestTimeFor:DEPART],
                   timeOnlyFromDate([tripDate dateByAddingTimeInterval:(6*60*60)]), @"");
    STAssertTrue([reqChunkFromGTFS2 isGtfs], @"");

    // Try another tripDate 02/14/2013 06:00 am
    parameters.originalTripDate = tripDate3;
    [plan generateMoreGtfsItinsIfNeededFor:uniqueItin3
                               requestDate:tripDate3
                     intervalBeforeRequest:(3*60+1)
                      intervalAfterRequest:(6*60*60)
                            departOrArrive:DEPART];
    [plan sortItineraries];   // do a raw sort
    STAssertEquals([[plan requestChunks] count], 3u, @"");  // non-overlapping request chunk, so # goes to 3
    STAssertEquals([[plan itineraries] count], 21u, @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:0] sortedLegs] objectAtIndex:3] tripId], @"210_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:1] sortedLegs] objectAtIndex:3] tripId], @"216_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:2] sortedLegs] objectAtIndex:3] tripId], @"220_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:3] sortedLegs] objectAtIndex:3] tripId], @"226_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:4] sortedLegs] objectAtIndex:3] tripId], @"230_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:5] sortedLegs] objectAtIndex:3] tripId], @"134_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:6] sortedLegs] objectAtIndex:3] tripId], @"236_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:7] sortedLegs] objectAtIndex:3] tripId], @"138_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:8] sortedLegs] objectAtIndex:3] tripId], @"142_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:9] sortedLegs] objectAtIndex:3] tripId], @"146_20121001", @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:10] sortedLegs] objectAtIndex:3] tripId], @"150_20121001", @"");

    //
    // Test prepareSortedItinerariesWithMatchesForDate, especially the optimization code
    //
    [plan prepareSortedItinerariesWithMatchesForDate:tripDate departOrArrive:DEPART];
    [[toFromViewController routeOptionsVC] newPlanAvailable:plan status:PLAN_STATUS_OK RequestParameter:parameters];
    STAssertEquals([[plan sortedItineraries] count], 6u, @"");  // Removed itinerary #5 (OTP duplicate)
    
    // itin4, from GTFS, Muni bus leaves 7:19pm, straight to San Carlos
    STAssertEquals([[[[plan sortedItineraries] objectAtIndex:4] sortedLegs] count],5u, @"");
    STAssertEqualObjects([[[[[plan sortedItineraries] objectAtIndex:4] sortedLegs] objectAtIndex:1] startTime],
                         [dateFormatter dateFromString:@"02/11/2013 07:19 pm"],@"");
    STAssertEqualObjects([[[[[[plan sortedItineraries] objectAtIndex:4] sortedLegs] objectAtIndex:3] to] name],
                         @"San Carlos Caltrain Station",@"");
    STAssertFalse([[[plan sortedItineraries] objectAtIndex:4] isOTPItinerary], @"");
    
    // [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
    
    Leg* firstGeneratedLeg = [[[[plan sortedItineraries] objectAtIndex:0] sortedLegs] objectAtIndex:0];
    STAssertNotNil([firstGeneratedLeg startTime], @"First leg start-time should not be nil");
    // View in the ViewController (uncomment when above problem resolved)
    [[toFromViewController routeOptionsVC] newPlanAvailable:plan status:PLAN_STATUS_OK RequestParameter:parameters];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    

    
    [[toFromViewController routeOptionsVC] newPlanAvailable:plan status:PLAN_STATUS_OK RequestParameter:parameters];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    
    //
    // Use RealTime Data from Data.json File and generate realtime itineraries.
    //
    [[NSUserDefaults standardUserDefaults] setObject:@"data.json" forKey:DEVICE_TOKEN];
    [[RealTimeManager realTimeManager] requestRealTimeDataFromServerUsingPlan:plan tripDate:tripDate];
    STAssertTrue([self waitForNonNullValueOfBlock:^(void){BOOL result=[RealTimeManager realTimeManager].loadedRealTimeData; return result;}], @"Timed out waiting for RealTimeData");
    [gtfsParser generateItinerariesFromRealTime:plan TripDate:tripDate Context:managedObjectContext];
    
    [plan prepareSortedItinerariesWithMatchesForDate:tripDate departOrArrive:DEPART];

    NSMutableArray *arrRealTimeItinerary = [[NSMutableArray alloc] init];
    for(int i=0;i<[[plan sortedItineraries] count];i++){
        Itinerary *itinerary = [[plan sortedItineraries] objectAtIndex:i];
        if(itinerary.isRealTimeItinerary){
            [arrRealTimeItinerary addObject:[[plan sortedItineraries] objectAtIndex:i]];
        }
    }
    
    STAssertTrue([arrRealTimeItinerary count] == 2, @"");
    
    Itinerary *firstItinerary = [arrRealTimeItinerary objectAtIndex:0];
    Itinerary *secondItinerary = [arrRealTimeItinerary objectAtIndex:1];
    
    Leg *first_2Leg = [[firstItinerary sortedLegs] objectAtIndex:1];
    Leg *first_4Leg = [[firstItinerary sortedLegs] objectAtIndex:3];
    Leg *first_5Leg = [[firstItinerary sortedLegs] objectAtIndex:4];

    STAssertTrue([first_2Leg.arrivalFlag intValue] == ON_TIME, @"");
    STAssertTrue([first_4Leg.arrivalFlag intValue] == DELAYED, @"");
    STAssertTrue([first_5Leg.arrivalFlag intValue] == DELAYED, @"");
    
    Leg *second_2Leg = [[secondItinerary sortedLegs] objectAtIndex:1];
    Leg *second_4Leg = [[secondItinerary sortedLegs] objectAtIndex:3];
    Leg *second_5Leg = [[secondItinerary sortedLegs] objectAtIndex:4];
    
    STAssertTrue([second_2Leg.arrivalFlag intValue] == DELAYED, @"");
    STAssertTrue([second_4Leg.arrivalFlag intValue] == DELAYED, @"");
    STAssertTrue([second_5Leg.arrivalFlag intValue] == DELAYED, @"");
    
    [toFromViewController.routeOptionsVC setIsReloadRealData:YES];
    [toFromViewController.routeOptionsVC.mainTable reloadData];
    [[RealTimeManager realTimeManager].routeDetailVC ReloadLegWithNewData];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.0]];
    
    // Clear The Previously Generated Realtime Itineraries.
    for(int i=0;i<[[plan itineraries] count];i++){
        Itinerary *iti = [[[plan itineraries] allObjects]  objectAtIndex:i];
        iti.itinArrivalFlag = nil;
        iti.hideItinerary = false;
        if(iti.isRealTimeItinerary){
            for(int j=0;j<[[iti sortedLegs] count];j++){
                Leg *leg = [[iti sortedLegs] objectAtIndex:j];
                leg.predictions = nil;
                leg.arrivalFlag = nil;
                leg.timeDiffInMins = nil;
            }
            [plan deleteItinerary:iti];
        }
    }
    
    for(int i=0;i<[[plan requestChunks] count];i++){
        PlanRequestChunk *reqChunks = [[[plan requestChunks] allObjects] objectAtIndex:i];
        if(reqChunks.type == [NSNumber numberWithInt:2]){
            [managedObjectContext deleteObject:reqChunks];
        }
    }
    saveContext(managedObjectContext);
    
    // Use RealTime Data from data1.json File and generate realtime itineraries.
    [[NSUserDefaults standardUserDefaults] setObject:@"data1.json" forKey:DEVICE_TOKEN];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    
    [[RealTimeManager realTimeManager] requestRealTimeDataFromServerUsingPlan:plan tripDate:tripDate];
    [RealTimeManager realTimeManager].loadedRealTimeData = false;
    STAssertTrue([self waitForNonNullValueOfBlock:^(void){BOOL result=[RealTimeManager realTimeManager].loadedRealTimeData; return result;}], @"Timed out waiting for RealTimeData");
    [gtfsParser generateItinerariesFromRealTime:plan TripDate:tripDate Context:managedObjectContext];
    
    
    [plan prepareSortedItinerariesWithMatchesForDate:tripDate departOrArrive:DEPART];
    
    NSMutableArray *arrRealTimeItinerary1 = [[NSMutableArray alloc] init];
    for(int i=0;i<[[plan sortedItineraries] count];i++){
        Itinerary *itinerary = [[plan sortedItineraries] objectAtIndex:i];
        if(itinerary.isRealTimeItinerary){
            [arrRealTimeItinerary1 addObject:[[plan sortedItineraries] objectAtIndex:i]];
        }
    }
    
    STAssertTrue([arrRealTimeItinerary1 count] == 3, @"");
    
    Itinerary *second_FirstItinerary = [arrRealTimeItinerary1 objectAtIndex:0];
    Itinerary *second_SecondItinerary = [arrRealTimeItinerary1 objectAtIndex:1];
    Itinerary *second_ThirdItinerary = [arrRealTimeItinerary1 objectAtIndex:2];
    
    Leg *second_FirstItinerary_2Leg = [[second_FirstItinerary sortedLegs] objectAtIndex:1];
    Leg *second_FirstItinerary_4Leg = [[second_FirstItinerary sortedLegs] objectAtIndex:3];
    Leg *second_FirstItinerary_5Leg = [[second_FirstItinerary sortedLegs] objectAtIndex:4];
    
    STAssertTrue([second_FirstItinerary_2Leg.arrivalFlag intValue] == ON_TIME, @"");
    STAssertTrue([second_FirstItinerary_4Leg.arrivalFlag intValue] == ON_TIME, @"");
    STAssertTrue([second_FirstItinerary_5Leg.arrivalFlag intValue] == ON_TIME, @"");
    
    Leg *second_SecondItinerary_2Leg = [[second_SecondItinerary sortedLegs] objectAtIndex:1];
    Leg *second_SecondItinerary_4Leg = [[second_SecondItinerary sortedLegs] objectAtIndex:3];
    Leg *second_SecondItinerary_5Leg = [[second_SecondItinerary sortedLegs] objectAtIndex:4];
    
    STAssertTrue([second_SecondItinerary_2Leg.arrivalFlag intValue] == DELAYED, @"");
    NSLog(@"%@",second_SecondItinerary_4Leg.arrivalFlag);
    NSLog(@"%@",second_SecondItinerary_5Leg.arrivalFlag);
    STAssertTrue([second_SecondItinerary_4Leg.arrivalFlag intValue] == ON_TIME, @"");
    STAssertTrue([second_SecondItinerary_5Leg.arrivalFlag intValue] == ON_TIME, @"");
    
    Leg *second_ThirdItinerary_2Leg = [[second_ThirdItinerary sortedLegs] objectAtIndex:1];
    Leg *second_ThirdItinerary_4Leg = [[second_ThirdItinerary sortedLegs] objectAtIndex:3];
   
    
    STAssertTrue([second_ThirdItinerary_2Leg.arrivalFlag intValue] == DELAYED, @"");
    STAssertTrue([second_ThirdItinerary_4Leg.arrivalFlag intValue] == DELAYED, @"");
    
    [toFromViewController.routeOptionsVC setIsReloadRealData:YES];
    [toFromViewController.routeOptionsVC.mainTable reloadData];
    [[RealTimeManager realTimeManager].routeDetailVC ReloadLegWithNewData];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    
    // Clear The Previously Generated Realtime Itineraries.
    for(int i=0;i<[[plan itineraries] count];i++){
        Itinerary *iti = [[[plan itineraries] allObjects]  objectAtIndex:i];
        iti.itinArrivalFlag = nil;
        iti.hideItinerary = false;
        if(iti.isRealTimeItinerary){
            for(int j=0;j<[[iti sortedLegs] count];j++){
                Leg *leg = [[iti sortedLegs] objectAtIndex:j];
                leg.predictions = nil;
                leg.arrivalFlag = nil;
                leg.timeDiffInMins = nil;
            }
            [plan deleteItinerary:iti];
        }
    }
    
    for(int i=0;i<[[plan requestChunks] count];i++){
        PlanRequestChunk *reqChunks = [[[plan requestChunks] allObjects] objectAtIndex:i];
        if(reqChunks.type == [NSNumber numberWithInt:2]){
            [managedObjectContext deleteObject:reqChunks];
        }
    }
    saveContext(managedObjectContext);
    
    // Use RealTime Data from data2.json File and generate realtime itineraries.
    [[NSUserDefaults standardUserDefaults] setObject:@"data2.json" forKey:DEVICE_TOKEN];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    
    [[RealTimeManager realTimeManager] requestRealTimeDataFromServerUsingPlan:plan tripDate:tripDate];
    [RealTimeManager realTimeManager].loadedRealTimeData = false;
    STAssertTrue([self waitForNonNullValueOfBlock:^(void){BOOL result=[RealTimeManager realTimeManager].loadedRealTimeData; return result;}], @"Timed out waiting for RealTimeData");
    [gtfsParser generateItinerariesFromRealTime:plan TripDate:tripDate Context:managedObjectContext];
    
    
    [plan prepareSortedItinerariesWithMatchesForDate:tripDate departOrArrive:DEPART];
    
    NSMutableArray *arrRealTimeItinerary2 = [[NSMutableArray alloc] init];
    for(int i=0;i<[[plan sortedItineraries] count];i++){
        Itinerary *itinerary = [[plan sortedItineraries] objectAtIndex:i];
        if(itinerary.isRealTimeItinerary){
            [arrRealTimeItinerary2 addObject:[[plan sortedItineraries] objectAtIndex:i]];
        }
    }
    
    STAssertTrue([arrRealTimeItinerary2 count] == 2, @"");
    
    Itinerary *third_FirstItinerary = [arrRealTimeItinerary2 objectAtIndex:0];
    Itinerary *third_SecondItinerary = [arrRealTimeItinerary2 objectAtIndex:1];
    
    Leg *third_FirstItinerary_2Leg = [[third_FirstItinerary sortedLegs] objectAtIndex:1];
    STAssertTrue([third_FirstItinerary_2Leg.arrivalFlag intValue] == DELAYED, @"");
    
    Leg *third_SecondItinerary_2Leg = [[third_SecondItinerary sortedLegs] objectAtIndex:1];
    STAssertTrue([third_SecondItinerary_2Leg.arrivalFlag intValue] == DELAYED, @"");
    
    [toFromViewController.routeOptionsVC setIsReloadRealData:YES];
    [toFromViewController.routeOptionsVC.mainTable reloadData];
    [[RealTimeManager realTimeManager].routeDetailVC ReloadLegWithNewData];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
}

// NOTE from John 2/10/2013:
// Set-up and tear-down are not working with multiple test methods.  Recommend putting all automated tests into the above test procedure if possible.

@end
