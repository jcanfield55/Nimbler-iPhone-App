//
//  Network_CommutingTests.m
//  Network CommutingTests
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Network_CommutingTests.h"

@implementation Network_CommutingTests

- (void)setUp
{
    [super setUp];
    
    // Set-up test Core Data using an in-memory PSC
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    STAssertNotNil(managedObjectModel, @"Cannot create managedObjectModel instance");
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];  
    STAssertNotNil(psc, @"Cannot create PersistentStoreCoordinator instance");

    NSError *error = nil;
    [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    STAssertNotNil(psc, @"Data store open failed for reason: %@", [error localizedDescription]);
    
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    STAssertNotNil(managedObjectContext, @"Cannot create managedObjectContexrt instance");

    [managedObjectContext setPersistentStoreCoordinator:psc];
    [managedObjectContext setUndoManager:nil];
    
    // Set up KeyObjectStore
    [KeyObjectStore setUpWithManagedObjectContext:managedObjectContext];
    
    // Set up Locations wrapper object pointing at the test Managed Object Context
    locations = [[Locations alloc] initWithManagedObjectContext:managedObjectContext rkGeoMgr:nil];
    
    // Set up individual Location objects
    // loc1 is used for testing most methods including isMatchingTypedString and has Address Components included
    loc1 = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
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

    [loc1 setFormattedAddress:@"750 Hawthorne Street, San Francisco, CA 94103, USA"];
    [loc1 setAddressComponents:[NSSet setWithObjects:ac1,ac2,ac3,ac4,ac5,ac6,ac7,nil]];
    
    [loc1 addRawAddressString:@"750 Hawthorne St., SF"];
    [loc1 addRawAddressString:@"750 Hawthorn, San Fran California"];

    [loc1 setApiTypeEnum:GOOGLE_GEOCODER];
    [loc1 setFromFrequencyFloat:5.0];
    [loc1 setToFrequencyFloat:7.0];
    [loc1 setLatFloat:67.3];
    [loc1 setLngFloat:-122.3];

    //
    // Set up plans, itineraries, and legs for testing plan caching
    //
    
    // Set-up dates
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSDate* date10 = [dateFormatter dateFromString:@"June 8, 2012 11:59 PM"]; // Friday before last load
    NSDate* date20 = [dateFormatter dateFromString:@"August 5, 2012 7:00 PM"]; // Sunday
    NSDate* date30req = [dateFormatter dateFromString:@"August 17, 2012 7:45 AM"]; // Friday
    NSDate* date30 = [dateFormatter dateFromString:@"August 17, 2012 8:00 AM"]; // Friday
    NSDate* date31 = [dateFormatter dateFromString:@"August 17, 2012 8:30 AM"]; // Friday
    NSDate* date32 = [dateFormatter dateFromString:@"August 17, 2012 9:00 AM"]; // Friday
    NSDate* date40req = [dateFormatter dateFromString:@"August 18, 2012 8:40 AM"]; // Saturday
    NSDate* date40 = [dateFormatter dateFromString:@"August 18, 2012 9:20 AM"]; // Saturday
    NSDate* date41 = [dateFormatter dateFromString:@"August 18, 2012 10:20 AM"]; // Saturday
    NSDate* date50req = [dateFormatter dateFromString:@"August 20, 2012 12:01 AM"]; // Monday
    NSDate* date50 = [dateFormatter dateFromString:@"August 20, 2012 7:00 AM"]; // Monday
    NSDate* date51 = [dateFormatter dateFromString:@"August 20, 2012 7:30 AM"]; // Monday
    NSDate* date52 = [dateFormatter dateFromString:@"August 20, 2012 8:00 AM"]; // Monday
    NSDate* date60req = [dateFormatter dateFromString:@"August 22, 2012 11:00 AM"]; // Wednesday
    NSDate* date60 = [dateFormatter dateFromString:@"August 22, 2012 9:00 AM"]; // Wednesday
    NSDate* date61 = [dateFormatter dateFromString:@"August 22, 2012 9:30 AM"]; // Wednesday
    NSDate* date62 = [dateFormatter dateFromString:@"August 22, 2012 10:00 AM"]; // Wednesday
    NSDate* date70 = [dateFormatter dateFromString:@"September 3, 2012 6:00 AM"]; // Monday Labor Day

    // Legs
    Leg *leg10 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg20 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg30 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg31 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg32 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg40 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg41 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg50 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg51 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg52 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg60 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg61 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg62 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg70 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg80 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg90 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    
    // Itineraries
    itin10 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin20 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin30 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin31 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin32 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin40 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin41 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin50 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin51 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin52 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin60 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin61 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin62 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];

    
    // Plan
    plan3 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan4 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan5 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan6 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];


    // Agency IDs
    NSString* caltrain = @"caltrain-ca-us";
    NSString* Bart = @"BART";
    NSString* ACTransit = @"AC Transit";
    
    // Plan3 -- 3 itineraries starting at 8:00am (7:45 request) on Friday August 17
    leg30.startTime = date30;
    leg30.agencyId = caltrain;
    leg30.itinerary = itin30;
    itin30.startTime = date30;
    itin30.plan = plan3;
    
    leg31.startTime = date31;
    leg31.agencyId = caltrain;
    leg31.itinerary = itin31;
    itin31.startTime = date31;
    itin31.plan = plan3;
    
    leg32.startTime = date32;
    leg32.agencyId = caltrain;
    leg32.itinerary = itin32;
    itin32.startTime = date32;
    itin32.plan = plan3;
    
    [plan3 createRequestChunkWithAllItinerariesAndRequestDate:date30req departOrArrive:DEPART];
    
    // Plan5 -- 3 itineraries starting at 7:00am (12:01 request) on Monday August 20
    leg50.startTime = date50;
    leg50.agencyId = caltrain;
    leg50.itinerary = itin50;
    itin50.startTime = date50;
    itin50.plan = plan5;
    
    leg51.startTime = date51;
    leg51.agencyId = caltrain;
    leg51.itinerary = itin51;
    itin51.startTime = date51;
    itin51.plan = plan5;
    
    leg52.startTime = date52;
    leg52.agencyId = caltrain;
    leg52.itinerary = itin52;
    itin52.startTime = date52;
    itin52.plan = plan5;

    [plan5 createRequestChunkWithAllItinerariesAndRequestDate:date50req departOrArrive:DEPART];

    // Plan4 -- itineraries starting at 8:40am request on Saturday, August 18
    leg40.startTime = date40;
    leg40.agencyId = caltrain;
    leg40.itinerary = itin40;
    itin40.startTime = date40;
    itin40.plan = plan4;
    
    leg41.startTime = date41;
    leg41.agencyId = caltrain;
    leg41.itinerary = itin41;
    itin41.startTime = date41;
    itin41.plan = plan4;
    
    [plan4 createRequestChunkWithAllItinerariesAndRequestDate:date40req departOrArrive:DEPART];
    
    // Plan6 -- 3 itineraries starting at 9:00am for an 11:00am arrive time request on Wednesday August 22
    leg60.startTime = date60;
    leg60.agencyId = caltrain;
    leg60.itinerary = itin60;
    itin60.startTime = date60;
    itin60.plan = plan6;
    
    leg61.startTime = date61;
    leg61.agencyId = caltrain;
    leg61.itinerary = itin61;
    itin61.startTime = date61;
    itin61.plan = plan6;
    
    leg62.startTime = date62;
    leg62.agencyId = caltrain;
    leg62.itinerary = itin62;
    itin62.startTime = date62;
    itin62.plan = plan6;
    
    [plan6 createRequestChunkWithAllItinerariesAndRequestDate:date60req departOrArrive:DEPART];
    
    // TODO make sure I have a walking leg in the mix

}

