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

- (void) parseAgencyDataAndStroreToDataBase:(NSDictionary *)dictFileData{
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
            if([arraySubComponents count] > 0){
                [arrayAgencyID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayAgencyID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayAgencyName addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayAgencyName addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayAgencyURL addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayAgencyURL addObject:@""];
            }
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

- (void) parseCalendarDatesDataAndStroreToDataBase:(NSDictionary *)dictFileData{
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
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayServiceID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayServiceID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayDate addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayDate addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayExceptionType addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayExceptionType addObject:@""];
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
        NSDate *dates = [formtter dateFromString:[arrayDate objectAtIndex:i]];
        calendarDates.date = dates;
        calendarDates.exceptionType = [arrayExceptionType objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseCalendarDataAndStroreToDataBase:(NSDictionary *)dictFileData{
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
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayServiceID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayServiceID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayMonday addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayMonday addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayTuesday addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayTuesday addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayWednesday addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayWednesday addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayThursday addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayThursday addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayFriday addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayFriday addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arraySaturday addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arraySaturday addObject:@""];
            }
            if([arraySubComponents count] > 7){
                [arraySunday addObject:[arraySubComponents objectAtIndex:7]];
            }
            else{
                [arraySunday addObject:@""];
            }
            if([arraySubComponents count] > 8){
                [arrayStartDate addObject:[arraySubComponents objectAtIndex:8]];
            }
            else{
                [arrayStartDate addObject:@""];
            }
            if([arraySubComponents count] > 9){
                [arrayEndDate addObject:[arraySubComponents objectAtIndex:9]];
            }
            else{
                [arrayEndDate addObject:@""];
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
        
        NSDate *startDate = [formtter dateFromString:[arrayStartDate objectAtIndex:i]];
        NSDate *endDate = [formtter dateFromString:[arrayEndDate objectAtIndex:i]];
        calendar.startDate = startDate;
        calendar.endDate = endDate;
    }
    saveContext(self.managedObjectContext);
}

- (void) parseRoutesDataAndStroreToDataBase:(NSDictionary *)dictFileData{
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
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayRouteID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayRouteID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayRouteShortName addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayRouteShortName addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayRouteLongName addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayRouteLongName addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayRouteDesc addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayRouteDesc addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayRouteType addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayRouteType addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayRouteURL addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayRouteURL addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arrayRouteColor addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arrayRouteColor addObject:@""];
            }
            if([arraySubComponents count] > 7){
                [arrayRouteTextColor addObject:[arraySubComponents objectAtIndex:7]];
            }
            else{
                [arrayRouteTextColor addObject:@""];
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

- (void) parseStopsDataAndStroreToDataBase:(NSDictionary *)dictFileData{
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
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayStopID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayStopID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayStopName addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayStopName addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayStopDesc addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayStopDesc addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayStopLat addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayStopLat addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayStopLong addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayStopLong addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayZoneID addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayZoneID addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arrayStopURL addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arrayStopURL addObject:@""];
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

- (void) parseTripsDataAndStroreToDataBase:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsTrips" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayTrips = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    for (id trips in arrayTrips){
        [self.managedObjectContext deleteObject:trips];
    }
    
    NSMutableArray *arrayTripID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayTripHeadSign = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDirectionID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayBlockID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayShapeID = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_trips",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayTripID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayTripID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayRouteID addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayRouteID addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayServiceID addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayServiceID addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayTripHeadSign addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayTripHeadSign addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayDirectionID addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayDirectionID addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayBlockID addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayBlockID addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arrayShapeID addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arrayShapeID addObject:@""];
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

