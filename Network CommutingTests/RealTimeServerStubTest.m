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

    [rkMOS deletePersistantStoreUsingSeedDatabaseName:nil];  // Make sure data store is cleared to start with
    
    // Set up the ManagedObjectContect and RKObjectManager
    rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:TEST_TRIP_PROCESS_URL];
    [rkPlanMgr setObjectStore:rkMOS];
    
    // Get the NSManagedObjectContext from restkit
    managedObjectContext = [rkMOS managedObjectContext];
    int storeCount = [[[managedObjectContext persistentStoreCoordinator] persistentStores] count];
    if (storeCount > 0) {
        NIMLOG_AUTOTEST(@"managedObjectContext Store URL = %@", [[[[managedObjectContext persistentStoreCoordinator] persistentStores] objectAtIndex:0] URL]);
    }
    
    rkTpClient = [RKClient clientWithBaseURL:TEST_TRIP_PROCESS_URL];

    // Set up the planStore
    planStore = [[PlanStore alloc] initWithManagedObjectContext:managedObjectContext rkPlanMgr:rkPlanMgr];
    
    // Set up RealTimeManager
    [[RealTimeManager realTimeManager] setRkTpClient:rkTpClient];
    
    // Initialize The GtfsParser
    gtfsParser = [[GtfsParser alloc] initWithManagedObjectContext:managedObjectContext
                                                       rkTpClient:rkTpClient];
    
    // Set up Locations wrapper object pointing at the test Managed Object Context
    locations = [[Locations alloc] initWithManagedObjectContext:managedObjectContext rkGeoMgr:nil];
    
    // Set up individual Location objects
    // loc1 is used for testing most methods including isMatchingTypedString and has Address Components included
    LocationFromGoogle* loc1G = [NSEntityDescription insertNewObjectForEntityForName:@"LocationFromGoogle" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac1 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac2 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac3 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac4 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac5 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac6 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac7 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    [ac1 setLongName:@"750"];
    [ac2 setLongName:@"Hawthorne Street"];
    [ac3 setLongName:@"San Francisco"];
    [ac4 setLongName:@"San Francisco"];
    [ac5 setLongName:@"California"];
    [ac6 setLongName:@"94103"];
    [ac6 setShortName:@"94103"];
    [ac7 setLongName:@"United States of America"];
    [ac7 setShortName:@"USA"];
    [ac1 setTypes:[NSArray arrayWithObjects:@"street_number", nil]];
    [ac2 setTypes:[NSArray arrayWithObjects:@"route", nil]];
    [ac3 setTypes:[NSArray arrayWithObjects:@"locality", @"political", nil]];
    [ac4 setTypes:[NSArray arrayWithObjects:@"political", @"locality", nil]];  // try reverse order
    [ac5 setTypes:[NSArray arrayWithObjects:@"administrative_area_level_1", @"political", nil]];
    [ac6 setTypes:[NSArray arrayWithObjects:@"postal_code", nil]];
    [ac7 setTypes:[NSArray arrayWithObjects:@"country", @"political", nil]];
    
    [loc1G setFormattedAddress:@"750 Hawthorne Street, San Francisco, CA 94103, USA"];
    [loc1G setAddressComponents:[NSSet setWithObjects:ac1,ac2,ac3,ac4,ac5,ac6,ac7,nil]];
    
    [loc1G addRawAddressString:@"750 Hawthorne St., SF"];
    [loc1G addRawAddressString:@"750 Hawthorn, San Fran California"];
    
    [loc1G setFromFrequencyFloat:5.0];
    [loc1G setToFrequencyFloat:7.0];
    [loc1G setLatFloat:67.3];
    [loc1G setLngFloat:-122.3];
    loc1 = loc1G;  // Now treat it as a generic Location object
    
    // Additional set-up
    // loc2 and loc3 give additional testing for formatted address and raw address retrieval
    // It has some (number, city, state) but not all the address components from loc1
    LocationFromGoogle* loc2G = [NSEntityDescription insertNewObjectForEntityForName:@"LocationFromGoogle" inManagedObjectContext:managedObjectContext];
    [loc2G setFormattedAddress:@"750 Hawthorne Street, San Francisco"];
    [loc2G addRawAddressString:@"750 Hawthorne, San Fran California"];
    [loc2G addRawAddressString:@"750 Hawthoorn, SF"];
    [loc2G setFromFrequencyFloat:7];  // greater than loc1
    loc2 = loc2G; // Treat as a generic location object
    
    LocationFromGoogle* loc3G = [NSEntityDescription insertNewObjectForEntityForName:@"LocationFromGoogle" inManagedObjectContext:managedObjectContext];
    [loc3G setFormattedAddress:@"1350 Hull Drive, San Carlos, CA USA"];
    [loc3G addRawAddressString:@"1350 Hull, San Carlos CA"];
    [loc3G addRawAddressString:@"1350 Hull Dr. San Carlos CA"];
    loc3 = loc3G;
    
    //
    // Set up plans, itineraries, and legs for testing plan caching
    //
    
    // Set-up dates
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM dd, yyyy hh:mm a"];
    NSDate* date10 = [dateFormatter dateFromString:@"June 8, 2012 5:00 PM"]; // Friday before last load
    NSDate* date11 = [dateFormatter dateFromString:@"June 8, 2012 5:30 PM"]; // Friday before last load
    
    //
    // Set up plans, itineraries, and legs for testing Itinerary and leg generation from Patterns
    //
    
    plan10 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    
    itin101 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin102 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin103 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    
    leg1011 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1012 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1013 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1021 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1031 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    
    leg1011.startTime = date10;
    leg1011.duration = [NSNumber numberWithInt:519000];
    leg1011.mode = @"WALK";
    leg1011.itinerary = itin101;
    itin101.startTime = date10;
    itin101.endTime = [itin101.startTime dateByAddingTimeInterval:(30.0*60)];
    itin101.plan = plan10;
    PlanPlace *pp101 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    PlanPlace *pp102 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    [pp101 setLat:[NSNumber numberWithDouble:37.75768017385226]];
    [pp101 setLng:[NSNumber numberWithDouble:-122.3926363695829]];
    [pp102 setLat:[NSNumber numberWithDouble:37.755414]];
    [pp102 setLng:[NSNumber numberWithDouble:-122.388001]];
    [pp102 setStopId:@"7354"];
    [pp101 setName:@"22nd Street"];
    [pp102 setName:@"Third Street & 23rd St"];
    leg1011.from = pp101;
    leg1011.to = pp102;
    leg1011.endTime = [leg1011.startTime dateByAddingTimeInterval:(30.0*60)];
    
    leg1012.startTime = date11;
    leg1012.duration = [NSNumber numberWithInt:500000];
    leg1012.agencyId = @"SFMTA";
    leg1012.mode = @"TRAM";
    leg1012.route = @"KT";
    leg1012.routeShortName = @"KT";
    leg1012.routeLongName = @"OCEAN VIEW";
    leg1012.routeId = @"1196";
    leg1012.tripId = @"5249630";
    leg1012.itinerary = itin101;
    itin101.startTime = date11;
    itin101.endTime = [itin101.startTime dateByAddingTimeInterval:(30.0*60)];
    itin101.plan = plan10;
    
    PlanPlace *pp103 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    PlanPlace *pp104 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    [pp103 setLat:[NSNumber numberWithDouble:37.755414]];
    [pp103 setLng:[NSNumber numberWithDouble:-122.388001]];
    [pp104 setLat:[NSNumber numberWithDouble:37.776278]];
    [pp104 setLng:[NSNumber numberWithDouble:-122.393864]];
    [pp103 setStopId:@"7354"];
    [pp104 setStopId:@"7166"];
    [pp103 setName:@"Third Street & 23rd St"];
    [pp104 setName:@"4th St & King St"];
    leg1012.from = pp103;
    leg1012.to = pp104;
    leg1012.endTime = [leg1013.startTime dateByAddingTimeInterval:(30.0*60)];
    
    leg1013.startTime = date10;
    leg1013.duration = [NSNumber numberWithInt:519000];
    leg1013.mode = @"WALK";
    leg1013.itinerary = itin101;
    itin101.startTime = date10;
    itin101.endTime = [itin101.startTime dateByAddingTimeInterval:(30.0*60)];
    itin101.plan = plan10;
    PlanPlace *pp105 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    PlanPlace *pp106 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    [pp105 setLat:[NSNumber numberWithDouble:37.776281735478]];
    [pp105 setLng:[NSNumber numberWithDouble:-122.3938669227692]];
    [pp106 setLat:[NSNumber numberWithDouble:37.77651903369463]];
    [pp106 setLng:[NSNumber numberWithDouble:-122.3942596619232]];
    [pp106 setStopId:@"7354"];
    [pp105 setName:@"King Street"];
    [pp106 setName:@"4th Street"];
    leg1013.from = pp105;
    leg1013.to = pp106;
    leg1013.endTime = [leg1013.startTime dateByAddingTimeInterval:(30.0*60)];
    
    
    leg1021.startTime = date11;
    leg1021.duration = [NSNumber numberWithInt:540000];
    leg1021.agencyId = @"caltrain-ca-us";
    leg1021.agencyName = @"Caltrain";
    leg1021.mode = @"RAIL";
    leg1021.route = @"Local";
    leg1021.routeLongName = @"Local";
    leg1021.routeId = @"ct_local_20121001";
    leg1021.tripId = @"195_20121001";
    leg1021.itinerary = itin102;
    itin102.startTime = date11;
    itin102.endTime = [itin102.startTime dateByAddingTimeInterval:(30.0*60)];
    itin102.plan = plan10;
    
    PlanPlace *pp107 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    PlanPlace *pp108 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    [pp107 setLat:[NSNumber numberWithDouble:37.757674]];
    [pp107 setLng:[NSNumber numberWithDouble:-122.392636]];
    [pp108 setLat:[NSNumber numberWithDouble:37.7764393371]];
    [pp108 setLng:[NSNumber numberWithDouble:-122.394322993]];
    [pp107 setStopId:@"22nd Street Caltrain"];
    [pp108 setStopId:@"San Francisco Caltrain"];
    [pp107 setName:@"22nd Street Caltrain Station"];
    [pp108 setName:@"San Francisco Caltrain Station"];
    leg1021.from = pp107;
    leg1021.to = pp108;
    leg1021.endTime = [leg1021.startTime dateByAddingTimeInterval:(30.0*60)];
    
    
    leg1031.startTime = date11;
    leg1031.duration = [NSNumber numberWithInt:540000];
    leg1031.agencyId = @"caltrain-ca-us";
    leg1031.agencyName = @"Caltrain";
    leg1031.mode = @"RAIL";
    leg1031.route = @"Local";
    leg1031.routeLongName = @"Local";
    leg1031.routeId = @"ct_local_20121001";
    leg1031.tripId = @"197_20121001";
    leg1031.itinerary = itin103;
    itin103.startTime = date11;
    itin103.endTime = [itin103.startTime dateByAddingTimeInterval:(30.0*60)];
    itin103.plan = plan10;
    
    PlanPlace *pp109 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    PlanPlace *pp1010 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    [pp109 setLat:[NSNumber numberWithDouble:37.757674]];
    [pp109 setLng:[NSNumber numberWithDouble:-122.392636]];
    [pp1010 setLat:[NSNumber numberWithDouble:37.7764393371]];
    [pp1010 setLng:[NSNumber numberWithDouble:-122.394322993]];
    [pp109 setStopId:@"22nd Street Caltrain"];
    [pp1010 setStopId:@"San Francisco Caltrain"];
    [pp109 setName:@"22nd Street Caltrain Station"];
    [pp1010 setName:@"San Francisco Caltrain Station"];
    leg1031.from = pp109;
    leg1031.to = pp1010;
    leg1031.endTime = [leg1031.startTime dateByAddingTimeInterval:(30.0*60)];
    
    
    plan11 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    itin111 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin112 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin113 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    leg1111 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1112 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1113 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1121 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1131 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    
    leg1111.startTime = date11;
    leg1111.duration = [NSNumber numberWithInt:540000];
    leg1111.agencyId = @"caltrain-ca-us";
    leg1111.agencyName = @"Caltrain";
    leg1111.mode = @"RAIL";
    leg1111.route = @"Local";
    leg1111.routeLongName = @"Local";
    leg1111.routeId = @"ct_local_20121001";
    leg1111.tripId = @"197_20121001";
    leg1111.itinerary = itin111;
    itin111.startTime = date11;
    itin111.endTime = [itin111.startTime dateByAddingTimeInterval:(30.0*60)];
    itin111.plan = plan11;
    
    PlanPlace *pp110 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    PlanPlace *pp111 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    [pp110 setLat:[NSNumber numberWithDouble:37.757674]];
    [pp110 setLng:[NSNumber numberWithDouble:-122.392636]];
    [pp111 setLat:[NSNumber numberWithDouble:37.7764393371]];
    [pp111 setLng:[NSNumber numberWithDouble:-122.394322993]];
    [pp110 setStopId:@"22nd Street Caltrain"];
    [pp111 setStopId:@"San Francisco Caltrain"];
    [pp110 setName:@"22nd Street Caltrain Station"];
    [pp111 setName:@"San Francisco Caltrain Station"];
    leg1111.from = pp110;
    leg1111.to = pp111;
    leg1111.endTime = [leg1111.startTime dateByAddingTimeInterval:(30.0*60)];
    
    
    leg1121.startTime = date11;
    leg1121.duration = [NSNumber numberWithInt:540000];
    leg1121.agencyId = @"caltrain-ca-us";
    leg1121.agencyName = @"Caltrain";
    leg1121.mode = @"RAIL";
    leg1121.route = @"Local";
    leg1121.routeLongName = @"Limited";
    leg1121.routeId = @"ct_limited_20121001";
    leg1121.tripId = @"195_20121001";
    leg1121.itinerary = itin112;
    itin112.startTime = date11;
    itin112.endTime = [itin112.startTime dateByAddingTimeInterval:(30.0*60)];
    itin112.plan = plan11;
    
    PlanPlace *pp117 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    PlanPlace *pp118 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    [pp117 setLat:[NSNumber numberWithDouble:37.757674]];
    [pp117 setLng:[NSNumber numberWithDouble:-122.392636]];
    [pp118 setLat:[NSNumber numberWithDouble:37.7764393371]];
    [pp118 setLng:[NSNumber numberWithDouble:-122.394322993]];
    [pp117 setStopId:@"22nd Street Caltrain"];
    [pp118 setStopId:@"San Francisco Caltrain"];
    [pp117 setName:@"22nd Street Caltrain Station"];
    [pp118 setName:@"San Francisco Caltrain Station"];
    leg1121.from = pp117;
    leg1121.to = pp118;
    leg1121.endTime = [leg1121.startTime dateByAddingTimeInterval:(30.0*60)];
    
    
    leg1131.startTime = date11;
    leg1131.duration = [NSNumber numberWithInt:540000];
    leg1131.agencyId = @"caltrain-ca-us";
    leg1131.agencyName = @"Caltrain";
    leg1131.mode = @"RAIL";
    leg1131.route = @"Local";
    leg1131.routeLongName = @"Bullet";
    leg1131.routeId = @"ct_bullet_20121001";
    leg1131.tripId = @"197_20121001";
    leg1131.itinerary = itin113;
    itin113.startTime = date11;
    itin113.endTime = [itin113.startTime dateByAddingTimeInterval:(30.0*60)];
    itin113.plan = plan11;
    
    PlanPlace *pp119 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    PlanPlace *pp1110 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    [pp119 setLat:[NSNumber numberWithDouble:37.757674]];
    [pp119 setLng:[NSNumber numberWithDouble:-122.392636]];
    [pp1110 setLat:[NSNumber numberWithDouble:37.7764393371]];
    [pp1110 setLng:[NSNumber numberWithDouble:-122.394322993]];
    [pp119 setStopId:@"22nd Street Caltrain"];
    [pp1110 setStopId:@"San Francisco Caltrain"];
    [pp119 setName:@"22nd Street Caltrain Station"];
    [pp1110 setName:@"San Francisco Caltrain Station"];
    leg1131.from = pp119;
    leg1131.to = pp1110;
    leg1131.endTime = [leg1131.startTime dateByAddingTimeInterval:(30.0*60)];
    // Save context
    saveContext(managedObjectContext);
}