- (void)tearDown
{
    // Tear-down code here.
    
    // Set up database requests
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSError *error;

    // Fetch and delete all Location
    NSEntityDescription *e = [[managedObjectModel entitiesByName] objectForKey:@"Location"];
    [fetchRequest setEntity:e];
    NSArray *allFromLocations = [managedObjectContext executeFetchRequest:fetchRequest
                                                              error:&error];
    for (Location *loc in allFromLocations) {
        [managedObjectContext deleteObject:loc];
    }

    // Fetch and delete all Itineraries
    [fetchRequest setEntity:[[managedObjectModel entitiesByName] objectForKey:@"Itinerary"]];
    NSArray *allObjects = [managedObjectContext executeFetchRequest:fetchRequest
                                                                    error:&error];
    for (Itinerary *obj in allObjects) {
        [managedObjectContext deleteObject:obj];
    }
    
    // Fetch and delete all Legs
    [fetchRequest setEntity:[[managedObjectModel entitiesByName] objectForKey:@"Leg"]];
    allObjects = [managedObjectContext executeFetchRequest:fetchRequest
                                                              error:&error];
    for (Leg *obj in allObjects) {
        [managedObjectContext deleteObject:obj];
    }
    
    // Fetch and delete all Plans
    [fetchRequest setEntity:[[managedObjectModel entitiesByName] objectForKey:@"Plan"]];
    allObjects = [managedObjectContext executeFetchRequest:fetchRequest
                                                     error:&error];
    for (Plan *obj in allObjects) {
        [managedObjectContext deleteObject:obj];
    }
    
    // Fetch and delete all PlanRequestChunks
    [fetchRequest setEntity:[[managedObjectModel entitiesByName] objectForKey:@"PlanRequestChunk"]];
    allObjects = [managedObjectContext executeFetchRequest:fetchRequest
                                                     error:&error];
    for (PlanRequestChunk *obj in allObjects) {
        [managedObjectContext deleteObject:obj];
    }
    
    
    [super tearDown];
}

