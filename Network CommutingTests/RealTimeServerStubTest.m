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

    // Set up the ManagedObjectContect and RKObjectManager
    rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:TEST_TRIP_PROCESS_URL];
    [rkPlanMgr setObjectStore:rkMOS];
    
    // Get the NSManagedObjectContext from restkit
    managedObjectContext = [rkMOS managedObjectContext];
    int storeCount = [[[managedObjectContext persistentStoreCoordinator] persistentStores] count];
    if (storeCount > 0) {
        NIMLOG_AUTOTEST(@"managedObjectContext Store URL = %@", [[[[managedObjectContext persistentStoreCoordinator] persistentStores] objectAtIndex:0] URL]);
    }
    
    rkTpClient = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];

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
    
    [super tearDown];
}

// Methods wait until Error or Reply arrives from TP.
-(void)someMethodToWaitForResult
{
    while (!([nc_AppDelegate sharedInstance].receivedReply^[nc_AppDelegate sharedInstance].receivedError))
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
}


// Test The GtfsAgency Data Parsing and DB Insertion with some test data.
- (void)testGtfsAgencyDataParsingAndDBInsertion{
    NSString *strTitle = @"agency_id,agency_name,agency_url";
    NSString *strCaltrain = @"caltrain-ca-us,Caltrain,http://www.caltrain.com";
    NSString *strAirBart = @"AirBART,AirBART,http://www.bart.gov/guide/airport/inbound_oak.aspx";
    NSString *strBart = @"BART,Bay Area Rapid Transit,http://www.bart.gov";
    NSString *strMuni = @"SFMTA,San Francisco Municipal Transportation Agency,http://www.sfmta.com";
    NSString *strAcTransit = @",AC Transit,http://www.actransit.org";
    
    NSArray *arrCaltrainAgencyData = [NSArray arrayWithObjects:strTitle,strCaltrain, nil];
    NSArray *arrBartnAgencyData = [NSArray arrayWithObjects:strTitle,strAirBart,strBart, nil];
    NSArray *arrSfmtaAgencyData = [NSArray arrayWithObjects:strTitle,strMuni, nil];
    NSArray *arractransitAgencyData = [NSArray arrayWithObjects:strTitle,strAcTransit, nil];
    NSDictionary *dictData = [NSDictionary dictionaryWithObjectsAndKeys:arrCaltrainAgencyData,@"1_agency",arrBartnAgencyData,@"2_agency",arrSfmtaAgencyData,@"3_agency",arractransitAgencyData,@"4_agency", nil];
    NSDictionary *agencyDict = [NSDictionary dictionaryWithObjectsAndKeys:@"105",@"code",@"msg",@"Operation Completed Sucessfully",dictData,@"data", nil];
    [gtfsParser parseAndStroreGtfsAgencyData:agencyDict];
}

// Test GtfsCalendar data load using Sinatra to load file gtfs_rawdata_calendar.json
- (void)testGtfsCalendarDataLoadAndParsing {
    [gtfsParser requestCalendarDatafromServer];
    [self someMethodToWaitForResult];
    
    // Retrieve all calendar entries from CoreData
    NSFetchRequest * fetchCalendar = [[NSFetchRequest alloc] init];
    [fetchCalendar setEntity:[NSEntityDescription entityForName:@"GtfsCalendar" inManagedObjectContext:managedObjectContext]];
    NSArray* arrayCalendar = [managedObjectContext executeFetchRequest:fetchCalendar error:nil];
    
    bool test1 = false;
    bool test2 = false;
    bool test3 = false;
    for (GtfsCalendar* calendar in arrayCalendar) {
        if ([calendar.serviceID isEqualToString:@"WE_20121001"]) {
            test1 = (calendar.monday.integerValue == 0);
            test2 = (calendar.saturday.integerValue == 1);
        }
        else if ([calendar.serviceID isEqualToString:@"WKDY"]) {
            test3 = (calendar.wednesday.integerValue == 1);
        }
    }
    STAssertTrue(test1, @"Calendar test1");
    STAssertTrue(test2, @"Calendar test2");
    STAssertTrue(test3, @"Calendar test3");
    
}

