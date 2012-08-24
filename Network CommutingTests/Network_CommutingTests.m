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
    NSDate* date1 = [dateFormatter dateFromString:@"June 8, 2012 11:59 PM"]; // Friday before last load
    NSDate* date2 = [dateFormatter dateFromString:@"August 5, 2012 7:00 PM"]; // Sunday
    NSDate* date3 = [dateFormatter dateFromString:@"August 17, 2012 8:00 AM"]; // Friday
    NSDate* date4 = [dateFormatter dateFromString:@"August 18, 2012 2:00 AM"]; // Saturday
    NSDate* date5 = [dateFormatter dateFromString:@"August 20, 2012 12:01 AM"]; // Monday
    NSDate* date6 = [dateFormatter dateFromString:@"August 22, 2012 5:00 PM"]; // Wednesday
    NSDate* date7 = [dateFormatter dateFromString:@"September 3, 2012 6:00 AM"]; // Monday Labor Day

    // Legs
    Leg *leg1 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg2 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg3 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg4 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg5 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg6 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg7 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg8 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg9 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    
    // Itineraries
    Itinerary *itin1 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    Itinerary *itin2 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    Itinerary *itin3 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    Itinerary *itin4 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    Itinerary *itin5 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];

    // Plan Request Chunks
    PlanRequestChunk* chunk1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanRequestChunk" inManagedObjectContext:managedObjectContext];
    PlanRequestChunk* chunk2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanRequestChunk" inManagedObjectContext:managedObjectContext];
    PlanRequestChunk* chunk3 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanRequestChunk" inManagedObjectContext:managedObjectContext];
    
    
    // Plan
    Plan* plan1 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    [chunk1 setPlan:plan1];
    [chunk2 setPlan:plan1];
    [chunk3 setPlan:plan1];
    
    // TODO make sure I have a walking leg in the mix

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

- (void)testPlan
{
    
}
@end