- (void)testLocations
{
    // Additional set-up
    // loc2 and loc 3 give additional testing for formatted address and raw address retrieval
    // It has some (number, city, state) but not all the address components from loc1
    loc2 = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
    [loc2 setFormattedAddress:@"750 Hawthorne Street, San Francisco"];
    [loc2 addRawAddressString:@"750 Hawthorne, San Fran California"];
    [loc2 addRawAddressString:@"750 Hawthoorn, SF"];
    [loc2 setFromFrequencyFloat:7];  // greater than loc1
    
    loc3 = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
    [loc3 setFormattedAddress:@"1350 Hull Drive, San Carlos, CA USA"];
    [loc3 addRawAddressString:@"1350 Hull, San Carlos CA"];
    [loc3 addRawAddressString:@"1350 Hull Dr. San Carlos CA"];


    // Test numberOfLocations
    STAssertEquals([locations numberOfLocations:YES], 2, @"");  // 2 Locations with fromFrequency>0
    STAssertEquals([locations numberOfLocations:NO], 1, @"");  // 1 Location with toFrequency>0
    
    // Test locationAtIndex
    STAssertEquals([locations locationAtIndex:0 isFrom:YES], loc2, @"");
    STAssertEquals([locations locationAtIndex:1 isFrom:YES], loc1, @"");
    STAssertEquals([locations locationAtIndex:2 isFrom:YES], loc3, @"");
    STAssertEquals([locations locationAtIndex:0 isFrom:NO], loc1, @"");
    STAssertEquals([locations locationAtIndex:1 isFrom:NO], loc3, @""); // loc3 & loc2 have same toFrequency, but loc3 was created more recently
    STAssertEquals([locations locationAtIndex:2 isFrom:NO], loc2, @"");

    // Test adding a new Location
    Location *loc4tl = [locations newEmptyLocation];
    STAssertNotNil(loc4tl, @""); 
    STAssertNil([loc4tl formattedAddress], @"");
    [loc4tl incrementToFrequency];
    
    // Test numberOfLocations and locationAtIndex after adding loc4tl
    STAssertEquals([locations numberOfLocations:YES], 3, @"");  // 3 Locations with fromFrequency>0
    STAssertEquals([locations numberOfLocations:NO], 2, @"");  // 2 Location with toFrequency>0    
    STAssertEquals([locations locationAtIndex:0 isFrom:YES], loc2, @"");
    STAssertEquals([locations locationAtIndex:1 isFrom:YES], loc1, @"");
    STAssertEquals([locations locationAtIndex:2 isFrom:YES], loc4tl, @"");
    STAssertEquals([locations locationAtIndex:3 isFrom:YES], loc3, @"");
    STAssertEquals([locations locationAtIndex:0 isFrom:NO], loc1, @"");
    STAssertEquals([locations locationAtIndex:1 isFrom:NO], loc4tl, @"");
    STAssertEquals([locations locationAtIndex:2 isFrom:NO], loc3, @"");
    
    // Test response to setTypedFromString
    [locations setTypedFromString:@"750"];
    STAssertEquals([locations numberOfLocations:YES], 2, @"");  // 2 locations with address component with 750
    STAssertEquals([locations locationAtIndex:0 isFrom:YES], loc2, @"");
    STAssertEquals([locations locationAtIndex:1 isFrom:YES], loc1, @"");
    // Make sure no impact on To locations
    STAssertEquals([locations numberOfLocations:NO], 2, @"");  // 2 locations with address component with 750
    STAssertEquals([locations locationAtIndex:0 isFrom:NO], loc1, @"");
    STAssertEquals([locations locationAtIndex:1 isFrom:NO], loc4tl, @"");
    STAssertEquals([locations locationAtIndex:2 isFrom:NO], loc3, @"");
    
    // Test response to setTypedToString
    [locations setTypedToString:@"Hawthorne"];
    STAssertEquals([locations numberOfLocations:NO], 1, @"");   
    STAssertEquals([locations locationAtIndex:0 isFrom:NO], loc1, @"");
    [locations setTypedToString:@"1350 Hull"];  
    STAssertEquals([locations numberOfLocations:NO], 1, @"");  // This is a simple prefix match off of the formatted address.  Note this appears even tho frequency=0.  
    STAssertEquals([locations locationAtIndex:0 isFrom:NO], loc3, @"");
    
    // Test that a full formatted address will match
    [locations setTypedToString:@"750 Hawthorne Street, San Francisco, CA 94103, USA"];
    STAssertEquals([locations numberOfLocations:NO], 1, @"");   
    STAssertEquals([locations locationAtIndex:0 isFrom:NO], loc1, @"");  
    
    // Test with a full formatted address except for different case
    [locations setTypedToString:@"1350 hull Drive, San Carlos, CA USA"];
    STAssertEquals([locations numberOfLocations:NO], 1, @"");   
    STAssertEquals([locations locationAtIndex:0 isFrom:NO], loc3, @"");
    
    // Delete object and retest that the number of Locations goes back correct
    [managedObjectContext deleteObject:loc4tl];
    [locations setTypedFromString:@""];
    [locations setTypedToString:@""];
    STAssertEquals([locations numberOfLocations:YES], 2, @"");  // 2 Locations with fromFrequency>0
    STAssertEquals([locations numberOfLocations:NO], 1, @"");  // 1 Location with toFrequency>0
    STAssertEquals([locations locationAtIndex:0 isFrom:YES], loc2, @"");
    STAssertEquals([locations locationAtIndex:1 isFrom:YES], loc1, @"");
    STAssertEquals([locations locationAtIndex:2 isFrom:YES], loc3, @"");
    STAssertEquals([locations locationAtIndex:0 isFrom:NO], loc1, @"");
    STAssertEquals([locations locationAtIndex:1 isFrom:NO], loc3, @"");
    STAssertEquals([locations locationAtIndex:2 isFrom:NO], loc2, @"");
    
    // locationsWithFormattedAddress
    STAssertEquals([[locations locationsWithFormattedAddress:@"750 Hawthorne Street, San Francisco"] objectAtIndex:0], loc2, @"");
    STAssertEquals([[locations locationsWithFormattedAddress:@"750 Hawthorne Street, San Francisco, CA 94103, USA"] objectAtIndex:0], loc1, @"");
    STAssertTrue([[locations locationsWithFormattedAddress:@"No matching location"] count]==0, @"");
    STAssertNil([locations locationsWithFormattedAddress:nil], @"");

    
    // locationWithRawAddress
    STAssertEquals([locations locationWithRawAddress:@"750 Hawthorne St., SF"], loc1, @"");
    STAssertEquals([locations locationWithRawAddress:@"750 Hawthorn, San Fran California"], loc1, @"");
    STAssertNil([locations locationWithRawAddress:@""], @"");
    STAssertNil([locations locationWithRawAddress:nil], @"");

    // consolidateWithMatchingLocations testing
    // Set up a new location object that will be consolidated
    Location *loc5tl = [locations newEmptyLocation];
    [loc5tl setToFrequencyFloat:1.0];
    [loc5tl setFromFrequencyFloat:1.0];
    [loc5tl setFormattedAddress:@"750 Hawthorne Street, San Francisco"];  // the same as loc2
    [loc5tl addRawAddressString:@"extra addr 1"];
    [loc5tl addRawAddressString:@"extra addr 2"];
    
    STAssertEquals([locations consolidateWithMatchingLocations:loc5tl
                    keepThisLocation:false], loc2, @""); // found a match in loc2
    STAssertTrue([loc5tl isDeleted], @"");
    STAssertEquals([loc2 fromFrequencyFloat], 8.0, @"");  // Added loc5tl frequency to loc2's frequency
    STAssertEquals([loc2 toFrequencyFloat], 1.0, @"");  // Added loc5tl frequency to loc2's frequency
    STAssertEquals([locations locationWithRawAddress:@"extra addr 1"], loc2, @"");
    STAssertEquals([locations locationWithRawAddress:@"extra addr 2"], loc2, @"");
    
    STAssertEquals([locations consolidateWithMatchingLocations:loc1
                    keepThisLocation:true], loc1, @""); // no matches, returns loc1
    STAssertFalse([loc1 isDeleted], @"");

    // Tear down extra locations
    [managedObjectContext deleteObject:loc2];
    [managedObjectContext deleteObject:loc3];


}