// Test The GtfsCalendar Data Parsing and DB Insertion with some test data.
- (void)testGtfsCalendarDataParsingAndDBInsertion{
    NSString *strTitle = @"service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date";
    NSString *strCalRow1 = @"ST_20120701,0,0,0,0,0,1,0,20120701,20120930";
    NSString *strCalRow2 = @"WD_20120701,1,1,1,1,1,0,0,20120701,20120930";
    NSString *strCalRow3 = @"WE_20120701,0,0,0,0,0,1,1,20120701,20120930";
    NSString *strCalRow4 = @"WE_20121001,0,0,0,0,0,1,1,20121001,20131001";
    
    NSArray *arrCaltrainData = [NSArray arrayWithObjects:strTitle,strCalRow1,strCalRow3, nil];
    NSArray *arrBartData = [NSArray arrayWithObjects:strTitle,strCalRow2,strCalRow4, nil];
    NSArray *arrMuniData = [NSArray arrayWithObjects:strTitle,strCalRow1,strCalRow2, nil];
    NSArray *arrAcTransitData = [NSArray arrayWithObjects:strTitle,strCalRow3,strCalRow4, nil];
    NSDictionary *dictData = [NSDictionary dictionaryWithObjectsAndKeys:arrCaltrainData,@"1_calendar",arrBartData,@"2_calendar",arrMuniData,@"3_calendar",arrAcTransitData,@"4_calendar", nil];
    NSDictionary *agencyDict = [NSDictionary dictionaryWithObjectsAndKeys:@"105",@"code",@"msg",@"Operation Completed Sucessfully",dictData,@"data", nil];
    [gtfsParser parseAndStoreGtfsCalendarData:agencyDict];
}

// Test The GtfsCalendarDates Data Parsing and DB Insertion with some test data.
- (void)testGtfsCalendarDatesParsingAndDBInsertion{
    NSString *strTitle = @"service_id,date,exception_type";
    NSString *strCalDatesRow1 = @"WE_20120701,20120704,1";
    NSString *strCalDatesRow2 = @"WD_20120701,20120704,2";
    NSString *strCalDatesRow3 = @"WD_20120701,20120903,2";
    NSString *strCalDatesRow4 = @"WE_20120701,20120903,1";
    NSString *strCalDatesRow5 = @"WE_20120701,20121122,1";
    
    NSArray *arrCaltrainData = [NSArray arrayWithObjects:strTitle,strCalDatesRow1,strCalDatesRow3, nil];
    NSArray *arrBartData = [NSArray arrayWithObjects:strTitle,strCalDatesRow2,strCalDatesRow4,strCalDatesRow5, nil];
    NSArray *arrMuniData = [NSArray arrayWithObjects:strTitle,strCalDatesRow1,strCalDatesRow2, nil];
    NSArray *arrAcTransitData = [NSArray arrayWithObjects:strTitle,strCalDatesRow3,strCalDatesRow4,strCalDatesRow5, nil];
    NSDictionary *dictData = [NSDictionary dictionaryWithObjectsAndKeys:arrCaltrainData,@"1_calendar_dates",arrBartData,@"2_calendar_dates",arrMuniData,@"3_calendar_dates",arrAcTransitData,@"4_calendar_dates", nil];
    NSDictionary *agencyDict = [NSDictionary dictionaryWithObjectsAndKeys:@"105",@"code",@"msg",@"Operation Completed Sucessfully",dictData,@"data", nil];
    [gtfsParser parseAndStoreGtfsCalendarDatesData:agencyDict];
}

// Test The GtfsRoutes Data Parsing and DB Insertion with some test data.
- (void)testGtfsRoutesDataParsingAndDBInsertion{
    NSString *strTitle = @"route_id,route_short_name,route_long_name,route_desc,route_type";
    NSString *strRoutesRow1 = @"ct_bullet_20120701,,Bullet,,";
    NSString *strRoutesRow2 = @"ct_limited_20120701,,Limited,,2";
    NSString *strRoutesRow3 = @"ct_local_20120701,,Local,,2";
    NSString *strRoutesRow4 = @"ct_bullet_20121001,,Bullet,,2";
    NSString *strRoutesRow5 = @"ct_limited_20121001,,Limited,,2";
    
    NSArray *arrCaltrainData = [NSArray arrayWithObjects:strTitle,strRoutesRow1,strRoutesRow3, nil];
    NSArray *arrBartData = [NSArray arrayWithObjects:strTitle,strRoutesRow2,strRoutesRow4,strRoutesRow5, nil];
    NSArray *arrMuniData = [NSArray arrayWithObjects:strTitle,strRoutesRow1,strRoutesRow2, nil];
    NSArray *arrAcTransitData = [NSArray arrayWithObjects:strTitle,strRoutesRow3,strRoutesRow4,strRoutesRow5, nil];
    NSDictionary *dictData = [NSDictionary dictionaryWithObjectsAndKeys:arrCaltrainData,@"1_routes",arrBartData,@"2_routes",arrMuniData,@"3_routes",arrAcTransitData,@"4_routes", nil];
    NSDictionary *agencyDict = [NSDictionary dictionaryWithObjectsAndKeys:@"105",@"code",@"msg",@"Operation Completed Sucessfully",dictData,@"data", nil];
    [gtfsParser parseAndStoreGtfsRoutesData:agencyDict];
}

