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
@synthesize strAgenciesURL;
@synthesize strCalendarDatesURL;
@synthesize strCalendarURL;
@synthesize strRoutesURL;
@synthesize strStopsURL;
@synthesize strTripsURL;
@synthesize strStopTimesURL;


- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        self.managedObjectContext = moc;
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
    for(int i=0;i<[arrayServiceID count];i++){
        GtfsCalendarDates* calendarDates = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsCalendarDates" inManagedObjectContext:self.managedObjectContext];
        calendarDates.serviceID = [arrayServiceID objectAtIndex:i];
        GtfsCalendar *calendar = [self getCalendarDataFromDatabase:calendarDates.serviceID];
        calendarDates.calendar = calendar;
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
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=0;k<[arrayAgencyIds count];k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[arrayAgencyIds objectAtIndex:k]];
        for(int i=0;i<[arrayComponentsAgency count];i++){
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
    for(int i=0;i<[arrayTripID count];i++){
        GtfsTrips* trips = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsTrips" inManagedObjectContext:self.managedObjectContext];
        trips.tripID = [arrayTripID objectAtIndex:i];
        trips.routeID = [arrayRouteID objectAtIndex:i];
        GtfsRoutes *routes = [self getRoutesDataFromDatabase:trips.routeID];
        trips.route = routes;
        trips.serviceID = [arrayServiceID objectAtIndex:i];
        GtfsCalendar *calendar = [self getCalendarDataFromDatabase:trips.serviceID];
        trips.calendar = calendar;
        trips.tripHeadSign = [arrayTripHeadSign objectAtIndex:i];
        trips.directionID = [arrayDirectionID objectAtIndex:i];
        trips.blockID = [arrayBlockID objectAtIndex:i];
        trips.shapeID = [arrayShapeID objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseAndStoreGtfsStopTimesData:(NSDictionary *)dictFileData RequestUrl:(NSString *)strResourcePath{
    NSArray *arrayComponents = [strResourcePath componentsSeparatedByString:@"?"];
    NSString *tempString = [arrayComponents objectAtIndex:1];
    NSArray *arraySubComponents = [tempString componentsSeparatedByString:@"="];
    NSString *tempStringSubComponents = [arraySubComponents objectAtIndex:1];
    NSArray *arrayAgencyIds = [tempStringSubComponents componentsSeparatedByString:@"%2C"];
    
    
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
    
    for(int l=0;l<[arrayTripID count];l++){
        NSFetchRequest *fetchTrips = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopTimesBySequence" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:[arrayTripID objectAtIndex:l],@"TRIPID",[arrayStopSequence objectAtIndex:l],@"STOPSEQUENCE", nil]];
        NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
        for (id stopTimes in arrayStopTimes){
            [self.managedObjectContext deleteObject:stopTimes];
        }
    }
    for(int j=0;j<[arrayTripID count];j++){
        GtfsStopTimes* stopTimes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsStopTimes" inManagedObjectContext:self.managedObjectContext];
        stopTimes.tripID = [arrayTripID objectAtIndex:j];
        GtfsTrips *trips = [self getTripsDataFromDatabase:stopTimes.tripID];
        stopTimes.trips = trips;
        stopTimes.arrivalTime = [arrayArrivalTime objectAtIndex:j];
        stopTimes.departureTime = [arrayDepartureTime objectAtIndex:j];
        stopTimes.stopID = [arrayStopID objectAtIndex:j];
        GtfsStop *stops = [self getStopsDataFromDatabase:stopTimes.stopID];
        stopTimes.stop = stops;
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
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"agency",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strAgenciesURL = request;
        NIMLOG_OBJECT1(@"Get Agencies: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getAgencies", @"", exception);
    }
}

// Request The Server For Calendar Dates.
-(void)requestCalendarDatesDataFromServer{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"calendar_dates",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strCalendarDatesURL = request;
        NIMLOG_OBJECT1(@"Get Calendar Dates: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getCalendarDates", @"", exception);
    }
}

// Request The Server For Calendar Data.
-(void)requestCalendarDatafromServer{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"calendar",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strCalendarURL = request;
        NIMLOG_OBJECT1(@"Get Calendar: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getCalendarData", @"", exception);
    }
}

// Request The Server For Routes Data.
-(void)requestRoutesDatafromServer{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"routes",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strRoutesURL = request;
        NIMLOG_OBJECT1(@"Get Routes: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getRoutesData", @"", exception);
    }
}