- (void)testLocation
{
    // Test isMatchingTypedString
    STAssertTrue([loc1 isMatchingTypedString:@""],@"");  // everything matches empty string
    STAssertTrue([loc1 isMatchingTypedString:nil],@"");  // everything matches nil string
    STAssertTrue([loc1 isMatchingTypedString:@"H"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"h"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"t"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"ha"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"Franci"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"ncisc"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"7"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"750"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"75 treet"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"7 San"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"750  Hawthorne St., San Fran"],@"");
    STAssertTrue([loc1 isMatchingTypedString:@"75 Hawthorne CA"],@""); 


    STAssertFalse([loc1 isMatchingTypedString:@"Hu"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"Hull"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"5"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"Ca"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"75 Huwthorne"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"USA"],@"");

    // Test scalar setters and accessors
    STAssertEquals([loc1 apiTypeEnum], GOOGLE_GEOCODER, @"");
    STAssertEquals([loc1 fromFrequencyFloat], 5.0, @"");
    STAssertEquals([loc1 toFrequencyFloat], 7.0, @"");
    STAssertEquals([loc1 latFloat], 67.3, @"");
    STAssertEquals([loc1 lngFloat], -122.3, @"");
    
    // Test shortFormattedAddress
    STAssertTrue([[loc1 shortFormattedAddress] isEqualToString:@"750 Hawthorne Street, San Francisco"], @"");
    
    // Clean-up
    
}

