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

-(NSDate *) endTime{
    if (![super endTime]) {
        [super setEndTime:dateFromTimeString(self.toStopTime.departureTime)];
    }
    return [super endTime];
}

-(NSDate *) startTime{
    if (![super startTime]) {
        [super setStartTime:dateFromTimeString(self.fromStopTime.departureTime)];
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
