//
//  LegFromGtfs.h
//  Nimbler Caltrain
//
//  Created by macmini on 30/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Leg.h"
#import "GtfsStopTimes.h"



@interface LegFromGtfs : Leg

@property(nonatomic,strong) GtfsStopTimes* fromStopTime; // origin stopTime used to compute this leg (if transit).  Null otherwise
@property(nonatomic,strong) GtfsStopTimes* toStopTime; // destination stopTime used to compute this leg (if transit).  Null otherwise.

// Initialize new LegFromGtfs
- (id)initWithToStopTime:(GtfsStopTimes *)toStopTime0 fromStopTime:(GtfsStopTimes *)fromStopTime0;


@end
