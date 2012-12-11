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
#import "GtfsCalendar.h"
#import "GtfsRoutes.h"
#import "GtfsStop.h"
#import "GtfsTrips.h"

@implementation GtfsParser

@synthesize managedObjectContext;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        self.managedObjectContext = moc;
    }
    
    return self;
}

- (void) parseAgencyDataAndStroreToDataBase:(NSDictionary *)dictFileData{
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
    [formtter setDateFormat:@"YYYMMdd"];
    for(int i=0;i<[arrayServiceID count];i++){
        GtfsCalendarDates* calendarDates = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsCalendarDates" inManagedObjectContext:self.managedObjectContext];
        calendarDates.serviceID = [arrayServiceID objectAtIndex:i];
        NSDate *dates = [formtter dateFromString:[arrayDate objectAtIndex:i]];
        calendarDates.date = dates;
        calendarDates.exceptionType = [arrayExceptionType objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseCalendarDataAndStroreToDataBase:(NSDictionary *)dictFileData{
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
    [formtter setDateFormat:@"YYYMMdd"];
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
        calendar.startDate = endDate;
    }
    saveContext(self.managedObjectContext);
}

- (void) parseRoutesDataAndStroreToDataBase:(NSDictionary *)dictFileData{
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
        GtfsTrips* routes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsTrips" inManagedObjectContext:self.managedObjectContext];
        routes.tripID = [arrayTripID objectAtIndex:i];
        routes.routeID = [arrayRouteID objectAtIndex:i];
        routes.serviceID = [arrayServiceID objectAtIndex:i];
        routes.tripHeadSign = [arrayTripHeadSign objectAtIndex:i];
        routes.directionID = [arrayDirectionID objectAtIndex:i];
        routes.blockID = [arrayBlockID objectAtIndex:i];
        routes.shapeID = [arrayShapeID objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

@end
