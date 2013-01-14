//
//  Network_CommutingTests.m
//  Network CommutingTests
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Network_CommutingTests.h"
#import "LocationFromGoogle.h"
#import "LocationFromIOS.h"
#import "Constants.h"
#import "Logging.h"
#import "PlanRequestParameters.h"
#import "PlanStore.h"
#import "nc_AppDelegate.h"
#import "GtfsStopTimes.h"

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
   // RKObjectManager *rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:TRIP_PROCESS_URL];
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:psc];
    [managedObjectContext setUndoManager:nil];
    
    // Set up KeyObjectStore
    [KeyObjectStore setUpWithManagedObjectContext:managedObjectContext];
    
    // Set up PlanStore
    planStore = [[PlanStore alloc] initWithManagedObjectContext:managedObjectContext rkPlanMgr:nil];
    
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
    NSDate* date10req = [dateFormatter dateFromString:@"June 8, 2012 5:02 PM"]; // Friday before last load
    NSDate* date10 = [dateFormatter dateFromString:@"June 8, 2012 5:00 PM"]; // Friday before last load
    NSDate* date11 = [dateFormatter dateFromString:@"June 8, 2012 5:30 PM"]; // Friday before last load
    NSDate* date20 = [dateFormatter dateFromString:@"August 6, 2012 11:00 PM"]; // Monday
    NSDate* date30req = [dateFormatter dateFromString:@"August 17, 2012 7:45 AM"]; // Friday
    NSDate* date30 = [dateFormatter dateFromString:@"August 17, 2012 8:00 AM"]; // Friday
    NSDate* date31 = [dateFormatter dateFromString:@"August 17, 2012 8:30 AM"]; // Friday
    NSDate* date32 = [dateFormatter dateFromString:@"August 17, 2012 9:00 AM"]; // Friday
    NSDate* date40req = [dateFormatter dateFromString:@"August 18, 2012 8:40 AM"]; // Saturday
    NSDate* date40 = [dateFormatter dateFromString:@"August 18, 2012 9:20 AM"]; // Saturday
    NSDate* date41 = [dateFormatter dateFromString:@"August 18, 2012 10:20 AM"]; // Saturday
    NSDate* date50req = [dateFormatter dateFromString:@"August 20, 2012 1:00 AM"]; // Monday
    NSDate* date50 = [dateFormatter dateFromString:@"August 20, 2012 7:00 AM"]; // Monday
    NSDate* date51 = [dateFormatter dateFromString:@"August 20, 2012 7:30 AM"]; // Monday
    NSDate* date52 = [dateFormatter dateFromString:@"August 20, 2012 8:00 AM"]; // Monday
    date60req = [dateFormatter dateFromString:@"August 22, 2012 10:55 AM"]; // Wednesday
    NSDate* date60 = [dateFormatter dateFromString:@"August 22, 2012 9:00 AM"]; // Wednesday
    NSDate* date61a = [dateFormatter dateFromString:@"August 22, 2012 9:30 AM"]; // Wednesday
    NSDate* date61b = [dateFormatter dateFromString:@"August 22, 2012 9:35 AM"]; // Wednesday
    NSDate* date62 = [dateFormatter dateFromString:@"August 22, 2012 10:00 AM"]; // Wednesday
    NSDate* date70req = [dateFormatter dateFromString:@"August 27, 2012 9:40 AM"]; // Monday
    NSDate* date70 = [dateFormatter dateFromString:@"August 27, 2012 10:00 AM"]; // Monday
    NSDate* date71a = [dateFormatter dateFromString:@"August 27, 2012 10:20 AM"]; // Monday
    NSDate* date71b = [dateFormatter dateFromString:@"August 27, 2012 10:55 AM"]; // Monday
    NSDate* date71c = [dateFormatter dateFromString:@"August 27, 2012 10:30 AM"]; // Monday
    NSDate* date72a = [dateFormatter dateFromString:@"August 27, 2012 11:20 AM"]; // Monday
    NSDate* date72b = [dateFormatter dateFromString:@"August 27, 2012 11:55 AM"]; // Monday
    NSDate* date80req = [dateFormatter dateFromString:@"August 22, 2012 10:01 AM"]; // Wednesday
    NSDate* date80 = [dateFormatter dateFromString:@"August 22, 2012 10:30 AM"]; // Wednesday
    NSDate* date90req = [dateFormatter dateFromString:@"August 20, 2012 11:20 PM"]; // Monday before midnight
    NSDate* date90ArrReq = [dateFormatter dateFromString:@"August 21, 2012 1:15 AM"]; // Tuesday after midnight
    NSDate* date90 = [dateFormatter dateFromString:@"August 20, 2012 11:35 PM"]; // Monday before midnight
    NSDate* date91 = [dateFormatter dateFromString:@"August 21, 2012 12:35 AM"]; // Tuesday past midnight
    NSDate* date92 = [dateFormatter dateFromString:@"August 21, 2012 1:00 AM"]; // Tuesday past midnight
    
    // Legs
    Leg *leg10 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg11 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
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
    Leg *leg61a = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg61b = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg62 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg70 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg71a = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg71b = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg71c = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg72a = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg72b = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg80 = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg90dep = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg91dep = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg92dep = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg93dep = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg90arr = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];
    Leg *leg91arr = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:managedObjectContext];

    // Itineraries
    itin10 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin11 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
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
    itin70 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin71 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin72 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin80 = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin90dep = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin91dep = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin92dep = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin93dep = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin90arr = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];
    itin91arr = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:managedObjectContext];

    
    // Plan
    plan1 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan2 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan3 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan4 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan5 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan6 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan7 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan8 = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan9depart = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    plan9arrive = [NSEntityDescription insertNewObjectForEntityForName:@"Plan" inManagedObjectContext:managedObjectContext];
    
    // Agency IDs
    NSString* caltrain = @"caltrain-ca-us";
    NSString* Bart = @"BART";
    NSString* ACTransit = @"AC Transit";
    
    // Set up TransitCalendar datastructures in the KeyStore based on stub functions
    KeyObjectStore* store = [KeyObjectStore keyObjectStore];
    TransitCalendar* transitCalendar = [[TransitCalendar alloc] init];
    [transitCalendar getAgencyCalendarDataStub];
    // Stored Dictionaries In DB With Data from getAgencyCalendarDataStub
    [store setObject:transitCalendar.testServiceByWeekdayByAgency forKey:TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY];
    [store setObject:transitCalendar.testLastGTFSLoadDateByAgency forKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
    [store setObject:transitCalendar.testCalendarByDateByAgency forKey:TR_CALENDAR_BY_DATE_BY_AGENCY];
    
    // Plan1 -- 3 itineraries starting 
    leg10.startTime = date10;
    leg10.agencyId = caltrain;
    leg10.itinerary = itin10;
    itin10.startTime = date10;
    itin10.endTime = [itin10.startTime dateByAddingTimeInterval:(30.0*60)];
    itin10.plan = plan1;
    
    leg11.startTime = date11;
    leg11.agencyId = Bart;
    leg11.itinerary = itin11;
    itin11.startTime = date11;
    itin11.endTime = [itin11.startTime dateByAddingTimeInterval:(30.0*60)];
    itin11.plan = plan1;
    
    [plan1 createRequestChunkWithAllItinerariesAndRequestDate:date10req departOrArrive:DEPART];
    [plan1 setFromLocation:loc1];
    [plan1 setToLocation:loc2];
    for (Itinerary* itin in [plan1 itineraries]) {
        for (Leg* leg in [itin legs]) {
            leg.route = @"Caltrain";
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
            leg.endTime = [leg.startTime dateByAddingTimeInterval:(30.0*60)];
        }
    }
    
    // Plan2 -- single walking itinerary only
    leg20.startTime = date20;
    leg20.agencyId = nil;
    leg20.itinerary = itin20;
    leg20.mode = @"WALK";
    itin20.startTime = date20;
    itin20.endTime = [itin20.startTime dateByAddingTimeInterval:(60.0*60)];
    itin20.plan = plan2;
    
    [plan2 createRequestChunkWithAllItinerariesAndRequestDate:date20 departOrArrive:DEPART];
    [plan2 setFromLocation:loc1];
    [plan2 setToLocation:loc2];
    for (Itinerary* itin in [plan2 itineraries]) {
        for (Leg* leg in [itin legs]) {
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
            leg.endTime = [leg.startTime dateByAddingTimeInterval:(60.0*60)];
        }
    }
    
    
    // Plan3 -- 3 itineraries starting at 8:00am (7:45 request) until 9:00 on Friday August 17
    leg30.startTime = date30;
    leg30.agencyId = caltrain;
    leg30.itinerary = itin30;
    itin30.startTime = date30;
    itin30.endTime = [itin30.startTime dateByAddingTimeInterval:(30.0*60)];
    itin30.plan = plan3;
    
    leg31.startTime = date31;
    leg31.agencyId = Bart;
    leg31.itinerary = itin31;
    itin31.startTime = date31;
    itin31.endTime = [itin31.startTime dateByAddingTimeInterval:(30.0*60)];
    itin31.plan = plan3;
    
    leg32.startTime = date32;
    leg32.agencyId = caltrain;
    leg32.itinerary = itin32;
    itin32.startTime = date32;
    itin32.endTime = [itin32.startTime dateByAddingTimeInterval:(30.0*60)];
    itin32.plan = plan3;
    
    [plan3 createRequestChunkWithAllItinerariesAndRequestDate:date30req departOrArrive:DEPART];
    [plan3 setFromLocation:loc1];
    [plan3 setToLocation:loc2];
    for (Itinerary* itin in [plan3 itineraries]) {
        for (Leg* leg in [itin legs]) {
            leg.route = @"Caltrain";
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
            leg.endTime = [leg.startTime dateByAddingTimeInterval:(30.0*60)];
        }
    }
    
    // Plan4 -- itineraries starting at 8:40am request on Saturday, August 18
    leg40.startTime = date40;
    leg40.agencyId = caltrain;
    leg40.itinerary = itin40;
    itin40.startTime = date40;
    itin40.endTime = [itin40.startTime dateByAddingTimeInterval:(30.0*60)];
    itin40.plan = plan4;
    
    leg41.startTime = date41;
    leg41.agencyId = Bart;
    leg41.itinerary = itin41;
    itin41.startTime = date41;
    itin41.endTime = [itin41.startTime dateByAddingTimeInterval:(30.0*60)];
    itin41.plan = plan4;
    
    [plan4 createRequestChunkWithAllItinerariesAndRequestDate:date40req departOrArrive:DEPART];
    [plan4 setFromLocation:loc1];
    [plan4 setToLocation:loc2];
    for (Itinerary* itin in [plan4 itineraries]) {
        for (Leg* leg in [itin legs]) {
            leg.route = @"Caltrain";
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
            leg.endTime = [leg.startTime dateByAddingTimeInterval:(30.0*60)];
        }
    }

    // Plan5 -- 3 itineraries starting at 7:00am - 8:00am (12:01 request) on Monday August 20
    leg50.startTime = date50;
    leg50.agencyId = caltrain;
    leg50.itinerary = itin50;
    itin50.startTime = date50;
    itin50.endTime = [itin50.startTime dateByAddingTimeInterval:(30.0*60)];
    itin50.plan = plan5;
    
    leg51.startTime = date51;
    leg51.agencyId = Bart;
    leg51.itinerary = itin51;
    itin51.startTime = date51;
    itin51.endTime = [itin51.startTime dateByAddingTimeInterval:(30.0*60)];
    itin51.plan = plan5;
    
    leg52.startTime = date52;
    leg52.agencyId = caltrain;
    leg52.itinerary = itin52;
    itin52.startTime = date52;
    itin52.endTime = [itin52.startTime dateByAddingTimeInterval:(30.0*60)];
    itin52.plan = plan5;

    [plan5 createRequestChunkWithAllItinerariesAndRequestDate:date50req departOrArrive:DEPART];
    [plan5 setFromLocation:loc1];
    [plan5 setToLocation:loc2];
    for (Itinerary* itin in [plan5 itineraries]) {
        for (Leg* leg in [itin legs]) {
            leg.route = @"Caltrain";
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
            leg.endTime = [leg.startTime dateByAddingTimeInterval:(30.0*60)];
        }
    }

    // Plan6 -- 3 itineraries starting at 9:00am for an 11:00am arrive time request on Wednesday August 22
    leg60.startTime = date60;
    leg60.agencyId = caltrain;
    leg60.itinerary = itin60;
    itin60.startTime = date60;
    itin60.endTime = [itin60.startTime dateByAddingTimeInterval:(30.0*60)];
    itin60.plan = plan6;
    
    leg61a.startTime = date61a;
    leg61a.agencyId = nil;
    leg61a.itinerary = itin61;
    leg61b.startTime = date61b;
    leg61b.agencyId = Bart;
    leg61b.itinerary = itin61;
    itin61.startTime = date61a;
    itin61.endTime = [itin61.startTime dateByAddingTimeInterval:(30.0*60)];
    itin61.plan = plan6;
    
    leg62.startTime = date62;
    leg62.agencyId = caltrain;
    leg62.itinerary = itin62;
    itin62.startTime = date62;
    itin62.endTime = [itin62.startTime dateByAddingTimeInterval:(30.0*60)];
    itin62.plan = plan6;
    
    [plan6 createRequestChunkWithAllItinerariesAndRequestDate:date60req departOrArrive:ARRIVE];
    [plan6 setFromLocation:loc1];
    [plan6 setToLocation:loc2];
    for (Itinerary* itin in [plan6 itineraries]) {
        for (Leg* leg in [itin legs]) {
            if (leg == leg61a) {
                leg.route = nil;
                leg.endTime = [leg.startTime dateByAddingTimeInterval:(5.0*60)];
            } else if (leg == leg61b) {
                leg.route = @"Caltrain";
                leg.endTime = [leg.startTime dateByAddingTimeInterval:(25.0*60)];
            } else {
                leg.route = @"Caltrain";
                leg.endTime = [leg.startTime dateByAddingTimeInterval:(30.0*60)];
            }
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
        }
    }
    
    
    // Plan7 -- 3 itineraries starting at 10:00 for an 9:40am departure time request on Monday August 27
    // itin71 and itin72 have an AC Transit leg and a walking leg
    leg70.startTime = date70;
    leg70.agencyId = caltrain;
    leg70.itinerary = itin70;
    leg70.route = @"Caltrain";
    itin70.startTime = date70;
    itin70.endTime = [itin70.startTime dateByAddingTimeInterval:(30.0*60)];
    itin70.plan = plan7;
    
    leg71a.startTime = date71a;
    leg71a.agencyId = nil;
    leg71a.itinerary = itin71;
    leg71a.mode = @"WALK";
    leg71b.startTime = date71b;
    leg71b.agencyId = ACTransit;
    leg71b.itinerary = itin71;
    leg71b.mode = @"BUS";
    leg71b.route = @"M";
    leg71c.startTime = date71c;
    leg71c.agencyId = Bart;
    leg71c.itinerary = itin71;
    leg71c.mode = @"TRAIN";
    itin71.startTime = date71a;
    itin71.endTime = [itin71.startTime dateByAddingTimeInterval:(100.0*60)];
    itin71.plan = plan7;
    
    leg72a.startTime = date72a;
    leg72a.agencyId = nil;
    leg72a.itinerary = itin72;
    leg72a.mode = @"WALK";
    leg72b.startTime = date72b;
    leg72b.agencyId = ACTransit;
    leg72b.itinerary = itin72;
    leg72b.mode = @"BUS";
    leg72b.route = @"M";
    itin72.startTime = date72a;
    itin72.endTime = [itin72.startTime dateByAddingTimeInterval:(60.0*60)];
    itin72.plan = plan7;
    
    [plan7 createRequestChunkWithAllItinerariesAndRequestDate:date70req departOrArrive:DEPART];
    [plan7 setFromLocation:loc1];
    [plan7 setToLocation:loc2];
    for (Itinerary* itin in [plan7 itineraries]) {
        for (Leg* leg in [itin legs]) {
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
            leg.endTime = [leg.startTime dateByAddingTimeInterval:(30.0*60)];
        }
    }
    
    // Plan8 -- 1 itineraries starting at 10:30 (10:01 request) on Wednesday August 22
    leg80.startTime = date80;
    leg80.agencyId = caltrain;
    leg80.itinerary = itin80;
    itin80.startTime = date80;
    itin80.endTime = [itin80.startTime dateByAddingTimeInterval:(30.0*60)];
    itin80.plan = plan8;
    
    [plan8 createRequestChunkWithAllItinerariesAndRequestDate:date80req departOrArrive:DEPART];
    [plan8 setFromLocation:loc1];
    [plan8 setToLocation:loc2];
    for (Itinerary* itin in [plan8 itineraries]) {
        for (Leg* leg in [itin legs]) {
            leg.route = @"Caltrain";
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
            leg.endTime = [leg.startTime dateByAddingTimeInterval:(30.0*60)];
        }
    }

    // Plan9depart -- 2 itineraries (11:35PM and 12:35AM the next day) (11:20 depart request) on Monday August 20
    leg90dep.startTime = date90;
    leg90dep.agencyId = caltrain;
    leg90dep.itinerary = itin90dep;
    itin90dep.startTime = date90;
    itin90dep.endTime = [itin90dep.startTime dateByAddingTimeInterval:(30.0*60)];
    itin90dep.plan = plan9depart;
    
    leg91dep.startTime = date91;
    leg91dep.agencyId = Bart;
    leg91dep.itinerary = itin91dep;
    itin91dep.startTime = date91;
    itin91dep.endTime = [itin91dep.startTime dateByAddingTimeInterval:(30.0*60)];
    itin91dep.plan = plan9depart;
    
    leg92dep.startTime = date90;  // begun before midnight
    leg92dep.agencyId = Bart;
    leg92dep.itinerary = itin92dep;
    itin92dep.startTime = date90;
    itin92dep.endTime = [itin92dep.startTime dateByAddingTimeInterval:(6*60*60)];  // goes overnight
    itin92dep.plan = plan9depart;
    
    leg93dep.startTime = date92;  // begun after midnight
    leg93dep.agencyId = Bart;
    leg93dep.itinerary = itin93dep;
    itin93dep.startTime = date92;
    itin93dep.endTime = [itin93dep.startTime dateByAddingTimeInterval:(6*60*60)];  // goes overnight
    itin93dep.plan = plan9depart;
    
    [plan9depart createRequestChunkWithAllItinerariesAndRequestDate:date90req departOrArrive:DEPART];
    [plan9depart setFromLocation:loc1];
    [plan9depart setToLocation:loc2];
    for (Itinerary* itin in [plan9depart itineraries]) {
        for (Leg* leg in [itin legs]) {
            leg.route = @"Caltrain";
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
            leg.endTime = [leg.startTime dateByAddingTimeInterval:(30.0*60)];
        }
    }
    
    // Plan9arrive -- same as Plan9depart but with an Arrive request at 1:10AM on August 21st
    leg90arr.startTime = date90;
    leg90arr.agencyId = caltrain;
    leg90arr.itinerary = itin90arr;
    itin90arr.startTime = date90;
    itin90arr.endTime = [itin90arr.startTime dateByAddingTimeInterval:(30.0*60)];
    itin90arr.plan = plan9arrive;
    
    leg91arr.startTime = date91;
    leg91arr.agencyId = Bart;
    leg91arr.itinerary = itin91arr;
    itin91arr.startTime = date91;
    itin91arr.endTime = [itin91arr.startTime dateByAddingTimeInterval:(30.0*60)];
    itin91arr.plan = plan9arrive;
    
    [plan9arrive createRequestChunkWithAllItinerariesAndRequestDate:date90ArrReq departOrArrive:ARRIVE];
    [plan9arrive setFromLocation:loc1];
    [plan9arrive setToLocation:loc2];
    for (Itinerary* itin in [plan9arrive itineraries]) {
        for (Leg* leg in [itin legs]) {
            leg.route = @"Caltrain";
            PlanPlace *pp1 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            PlanPlace *pp2 = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:managedObjectContext];
            [pp1 setName:@"75 Hawthorne St"];
            [pp2 setName:@"750 Hawthorne St"];
            leg.from = pp1;
            leg.to = pp2;
            leg.endTime = [leg.startTime dateByAddingTimeInterval:(30.0*60)];
        }
    }
    
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
    STAssertEquals([locations consolidateWithMatchingLocations:loc1
                                              keepThisLocation:false], loc1, @""); // no matches, returns loc1
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
    STAssertTrue([durationString(60.0 * 60.0*1000.0) isEqualToString:@"1 hr"], @"");
    STAssertTrue([durationString(1.5 * 60.0 * 60.0*1000.0) isEqualToString:@"1 hr, 30 min"], @"");

    STAssertTrue([durationString(23.0 * 60.0*60.0*1000.0) isEqualToString:@"23 hrs"], @"");
    STAssertTrue([durationString(23.0 * 60.0*60.0*1000.0 + 90*1000) isEqualToString:@"23 hrs, 2 min"], @"");
    STAssertTrue([durationString(24.0 * 60.0*60.0*1000.0) isEqualToString:@"1 day"], @"");
    STAssertTrue([durationString(100.0 *24.0 * 60.0*60.0*1000.0) isEqualToString:@"100 days"], @"");
    STAssertTrue([durationString(48.0 *24.0 * 60.0*60.0*1000.0 + 91.0 * 1000.0) isEqualToString:@"48 days, 2 min"], @"");
    NIMLOG_EVENT1(@"Test = %@", durationString(32.0 *24.0 * 60.0*60.0*1000.0 + 60.0* 60.0 * 1000.0));
    STAssertTrue([durationString(32.0 *24.0 * 60.0*60.0*1000.0 + 60.0* 60.0 * 1000.0) isEqualToString:@"32 days, 1 hr"], @"");
    STAssertTrue([durationString(2.0 *24.0 * 60.0*60.0*1000.0 + 15*60.0*60.0*1000.0 + 60.0*1000.0) isEqualToString:@"2 days, 15 hrs, 1 min"], @"");
    
    // distanceStringInMilesFeet tests
    NIMLOG_EVENT1(@"Test = %@", distanceStringInMilesFeet(3000.0));

    STAssertTrue([distanceStringInMilesFeet(3000.0) isEqualToString:@"1.9 miles"], @"");
    STAssertTrue([distanceStringInMilesFeet(100.0) isEqualToString:@"328 feet"], @"");
    STAssertTrue([distanceStringInMilesFeet(0.0) isEqualToString:@"less than 1 foot"], @"");
    
    // Calendar functions
    //
    NSDate* dayTime1 = [dateFormatter dateFromString:@"August 22, 2012 5:00 PM"]; // Wednesday
    NSDate* dayTime2 = [dateFormatter dateFromString:@"August 5, 2012 7:00 PM"]; // Sunday
    NSDate* dayTime3 = [dateFormatter dateFromString:@"September 1, 2012 6:00 AM"]; // Saturday
    NSDate* dayTime4 = [dateFormatter dateFromString:@"September 1, 2012 11:59 PM"];
    NSDate* timeOnly4 = timeOnlyFromDate(dayTime4);
    NSDate* timeOnly4Plus10 = [timeOnly4 dateByAddingTimeInterval:(10*60)]; // now past midnight, next day
    NSDate* dayTime5 = [dateFormatter dateFromString:@"August 5, 2012 11:59 PM"];
    NSDate* dayTime6 = [dateFormatter dateFromString:@"August 5, 2012 12:09 AM"];
    NSDate* timeOnly6Minus20 = [timeOnlyFromDate(dayTime6) dateByAddingTimeInterval:-(20*60)];
    NSDate* dayTime7 = [dateFormatter dateFromString:@"August 6, 2012 12:09 AM"];
    NSDate* dayTime8 = [dateFormatter dateFromString:@"August 5, 2012 11:49 PM"];
    NSDate* dayTime9 = [dateFormatter dateFromString:@"August 4, 2012 11:49 PM"];
    
    NSDate* dayTime60ReqNew = [dateFormatter dateFromString:@"August 23, 2012 10:29 AM"]; // Thursday
    NSDate* dayTime60ReqOrig = [dateFormatter dateFromString:@"August 22, 2012 11:00 AM"]; // Wednesday
    NSDate* dayTime50 = [dateFormatter dateFromString:@"August 20, 2012 7:00 AM"]; // Monday
    
    // dayOfWeekFromDate
    STAssertEquals(dayOfWeekFromDate(dayTime1), 4, @"");
    STAssertEquals(dayOfWeekFromDate(dayTime2), 1, @"");
    STAssertEquals(dayOfWeekFromDate(dayTime3), 7, @"");
    
    // timeOnlyFromDate
    NIMLOG_EVENT1(@"Time only of dayTime3 = %@", timeOnlyFromDate(dayTime3));
    STAssertEquals([dayTime1 laterDate:dayTime2], dayTime1, @""); // Full date compare
    STAssertTrue([[timeOnlyFromDate(dayTime1) laterDate:timeOnlyFromDate(dayTime2)] isEqualToDate:
                  timeOnlyFromDate(dayTime2)],@""); // Hours compare
    STAssertTrue([[timeOnlyFromDate(dayTime1) laterDate:timeOnlyFromDate(dayTime3)] isEqualToDate:
                  timeOnlyFromDate(dayTime1)],@""); // Hours compare
    STAssertTrue([[timeOnlyFromDate(dayTime60ReqNew) laterDate:timeOnlyFromDate(dayTime60ReqOrig)] isEqualToDate:timeOnlyFromDate(dayTime60ReqOrig)],@"");
    STAssertTrue([[timeOnlyFromDate(dayTime60ReqNew) laterDate:timeOnlyFromDate(dayTime50)] isEqualToDate:
    timeOnlyFromDate(dayTime60ReqNew)],@"");
    
    
    // dateOnlyFromDate
    STAssertTrue([dateOnlyFromDate(dayTime3) isEqualToDate:dateOnlyFromDate(dayTime4)], @"");
    STAssertFalse([dateOnlyFromDate(dayTime2) isEqualToDate:dateOnlyFromDate(dayTime4)], @"");

    // dateOnlyWithTimeOnly
    STAssertTrue([addDateOnlyWithTimeOnly(dayTime2, dayTime4) isEqualToDate:dayTime5], @"");
    STAssertTrue([addDateOnlyWithTimeOnly(dayTime2, timeOnly4Plus10) isEqualToDate:dayTime6], @"");
    STAssertTrue([addDateOnlyWithTimeOnly(dayTime2, timeOnly6Minus20) isEqualToDate:dayTime8], @"");

    // dateOnlyWithTime
    STAssertTrue([addDateOnlyWithTime(dayTime2, timeOnly4) isEqualToDate:dayTime5], @"");
    STAssertTrue([addDateOnlyWithTime(dayTime2, timeOnly4Plus10) isEqualToDate:dayTime7], @"");
    STAssertTrue([addDateOnlyWithTime(dayTime2, timeOnly6Minus20) isEqualToDate:dayTime9], @"");
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
    STAssertTrue(([[itin80 planRequestChunks] count]==1), @"");
    PlanRequestChunk* chunk8 = [[itin80 planRequestChunks] anyObject];
    STAssertTrue(([[itin90dep planRequestChunks] count]==1), @"");
    PlanRequestChunk* chunk9dep = [[itin90dep planRequestChunks] anyObject];
    STAssertTrue(([[itin90arr planRequestChunks] count]==1), @"");
    PlanRequestChunk* chunk9arr = [[itin90arr planRequestChunks] anyObject];
    
    // chunk3 and chunk5 occur on different days but same service and overlapping times
    STAssertTrue([chunk3 doTimesOverlapRequestChunk:chunk5 bufferInSeconds:120], @"");
    STAssertTrue([chunk5 doTimesOverlapRequestChunk:chunk3 bufferInSeconds:120], @"");
    STAssertTrue([chunk3 doAllServiceStringByAgencyMatchRequestChunk:chunk5], @"");
    STAssertTrue([chunk5 doAllServiceStringByAgencyMatchRequestChunk:chunk3], @"");
        
    // Chunk 5 and Chunk 6 are not overlapping
    STAssertFalse([chunk5 doTimesOverlapRequestChunk:chunk6 bufferInSeconds:120], @"");
    STAssertFalse([chunk6 doTimesOverlapRequestChunk:chunk5 bufferInSeconds:120], @"");

    // Chunk 6 and Chunk 8 only overlapping if we have a buffer (10:00 latest vs 10:01 earliest)
    STAssertFalse([chunk6 doTimesOverlapRequestChunk:chunk8 bufferInSeconds:0], @"");
    STAssertTrue([chunk6 doTimesOverlapRequestChunk:chunk8 bufferInSeconds:120], @"");
    
    // Consolidate chunks
    [chunk3 consolidateIntoSelfRequestChunk:chunk5];
    STAssertEqualObjects([chunk3 earliestRequestedDepartTimeDate], [chunk5 earliestRequestedDepartTimeDate], @"");
    STAssertTrue(([[chunk3 sortedItineraries] count]==6), @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:0], itin50, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:1], itin51, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:4], itin31, @"");
    STAssertEquals([[chunk3 sortedItineraries] objectAtIndex:5], itin32, @"");

    // chunk 3 and chunk4 occur on different service days but overlapping times
    STAssertTrue([chunk3 doTimesOverlapRequestChunk:chunk4 bufferInSeconds:120], @"");
    STAssertTrue([chunk4 doTimesOverlapRequestChunk:chunk3 bufferInSeconds:120], @"");
    STAssertFalse([chunk3 doAllServiceStringByAgencyMatchRequestChunk:chunk4], @"");
    STAssertFalse([chunk4 doAllServiceStringByAgencyMatchRequestChunk:chunk3], @"");
    
    // chunk6 is an arrive-time request that occurs on the same service and overlapping time with Chunk3
    STAssertTrue([chunk3 doTimesOverlapRequestChunk:chunk6 bufferInSeconds:120], @"");
    STAssertTrue([chunk6 doTimesOverlapRequestChunk:chunk3 bufferInSeconds:120], @"");
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

    // Itin90arr and Itin90dep -- from chunks that cross midnight
    // Test that itineraries have correct startTime and endTime only
    STAssertEqualObjects(timeOnlyFromDate([itin90dep startTime]), [itin90dep startTimeOnly], @"");
    STAssertEqualObjects(timeOnlyFromDate([itin91arr startTime]), [itin91arr startTimeOnly], @"");
    STAssertEquals([[itin91dep startTimeOnly] timeIntervalSinceDate:timeOnlyFromDate([itin91dep startTime])],
                    (24.0*60.0*60.0), @""); // added one day since it went past midnight
    STAssertEquals([[itin90arr startTimeOnly] timeIntervalSinceDate:timeOnlyFromDate([itin90arr startTime])],
                   (-24.0*60.0*60.0), @""); // subtracted one day since arrive request date was past midnight
    
    // Itin9xarr & dep -- now test end-times.  itin90 endtime crosses midnight, so results different than startTime
    STAssertEqualObjects(timeOnlyFromDate([itin90arr endTime]), [itin90arr endTimeOnly], @"");
    STAssertEqualObjects(timeOnlyFromDate([itin91arr endTime]), [itin91arr endTimeOnly], @"");
    STAssertEquals([[itin90dep endTimeOnly] timeIntervalSinceDate:timeOnlyFromDate([itin90dep endTime])],
                   (24.0*60.0*60.0), @""); // added on day since endTime was past midnight
    STAssertEquals([[itin91dep endTimeOnly] timeIntervalSinceDate:timeOnlyFromDate([itin91dep endTime])],
                   (24.0*60.0*60.0), @""); // added one day since it went past midnight
    
    // Chunk9dep -- itineraries cross midnight
    // Verify that itin91dep is indeed sorted after itin90dep (i.e. factors in that it is next day)
    STAssertTrue(([[chunk9dep sortedItineraries] count]==2), @"");
    STAssertEquals([[chunk9dep sortedItineraries] objectAtIndex:0], itin90dep, @"");
    STAssertEquals([[chunk9dep sortedItineraries] objectAtIndex:1], itin91dep, @"");
    STAssertTrue([[chunk9dep earliestTimeFor:DEPART] isEqualToDate:timeOnlyFromDate([chunk9dep earliestRequestedDepartTimeDate])], @"");
    STAssertTrue([[chunk9dep latestTimeFor:DEPART] isEqualToDate:[itin91dep startTimeOnly]], @"");
     
    // Chunk9arr -- itineraries cross midnight with a past midnight arrive date
    STAssertTrue(([[chunk9arr sortedItineraries] count]==2), @"");
    STAssertEquals([[chunk9arr sortedItineraries] objectAtIndex:0], itin90arr, @"");
    STAssertEquals([[chunk9arr sortedItineraries] objectAtIndex:1], itin91arr, @"");
    STAssertTrue([[chunk9arr latestTimeFor:ARRIVE] isEqualToDate:timeOnlyFromDate([chunk9arr latestRequestedArriveTimeDate])], @"");
    STAssertTrue([[chunk9arr earliestTimeFor:ARRIVE] isEqualToDate:[itin90arr endTimeOnly]], @"");

    // Make sure it is not overlapping with other requestChunks
    STAssertFalse([chunk9dep doTimesOverlapRequestChunk:chunk9arr bufferInSeconds:60], @"");
    STAssertFalse([chunk9dep doTimesOverlapRequestChunk:chunk3 bufferInSeconds:60], @"");
    STAssertFalse([chunk9arr doTimesOverlapRequestChunk:chunk3 bufferInSeconds:60], @"");
    
    // Leg is
    Leg* leg30 = [[itin30 sortedLegs] objectAtIndex:0];
    Leg* leg52 = [[itin52 sortedLegs] objectAtIndex:0];  // same route as leg30
    Leg* leg51 = [[itin51 sortedLegs] objectAtIndex:0];

    STAssertTrue([leg30 isEqualInSubstance:leg52], @"");
    STAssertFalse([leg30 isEqualInSubstance: leg51], @"");
    
}


