//
//  LegFromGtfs.m
//  Nimbler Caltrain
//
//  Created by macmini on 30/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LegFromGtfs.h"
#import "GtfsTrips.h"
#import "GtfsRoutes.h"



@implementation LegFromGtfs

@dynamic toStopTime;
@dynamic fromStopTime;


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
@end
