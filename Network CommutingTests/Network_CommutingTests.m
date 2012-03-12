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
    
    // Set up Locations wrapper object pointing at the test Managed Object Context
    locations = [[Locations alloc] initWithManagedObjectContext:managedObjectContext];
    
    // Set up individual Location objects
    // loc1 is used for testing most methods including isMatchingTypedString and has Address Components included
    loc1 = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac1 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac2 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac3 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac4 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    AddressComponent *ac5 = [NSEntityDescription insertNewObjectForEntityForName:@"AddressComponent" inManagedObjectContext:managedObjectContext];
    [ac1 setLongName:@"750"];
    [ac2 setLongName:@"Hawthorne Street"];
    [ac3 setLongName:@"San Francisco"];
    [ac4 setLongName:@"San Francisco"];
    [ac5 setLongName:@"California"];
    [ac1 setTypes:[NSArray arrayWithObjects:@"street_number", nil]];
    [ac2 setTypes:[NSArray arrayWithObjects:@"route", nil]];
    [ac3 setTypes:[NSArray arrayWithObjects:@"locality", @"political", nil]];
    [ac4 setTypes:[NSArray arrayWithObjects:@"political", @"locality", nil]];  // try reverse order
    [ac5 setTypes:[NSArray arrayWithObjects:@"administrative_area_level_1", @"political", nil]];
    
    [loc1 setFormattedAddress:@"750 Hawthorne Street, San Francisco, CA"];
    [loc1 setAddressComponents:[NSSet setWithObjects:ac1,ac2,ac3,ac4,ac5,nil]];
    
    [loc1 addRawAddressString:@"750 Hawthorne St., SF"];
    [loc1 addRawAddressString:@"750 Hawthorn, San Fran California"];

    [loc1 setApiTypeEnum:GOOGLE_GEOCODER];
    [loc1 setFromFrequencyInt:5];
    [loc1 setToFrequencyInt:7];
    [loc1 setLatFloat:67.3];
    [loc1 setLngFloat:-122.3];
    
}

- (void)tearDown
{
    // Tear-down code here.
    
    // Search for all Locations objects and delete them
    NSFetchRequest *locationsFetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *e = [[managedObjectModel entitiesByName] objectForKey:@"Location"];
    [locationsFetchRequest setEntity:e];


    // Fetch the sortedFromLocations array
    NSError *error;
    NSArray *allFromLocations = [managedObjectContext executeFetchRequest:locationsFetchRequest
                                                              error:&error];
    for (Location *loc in allFromLocations) {
        [managedObjectContext deleteObject:loc];
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
    [loc2 setFromFrequencyInt:7];  // greater than loc1
    
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
    STAssertEquals([[locations locationsWithFormattedAddress:@"750 Hawthorne Street, San Francisco, CA"] objectAtIndex:0], loc1, @"");
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
    [loc5tl setToFrequencyInt:1];
    [loc5tl setFromFrequencyInt:1];
    [loc5tl setFormattedAddress:@"750 Hawthorne Street, San Francisco"];  // the same as loc2
    [loc5tl addRawAddressString:@"extra addr 1"];
    [loc5tl addRawAddressString:@"extra addr 2"];
    
    STAssertEquals([locations consolidateWithMatchingLocations:loc5tl], loc2, @""); // found a match in loc2
    STAssertTrue([loc5tl isDeleted], @"");
    STAssertEquals([loc2 fromFrequencyInt], 8, @"");  // Added loc5tl frequency to loc2's frequency
    STAssertEquals([loc2 toFrequencyInt], 1, @"");  // Added loc5tl frequency to loc2's frequency
    STAssertEquals([locations locationWithRawAddress:@"extra addr 1"], loc2, @"");
    STAssertEquals([locations locationWithRawAddress:@"extra addr 2"], loc2, @"");
    
    STAssertEquals([locations consolidateWithMatchingLocations:loc1], loc1, @""); // no matches, returns loc1
    STAssertFalse([loc1 isDeleted], @"");

    // Tear down extra locations
    [managedObjectContext deleteObject:loc2];
    [managedObjectContext deleteObject:loc3];


}

- (void)testLocation
{
    // Test isMatchingTypedString
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

    STAssertFalse([loc1 isMatchingTypedString:@"Hu"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"Hull"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"5"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"Ca"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"USA"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"75 Huwthorne"],@"");
    STAssertFalse([loc1 isMatchingTypedString:@"75 Hawthorne CA"],@""); // state not included in matches

    // Test scalar setters and accessors

    STAssertEquals([loc1 apiTypeEnum], GOOGLE_GEOCODER, @"");
    STAssertEquals([loc1 fromFrequencyInt], 5, @"");
    STAssertEquals([loc1 toFrequencyInt], 7, @"");
    STAssertEquals([loc1 latFloat], 67.3, @"");
    STAssertEquals([loc1 lngFloat], -122.3, @"");
    
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
}
@end