- (void) parseStopTimesAndStroreToDataBase:(NSDictionary *)dictFileData:(NSString *)strResourcePath{
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
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strAgencyIds = [arrayAgencyIds objectAtIndex:k];
            NSArray *arrayAgencyIdsComponents = [strAgencyIds componentsSeparatedByString:@"_"];
            if([arrayAgencyIdsComponents count] > 1){
                [arrayAgencyID addObject:[arrayAgencyIdsComponents objectAtIndex:0]];
            }
            else{
                [arrayAgencyID addObject:@""];
            }
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayTripID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayTripID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayArrivalTime addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayArrivalTime addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayDepartureTime addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayDepartureTime addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayStopID addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayStopID addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayStopSequence addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayStopSequence addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayPickUpType addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayPickUpType addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arrayDropOffType addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arrayDropOffType addObject:@""];
            }
            if([arraySubComponents count] > 7){
                [arrayShapeDistTraveled addObject:[arraySubComponents objectAtIndex:7]];
            }
            else{
                [arrayShapeDistTraveled addObject:@""];
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

// Find The nearest Stations
- (NSArray *)findNearestStation:(CLLocation *)toLocation{
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsStop" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayTrips = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    NSMutableArray *arrayStops = [[NSMutableArray alloc] init];
    for (int i=0;i<[arrayTrips count];i++){
        GtfsStop *stop = [arrayTrips objectAtIndex:i];
        double lat = [stop.stopLat doubleValue];
        double lng = [stop.stopLon doubleValue];
        CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        CLLocationDistance distance = distanceBetweenTwoLocation(toLocation, fromLocation);
        int nDistance = distance/1000;
        if(nDistance <= 3){
            [arrayStops addObject:stop];
        }
    }
    return arrayStops;
}

#pragma mark  GTFS Requests

// Request The Server For Agency Data.
-(void)getAgencyDatas{
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
-(void)getCalendarDates{
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
-(void)getCalendarData{
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
-(void)getRoutesData{
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
-(void)getStopsData{
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
-(void)getTripsData{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"trips",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strTripsURL = request;
        NIMLOG_OBJECT1(@"Get Trips: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getTripsData", @"", exception);
    }
}

// Request The Server For StopTimes Data.
- (void) getGtfsStopTimes:(NSMutableString *)strRequestString{
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
                        [self performSelector:@selector(parseAgencyDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getCalendarData) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getAgencyDatas) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarDatesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseCalendarDatesDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getRoutesData) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getCalendarDates) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseCalendarDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getCalendarDates) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getCalendarData) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strRoutesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseRoutesDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getStopsData) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getRoutesData) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strStopsURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseStopsDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getTripsData) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getStopsData) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strTripsURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseTripsDataAndStroreToDataBase:) withObject:res];
                    }
                    else{
                        [self performSelector:@selector(getTripsData) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strStopTimesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseStopTimesAndStroreToDataBase:res :strRequestURL];
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->didLoadResponse", @"catching TPServer Response", exception);
    }
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