// Test The GtfsStops Data Parsing and DB Insertion with some test data.
- (void)testGtfsStopsDataParsingAndDBInsertion{
    NSString *strTitle = @"stop_id,stop_name,stop_desc,stop_lat,stop_lon,zone_id";
    NSString *strStopsRow1 = @"22nd Street Caltrain,22nd Street Caltrain Station,1149 22nd Street-San Francisco,37.757674,-122.392636,1";
    NSString *strStopsRow2 = @"Atherton Caltrain,Atherton Caltrain Station,1 Dinkelspiel Station Lane- Atherton,37.464349,-122.198106,3";
    NSString *strStopsRow3 = @"Bayshore Caltrain,Bayshore Caltrain Station,400 Tunnel Avenue-San Francisco,37.709544,-122.401318,1";
    NSString *strStopsRow4 = @"Belmont Caltrain,Belmont Caltrain Station,995 El Camino Real- Belmont,37.520504,-122.276075,2";
    NSString *strStopsRow5 = @"Blossom Hill Caltrain,Blossom Hill Caltrain Station,5560 Monterey Hwy.-San Jose,37.252801,-121.797369,5";
    
    NSArray *arrCaltrainData = [NSArray arrayWithObjects:strTitle,strStopsRow1,strStopsRow3, nil];
    NSArray *arrBartData = [NSArray arrayWithObjects:strTitle,strStopsRow2,strStopsRow4,strStopsRow5, nil];
    NSArray *arrMuniData = [NSArray arrayWithObjects:strTitle,strStopsRow1,strStopsRow2, nil];
    NSArray *arrAcTransitData = [NSArray arrayWithObjects:strTitle,strStopsRow4,strStopsRow5,strStopsRow3, nil];
    NSDictionary *dictData = [NSDictionary dictionaryWithObjectsAndKeys:arrCaltrainData,@"1_stops",arrBartData,@"2_stops",arrMuniData,@"3_stops",arrAcTransitData,@"4_stops", nil];
    NSDictionary *agencyDict = [NSDictionary dictionaryWithObjectsAndKeys:@"105",@"code",@"msg",@"Operation Completed Sucessfully",dictData,@"data", nil];
    [gtfsParser parseAndStoreGtfsStopsData:agencyDict];
}

// First we get all gtfs Data from server and save to database.
// Get unique itinerary patterns from database and add to plan.
// Get Gtfs trips and stoptimes data from server and save to database.
// generate  new itinerary from patterns and stoptimes data and add it to plan.

- (void)testItineraryCreationFromPattern{
    [gtfsParser requestAgencyDataFromServer];
    [self someMethodToWaitForResult];
    NSArray *uniqueitineraryFromPlan10 = [plan10 uniqueItineraries];
    STAssertTrue([uniqueitineraryFromPlan10 count] == 2, @"");
    NSArray *uniqueitineraryFromPlan11 = [plan11 uniqueItineraries];
    STAssertTrue([uniqueitineraryFromPlan11 count] == 3, @"");
    [gtfsParser generateGtfsTripsRequestStringUsingPlan:plan10];
    [self someMethodToWaitForResult];
    //[gtfsParser generateStopTimesRequestString:plan10];
    [self someMethodToWaitForResult];
    
    [plan10 setUniqueItineraryPatterns:[NSSet setWithArray:uniqueitineraryFromPlan10]];
    PlanRequestParameters *parameters = [[PlanRequestParameters alloc] init];
    NSDate* date10req = [dateFormatter dateFromString:@"June 8, 2012 9:40 AM"]; // Friday before last load
    parameters.originalTripDate = date10req;
    
    NSArray *arrItineraries = [[plan10 itineraries] allObjects];
    plan10 = [gtfsParser generateLegsAndItineraryFromPatternsOfPlan:plan10 parameters:parameters Context:managedObjectContext];
    saveContext(managedObjectContext);
    NSArray *arrnewItineraries = [[plan10 itineraries] allObjects];
    STAssertTrue([arrItineraries count] <= [arrnewItineraries count],@"");
}

// TODO: Need to load proper Gtfs StopTimes Data and then test result of generateNewItineraryByRemovingConflictLegs method.

