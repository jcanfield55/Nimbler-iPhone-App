//
//  GtfsParser.m
//  Nimbler Caltrain
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "GtfsParser.h"
#import "GtfsAgency.h"
#import "UtilityFunctions.h"
#import "GtfsCalendarDates.h"
#import "GtfsStopTimes.h"
#import "UtilityFunctions.h"
#import "LegFromGtfs.h"
#import "nc_AppDelegate.h"
#import "GtfsRoutes.h"

@implementation GtfsParser

@synthesize managedObjectContext;
@synthesize rkTpClient;
@synthesize strAgenciesURL;
@synthesize strCalendarDatesURL;
@synthesize strCalendarURL;
@synthesize strRoutesURL;
@synthesize strStopsURL;
@synthesize strTripsURL;
@synthesize strStopTimesURL;
@synthesize tempPlan;
@synthesize loadedInitialData;


- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkTpClient:(RKClient *)rkClient
{
    self = [super init];
    if (self) {
        self.managedObjectContext = moc;
        self.rkTpClient = rkClient;
    }
    
    return self;
}

- (void) parseAndStroreGtfsAgencyData:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchAgencies = [[NSFetchRequest alloc] init];
    [fetchAgencies setEntity:[NSEntityDescription entityForName:@"GtfsAgency" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayAgencies = [self.managedObjectContext executeFetchRequest:fetchAgencies error:nil];
    for (id planRequestChunks in arrayAgencies){
        [self.managedObjectContext deleteObject:planRequestChunks];
    }
    
    NSMutableArray *arrayAgencyID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyURL = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_agency",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            [arrayAgencyID addObject:getItemAtIndexFromArray(0, arraySubComponents)];
            [arrayAgencyName addObject:getItemAtIndexFromArray(1,arraySubComponents)];
            [arrayAgencyURL addObject:getItemAtIndexFromArray(2,arraySubComponents)];
        }
    }
    for(int i=0;i<[arrayAgencyID count];i++){
        GtfsAgency* agency = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsAgency" inManagedObjectContext:self.managedObjectContext];
        agency.agencyID = [arrayAgencyID objectAtIndex:i];
        agency.agencyName = [arrayAgencyName objectAtIndex:i];
        agency.agencyURL = [arrayAgencyURL objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseAndStoreGtfsCalendarDatesData:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchCalendarDates = [[NSFetchRequest alloc] init];
    [fetchCalendarDates setEntity:[NSEntityDescription entityForName:@"GtfsCalendarDates" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayPlanCalendarDates = [self.managedObjectContext executeFetchRequest:fetchCalendarDates error:nil];
    for (id calendarDates in arrayPlanCalendarDates){
        [self.managedObjectContext deleteObject:calendarDates];
    }
    
    NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDate = [[NSMutableArray alloc] init];
    NSMutableArray *arrayExceptionType = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_calendar_dates",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            if(strSubComponents && strSubComponents.length > 0){
                NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                [arrayServiceID addObject:getItemAtIndexFromArray(0, arraySubComponents)];
                [arrayDate addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                [arrayExceptionType addObject:getItemAtIndexFromArray(2,arraySubComponents)];
            }
        }
    }
    NSDateFormatter *formtter = [[NSDateFormatter alloc] init];
    [formtter setDateFormat:@"yyyyMMdd"];
    NSFetchRequest * fetchCalendar = [[NSFetchRequest alloc] init];
    [fetchCalendar setEntity:[NSEntityDescription entityForName:@"GtfsCalendar" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayCalendar = [self.managedObjectContext executeFetchRequest:fetchCalendar error:nil];
    NSMutableDictionary *dictCalendar = [[NSMutableDictionary alloc] init];
    for(int i=0;i<[arrayCalendar count];i++){
        GtfsCalendar *calendar = [arrayCalendar objectAtIndex:i];
        [dictCalendar setObject:calendar forKey:calendar.serviceID];
    }
    for(int i=0;i<[arrayServiceID count];i++){
        GtfsCalendarDates* calendarDates = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsCalendarDates" inManagedObjectContext:self.managedObjectContext];
        calendarDates.serviceID = [arrayServiceID objectAtIndex:i];
        calendarDates.calendar = [dictCalendar objectForKey:calendarDates.serviceID];
        NSString *strDate = [arrayDate objectAtIndex:i];
        NSDate *dates;
        if(strDate.length > 0){
            dates = [formtter dateFromString:[arrayDate objectAtIndex:i]];
            calendarDates.date = dates;
        }
        calendarDates.exceptionType = [arrayExceptionType objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseAndStoreGtfsCalendarData:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchCalendar = [[NSFetchRequest alloc] init];
    [fetchCalendar setEntity:[NSEntityDescription entityForName:@"GtfsCalendar" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayCalendar = [self.managedObjectContext executeFetchRequest:fetchCalendar error:nil];
    for (id calendar in arrayCalendar){
        [self.managedObjectContext deleteObject:calendar];
    }
    
    NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayMonday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayTuesday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayWednesday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayThursday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayFriday = [[NSMutableArray alloc] init];
    NSMutableArray *arraySaturday = [[NSMutableArray alloc] init];
    NSMutableArray *arraySunday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStartDate = [[NSMutableArray alloc] init];
    NSMutableArray *arrayEndDate = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_calendar",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            if(strSubComponents && strSubComponents.length > 0){
                NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                [arrayServiceID addObject:getItemAtIndexFromArray(0, arraySubComponents)];
                [arrayMonday addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                [arrayTuesday addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                [arrayWednesday addObject:getItemAtIndexFromArray(3, arraySubComponents)];
                [arrayThursday addObject:getItemAtIndexFromArray(4,arraySubComponents)];
                [arrayFriday addObject:getItemAtIndexFromArray(5,arraySubComponents)];
                [arraySaturday addObject:getItemAtIndexFromArray(6, arraySubComponents)];
                [arraySunday addObject:getItemAtIndexFromArray(7,arraySubComponents)];
                [arrayStartDate addObject:getItemAtIndexFromArray(8,arraySubComponents)];
                [arrayEndDate addObject:getItemAtIndexFromArray(9,arraySubComponents)];
            }
        }
    }
    NSDateFormatter *formtter = [[NSDateFormatter alloc] init];
    [formtter setDateFormat:@"yyyyMMdd"];
    for(int i=0;i<[arrayServiceID count];i++){
        GtfsCalendar* calendar = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsCalendar" inManagedObjectContext:self.managedObjectContext];
        calendar.serviceID = [arrayServiceID objectAtIndex:i];
        int dMonday = [[arrayMonday objectAtIndex:i] intValue];
        int dTuesday = [[arrayTuesday objectAtIndex:i] intValue];
        int dWednesday = [[arrayWednesday objectAtIndex:i] intValue];
        int dThursday = [[arrayThursday objectAtIndex:i] intValue];
        int dFriday = [[arrayFriday objectAtIndex:i] intValue];
        int dSaturday = [[arraySaturday objectAtIndex:i] intValue];
        int dSunday = [[arraySunday objectAtIndex:i] intValue];
        calendar.monday = [NSNumber numberWithInt:dMonday];
        calendar.tuesday = [NSNumber numberWithInt:dTuesday];
        calendar.wednesday = [NSNumber numberWithInt:dWednesday];
        calendar.thursday = [NSNumber numberWithInt:dThursday];
        calendar.friday = [NSNumber numberWithInt:dFriday];
        calendar.saturday = [NSNumber numberWithInt:dSaturday];
        calendar.sunday = [NSNumber numberWithInt:dSunday];
        NSString *strStartDate = [arrayStartDate objectAtIndex:i];
        NSString *strEndDate = [arrayEndDate objectAtIndex:i];
        if(strStartDate.length > 0){
           NSDate *startDate = [formtter dateFromString:strStartDate];
            calendar.startDate = startDate;
        }
        if(strEndDate.length > 0){
            NSDate *endDate = [formtter dateFromString:strEndDate];
            calendar.endDate = endDate;
        }
    }
    saveContext(self.managedObjectContext);
}

- (void) parseAndStoreGtfsRoutesData:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchRoutes = [[NSFetchRequest alloc] init];
    [fetchRoutes setEntity:[NSEntityDescription entityForName:@"GtfsRoutes" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayRoutes = [self.managedObjectContext executeFetchRequest:fetchRoutes error:nil];
    for (id routes in arrayRoutes){
        [self.managedObjectContext deleteObject:routes];
    }
    
    NSMutableArray *arrayRouteID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteShortName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteLongName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteDesc = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteType = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteURL = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteColor = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteTextColor = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_routes",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            if(strSubComponents && strSubComponents.length > 0){
                NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                [arrayRouteID addObject:getItemAtIndexFromArray(0,arraySubComponents)];
                [arrayRouteShortName addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                [arrayRouteLongName addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                [arrayRouteDesc addObject:getItemAtIndexFromArray(3,arraySubComponents)];
                [arrayRouteType addObject:getItemAtIndexFromArray(4,arraySubComponents)];
                [arrayRouteURL addObject:getItemAtIndexFromArray(5,arraySubComponents)];
                [arrayRouteColor addObject:getItemAtIndexFromArray(6,arraySubComponents)];
                [arrayRouteTextColor addObject:getItemAtIndexFromArray(7,arraySubComponents)];
            }
 
        }
    }
    for(int i=0;i<[arrayRouteID count];i++){
        GtfsRoutes* routes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsRoutes" inManagedObjectContext:self.managedObjectContext];
        routes.routeID = [arrayRouteID objectAtIndex:i];
        routes.routeShortName = [arrayRouteShortName objectAtIndex:i];
        routes.routeLongname = [arrayRouteLongName objectAtIndex:i];
        routes.routeDesc = [arrayRouteDesc objectAtIndex:i];
        routes.routeType = [arrayRouteType objectAtIndex:i];
        routes.routeURL = [arrayRouteURL objectAtIndex:i];
        routes.routeColor = [arrayRouteColor objectAtIndex:i];
        routes.routeTextColor = [arrayRouteTextColor objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseAndStoreGtfsStopsData:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchStops = [[NSFetchRequest alloc] init];
    [fetchStops setEntity:[NSEntityDescription entityForName:@"GtfsStop" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayStops = [self.managedObjectContext executeFetchRequest:fetchStops error:nil];
    for (id stops in arrayStops){
        [self.managedObjectContext deleteObject:stops];
    }
    
    NSMutableArray *arrayStopID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopDesc = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopLat = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopLong = [[NSMutableArray alloc] init];
    NSMutableArray *arrayZoneID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopURL = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_stops",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            if(strSubComponents && strSubComponents.length > 0){
                NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                 [arrayStopID addObject:getItemAtIndexFromArray(0,arraySubComponents)];
                 [arrayStopName addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                 [arrayStopDesc addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                 [arrayStopLat addObject:getItemAtIndexFromArray(3,arraySubComponents)];
                 [arrayStopLong addObject:getItemAtIndexFromArray(4,arraySubComponents)];
                 [arrayZoneID addObject:getItemAtIndexFromArray(5,arraySubComponents)];
                 [arrayStopURL addObject:getItemAtIndexFromArray(6,arraySubComponents)];
            }
        }
    }
    for(int i=0;i<[arrayStopID count];i++){
        GtfsStop* routes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsStop" inManagedObjectContext:self.managedObjectContext];
        routes.stopID = [arrayStopID objectAtIndex:i];
        routes.stopName = [arrayStopName objectAtIndex:i];
        routes.stopDesc = [arrayStopDesc objectAtIndex:i];
        double stopLat = [[arrayStopLat objectAtIndex:i] doubleValue];
        double stopLong = [[arrayStopLong objectAtIndex:i] doubleValue];
        routes.stopLat = [NSNumber numberWithDouble:stopLat];
        routes.stopLon = [NSNumber numberWithDouble:stopLong];
        routes.zoneID = [arrayZoneID objectAtIndex:i];
        routes.stopURL = [arrayStopURL objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseAndStroreGtfsTripsData:(NSDictionary *)dictFileData RequestUrl:(NSString *)strRequestUrl{
    NSArray *arrayComponents = [strRequestUrl componentsSeparatedByString:@"?"];
    NSString *tempString = [arrayComponents objectAtIndex:1];
    NSArray *arraySubComponents = [tempString componentsSeparatedByString:@"="];
    NSString *tempStringSubComponents = [arraySubComponents objectAtIndex:1];
    NSArray *arrayAgencyIds = [tempStringSubComponents componentsSeparatedByString:@"%2C"];
    
    NSMutableArray *arrayTripID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayTripHeadSign = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDirectionID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayBlockID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayShapeID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyID = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=0;k<[arrayAgencyIds count];k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[arrayAgencyIds objectAtIndex:k]];
        for(int i=0;i<[arrayComponentsAgency count];i++){
            NSString *strAgencyIds = [arrayAgencyIds objectAtIndex:k];
            NSArray *arrayAgencyIdsComponents = [strAgencyIds componentsSeparatedByString:@"_"];
            [arrayAgencyID addObject:getItemAtIndexFromArray(0,arrayAgencyIdsComponents)];
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            if(strSubComponents && strSubComponents.length > 0){
                NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                [arrayTripID addObject:getItemAtIndexFromArray(0,arraySubComponents)];
                [arrayRouteID addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                [arrayServiceID addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                [arrayTripHeadSign addObject:getItemAtIndexFromArray(3,arraySubComponents)];
                [arrayDirectionID addObject:getItemAtIndexFromArray(4,arraySubComponents)];
                [arrayBlockID addObject:getItemAtIndexFromArray(5,arraySubComponents)];
                [arrayShapeID addObject:getItemAtIndexFromArray(6,arraySubComponents)];
            }
        }
    }
    NSFetchRequest * fetchRoutes = [[NSFetchRequest alloc] init];
    [fetchRoutes setEntity:[NSEntityDescription entityForName:@"GtfsRoutes" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayRoutes = [self.managedObjectContext executeFetchRequest:fetchRoutes error:nil];
    NSMutableDictionary *dictRoutes = [[NSMutableDictionary alloc] init];
    for(int i=0;i<[arrayRoutes count];i++){
        GtfsRoutes *routes = [arrayRoutes objectAtIndex:i];
        [dictRoutes setObject:routes forKey:routes.routeID];
    }
    
    NSFetchRequest * fetchCalendar = [[NSFetchRequest alloc] init];
    [fetchCalendar setEntity:[NSEntityDescription entityForName:@"GtfsCalendar" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayCalendar = [self.managedObjectContext executeFetchRequest:fetchCalendar error:nil];
    NSMutableDictionary *dictCalendar = [[NSMutableDictionary alloc] init];
    for(int i=0;i<[arrayCalendar count];i++){
        GtfsCalendar *calendar = [arrayCalendar objectAtIndex:i];
        [dictCalendar setObject:calendar forKey:calendar.serviceID];
    }
    
    for(int i=0;i<[arrayTripID count];i++){
        GtfsTrips* trips = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsTrips" inManagedObjectContext:self.managedObjectContext];
        trips.tripID = [arrayTripID objectAtIndex:i];
        trips.routeID = [arrayRouteID objectAtIndex:i];
        trips.route = [dictRoutes objectForKey:trips.routeID];
        trips.serviceID = [arrayServiceID objectAtIndex:i];
        trips.calendar = [dictCalendar objectForKey:trips.serviceID];
        trips.tripHeadSign = [arrayTripHeadSign objectAtIndex:i];
        trips.directionID = [arrayDirectionID objectAtIndex:i];
        trips.blockID = [arrayBlockID objectAtIndex:i];
        trips.shapeID = [arrayShapeID objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
    [self generateStopTimesRequestStringUsingTripIds:arrayTripID agencyIds:arrayAgencyID];
}

- (void) parseAndStoreGtfsStopTimesData:(NSDictionary *)dictFileData RequestUrl:(NSString *)strResourcePath{
    
    NSMutableArray *arrayTripID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayArrivalTime = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDepartureTime = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopSequence = [[NSMutableArray alloc] init];
    NSMutableArray *arrayPickUpType = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDropOffType = [[NSMutableArray alloc] init];
    NSMutableArray *arrayShapeDistTraveled = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyID = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
     NSArray *arrayAgencyIds = [dictComponents allKeys];
    for(int k=0;k<[arrayAgencyIds count];k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[arrayAgencyIds objectAtIndex:k]];
        for(int i=0;i<[arrayComponentsAgency count];i++){
            NSString *strAgencyIds = [arrayAgencyIds objectAtIndex:k];
            NSArray *arrayAgencyIdsComponents = [strAgencyIds componentsSeparatedByString:@"_"];
            [arrayAgencyID addObject:getItemAtIndexFromArray(0,arrayAgencyIdsComponents)];
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            if(strSubComponents && strSubComponents.length > 0){
                NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                [arrayTripID addObject:getItemAtIndexFromArray(0,arraySubComponents)];
                [arrayArrivalTime addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                [arrayDepartureTime addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                [arrayStopID addObject:getItemAtIndexFromArray(3,arraySubComponents)];
                [arrayStopSequence addObject:getItemAtIndexFromArray(4,arraySubComponents)];
                [arrayPickUpType addObject:getItemAtIndexFromArray(5,arraySubComponents)];
                [arrayDropOffType addObject:getItemAtIndexFromArray(6,arraySubComponents)];
                [arrayShapeDistTraveled addObject:getItemAtIndexFromArray(7,arraySubComponents)];
            }
        }
    }
    
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsTrips" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayTrips = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    NSMutableDictionary *dictTrips = [[NSMutableDictionary alloc] init];
    for(int i=0;i<[arrayTrips count];i++){
        GtfsTrips *trips = [arrayTrips objectAtIndex:i];
        [dictTrips setObject:trips forKey:trips.tripID];
    }
    
    NSFetchRequest * fetchStops = [[NSFetchRequest alloc] init];
    [fetchStops setEntity:[NSEntityDescription entityForName:@"GtfsStop" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayStops = [self.managedObjectContext executeFetchRequest:fetchStops error:nil];
    NSMutableDictionary *dictStops = [[NSMutableDictionary alloc] init];
    for(int i=0;i<[arrayStops count];i++){
        GtfsStop *stop = [arrayStops objectAtIndex:i];
        [dictStops setObject:stop forKey:stop.stopID];
    }
    
    for(int j=0;j<[arrayTripID count];j++){
            GtfsStopTimes* stopTimes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsStopTimes" inManagedObjectContext:self.managedObjectContext];
            stopTimes.tripID = [arrayTripID objectAtIndex:j];
            stopTimes.trips = [dictTrips objectForKey:stopTimes.tripID];
            stopTimes.arrivalTime = [arrayArrivalTime objectAtIndex:j];
            stopTimes.departureTime = [arrayDepartureTime objectAtIndex:j];
            stopTimes.stopID = [arrayStopID objectAtIndex:j];
            stopTimes.stop = [dictStops objectForKey:stopTimes.stopID];
            stopTimes.stopSequence = [arrayStopSequence objectAtIndex:j];
            stopTimes.pickUpTime = [arrayPickUpType objectAtIndex:j];
            stopTimes.dropOfTime = [arrayDropOffType objectAtIndex:j];
            stopTimes.shapeDistTravelled = [arrayShapeDistTraveled objectAtIndex:j];
            stopTimes.agencyID = [arrayAgencyID objectAtIndex:j];
    }
    saveContext(self.managedObjectContext);
}

#pragma mark  GTFS Requests

// Request The Server For Agency Data.
-(void)requestAgencyDataFromServer{
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"agency",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strAgenciesURL = request;
        NIMLOG_OBJECT1(@"Get Agencies: %@", request);
        [self.rkTpClient get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getAgencies", @"", exception);
    }
}

// Request The Server For Calendar Dates.
-(void)requestCalendarDatesDataFromServer{
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"calendar_dates",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strCalendarDatesURL = request;
        NIMLOG_OBJECT1(@"Get Calendar Dates: %@", request);
        [self.rkTpClient  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getCalendarDates", @"", exception);
    }
}

// Request The Server For Calendar Data.
-(void)requestCalendarDatafromServer{
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"calendar",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strCalendarURL = request;
        NIMLOG_OBJECT1(@"Get Calendar: %@", request);
        [self.rkTpClient  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getCalendarData", @"", exception);
    }
}

// Request The Server For Routes Data.
-(void)requestRoutesDatafromServer{
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"routes",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strRoutesURL = request;
        NIMLOG_OBJECT1(@"Get Routes: %@", request);
        [self.rkTpClient get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getRoutesData", @"", exception);
    }
}

// Request The Server For Stops Data.
-(void)requestStopsDataFromServer{
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"stops",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strStopsURL = request;
        NIMLOG_OBJECT1(@"Get Stops: %@", request);
        [self.rkTpClient  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getStopsData", @"", exception);
    }
}

// Request The Server For Trips Data.
-(void)requestTripsDatafromServer:(NSMutableString *)strRequestString{
    int nLength = [strRequestString length];
    if(nLength > 0){
        [strRequestString deleteCharactersInRange:NSMakeRange(nLength-1, 1)];
    }
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:strRequestString,AGENCY_ID_AND_ROUTE_ID, nil];
        NSString *request = [GTFS_TRIPS appendQueryParams:dictParameters];
        strTripsURL = request;
        NIMLOG_OBJECT1(@"get Trips Data: %@", request);
        [self.rkTpClient  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getTripsData", @"", exception);
    }

}

// Request The Server For StopTimes Data.
- (void) requestStopTimesDataFromServer:(NSMutableString *)strRequestString{
    int nLength = [strRequestString length];
    if(nLength > 0){
        [strRequestString deleteCharactersInRange:NSMakeRange(nLength-1, 1)];
    }
    @try {
//        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:strRequestString,AGENCY_IDS, nil];
//        NSString *request = [GTFS_STOP_TIMES appendQueryParams:dictParameters];
//        strStopTimesURL = request;
//        NIMLOG_OBJECT1(@"get Gtfs Stop Times: %@", request);
//        [self.rkTpClient  get:request delegate:self];
        RKParams *requestParameter = [RKParams params];
        [requestParameter setValue:strRequestString forParam:AGENCY_IDS];
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        [[RKClient sharedClient] post:GTFS_STOP_TIMES params:requestParameter delegate:self];
        
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getGtfsStopTimes", @"", exception);
    }
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
    NSString *strRequestURL = request.resourcePath;
    @try {
        if ([request isGET]) {
            NSError *error = nil;
            if (error == nil)
            {
                if ([strRequestURL isEqualToString:strAgenciesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStroreGtfsAgencyData:res];
                        [self requestCalendarDatafromServer];
                    }
                    else{
                        [self requestAgencyDataFromServer];
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarDatesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsCalendarDatesData:res];
                        [self requestRoutesDatafromServer];
                    }
                    else{
                        [self requestCalendarDatesDataFromServer];
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarURL]) {
                    [nc_AppDelegate sharedInstance].receivedReply = true;
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsCalendarData:res];
                        [self requestCalendarDatesDataFromServer];
                    }
                    else{
                        [self requestCalendarDatafromServer];
                    }
                }
                else if ([strRequestURL isEqualToString:strRoutesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsRoutesData:res];
                        [self requestStopsDataFromServer];
                    }
                    else{
                        [self requestRoutesDatafromServer];
                    }
                }
                else if ([strRequestURL isEqualToString:strStopsURL]) {
                    [nc_AppDelegate sharedInstance].receivedReply = true;
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsStopsData:res];
                        loadedInitialData = true;  // mark that we are done with our initial data load
                    }
                    else{
                        [self requestStopsDataFromServer];
                    }
                }
                else if ([strRequestURL isEqualToString:strTripsURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStroreGtfsTripsData:res RequestUrl:strRequestURL];
                    }
                    else{
                        [self generateGtfsTripsRequestStringUsingPlan:tempPlan];
                    }
                }
                else if ([strRequestURL isEqualToString:strStopTimesURL]) {
                }
            }
        }
        else{
            [nc_AppDelegate sharedInstance].receivedReply = true;
            RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
            NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
            NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
            if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                [self parseAndStoreGtfsStopTimesData:res RequestUrl:strRequestURL];
                tempPlan = nil;
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->didLoadResponse", @"catching TPServer Response", exception);
    }
}


- (BOOL) isTripsAlreadyExistsForTripId:(NSString *)strTripId RouteId:(NSString *)routeId{
    NSFetchRequest *fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsTripsByTripIdAndRouteId" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strTripId,@"TRIPID",routeId,@"ROUTEID", nil]];
    NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
    if([arrayStopTimes count] > 0)
        return YES;
    return NO;
}

// Check StopTimes Table for particular tripID&agencyID data is exists or not.
// If Data For tripID&agencyID  Already Exists then we will not ask StopTimes Data for that tripID from Server otherwise we will ask for StopTimes Data.
- (BOOL) checkIfTripIDAndAgencyIDAlreadyExists:(NSString *)strTripID:(NSString *)agencyID{
    NSFetchRequest *fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopTimesByAgencyID" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strTripID,@"TRIPID",agencyID,@"AGENCYID", nil]];
    NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
    if([arrayStopTimes count] > 0){
        return YES;
    }
    else{
        return NO;
    }
}

- (void)generateGtfsTripsRequestStringUsingPlan:(Plan *) plan{
    tempPlan = plan;
    [nc_AppDelegate sharedInstance].receivedReply = false;
    NSMutableString *strRequestString = [[NSMutableString alloc] init];
    NSArray *itiArray = [plan sortedItineraries];
    for(int i=0;i<[itiArray count];i++){
        Itinerary *iti = [itiArray objectAtIndex:i];
        NSArray *legArray = [iti sortedLegs];
        for(int j=0;j<[legArray count];j++){
            Leg *leg = [legArray objectAtIndex:j];
            if([leg isScheduled] && ![self isTripsAlreadyExistsForTripId:leg.tripId RouteId:leg.routeId] && [strRequestString rangeOfString:[NSString stringWithFormat:@"%@_%@",agencyIdFromAgencyName(leg.agencyName),leg.routeId]].location == NSNotFound){
                [strRequestString appendFormat:@"%@_%@,",agencyIdFromAgencyName(leg.agencyName),leg.routeId];
            }
        }
    }
    if([strRequestString length] > 0){
        [self requestTripsDatafromServer:strRequestString];
    } 
}
-(void)someMethodToWaitForResult
{
    while (!([nc_AppDelegate sharedInstance].receivedReply^[nc_AppDelegate sharedInstance].receivedError))
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.00001]];
}


// Generate The StopTimes Request Comma Separated string like agencyID_tripID
- (void)generateStopTimesRequestStringUsingTripIds:(NSArray *)tripIds agencyIds:(NSArray *)agencyIds{
//    NSArray *arrTripId;
//    NSArray *arrAgencyId;
//    int n1 = [tripIds count]/50;
//    int n2 = [tripIds count]%50;
//    int loopCount = 0;
//    for(int i=0;i<[tripIds count];i=i+50){
//        [nc_AppDelegate sharedInstance].receivedReply = false;
//        NSRange range;
//        if(loopCount < n1)
//            range = NSMakeRange (i, 50);
//        else
//            range = NSMakeRange(i,n2);
//        loopCount++;
//        arrTripId = [tripIds subarrayWithRange:range];
//        arrAgencyId = [agencyIds subarrayWithRange:range];
        NSMutableString *strRequestString = [[NSMutableString alloc] init];
        for(int i=0;i<[tripIds count];i++){
            NSString *strTripId = [tripIds objectAtIndex:i];
            NSString *strAgencyId = [agencyIds objectAtIndex:i];
            if(![self checkIfTripIDAndAgencyIDAlreadyExists:strTripId:strAgencyId] && [strRequestString rangeOfString:[NSString stringWithFormat:@"%@_%@,",strAgencyId,strTripId]].location == NSNotFound)
                [strRequestString appendFormat:@"%@_%@,",strAgencyId,strTripId];
        }
        if([strRequestString length] > 0){
                [self requestStopTimesDataFromServer:strRequestString];
        }
}

// This method get the serviceId based on tripId.
// Then get the calendar data for particular serviceID.
// the check for the request date comes after service start date and comes befor enddate.
// then check service is enabled on request day if yes then return yes otherwise return no.
- (BOOL) isServiceEnableForStopTimes:(GtfsStopTimes *)stopTimes RequestDate:(NSDate *)requestDate{
    @try {
        GtfsTrips *trips = stopTimes.trips;
        GtfsCalendar *calendar = trips.calendar;
        NSArray *arrServiceDays = [NSArray arrayWithObjects:calendar.sunday,calendar.monday,calendar.tuesday,calendar.wednesday,calendar.thursday,calendar.friday,calendar.saturday,nil];
        NSInteger dayOfWeek = dayOfWeekFromDate(requestDate)-1;
        NSDate* dateOnly = dateOnlyFromDate(requestDate);
        NSDateFormatter *dateFormatters = [[NSDateFormatter alloc] init];
        [dateFormatters setDateFormat:@"yyyyMMdd"];
        NSString *strStartDate = [dateFormatters stringFromDate:dateOnlyFromDate(calendar.startDate)];
        NSString *strEndDate =[dateFormatters stringFromDate:dateOnlyFromDate(calendar.endDate)] ;
        NSString* strDateOnly = [dateFormatters stringFromDate:dateOnly];
        
        if (strStartDate && strEndDate && [strDateOnly compare:strStartDate] == NSOrderedDescending && [strDateOnly compare:strEndDate] == NSOrderedAscending) {
            if([[arrServiceDays objectAtIndex:dayOfWeek] intValue] == 1){
                return YES;
            }
            return NO;
        }
        return NO;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->isServiceEnableForTripID", @"", exception);
    }
}

// first get stoptimes from StopTimes Table based on stopId
// Then make a pair of StopTimes if both stoptimes have same tripId then check for the stopSequence and the departure time is greater than request trip time and also check if service is enabled for that stopTimes if yes the add both stopTimes as To/From StopTimes pair.

- (NSMutableArray *)getStopTimes:(NSString *)strToStopID strFromStopID:(NSString *)strFromStopID startDate:(NSDate *)startDate{
    @try {
        NSFetchRequest *fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopTimesByStopID" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strToStopID,@"STOPID1",strFromStopID,@"STOPID2", nil]];
        NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
        NSMutableArray *arrMutableStopTimes = [[NSMutableArray alloc] init];
        NSMutableDictionary *dictStopTimes = [[NSMutableDictionary alloc] init];
        for(int i=0;i<[arrayStopTimes count];i++){
            GtfsStopTimes *stopTimes = [arrayStopTimes objectAtIndex:i];
            NSArray *arrStopTimesPair = [dictStopTimes objectForKey:stopTimes.tripID];
            if(arrStopTimesPair){
                NSMutableArray *arrStopTimes = [[NSMutableArray alloc] initWithArray:arrStopTimesPair];
                [arrStopTimes addObject:stopTimes];
                arrStopTimesPair = arrStopTimes;
                [dictStopTimes setObject:arrStopTimesPair forKey:stopTimes.tripID];
            }
            else{
                NSArray *arrStopTimes = [NSArray arrayWithObject:stopTimes];
                [dictStopTimes setObject:arrStopTimes forKey:stopTimes.tripID];
            }
        }
        
        NSArray *keys = [dictStopTimes allKeys];
        
        for(int j= 0;j<[keys count];j++){
            int hour = 0;
            NSArray *arrStopTimes = [dictStopTimes objectForKey:[keys objectAtIndex:j]];
            if([arrStopTimes count] < 2 || [arrStopTimes count] > 2){
                NIMLOG_UOS202(@"Exceptional StopTimes:%@",arrStopTimes);
                [dictStopTimes removeObjectForKey:[keys objectAtIndex:j]];
            }
            else{
                GtfsStopTimes *stopTimes1 = [arrStopTimes objectAtIndex:0];
                GtfsStopTimes *stopTimes2 = [arrStopTimes objectAtIndex:1];
                if(![stopTimes1.stopID isEqualToString: strFromStopID]){
                    stopTimes1 = [arrStopTimes objectAtIndex:1];
                    stopTimes2 = [arrStopTimes objectAtIndex:0];
                }
                NSString *strDepartureTime;
                NSArray *arrayDepartureTimeComponents = [stopTimes1.departureTime componentsSeparatedByString:@":"];
                if([arrayDepartureTimeComponents count] > 0){
                    int hours = [[arrayDepartureTimeComponents objectAtIndex:0] intValue];
                    int minutes = [[arrayDepartureTimeComponents objectAtIndex:1] intValue];
                    int seconds = [[arrayDepartureTimeComponents objectAtIndex:2] intValue];
                    if(hours > 23){
                        hour = hours;
                        hours = hours - 24;
                    }
                    strDepartureTime = [NSString stringWithFormat:@"%d:%d:%d",hours,minutes,seconds];
                }
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"HH:mm:ss";
                NSDate *departureDate = [formatter dateFromString:strDepartureTime];
                NSDate *departureTime = timeOnlyFromDate(departureDate);
                NSDate *tripTime = timeOnlyFromDate(startDate);
                
                NSCalendar *calendarDepartureTime = [NSCalendar currentCalendar];
                NSDateComponents *componentsDepartureTime = [calendarDepartureTime components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:departureTime];
                int hourDepartureTime = [componentsDepartureTime hour];
                int minuteDepartureTime = [componentsDepartureTime minute];
                int intervalDepartureTime = (hourDepartureTime)*60*60 + minuteDepartureTime*60;
                
                NSCalendar *calendarTripTime = [NSCalendar currentCalendar];
                NSDateComponents *componentsTripTime = [calendarTripTime components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:tripTime];
                int hourTripTime = [componentsTripTime hour];
                int minuteTripTime = [componentsTripTime minute];
                int intervalTripTime = hourTripTime*60*60 + minuteTripTime*60;
                if(stopTimes1 && stopTimes2){
                    if([stopTimes2.stopSequence intValue] > [stopTimes1.stopSequence intValue] && intervalDepartureTime >= intervalTripTime && intervalDepartureTime < intervalTripTime + TRIP_TIME_PLUS_INTERVAL && [self isServiceEnableForStopTimes:stopTimes1 RequestDate:startDate]){
                        NIMLOG_UOS202(@"stoptimes1=%@",stopTimes1);
                        NIMLOG_UOS202(@"stoptimes2=%@",stopTimes2);
                        NSArray *arrayTemp = [NSArray arrayWithObjects:stopTimes1,stopTimes2, nil];
                        [arrMutableStopTimes addObject:arrayTemp];
                     }
                  }
               }
            }
            return arrMutableStopTimes;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getStopTimes", @"", exception);
    }
}

// Return date with time from time string like (10:45:00)
- (NSDate *)timeAndDateFromString:(NSString *)strTime{
    @try {
        NSString *strDepartureTime;
        NSArray *arrayDepartureTimeComponents = [strTime componentsSeparatedByString:@":"];
        if([arrayDepartureTimeComponents count] > 0){
            int hours = [[arrayDepartureTimeComponents objectAtIndex:0] intValue];
            int minutes = [[arrayDepartureTimeComponents objectAtIndex:1] intValue];
            int seconds = [[arrayDepartureTimeComponents objectAtIndex:2] intValue];
            if(hours > 23){
                hours = hours - 24;
            }
            strDepartureTime = [NSString stringWithFormat:@"%d:%d:%d",hours,minutes,seconds];
        }
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss";
        NSDate *departureDate = [formatter dateFromString:strDepartureTime];
        NSDate *departureTime = timeOnlyFromDate(departureDate);
        NSDate *todayDate = dateOnlyFromDate([NSDate date]);
        NSDate *finalDate = addDateOnlyWithTimeOnly(todayDate, departureTime);
        return finalDate;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->timeAndDateFromString", @"", exception);
    }
}

// return time interval in seconds from time string like (10:45:00)
- (int)getTimeInterValInSeconds:(NSString *)strTime{
    @try {
        NSString *strDepartureTime;
        NSArray *arrayDepartureTimeComponents = [strTime componentsSeparatedByString:@":"];
        if([arrayDepartureTimeComponents count] > 0){
            int hours = [[arrayDepartureTimeComponents objectAtIndex:0] intValue];
            int minutes = [[arrayDepartureTimeComponents objectAtIndex:1] intValue];
            int seconds = [[arrayDepartureTimeComponents objectAtIndex:2] intValue];
            if(hours > 23){
                hours = hours - 24;
            }
            strDepartureTime = [NSString stringWithFormat:@"%d:%d:%d",hours,minutes,seconds];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss";
        NSDate *departureDate = [formatter dateFromString:strDepartureTime];
        NSDate *departureTime = timeOnlyFromDate(departureDate);
        
        NSCalendar *calendarDepartureTime = [NSCalendar currentCalendar];
        NSDateComponents *componentsDepartureTime = [calendarDepartureTime components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:departureTime];
        int hourDepartureTime = [componentsDepartureTime hour];
        int minuteDepartureTime = [componentsDepartureTime minute];
        int intervalDepartureTime = (hourDepartureTime)*60*60 + minuteDepartureTime*60;
        return intervalDepartureTime;
    }
    @catch (NSException *exception) {
         logException(@"GtfsParser->getTimeInterValInSeconds", @"", exception);
    }
}

// first check find stoptimes with the departure time greater than start time or end time.
// find stoptimes with minimum departure time from stoptimes array.
- (NSArray *)returnStopTimesWithNearestStartTimeOrEndTime:(NSDate *)time ArrStopTimes:(NSArray *)arrStopTimes{
    @try {
        NSMutableArray *arrStopTime = [[NSMutableArray alloc] init];
        NSCalendar *calendarDepartureTime = [NSCalendar currentCalendar];
        NSDateComponents *componentsDepartureTime = [calendarDepartureTime components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:time];
        int hour = [componentsDepartureTime hour];
        int minute = [componentsDepartureTime minute];
        int interval = hour*60*60 + minute*60;
        for (int i=0;i< [arrStopTimes count];i++) {
            NSArray *stopTimePair = [arrStopTimes objectAtIndex:i];
                GtfsStopTimes *fromStopTime = [stopTimePair objectAtIndex:0];
                int intervalDepartureTime = [self getTimeInterValInSeconds:fromStopTime.departureTime];
                if(intervalDepartureTime > interval){
                    [arrStopTime addObject:stopTimePair];
            }
        }
        NSArray * arrSelectedStopTime;
        if([arrStopTime count] > 0){
           arrSelectedStopTime = [arrStopTime objectAtIndex:0]; 
        }
        for(int i=0;i<[arrStopTime count];i++){
            NSArray *stopTimePair = [arrStopTime objectAtIndex:i];
            GtfsStopTimes *selectedFromStopTime = [arrSelectedStopTime objectAtIndex:0];
            GtfsStopTimes *fromStopTime = [stopTimePair objectAtIndex:0];
            int intervalSelectedDepartureTime = [self getTimeInterValInSeconds:selectedFromStopTime.departureTime];
            int intervalDepartureTime = [self getTimeInterValInSeconds:fromStopTime.departureTime];
            if(intervalSelectedDepartureTime > intervalDepartureTime){
                arrSelectedStopTime = [arrStopTime objectAtIndex:i];
            }
        }
        return arrSelectedStopTime;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->returnStopTimesWithNearestStartTimeOrEndTime", @"", exception);
    }
}

// return nearest stoptimes form stoptimes array based on itinerary start time or itinerary end time.
- (NSArray *) findNearestStopTimeFromStopTimeArray:(NSArray *)arrStopTimes Itinerary:(Itinerary *)itinerary{
    if(itinerary.endTime){
       return  [self returnStopTimesWithNearestStartTimeOrEndTime:itinerary.endTime ArrStopTimes:arrStopTimes];
    }
       return  [self returnStopTimesWithNearestStartTimeOrEndTime:itinerary.startTime ArrStopTimes:arrStopTimes];
}

// This method create unscheduled leg.
- (void) addUnScheduledLegToItinerary:(Itinerary *)itinerary WalkLeg:(Leg *)leg Context:(NSManagedObjectContext *)context{
    @try {
        Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
        newleg.itinerary = itinerary;
        itinerary.sortedLegs = nil;
        if([[itinerary sortedLegs] count] == 1)
            newleg.startTime = itinerary.startTime;
        else
            newleg.startTime = itinerary.endTime;
        newleg.endTime = [newleg.startTime dateByAddingTimeInterval:([leg.duration floatValue]/1000)];
        [newleg setNewlegAttributes:leg];
        itinerary.endTime = newleg.endTime;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->addUnScheduledLegToItinerary", @"", exception);
    }
}
-(void) checkIfItinerarySame:(Itinerary *)itinerary Plan:(Plan *)plan{
    int count = 0;
    for(int i=0;i<[[plan itineraries] count];i++){
        Itinerary *iti = [[[plan itineraries] allObjects] objectAtIndex:i];
        NSDate *newItiStartDate;
        NSDate *itiStartDate;
        if(itinerary.startTime){
           newItiStartDate = timeOnlyFromDate([itinerary startTime]); 
        }
        if(iti.startTime){
           itiStartDate = timeOnlyFromDate([iti startTime]); 
        }
        if(!newItiStartDate
            || [newItiStartDate isEqualToDate:itiStartDate])
            count++;
    }
    if (count > 1)
        [plan deleteItinerary:itinerary];
}

// This method create scheduled leg from gtfs data.
// First find the nearest stoptimes then create transit leg from stoptimes data.
- (void) addScheduledLegToItinerary:(Itinerary *)itinerary TransitLeg:(Leg *)leg StopTime:(NSMutableArray *)arrStopTimes Context:(NSManagedObjectContext *)context{
    @try {
        NSArray *arrayStopTime = [self findNearestStopTimeFromStopTimeArray:arrStopTimes Itinerary:itinerary];
        GtfsStopTimes *fromStopTime = [arrayStopTime objectAtIndex:0];
        GtfsStopTimes *toStopTime = [arrayStopTime objectAtIndex:1];
        Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
        newleg.itinerary = itinerary;
        if(fromStopTime.departureTime){
            newleg.startTime = [self timeAndDateFromString:fromStopTime.departureTime];
            newleg.endTime = [self timeAndDateFromString:toStopTime.departureTime];
        }
        [newleg setNewlegAttributes:leg];
        newleg.duration = [NSNumber numberWithDouble:[newleg.startTime timeIntervalSinceDate:newleg.endTime] * 1000];
        itinerary.endTime = newleg.endTime;
        [arrStopTimes removeObject:arrayStopTime];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->addScheduledLegToItinerary", @"", exception);
    }
}

// This method continues to create itinerary until we have stoptimes data.
// First loop through every leg of itinerary pattern if it is walk leg then we create new leg from old leg by updating some attributes.
// if leg is transit leg then we get the stoptimes data for that leg.
// Next find the nearest stoptimes by comparing departureTime with new itinerary start time or end time.
// Then create the new leg and itinerary from stoptimes data. 
- (void) generateItineraryFromItinerayPatern:(Itinerary *)itinerary tripDate:(NSDate *)tripDate Plan:(Plan *)plan Context:(NSManagedObjectContext *)context{
    NSMutableDictionary *dictStopTimes = [[NSMutableDictionary alloc] init];
    NSDate *startDate = [NSDate date];
    while (true) {
        if([startDate timeIntervalSinceNow] > ITINERARY_GANERATION_TIMEOUT  || [itinerary haveOnlyUnScheduledLeg]){
            NIMLOG_UOS202(@"Generation Of itinerary from pattern Timeout");
            break;
        }
        Itinerary* newItinerary = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:context];
        newItinerary.plan = plan;
        newItinerary.startTime = tripDate;
        for(int j=0;j<[[itinerary sortedLegs] count];j++){
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:j];
            if(![leg isScheduled]){
                [self addUnScheduledLegToItinerary:newItinerary WalkLeg:leg Context:context];
            }
            else{
                NSMutableArray *arrStopTime = [dictStopTimes objectForKey:leg.agencyName];
                if(!arrStopTime){
                    NSString *strTOStopID = leg.to.stopId;
                    NSString *strFromStopID = leg.from.stopId;
                    arrStopTime = [self getStopTimes:strTOStopID strFromStopID:strFromStopID startDate:tripDate];
                    if(arrStopTime && [arrStopTime count] > 0){
                        [dictStopTimes setObject:arrStopTime forKey:leg.agencyName];
                    }
                }
                if([arrStopTime count] == 0){
                    [plan deleteItinerary:newItinerary];
                    return;
                }
                [self addScheduledLegToItinerary:newItinerary TransitLeg:leg StopTime:arrStopTime Context:context];
                [dictStopTimes setObject:arrStopTime forKey:leg.agencyName];
            }
        }
        [self adjustItineraryAndLegsTimes:newItinerary Context:context];
    }
}

// generate new leg from prediction data.
- (void) generateLegFromPrediction:(NSDictionary *)prediction newItinerary:(Itinerary *)newItinerary Leg:(Leg *)leg Context:(NSManagedObjectContext *)context ISExtraPrediction:(BOOL)isExtraPrediction{
    NSDate *predtctionTime = [NSDate dateWithTimeIntervalSince1970:([[prediction objectForKey:@"epochTime"] doubleValue]/1000.0)];
    Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
    newleg.itinerary = newItinerary;
    newleg.startTime = predtctionTime;
    newleg.endTime = [newleg.startTime dateByAddingTimeInterval:([leg.duration floatValue]/1000)];
    [newleg setNewlegAttributes:leg];
    if(isExtraPrediction)
        newItinerary.startTime = newleg.startTime;

    newItinerary.endTime = newleg.endTime;
    newleg.isRealTimeLeg = true;
    newItinerary.isRealTimeItinerary = true;
}

- (void) adjustItineraryAndLegsTimes:(Itinerary *)itinerary Context:(NSManagedObjectContext *)context{
        itinerary.sortedLegs = nil;
        if([[itinerary sortedLegs] count] > 0){
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:0];
            if(![leg isScheduled]){
                Leg *nextLeg = [leg getLegAtOffsetFromListOfLegs:[itinerary sortedLegs] offset:1];
                Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
                newleg.itinerary = itinerary;
                newleg.endTime = nextLeg.startTime;
                [newleg setNewlegAttributes:leg];
                newleg.startTime = [newleg.endTime dateByAddingTimeInterval:(-[newleg.duration intValue])/1000];
                itinerary.startTime = newleg.startTime;
                [itinerary removeLegsObject:leg];
            }
            
            Leg *lastLeg = [[itinerary sortedLegs] lastObject];
            if(![lastLeg isScheduled]){
                Leg *previousLeg = [lastLeg getLegAtOffsetFromListOfLegs:[itinerary sortedLegs] offset:-1];
                Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
                newleg.itinerary = itinerary;
                newleg.startTime = previousLeg.endTime;
                newleg.endTime = [newleg.startTime dateByAddingTimeInterval:([newleg.duration intValue])/1000];
                [newleg setNewlegAttributes:lastLeg];
                itinerary.endTime = newleg.endTime;
                [itinerary removeLegsObject:lastLeg];
            }
        }
}

// Generate new leg with all parameters from old leg
- (void) generateNewLegFromOldLeg:(Leg *)leg Context:(NSManagedObjectContext *)context Itinerary:(Itinerary *)itinerary{
    Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
    newleg.itinerary = itinerary;
    newleg.startTime = leg.startTime;
    newleg.endTime = leg.endTime;
    itinerary.endTime = newleg.endTime;
    [newleg setNewlegAttributes:leg];
}

// Generate new itinerary with remaining prediction and pattern.
- (void) generateNewItineraryFromExtraPrediction:(NSDictionary *)prediction :(Plan *)plan Itinerary:(Itinerary *)itinerary UniqueLeg:(Leg *)uniqueLeg Context:(NSManagedObjectContext *)context{
    if(!context){
        context = managedObjectContext;
    }
    Itinerary* newItinerary = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:context];
    newItinerary.plan = plan;
    newItinerary.startTime = itinerary.startTime;
    for(int i=0;i<[[itinerary sortedLegs] count];i++){
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:i];
         if([uniqueLeg.to.lat doubleValue] == [leg.to.lat doubleValue] && [uniqueLeg.to.lng doubleValue] == [leg.to.lng doubleValue] && [uniqueLeg.from.lat doubleValue ] == [leg.from.lat doubleValue] && [uniqueLeg.from.lng doubleValue] == [leg.from.lng doubleValue] && [uniqueLeg.routeId isEqualToString:leg.routeId]){
             [self generateLegFromPrediction:prediction newItinerary:newItinerary Leg:leg Context:context ISExtraPrediction:true];
         }
         else{
             if([leg isScheduled]){
                 NSString *strTOStopID = leg.to.stopId;
                 NSString *strFromStopID = leg.from.stopId;
                 NSMutableArray *arrStopTime = [self getStopTimes:strTOStopID strFromStopID:strFromStopID startDate:leg.startTime];
                 if([arrStopTime count] == 0){
                     [plan deleteItinerary:newItinerary];
                     break;
                 }
                 [self addScheduledLegToItinerary:newItinerary TransitLeg:leg StopTime:arrStopTime Context:context];
             }
             else{
                 [self addUnScheduledLegToItinerary:newItinerary WalkLeg:leg Context:context];
             }
         }
    }
    [self adjustItineraryAndLegsTimes:newItinerary Context:context];
}

// Generate new itinerary by chaging the legs from miss connection found.
// i.e if pattern is w,c,w,b and if miss connection found from c then we will create c,w,b legs.
- (void) generateNewItineraryByRemovingConflictLegs:(Leg *)leg FromItinerary:(Itinerary *)itinerary Plan:(Plan *)plan Context:(NSManagedObjectContext *)context{
    if(!context){
        context = managedObjectContext;
    }
    if([[leg arrivalFlag] intValue] == DELAYED){
        Itinerary* newItinerary = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:context];
        newItinerary.plan = plan;
        newItinerary.startTime = itinerary.startTime;
        NSArray *sortedlegs = itinerary.sortedLegs;
        int index = [sortedlegs indexOfObject:leg];
        for(int i=0;i<index;i++){
            [self generateNewLegFromOldLeg:[sortedlegs objectAtIndex:i] Context:context Itinerary:newItinerary];
        }
        
        for(int i=index;i<[sortedlegs count];i++){
            Leg *leg = [sortedlegs objectAtIndex:i];
            if([leg isScheduled]){
                if(leg.prediction){
                    [self generateLegFromPrediction:leg.prediction newItinerary:newItinerary Leg:leg Context:context ISExtraPrediction:false];
                }
                else{
                    NSString *strTOStopID = leg.to.stopId;
                    NSString *strFromStopID = leg.from.stopId;
                    NSMutableArray *arrStopTime = [self getStopTimes:strTOStopID strFromStopID:strFromStopID startDate:newItinerary.endTime];
                    if([arrStopTime count] == 0){
                        [plan deleteItinerary:newItinerary];
                        break;
                    }
                    [self addScheduledLegToItinerary:newItinerary TransitLeg:leg StopTime:arrStopTime Context:context];
                }
            }
            else{
                [self addUnScheduledLegToItinerary:newItinerary WalkLeg:leg Context:context];
            }
        }
        [self adjustItineraryAndLegsTimes:newItinerary Context:context];
    }
}

// Generate new itineraries from patterns and stoptimes data.
- (void) generateScheduledItinerariesFromPatternOfPlan:(Plan *)plan Context:(NSManagedObjectContext *)context tripDate:(NSDate *)tripDate{
    if(!context){
        context = managedObjectContext;
    }
    for(int i=0;i<[[plan uniqueItineraries] count];i++){
        Itinerary *itinerary = [[plan uniqueItineraries] objectAtIndex:i];
        [self generateItineraryFromItinerayPatern:itinerary tripDate:tripDate Plan:plan Context:context];
    }
}
@end