- (void)testUtilities
{
    // durationString tests
    STAssertTrue([durationString(60.0*1000.0) isEqualToString:@"1 minute"], @"");
    STAssertTrue([durationString(59.0*1000.0) isEqualToString:@"less than 1 minute"], @"");
    STAssertTrue([durationString(91.0*1000.0) isEqualToString:@"2 minutes"], @"");
    STAssertTrue([durationString(59.4*60.0*1000.0) isEqualToString:@"59 minutes"], @"");
    STAssertTrue([durationString(59.6*60.0*1000.0) isEqualToString:@"60 minutes"], @"");
    STAssertTrue([durationString(60.0 * 60.0*1000.0) isEqualToString:@"1 hour"], @"");
    STAssertTrue([durationString(1.5 * 60.0 * 60.0*1000.0) isEqualToString:@"1 hour, 30 minutes"], @"");

    STAssertTrue([durationString(23.0 * 60.0*60.0*1000.0) isEqualToString:@"23 hours"], @"");
    STAssertTrue([durationString(23.0 * 60.0*60.0*1000.0 + 90*1000) isEqualToString:@"23 hours, 2 minutes"], @"");
    STAssertTrue([durationString(24.0 * 60.0*60.0*1000.0) isEqualToString:@"1 day"], @"");
    STAssertTrue([durationString(100.0 *24.0 * 60.0*60.0*1000.0) isEqualToString:@"100 days"], @"");
    STAssertTrue([durationString(48.0 *24.0 * 60.0*60.0*1000.0 + 91.0 * 1000.0) isEqualToString:@"48 days, 2 minutes"], @"");
    NSLog(@"Test = %@", durationString(32.0 *24.0 * 60.0*60.0*1000.0 + 60.0* 60.0 * 1000.0));
    STAssertTrue([durationString(32.0 *24.0 * 60.0*60.0*1000.0 + 60.0* 60.0 * 1000.0) isEqualToString:@"32 days, 1 hour"], @"");
    STAssertTrue([durationString(2.0 *24.0 * 60.0*60.0*1000.0 + 15*60.0*60.0*1000.0 + 60.0*1000.0) isEqualToString:@"2 days, 15 hours, 1 minute"], @"");
    
    // distanceStringInMilesFeet tests
    NSLog(@"Test = %@", distanceStringInMilesFeet(3000.0));

    STAssertTrue([distanceStringInMilesFeet(3000.0) isEqualToString:@"1.9 miles"], @"");
    STAssertTrue([distanceStringInMilesFeet(100.0) isEqualToString:@"328 feet"], @"");
    STAssertTrue([distanceStringInMilesFeet(0.0) isEqualToString:@"less than 1 foot"], @"");
    
    // Calendar functions
    //
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSDate* dayTime1 = [dateFormatter dateFromString:@"August 22, 2012 5:00 PM"]; // Wednesday
    NSDate* dayTime2 = [dateFormatter dateFromString:@"August 5, 2012 7:00 PM"]; // Sunday
    NSDate* dayTime3 = [dateFormatter dateFromString:@"September 1, 2012 6:00 AM"]; // Saturday
    NSDate* dayTime4 = [dateFormatter dateFromString:@"September 1, 2012 11:59 PM"];
    NSDate* dayTime5 = [dateFormatter dateFromString:@"August 5, 2012 11:59 PM"];
    
    // dayOfWeekFromDate
    STAssertEquals(dayOfWeekFromDate(dayTime1), 4, @"");
    STAssertEquals(dayOfWeekFromDate(dayTime2), 1, @"");
    STAssertEquals(dayOfWeekFromDate(dayTime3), 7, @"");
    
    // timeOnlyFromDate
    NSLog(@"Time only of dayTime3 = %@", timeOnlyFromDate(dayTime3));
    STAssertEquals([dayTime1 laterDate:dayTime2], dayTime1, @""); // Full date compare
    STAssertTrue([[timeOnlyFromDate(dayTime1) laterDate:timeOnlyFromDate(dayTime2)] isEqualToDate:
                  timeOnlyFromDate(dayTime2)],@""); // Hours compare
    STAssertTrue([[timeOnlyFromDate(dayTime1) laterDate:timeOnlyFromDate(dayTime3)] isEqualToDate:
                  timeOnlyFromDate(dayTime1)],@""); // Hours compare
    
    // dateOnlyFromDate
    STAssertTrue([dateOnlyFromDate(dayTime3) isEqualToDate:dateOnlyFromDate(dayTime4)], @"");
    STAssertFalse([dateOnlyFromDate(dayTime2) isEqualToDate:dateOnlyFromDate(dayTime4)], @"");

    //
    STAssertTrue([addDateOnlyWithTimeOnly(dayTime2, dayTime4) isEqualToDate:dayTime5], @"");
}