// Generate The StopTimes Request Comma Separated string like agencyID_tripID
- (void)generateStopTimesRequestString:(Plan *)plan{
    NSMutableString *strRequestString = [[NSMutableString alloc] init];
    NSArray *itiArray = [plan sortedItineraries];
    for(int i=0;i<[itiArray count];i++){
        Itinerary *iti = [itiArray objectAtIndex:i];
        NSArray *legArray = [iti sortedLegs];
        for(int j=0;j<[legArray count];j++){
            Leg *leg = [legArray objectAtIndex:j];
            if(![[leg mode] isEqualToString:@"WALK"]){
                if([leg.agencyName isEqualToString:CALTRAIN_AGENCY_NAME]){
                    if(![self checkIfTripIDAndAgencyIDAlreadyExists:leg.tripId:CALTRAIN_AGENCY_IDS]){
                        [strRequestString appendFormat:@"%@_%@,",CALTRAIN_AGENCY_IDS,leg.tripId];
                    }
                }
                else if(([leg.agencyName isEqualToString:BART_AGENCY_NAME] ||[leg.agencyName isEqualToString:AIRBART_AGENCY_NAME])){
                    if(![self checkIfTripIDAndAgencyIDAlreadyExists:leg.tripId:BART_AGENCY_ID]){
                        [strRequestString appendFormat:@"%@_%@,",BART_AGENCY_ID,leg.tripId];
                    }
                }
                else if([leg.agencyName isEqualToString:SFMUNI_AGENCY_NAME]){
                    if(![self checkIfTripIDAndAgencyIDAlreadyExists:leg.tripId:SFMUNI_AGENCY_ID]){
                        [strRequestString appendFormat:@"%@_%@,",SFMUNI_AGENCY_ID,leg.tripId];
                    }
                }
                else if ([leg.agencyName isEqualToString:ACTRANSIT_AGENCY_NAME]){
                    if(![self checkIfTripIDAndAgencyIDAlreadyExists:leg.tripId:ACTRANSIT_AGENCY_ID]){
                        [strRequestString appendFormat:@"%@_%@,",ACTRANSIT_AGENCY_ID,leg.tripId];
                    }
                }
            }
        }
    }
    if([strRequestString length] > 0){
        [self getGtfsStopTimes:strRequestString];
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
    GtfsTrips *trips = [arrServiceID objectAtIndex:0];
    return trips.serviceID;
}

// Get trips Data from GtfsTrips based on tripID
- (GtfsTrips *)getTripsDataFromDatabase:(NSString *)strTripID{
    NSFetchRequest *fetchTrips = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsTrips" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strTripID,@"TRIPID",nil]];
    NSArray * arrServiceID = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    GtfsTrips *trips = [arrServiceID objectAtIndex:0];
    return trips;
}


// Get stops Data from GtfsStop based on stopID
- (GtfsStop *)getStopsDataFromDatabase:(NSString *)strStopID{
    NSFetchRequest *fetchStops = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStop" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strStopID,@"STOPID",nil]];
    NSArray * arrServiceID = [self.managedObjectContext executeFetchRequest:fetchStops error:nil];
    GtfsStop *stops = [arrServiceID objectAtIndex:0];
    return stops;
}

// Get routes Data from GtfsRoutes based on routeID
- (GtfsRoutes *)getRoutesDataFromDatabase:(NSString *)strRouteID{
    NSFetchRequest *fetchRoutes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsRouteByRouteID" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strRouteID,@"ROUTEID",nil]];
    NSArray * arrServiceID = [self.managedObjectContext executeFetchRequest:fetchRoutes error:nil];
    GtfsRoutes *routes = [arrServiceID objectAtIndex:0];
    return routes;
    
}

// Get Calendar Data from GtfsCalendar based on serviceID
- (GtfsCalendar *)getCalendarDataFromDatabase:(NSString *)strServiceID{
    NSFetchRequest *fetchCalendar = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsCalendar" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strServiceID,@"SERVICEID",nil]];
    NSArray * arrServiceID = [managedObjectContext executeFetchRequest:fetchCalendar error:nil];
    GtfsCalendar *calendar = [arrServiceID objectAtIndex:0];
    return calendar;
    
}
// This method get the serviceId based on tripId.
// Then get the calendar data for particular serviceID.
// the check for the request date comes after service start date and comes befor enddate.
// then check service is enabled on request day if yes then return yes otherwise return no.
- (BOOL) isServiceEnableForDay:(NSString *)strTripID:(NSDate *)requestDate{
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

// first get stoptimes from StopTimes Table based on stopId
// Then make a pair of StopTimes if both stoptimes have same tripId then check for the stopSequence and the departure time is greater than request trip time and also check if service is enabled for that stopTimes if yes the add both stopTimes as To/From StopTimes pair.

- (NSArray *)getStopTimes:(NSString *)strToStopID:(NSString *)strFromStopID:(PlanRequestParameters *)parameters{
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
            NSDate *tripTime = timeOnlyFromDate(parameters.thisRequestTripDate);
            
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
                if([stopTimes1.tripID isEqualToString:stopTimes2.tripID] && [stopTimes2.stopSequence intValue] > [stopTimes1.stopSequence intValue] && intervalDepartureTime >= intervalTripTime&& [self isServiceEnableForDay:stopTimes1.tripID :parameters.thisRequestTripDate]){
                    NSArray *arrayTemp = [NSArray arrayWithObjects:stopTimes1,stopTimes2, nil];
                    [arrMutableStopTimes addObject:arrayTemp];
                }
                else if([stopTimes1.tripID isEqualToString:stopTimes2.tripID] && [stopTimes2.stopSequence intValue] < [stopTimes1.stopSequence intValue] && intervalDepartureTime >= intervalTripTime&& [self isServiceEnableForDay:stopTimes1.tripID :parameters.thisRequestTripDate]){
                    NSArray *arrayTemp = [NSArray arrayWithObjects:stopTimes2,stopTimes1, nil];
                    [arrMutableStopTimes addObject:arrayTemp];
                }
            }
        }
    }
    return arrMutableStopTimes;
}


// TODO: Need to sort the stopTimes array according to departureTime. Then take first stopTimes from leg and call initWithToStopTime method to set from&toStopTime and save leg.

// Get Stored Patterns fron Database
// Get The StopId From Stop Table and then get stoptimes according to stopID from StopTimes Table.
- (void)generateLegsFromPatterns:(Plan *)plan:(PlanRequestParameters *)parameters{
    NSArray *arrUniquePatterns = [[plan uniqueItineraryPatterns] allObjects];
    for(int i=0;i<[arrUniquePatterns count];i++){
        Itinerary *iti = [arrUniquePatterns objectAtIndex:i];
        for(int j=0;j<[[iti sortedLegs] count];j++){
            Leg *leg = [[iti sortedLegs] objectAtIndex:j];
            if(![leg.mode isEqualToString:@"WALK"]){
                NSString *strTOStopID = [self getTheStopIDAccrodingToStation:leg.to.lat:leg.to.lng];
                NSString *strFromStopID = [self getTheStopIDAccrodingToStation:leg.from.lat:leg.from.lng];
                NSArray *arrStopTimes = [self getStopTimes:strTOStopID :strFromStopID:parameters];
            }
        }
    }
}

@end