// Request The Server For Stops Data.
-(void)requestStopsDataFromServer{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"stops",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strStopsURL = request;
        NIMLOG_OBJECT1(@"Get Stops: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
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
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:strRequestString,AGENCY_ID_AND_ROUTE_ID, nil];
        NSString *request = [GTFS_TRIPS appendQueryParams:dictParameters];
        strTripsURL = request;
        NIMLOG_OBJECT1(@"get Trips Data: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
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
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:strRequestString,AGENCY_IDS, nil];
        NSString *request = [GTFS_STOP_TIMES appendQueryParams:dictParameters];
        strStopTimesURL = request;
        NIMLOG_OBJECT1(@"get Gtfs Stop Times: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
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
                        [self performSelector:@selector(parseAndStroreGtfsAgencyData:) withObject:res];
                        [self performSelector:@selector(requestCalendarDatafromServer) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(requestAgencyDataFromServer) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarDatesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseAndStoreGtfsCalendarDatesData:) withObject:res];
                        [self performSelector:@selector(requestRoutesDatafromServer) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(requestCalendarDatesDataFromServer) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseAndStoreGtfsCalendarData:) withObject:res];
                        [self performSelector:@selector(requestCalendarDatesDataFromServer) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(requestCalendarDatafromServer) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strRoutesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseAndStoreGtfsRoutesData:) withObject:res];
                        [self performSelector:@selector(requestStopsDataFromServer) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(requestRoutesDatafromServer) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strStopsURL]) {
                    [nc_AppDelegate sharedInstance].receivedReply = true;
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseAndStoreGtfsStopsData:) withObject:res];
                    }
                    else{
                        [self performSelector:@selector(requestStopsDataFromServer) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strTripsURL]) {
                    [nc_AppDelegate sharedInstance].receivedReply = true;
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStroreGtfsTripsData:res RequestUrl:strRequestURL];
                    }
                }
                else if ([strRequestURL isEqualToString:strStopTimesURL]) {
                    [nc_AppDelegate sharedInstance].receivedReply = true;
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsStopTimesData:res RequestUrl:strRequestURL];
                    }
                }
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
// Generate The StopTimes Request Comma Separated string like agencyID_tripID
- (void)generateStopTimesRequestString:(Plan *)plan{
    [nc_AppDelegate sharedInstance].receivedReply = false;
    NSMutableString *strRequestString = [[NSMutableString alloc] init];
    NSArray *itiArray = [plan sortedItineraries];
    for(int i=0;i<[itiArray count];i++){
        Itinerary *iti = [itiArray objectAtIndex:i];
        NSArray *legArray = [iti sortedLegs];
        for(int j=0;j<[legArray count];j++){
            Leg *leg = [legArray objectAtIndex:j];
            if([leg isScheduled] && ![self checkIfTripIDAndAgencyIDAlreadyExists:leg.tripId:agencyIdFromAgencyName(leg.agencyName)] && [strRequestString rangeOfString:[NSString stringWithFormat:@"%@_%@,",agencyIdFromAgencyName(leg.agencyName),leg.tripId]].location == NSNotFound)
                    [strRequestString appendFormat:@"%@_%@,",agencyIdFromAgencyName(leg.agencyName),leg.tripId];
        }
    }
    if([strRequestString length] > 0){
        [self requestStopTimesDataFromServer:strRequestString];
    }
}

// Get The stopID For To&From Location.
- (NSString *) getTheStopIDAccrodingToStation:(NSNumber *)lat:(NSNumber *)lng{
    NSFetchRequest *fetchStop = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopByLatLng" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:lat,@"STOPLAT",lng,@"STOPLON", nil]];
    NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchStop error:nil];
    NSString *strStopID;
    if([arrayStopTimes count] > 0){
        GtfsStop *stop = [arrayStopTimes objectAtIndex:0];
        strStopID = stop.stopID;
    }
    else{
        strStopID = nil;
    }
    return strStopID;
}

// get serviceID based on tripId.
- (NSString *) getServiceIdFromTripID:(NSString *)strTripID{
    NSFetchRequest *fetchServiceID = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"ServiceIdByTripId" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strTripID,@"TRIPID",nil]];
    NSArray * arrServiceID = [self.managedObjectContext executeFetchRequest:fetchServiceID error:nil];
    GtfsTrips *trips = nil;
    if([arrServiceID count] > 0){
       trips = [arrServiceID objectAtIndex:0]; 
    }
    return trips.serviceID;
}

// Get trips Data from GtfsTrips based on tripID
- (GtfsTrips *)getTripsDataFromDatabase:(NSString *)strTripID{
    NSFetchRequest *fetchTrips = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsTrips" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strTripID,@"TRIPID",nil]];
    NSArray * arrServiceID = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    GtfsTrips *trips = nil;
    if([arrServiceID count] > 0){
        trips = [arrServiceID objectAtIndex:0];
    }
    return trips;
}


