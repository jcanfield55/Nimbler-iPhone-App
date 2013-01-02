//
//  LegFromGtfs.h
//  Nimbler Caltrain
//
//  Created by macmini on 02/01/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Leg.h"

@class GtfsStopTimes;

@interface LegFromGtfs : Leg

@property (nonatomic, strong) GtfsStopTimes *fromStopTime;
@property (nonatomic, strong) GtfsStopTimes *toStopTime;

// Initialize new LegFromGtfs
- (id)initWithToStopTime:(GtfsStopTimes *)toStopTime0 fromStopTime:(GtfsStopTimes *)fromStopTime0;
@end