- (void)tearDown
{
    // Tear-down code here.
    
    // Delete Core Data persistent store
    [rkMOS deletePersistantStoreUsingSeedDatabaseName:nil];
    NIMLOG_AUTOTEST(@"tearDown: PersistentStore cleared");
    
    [super tearDown];
}

// Methods wait until Error or Reply arrives from TP.
-(void)someMethodToWaitForResult
{
    while (!gtfsParser.loadedInitialData) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    }
}


// Test The GtfsAgency Data Parsing and DB Insertion with some test data.
- (void)testGtfsDataParsingAndDBInsertion{
    // Agency DataParsing and DB Insertion Testing
    [gtfsParser requestAgencyDataFromServer];
    [self someMethodToWaitForResult];
    
    NSFetchRequest * fetchAgency = [[NSFetchRequest alloc] init];
    [fetchAgency setEntity:[NSEntityDescription entityForName:@"GtfsAgency" inManagedObjectContext:managedObjectContext]];
    NSArray* arrayAgency = [managedObjectContext executeFetchRequest:fetchAgency error:nil];
    STAssertTrue([arrayAgency count] == 5, @"");
    
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
        else {
            test9 = ([agency.agencyName isEqualToString:@"AC Transit"]);
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
    bool testStops4 = false;
    bool testStops5 = false;
    bool testStops6 = false;
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
        else if ([stops.stopID isEqualToString:@"3009"]) {
            testStops4 = ([stops.stopName isEqualToString:@"2nd St & Harrison St"]);
            testStops5 = ([stops.stopLat doubleValue] ==  37.784532);
            testStops6 = ([stops.stopLon doubleValue] ==  -122.395325);
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
    STAssertTrue(testStops4, @"Stops testStops4");
    STAssertTrue(testStops5, @"Stops testStops5");
    STAssertTrue(testStops6, @"Stops testStops6");
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
}
@end