// Get stops Data from GtfsStop based on stopID
- (GtfsStop *)getStopsDataFromDatabase:(NSString *)strStopID{
    NSFetchRequest *fetchStops = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStop" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strStopID,@"STOPID",nil]];
    NSArray * arrServiceID = [self.managedObjectContext executeFetchRequest:fetchStops error:nil];
    GtfsStop *stops = nil;
    if([arrServiceID count] > 0){
        stops = [arrServiceID objectAtIndex:0];
    }
    return stops;
}

// Get routes Data from GtfsRoutes based on routeID
- (GtfsRoutes *)getRoutesDataFromDatabase:(NSString *)strRouteID{
    NSFetchRequest *fetchRoutes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsRouteByRouteID" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strRouteID,@"ROUTEID",nil]];
    NSArray * arrServiceID = [self.managedObjectContext executeFetchRequest:fetchRoutes error:nil];
    GtfsRoutes *routes = nil;
    if([arrServiceID count] > 0){
        routes = [arrServiceID objectAtIndex:0];
    }
    return routes;
    
}

// Get Calendar Data from GtfsCalendar based on serviceID
- (GtfsCalendar *)getCalendarDataFromDatabase:(NSString *)strServiceID{
    @try {
        NSFetchRequest *fetchCalendar = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsCalendar" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strServiceID,@"SERVICEID",nil]];
        NSArray * arrServiceID = [managedObjectContext executeFetchRequest:fetchCalendar error:nil];
        GtfsCalendar *calendar = nil;
        if([arrServiceID count] > 0){
            calendar = [arrServiceID objectAtIndex:0];
        }
        return calendar;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getCalendarDataFromDatabase", @"", exception);
    }
}
// This method get the serviceId based on tripId.
// Then get the calendar data for particular serviceID.
// the check for the request date comes after service start date and comes befor enddate.
// then check service is enabled on request day if yes then return yes otherwise return no.
- (BOOL) isServiceEnableForTripID:(NSString *)strTripID RequestDate:(NSDate *)requestDate{
    @try {
        NSString *serviceID = [self getServiceIdFromTripID:strTripID];
        GtfsCalendar *calendar = [self getCalendarDataFromDatabase:serviceID];
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

- (NSMutableArray *)getStopTimes:(NSString *)strToStopID strFromStopID:(NSString *)strFromStopID parameters:(PlanRequestParameters *)parameters{
    @try {
        NSFetchRequest *fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopTimesByStopID" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strToStopID,@"STOPID1",strFromStopID,@"STOPID2", nil]];
        NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
        NSMutableArray *arrMutableStopTimes = [[NSMutableArray alloc] init];
        for(int i=0;i<[arrayStopTimes count];i++){
            for(int j= i+1;j<[arrayStopTimes count];j++){
                int hour = 0;
                GtfsStopTimes *stopTimes1 = [arrayStopTimes objectAtIndex:i];
                GtfsStopTimes *stopTimes2 = [arrayStopTimes objectAtIndex:j];
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
                NSDate *tripTime = timeOnlyFromDate(parameters.originalTripDate);
                
                NSCalendar *calendarDepartureTime = [NSCalendar currentCalendar];
                NSDateComponents *componentsDepartureTime = [calendarDepartureTime components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:departureTime];
                int hourDepartureTime = [componentsDepartureTime hour];
                int minuteDepartureTime = [componentsDepartureTime minute];
                int intervalDepartureTime = (hour+hourDepartureTime)*60*60 + minuteDepartureTime*60;
                
                NSCalendar *calendarTripTime = [NSCalendar currentCalendar];
                NSDateComponents *componentsTripTime = [calendarTripTime components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:tripTime];
                int hourTripTime = [componentsTripTime hour];
                int minuteTripTime = [componentsTripTime minute];
                int intervalTripTime = hourTripTime*60*60 + minuteTripTime*60;
                if(stopTimes1 && stopTimes2){
                    if([stopTimes1.tripID isEqualToString:stopTimes2.tripID] && [stopTimes2.stopSequence intValue] > [stopTimes1.stopSequence intValue] && intervalDepartureTime >= intervalTripTime && intervalDepartureTime < intervalTripTime + TRIP_TIME_PLUS_INTERVAL  && [self isServiceEnableForTripID:stopTimes1.tripID RequestDate:parameters.originalTripDate]){
                        NIMLOG_UOS202(@"stoptimes1=%@",stopTimes1);
                        NIMLOG_UOS202(@"stoptimes2=%@",stopTimes2);
                        NSArray *arrayTemp = [NSArray arrayWithObjects:stopTimes1,stopTimes2, nil];
                        [arrMutableStopTimes addObject:arrayTemp];
                    }
                    else if([stopTimes1.tripID isEqualToString:stopTimes2.tripID] && [stopTimes2.stopSequence intValue] < [stopTimes1.stopSequence intValue] && intervalDepartureTime >= intervalTripTime && intervalDepartureTime < intervalTripTime + TRIP_TIME_PLUS_INTERVAL && [self isServiceEnableForTripID:stopTimes1.tripID RequestDate:parameters.originalTripDate]){
                        NIMLOG_UOS202(@"stoptimes1=%@",stopTimes1);
                        NIMLOG_UOS202(@"stoptimes2=%@",stopTimes2);
                        NSArray *arrayTemp = [NSArray arrayWithObjects:stopTimes2,stopTimes1, nil];
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
         logException(@"GtfsParser->timeAndDateFromString", @"", exception);
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
        //newleg = leg;
        if([[itinerary sortedLegs] count] == 0)
            newleg.startTime = itinerary.startTime;
        else
            newleg.startTime = itinerary.endTime;
        [newleg setNewlegAttributes:leg];
        newleg.endTime = [newleg.startTime dateByAddingTimeInterval:([newleg.duration floatValue]/1000)];
        itinerary.endTime = newleg.endTime;
        newleg.itinerary = itinerary;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->addUnScheduledLegToItinerary", @"", exception);
    }
}

// This method create scheduled leg from gtfs data.
// First find the nearest stoptimes then create transit leg from stoptimes data.
- (void) addScheduledLegToItinerary:(Itinerary *)itinerary TransitLeg:(Leg *)leg StopTime:(NSMutableArray *)arrStopTimes Context:(NSManagedObjectContext *)context{
    @try {
        NSArray *arrayStopTime = [self findNearestStopTimeFromStopTimeArray:arrStopTimes Itinerary:itinerary];
        GtfsStopTimes *fromStopTime = [arrayStopTime objectAtIndex:0];
        Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
        newleg.startTime = [self timeAndDateFromString:fromStopTime.departureTime];
        newleg.endTime = [newleg.startTime dateByAddingTimeInterval:([newleg.duration floatValue]/1000)];
        [newleg setNewlegAttributes:leg];
        itinerary.endTime = newleg.endTime;
        newleg.itinerary = itinerary;
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
- (void) generateItineraryFromItinerayPatern:(Itinerary *)itinerary Parameters:(PlanRequestParameters *)parameters Plan:(Plan *)plan Context:(NSManagedObjectContext *)context{
    NSMutableDictionary *dictStopTimes = [[NSMutableDictionary alloc] init];
    NSDate *startDate = [NSDate date];
    while (true) {
        if([startDate timeIntervalSinceNow] > ITINERARY_GANERATION_TIMEOUT ){
            NIMLOG_UOS202(@"Generation Of itinerary from pattern Timeout");
            break;
        }
        Itinerary* newItinerary = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:context];
        newItinerary.startTime = parameters.originalTripDate;
        newItinerary.startTimeOnly = timeOnlyFromDate(parameters.originalTripDate);
        newItinerary.plan = plan;
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
                    arrStopTime = [self getStopTimes:strTOStopID strFromStopID:strFromStopID parameters:parameters];
                    if(arrStopTime && [arrStopTime count] > 0){
                        [dictStopTimes setObject:arrStopTime forKey:leg.agencyName];
                    }
                }
                if([arrStopTime count] == 0){
                    return;
                }
                [self addScheduledLegToItinerary:newItinerary TransitLeg:leg StopTime:arrStopTime Context:context];
                [dictStopTimes setObject:arrStopTime forKey:leg.agencyName];
            }
        }
    }
}

// First get The unique itinerary pattern from plan.the loop through every itinerary pattern.
// For each legs of itinerary pattern check first if it is walk leg if yes the create new leg with some additional attributes.
// if leg is transit leg then first get the stoptimes from that leg and choose nearest stoptimes and remove it from mutable array.
// this lopp continue until we have stoptimes data.

- (Plan *)generateLegsAndItineraryFromPatternsOfPlan:(Plan *)plan parameters:(PlanRequestParameters *)parameters Context:(NSManagedObjectContext *)context{
    if(!context){
        context = self.managedObjectContext;
    }
    NSArray *arrUniquePatterns = [[plan uniqueItineraryPatterns] allObjects];
    for(int i=0;i<[arrUniquePatterns count];i++){
        Itinerary *iti = [arrUniquePatterns objectAtIndex:i];
        [self generateItineraryFromItinerayPatern:iti Parameters:parameters Plan:plan Context:context];
    }
    return plan;
}

@end