- (void)testKeyObjectStore
{
    // Simple store and retrieve before saving changes to permanent store
    NSArray* testArray1 = [NSArray arrayWithObjects:@"Item1", @"Item2", @"Item3", nil];
    KeyObjectStore* store = [KeyObjectStore keyObjectStore];
    [store setObject:testArray1 forKey:@"testKey1"];
    NSArray* result1 = [store objectForKey:@"testKey1"];
    STAssertTrue([[result1 objectAtIndex:1] isEqualToString:@"Item2"], @"");
    
    // Now save context and save an additional Dictionary
    saveContext(managedObjectContext);
    NSDictionary* testDictionary2 = [NSDictionary dictionaryWithKeysAndObjects:
                           @"Key1", @"Object1",
                           @"Key2", @"Object2", nil];
    [store setObject:testDictionary2 forKey:@"testKey2"];
    saveContext(managedObjectContext);
    NSDictionary* result2 = [store objectForKey:@"testKey2"];
    STAssertTrue([[result2 objectForKey:@"Key2"] isEqualToString:@"Object2"], @"");
    
    // Now replace the first object with the second
    [store setObject:testDictionary2 forKey:@"testKey1"];
    saveContext(managedObjectContext);
    NSDictionary* result3 = [store objectForKey:@"testKey1"];
    STAssertTrue([[result3 objectForKey:@"Key1"] isEqualToString:@"Object1"], @"");
    
    // Clean-up
    [store removeKeyObjectForKey:@"testKey1"];
    STAssertNil([store objectForKey:@"testKey1"], @"");
    [store removeKeyObjectForKey:@"testKey2"];
}