- (void)testPlanStore
{
    // Set-up dates
    NSDate* dayTime0 = [dateFormatter dateFromString:@"August 22, 2012 5:01 PM"]; // Wednesday
    NSDate* dayTime01 = [dateFormatter dateFromString:@"August 7, 2012 11:00 PM"]; // Tuesday
    NSDate* dayTime02 = [dateFormatter dateFromString:@"August 7, 2012 11:05 PM"]; // Tuesday
    NSDate* dayTime1 = [dateFormatter dateFromString:@"August 22, 2012 7:50 AM"]; // Wednesday
    NSDate* dayTime2 = [dateFormatter dateFromString:@"August 22, 2012 6:30 AM"]; // Wednesday
    NSDate* dayTime3 = [dateFormatter dateFromString:@"August 22, 2012 7:02 AM"]; // Wednesday
    NSDate* dayTime4 = [dateFormatter dateFromString:@"August 23, 2012 10:29 AM"]; // Thursday
    NSDate* dayTime5 = [dateFormatter dateFromString:@"August 25, 2012 8:50 AM"]; // Saturday
    NSDate* dayTime6 = [dateFormatter dateFromString:@"August 28, 2012 9:10 AM"]; // Tuesday
    NSDate* dayTime7 = [dateFormatter dateFromString:@"August 27, 2012 9:50 AM"]; // Monday
    NSDate* dayTime8 = [dateFormatter dateFromString:@"August 27, 2012 8:00 AM"]; // Monday
    NSDate* dayTime9 = [dateFormatter dateFromString:@"August 28, 2012 9:55 AM"]; // Tuesday

    
    // Find matching plans

    NSArray* matches = [planStore fetchPlansWithToLocation:loc2 fromLocation:loc1];
    STAssertEquals([matches count], 10U, @"");
    
    // Request that matches plan1 by time, but will return nothing because plan1 is out of GTFS current date
    STAssertFalse([plan1 prepareSortedItinerariesWithMatchesForDate:dayTime0 departOrArrive:DEPART], @"");
    STAssertEquals([[plan1 requestChunks] count], 1U, @"");
    PlanRequestChunk* plan1chunk = [[plan1 requestChunks] anyObject];
    STAssertNotNil([plan1chunk earliestRequestedDepartTimeDate], @"");

    // Consolidate plan1 (out of date) into plan3. All the itineraries and requestChunk from plan1 should be deleted
    [plan3 consolidateIntoSelfPlan:plan1];
    STAssertNil([plan1 fromLocation], @"");  // proof that plan1 was deleted in context change
    STAssertEquals([[plan3 itineraries] count], 3U, @"");
    STAssertEquals([[plan3 requestChunks] count], 1U, @"");
    STAssertNil([itin10 startTime], @""); // itin10 is deleted because it is out of date
    STAssertNil([itin11 startTime], @""); // itin11 is deleted because it is out of date
    STAssertNil([plan1chunk earliestRequestedDepartTimeDate], @"");  // shows plan1chunk is deleted

    // Plan2 is pure walking leg.  Ask for it at exact same time as original request (but different day)
    STAssertTrue([plan2 prepareSortedItinerariesWithMatchesForDate:dayTime01 departOrArrive:DEPART], @"");
    STAssertEquals([[plan2 sortedItineraries] count], 1U, @"");
    STAssertEqualObjects([[plan2 sortedItineraries] objectAtIndex:0], itin20, @"");
    
    // Try again with Plan2, but this time 5 minutes later -- should not match because does not fit within
    // time window.  This is a very conservative approach to re-using walking legs for now.  
    STAssertFalse([plan2 prepareSortedItinerariesWithMatchesForDate:dayTime02 departOrArrive:DEPART], @"");
    
    // Consolidate Plan2 into Plan3
    [plan3 consolidateIntoSelfPlan:plan2];
    STAssertNil([plan2 fromLocation], @"");  // proof that plan5 was deleted in context change
    STAssertEquals([[plan3 itineraries] count], 4U, @"");
    STAssertEquals([[plan3 requestChunks] count], 2U, @"");
    
    // Request that matches plan3 from August 17
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime1 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 3U, @"");
    STAssertEquals([[plan3 sortedItineraries] objectAtIndex:0], itin30, @"");
    STAssertEquals([[plan3 sortedItineraries] objectAtIndex:1], itin31, @"");
    STAssertEquals([[plan3 sortedItineraries] objectAtIndex:2], itin32, @"");

    // Request that is too early to match any of the plans, itineraries should be unchanged
    STAssertFalse([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime2 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 3U, @"");
    STAssertEquals([[plan3 sortedItineraries] objectAtIndex:0], itin30, @"");
    STAssertEquals([[plan3 sortedItineraries] objectAtIndex:1], itin31, @"");
    STAssertEquals([[plan3 sortedItineraries] objectAtIndex:2], itin32, @"");
    
    // Request for a Saturday at 8:50 will not work because services do not match
    STAssertFalse([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime5 departOrArrive:DEPART], @"");
    
    // Now combine in plan4, which will give a separate requestChunk
    [plan3 consolidateIntoSelfPlan:plan4];
    STAssertNil([plan4 fromLocation], @"");  // proof that plan4 was deleted in context change
    STAssertFalse([plan3 isDeleted], @"");
    STAssertEquals([[plan3 itineraries] count], 6U, @"");
    STAssertEquals([[plan3 requestChunks] count], 3U, @"");
    
    // Request for a Saturday at 8:50 again will work because of Plan4 availability
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime5 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 2U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin40, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:1], itin41, @"");

    
    // Combine with plan5, there is one overlapping itinerary (itin52 duplicate with itin30)
    [plan3 consolidateIntoSelfPlan:plan5];
    STAssertNil([plan5 fromLocation], @"");  // proof that plan5 was deleted in context change
    STAssertFalse([plan3 isDeleted], @"");
    STAssertEquals([[plan3 itineraries] count], 8U, @"");
    STAssertEquals([[plan3 requestChunks] count], 3U, @"");
    STAssertNil([itin30 startTime], @""); // itin30 is deleted because it was created first

    // Now request at 7:02 and we will get all the itineraries back
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime3 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 5U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin50, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:1], itin51, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:2], itin52, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:3], itin31, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:4], itin32, @"");

    // Test against 7:50 departure time (should have only 3 itineraries)
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime1 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 3U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin52, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:1], itin31, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:2], itin32, @"");
    
    // Test against arrival time request of 10:29AM (should have no results)
    STAssertFalse([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime4 departOrArrive:ARRIVE], @"");

    // Now lets try that arrival request at 10:29 with plan6 (falls within buffer).
    // Arrive itineraries are in reverse chrono order (DE191 fix)
    STAssertTrue([plan6 prepareSortedItinerariesWithMatchesForDate:dayTime4 departOrArrive:ARRIVE], @"");
    STAssertEquals([[plan6 sortedItineraries] count], 3U, @"");
    STAssertEqualObjects([[plan6 sortedItineraries] objectAtIndex:2], itin60, @"");
    STAssertEqualObjects([[plan6 sortedItineraries] objectAtIndex:1], itin61, @"");
    STAssertEqualObjects([[plan6 sortedItineraries] objectAtIndex:0], itin62, @"");

    // Combine with Plan6 (3 itineraries at 9, 9:30 and 10:00 with arrive time request at 11:00am)
    [plan3 consolidateIntoSelfPlan:plan6];
    STAssertNil([plan6 fromLocation], @"");  // proof that plan6 was deleted in context change
    STAssertFalse([plan3 isDeleted], @"");
    STAssertEquals([[plan3 itineraries] count], 10U, @"");
    STAssertEquals([[plan3 requestChunks] count], 3U, @"");
    
    //Test 10:29 arrival again now with consolidate plan3 (will get continuous itineraries)
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime4 departOrArrive:ARRIVE], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 7U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:6], itin50, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:5], itin51, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:4], itin52, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:3], itin31, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:2], itin60, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:1], itin61, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin62, @"");
    STAssertNil([itin32 startTime], @""); // Showing that itin32 was deleted

    // Test returnSortedItinerariesWithMatchesForDate with various parameters
    NSArray* testArray1 = [plan3 returnSortedItinerariesWithMatchesForDate:dayTime4
                                                            departOrArrive:ARRIVE
                                                  planMaxItinerariesToShow:20
                                          planBufferSecondsBeforeItinerary:(3*60+1)
                                               planMaxTimeForResultsToShow:(2*60*60)]; // Constrain # of hours
    STAssertEquals([testArray1 count], 5U, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:4], itin52, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:3], itin31, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:2], itin60, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:1], itin61, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:0], itin62, @"");
    
    testArray1 = [plan3 returnSortedItinerariesWithMatchesForDate:dayTime4
                                                            departOrArrive:ARRIVE
                                                  planMaxItinerariesToShow:4
                                          planBufferSecondsBeforeItinerary:(3*60+1)
                                               planMaxTimeForResultsToShow:(2*60*60)]; // Constrain # of itineraries
    STAssertEquals([testArray1 count], 4U, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:3], itin31, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:2], itin60, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:1], itin61, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:0], itin62, @"");
    
    testArray1 = [plan3 returnSortedItinerariesWithMatchesForDate:dayTime2
                                                   departOrArrive:DEPART
                                         planMaxItinerariesToShow:2
                                 planBufferSecondsBeforeItinerary:(3*60+1)
                                      planMaxTimeForResultsToShow:(2*60*60)]; // Constrain # of itineraries
    STAssertEquals([testArray1 count], 2U, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:0], itin50, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:1], itin51, @"");

    testArray1 = [plan3 returnSortedItinerariesWithMatchesForDate:dayTime3
                                                   departOrArrive:DEPART
                                         planMaxItinerariesToShow:10
                                 planBufferSecondsBeforeItinerary:(3*60+1)
                                      planMaxTimeForResultsToShow:(2*60*60+1)]; // Constrain # of hours
    STAssertEquals([testArray1 count], 5U, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:0], itin50, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:1], itin51, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:2], itin52, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:3], itin31, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:4], itin60, @"");
    
    testArray1 = [plan3 returnSortedItinerariesWithMatchesForDate:dayTime3
                                                   departOrArrive:DEPART
                                         planMaxItinerariesToShow:10
                                 planBufferSecondsBeforeItinerary:(0)
                                      planMaxTimeForResultsToShow:(2*60*60+1)]; // Without buffer, does not pick up itin50
    STAssertEquals([testArray1 count], 4U, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:0], itin51, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:1], itin52, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:2], itin31, @"");
    STAssertEqualObjects([testArray1 objectAtIndex:3], itin60, @"");
    
    // Test 9:10 departure to pick up itineraries from plan6
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime6 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 2U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin61, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:1], itin62, @"");
    
    // Test against Plan7, which has 9:40 req time, 10:00 caltrain route, and 10:20 & 11:20 walk & AC transit legs
    STAssertTrue([plan7 prepareSortedItinerariesWithMatchesForDate:dayTime7 departOrArrive:DEPART], @"");
    STAssertEquals([[plan7 sortedItineraries] count], 3U, @"");
    STAssertEqualObjects([[plan7 sortedItineraries] objectAtIndex:0], itin70, @"");
    STAssertEqualObjects([[plan7 sortedItineraries] objectAtIndex:1], itin71, @"");
    STAssertEqualObjects([[plan7 sortedItineraries] objectAtIndex:2], itin72, @"");

    // Consolidate Plan7
    [plan3 consolidateIntoSelfPlan:plan7];
    STAssertNil([plan7 fromLocation], @"");  // proof that plan6 was deleted in context change
    STAssertEquals([[plan3 itineraries] count], 12U, @"");
    STAssertEquals([[plan3 requestChunks] count], 4U, @"");
    STAssertNil([itin62 startTime], @""); // Showing that itin62 was deleted
    
    // Test on a Monday at 8:00, and we should get combo of plan3 and plan7 Caltrain itinerary only
    // The other plan7 itineraries will appear due to chaining in returnSortedItinerariesWithMatchesForDate
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime8 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 7U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin52, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:1], itin31, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:2], itin60, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:3], itin61, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:4], itin70, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:5], itin71, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:6], itin72, @"");

    // Now if we try on Wednesday at 7:50, we do not get itin71 & itin72 because service days do not match
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime1 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 5U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin52, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:1], itin31, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:2], itin60, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:3], itin61, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:4], itin70, @"");
    
    // Re-test plan7 itineraries after consolidation (should be the same)
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime7 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 3U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin70, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:1], itin71, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:2], itin72, @"");
    
    // Test plan7 itineraries on a Tuesday @ 9:50am -- should only get itin70 (Caltrain one)
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime9 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 1U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin70, @"");
    
    // Triple check Saturday at 8:50 again will work because of Plan4 availability
    STAssertTrue([plan3 prepareSortedItinerariesWithMatchesForDate:dayTime5 departOrArrive:DEPART], @"");
    STAssertEquals([[plan3 sortedItineraries] count], 2U, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:0], itin40, @"");
    STAssertEqualObjects([[plan3 sortedItineraries] objectAtIndex:1], itin41, @"");
    
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
    [[nc_AppDelegate sharedInstance].gtfsParser parseAndStroreGtfsAgencyData:agencyDict];
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
    [[nc_AppDelegate sharedInstance].gtfsParser parseAndStoreGtfsCalendarData:agencyDict];
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
    [[nc_AppDelegate sharedInstance].gtfsParser parseAndStoreGtfsCalendarDatesData:agencyDict];
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
    [[nc_AppDelegate sharedInstance].gtfsParser parseAndStoreGtfsRoutesData:agencyDict];
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
    [[nc_AppDelegate sharedInstance].gtfsParser parseAndStoreGtfsStopsData:agencyDict];
}