- (void)testgenerateNewItineraryByRemovingConflictLegs{
    NSDate* date1 = [dateFormatter dateFromString:@"June 8, 2012 5:00 PM"];
    NSDate* date2 = [dateFormatter dateFromString:@"June 8, 2012 5:05 PM"];
    NSDate* date3 = [dateFormatter dateFromString:@"June 8, 2012 5:05 PM"];
    NSDate* date4 = [dateFormatter dateFromString:@"June 8, 2012 5:20 PM"];
    NSDate* date5 = [dateFormatter dateFromString:@"June 8, 2012 5:20 PM"];
    NSDate* date6 = [dateFormatter dateFromString:@"June 8, 2012 5:25 PM"];
    
    NSDate* dater3 = [dateFormatter dateFromString:@"June 8, 2012 5:08 PM"];
    NSDate* dater4 = [dateFormatter dateFromString:@"June 8, 2012 5:23 PM"];
    NSDate* dater5 = [dateFormatter dateFromString:@"June 8, 2012 5:24 PM"];
    NSDate* dater6 = [dateFormatter dateFromString:@"June 8, 2012 5:29 PM"];
    
    plan12 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];;
    itin120 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    
    leg1201= [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1201.mode = @"WALK";
    PlanPlace *pp101 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    PlanPlace *pp102 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    [pp101 setLat:[NSNumber numberWithDouble:37.75768017385226]];
    [pp101 setLng:[NSNumber numberWithDouble:-122.3926363695829]];
    [pp102 setLat:[NSNumber numberWithDouble:37.755414]];
    [pp102 setLng:[NSNumber numberWithDouble:-122.388001]];
    [pp102 setStopId:@"7354"];
    [pp101 setName:@"22nd Street"];
    [pp102 setName:@"Third Street & 23rd St"];
    leg1201.from = pp101;
    leg1201.to = pp102;
    leg1201.startTime = date1;
    leg1201.endTime = date2;
    leg1201.duration = [NSNumber numberWithInt:300000];
    leg1201.itinerary = itin120;
    
    
    leg1202 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1202.agencyId = @"SFMTA";
    leg1202.agencyName = @"San Francisco Municipal Transportation Agency";
    leg1202.mode = @"TRAM";
    leg1202.route = @"KT";
    leg1202.routeShortName = @"KT";
    leg1202.routeLongName = @"OCEAN VIEW";
    leg1202.routeId = @"1196";
    leg1202.tripId = @"5249630";
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
    leg1202.from = pp103;
    leg1202.to = pp104;
    leg1202.startTime = date3;
    leg1202.endTime = date4;
    leg1202.realStartTime = dater3;
    leg1202.realEndTime = dater4;
    leg1202.timeDiffInMins = @"3";
    leg1202.duration = [NSNumber numberWithInt:900000];
    leg1202.itinerary = itin120;
    
    itin120.plan = plan12;
    
    
    
    leg1203 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    leg1203.agencyId = @"caltrain-ca-us";
    leg1203.agencyName = @"Caltrain";
    leg1203.mode = @"RAIL";
    leg1203.route = @"Local";
    leg1203.routeLongName = @"Bullet";
    leg1203.routeId = @"ct_bullet_20121001";
    leg1203.tripId = @"197_20121001";
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
    leg1203.from = pp119;
    leg1203.to = pp1110;
    leg1203.startTime = date5;
    leg1203.endTime = date6;
    leg1202.realStartTime = dater5;
    leg1202.realEndTime = dater6;
    leg1202.timeDiffInMins = @"2";
    leg1203.mode = @"Caltrain";
    leg1203.duration = [NSNumber numberWithInt:300000];
    leg1203.itinerary = itin120;
    itin120.plan = plan12;
    
    //    leg1203= [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    //    leg1203.mode = @"WALK";
    //    PlanPlace *pp119 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    //    PlanPlace *pp120 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
    //    [pp101 setLat:[NSNumber numberWithDouble:37.75768017385226]];
    //    [pp101 setLng:[NSNumber numberWithDouble:-122.3926363695829]];
    //    [pp102 setLat:[NSNumber numberWithDouble:37.755414]];
    //    [pp102 setLng:[NSNumber numberWithDouble:-122.388001]];
    //    [pp102 setStopId:@"7354"];
    //    [pp101 setName:@"22nd Street"];
    //    [pp102 setName:@"Third Street & 23rd St"];
    //    leg1203.from = pp119;
    //    leg1203.to = pp120;
    //    leg1203.startTime = date5;
    //    leg1203.endTime = date6;
    //    leg1203.duration = [NSNumber numberWithInt:300000];
    //    leg1203.itinerary = itin120;
    
    saveContext(managedObjectContext);
    
    // [gtfsParser requestAgencyDataFromServer];
    //[self someMethodToWaitForResult];
    //[gtfsParser generateGtfsTripsRequestStringUsingPlan:plan12];
    //[self someMethodToWaitForResult];
    
    for(int i=0;i<[[plan12 sortedItineraries] count];i++){
        Itinerary *iti = [[plan12 sortedItineraries] objectAtIndex:i];
        Leg * legs = [iti adjustLegsIfRequired];
        // Leg adjustment is not possible and we need to create new leg from this leg and realtime.
        STAssertNotNil(legs,@"");
    }
}

@end