- (void)testTransitCalendar
{
    // Set-up object
    TransitCalendar* transitCalendar = [[TransitCalendar alloc] init];
    
    // Set-up dates
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSDate* dayTime1 = [dateFormatter dateFromString:@"August 22, 2012 5:00 PM"]; // Wednesday
    NSDate* dayTime2 = [dateFormatter dateFromString:@"August 5, 2012 7:00 PM"]; // Sunday
    NSDate* dayTime3 = [dateFormatter dateFromString:@"September 3, 2012 6:00 AM"]; // Monday Labor Day
    NSDate* dayTime4 = [dateFormatter dateFromString:@"June 8, 2012 11:59 PM"]; // Friday before last load
    NSDate* dayTime5 = [dateFormatter dateFromString:@"August 20, 2012 12:01 AM"]; // Monday
    NSDate* dayTime6 = [dateFormatter dateFromString:@"August 18, 2012 2:00 AM"]; // Saturday
    NSDate* dayTime7 = [dateFormatter dateFromString:@"August 17, 2012 8:00 AM"]; // Friday


    // isCurrentVsGtfsFileFor:(NSDate *)date agencyId:(NSString *)agencyId
    STAssertTrue([transitCalendar isCurrentVsGtfsFileFor:dayTime1 agencyId:@"caltrain-ca-us"], @"");
    STAssertFalse([transitCalendar isCurrentVsGtfsFileFor:dayTime4 agencyId:@"caltrain-ca-us"], @"");
    STAssertFalse([transitCalendar isCurrentVsGtfsFileFor:dayTime4 agencyId:@"No such agency - Blah"], @"");


    // isEquivalentServiceDayFor
    STAssertTrue([transitCalendar isEquivalentServiceDayFor:dayTime1 And:dayTime5 agencyId:@"BART"], @"");
    STAssertFalse([transitCalendar isEquivalentServiceDayFor:dayTime1 And:dayTime5 agencyId:@"No such agency - Blah"], @"");
    STAssertFalse([transitCalendar isEquivalentServiceDayFor:dayTime1 And:dayTime3 agencyId:@"BART"], @"");
    STAssertFalse([transitCalendar isEquivalentServiceDayFor:dayTime1 And:dayTime2 agencyId:@"BART"], @"");
    STAssertFalse([transitCalendar isEquivalentServiceDayFor:dayTime2 And:dayTime5 agencyId:@"BART"], @"");
    STAssertTrue([transitCalendar isEquivalentServiceDayFor:dayTime3 And:dayTime2 agencyId:@"BART"], @"");
    STAssertFalse([transitCalendar isEquivalentServiceDayFor:dayTime5 And:dayTime6 agencyId:@"BART"], @"");
    STAssertTrue([transitCalendar isEquivalentServiceDayFor:dayTime1 And:dayTime7 agencyId:@"BART"], @"");
    STAssertFalse([transitCalendar isEquivalentServiceDayFor:dayTime2 And:dayTime6 agencyId:@"BART"], @"");
}