// First we get all gtfs Data from server and save to database.
// Get unique itinerary patterns from database and add to plan.
// Get Gtfs trips and stoptimes data from server and save to database.
// generate  new itinerary from patterns and stoptimes data and add it to plan.

- (void) testItineraryCreationFromPattern{
    [[nc_AppDelegate sharedInstance].gtfsParser requestAgencyDataFromServer];
    [self someMethodToWaitForResult];
    NSArray *uniqueitineraryFromPlan10 = [plan10 uniqueItineraries];
    STAssertTrue([uniqueitineraryFromPlan10 count] == 2, @"");
    NSArray *uniqueitineraryFromPlan11 = [plan11 uniqueItineraries];
    STAssertTrue([uniqueitineraryFromPlan11 count] == 3, @"");
    [[nc_AppDelegate sharedInstance].gtfsParser generateGtfsTripsRequestStringUsingPlan:plan10];
    [self someMethodToWaitForResult];
    [[nc_AppDelegate sharedInstance].gtfsParser generateStopTimesRequestString:plan10];
    [self someMethodToWaitForResult];
    
    [plan10 setUniqueItineraryPatterns:[NSSet setWithArray:uniqueitineraryFromPlan10]];
    PlanRequestParameters *parameters = [[PlanRequestParameters alloc] init];
    NSDate* date10req = [dateFormatter dateFromString:@"June 8, 2012 9:40 AM"]; // Friday before last load
    parameters.originalTripDate = date10req;
    
    NSArray *arrItineraries = [[plan10 itineraries] allObjects];
    plan10 = [[nc_AppDelegate sharedInstance].gtfsParser generateLegsAndItineraryFromPatternsOfPlan:plan10 parameters:parameters Context:managedObjectContext];
    saveContext(managedObjectContext);
    NSArray *arrnewItineraries = [[plan10 itineraries] allObjects];
    STAssertTrue([arrItineraries count] <= [arrnewItineraries count],@"");
}
@end
