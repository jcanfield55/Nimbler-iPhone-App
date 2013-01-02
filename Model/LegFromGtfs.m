//
//  LegFromGtfs.m
//  Nimbler Caltrain
//
//  Created by macmini on 02/01/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "LegFromGtfs.h"
#import "GtfsStopTimes.h"
#import "GtfsTrips.h"
#import "GtfsRoutes.h"
#import "UtilityFunctions.h"


@implementation LegFromGtfs

@dynamic fromStopTime;
@dynamic toStopTime;

// Initialize new LegFromGtfs
- (id)initWithToStopTime:(GtfsStopTimes *)toStopTime0 fromStopTime:(GtfsStopTimes *)fromStopTime0
{
    self = [super init];
    if (!self) {
        self.toStopTime = toStopTime0;
        self.fromStopTime = fromStopTime0;
    }
    return self;
}

// Create an accessor for each property of Leg to retrieve the needed info from GTFS and/or real-time data
// For example, here is the accessor for routeLongName
-(NSString *)routeLongName {
    if (![super routeLongName]) {
        [super setRouteLongName:self.toStopTime.trips.route.routeLongname];
    }
    return [super routeLongName];
}

-(NSString *)routeShortName {
    if (![super routeShortName]) {
        [super setRouteShortName:self.toStopTime.trips.route.routeShortName];
    }
    return [super routeShortName];
}

-(NSString *)agencyId {
    if (![super agencyId]) {
        [super setAgencyId:self.toStopTime.agencyID];
    }
    return [super agencyId];
}

-(NSString *)headSign {
    if (![super headSign]) {
        [super setHeadSign:self.toStopTime.trips.tripHeadSign];
    }
    return [super headSign];
}

- (NSDate *)timeAndDateFromString:(NSString *)strTime{
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
-(NSDate *) endTime{
    if (![super endTime]) {
        [super setEndTime:[self timeAndDateFromString:self.toStopTime.departureTime]];
    }
    return [super endTime];
}

-(NSDate *) startTime{
    if (![super startTime]) {
        [super setStartTime:[self timeAndDateFromString:self.fromStopTime.departureTime]];
    }
    return [super startTime];
}

-(NSString *) tripId{
    if (![super tripId]) {
        [super setTripId:self.toStopTime.tripID];
    }
    return [super tripId];
}


@end