- (void)testPlanRequestChunk
{
    // Make sure I have the right PlanRequestChunks
    STAssertTrue(([[itin30 planRequestChunks] count]==1), @"");
    PlanRequestChunk* chunk3 = [[itin30 planRequestChunks] anyObject];
    STAssertTrue(([[itin40 planRequestChunks] count]==1), @"");
    PlanRequestChunk* chunk4 = [[itin40 planRequestChunks] anyObject];
    STAssertTrue(([[itin50 planRequestChunks] count]==1), @"");
    PlanRequestChunk* chunk5 = [[itin50 planRequestChunks] anyObject];
    STAssertTrue(([[itin60 planRequestChunks] count]==1), @"");
    PlanRequestChunk* chunk6 = [[itin60 planRequestChunks] anyObject];
    
    // chunk3 and chunk5 occur on different days but same service and overlapping times
    STAssertTrue([chunk3 doTimesOverlapRequestChunk:chunk5], @"");
    STAssertTrue([chunk5 doTimesOverlapRequestChunk:chunk3], @"");
    STAssertTrue([chunk3 doAllServiceStringByAgencyMatchRequestChunk:chunk5], @"");
    STAssertTrue([chunk5 doAllServiceStringByAgencyMatchRequestChunk:chunk3], @"");
    // Consolidate chunks
    [chunk3 consolidateIntoSelfRequestChunk:chunk5];
    STAssertEqualObjects([chunk3 earliestRequestedDepartTimeDate], [chunk5 earliestRequestedDepartTimeDate], @"");
    STAssertTrue(([[chunk3 sortedItineraries] count]==6), @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:0], itin50, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:1], itin51, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:4], itin31, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:5], itin32, @"");

    // chunk 3 and chunk4 occur on different service days but overlapping times
    STAssertTrue([chunk3 doTimesOverlapRequestChunk:chunk4], @"");
    STAssertTrue([chunk4 doTimesOverlapRequestChunk:chunk3], @"");
    STAssertFalse([chunk3 doAllServiceStringByAgencyMatchRequestChunk:chunk4], @"");
    STAssertFalse([chunk4 doAllServiceStringByAgencyMatchRequestChunk:chunk3], @"");
    
    // chunk6 is an arrive-time request that occurs on the same service and overlapping time with Chunk3
    STAssertTrue([chunk3 doTimesOverlapRequestChunk:chunk6], @"");
    STAssertTrue([chunk6 doTimesOverlapRequestChunk:chunk3], @"");
    STAssertTrue([chunk3 doAllServiceStringByAgencyMatchRequestChunk:chunk6], @"");
    STAssertTrue([chunk6 doAllServiceStringByAgencyMatchRequestChunk:chunk3], @"");
    // Consolidate chunks
    [chunk3 consolidateIntoSelfRequestChunk:chunk6];
    STAssertEqualObjects([chunk3 earliestRequestedDepartTimeDate], [chunk5 earliestRequestedDepartTimeDate], @"");
    STAssertEqualObjects([chunk3 latestRequestedArriveTimeDate], [chunk6 latestRequestedArriveTimeDate], @"");
    STAssertTrue(([[chunk3 sortedItineraries] count]==9), @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:0], itin50, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:1], itin51, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:4], itin31, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:7], itin61, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:8], itin62, @"");

}


- (void)testPlan
{
    // Set-up dates
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSDate* dayTime1 = [dateFormatter dateFromString:@"August 22, 2012 8:00 AM"]; // Wednesday

    // prepareSortedItinerariesWithMatchesForDate:
    // Request that exactly matches PlanRequestChunk from August 17
    [plan3 prepareSortedItinerariesWithMatchesForDate:dayTime1 departOrArrive:DEPART];
    STAssertEquals([[plan3 sortedItineraries] objectAtIndex:0], itin30, @"");
    STAssertEquals([[plan3 sortedItineraries] objectAtIndex:1], itin31, @"");
    STAssertEquals([[plan3 sortedItineraries] objectAtIndex:2], itin32, @"");

}
@end
