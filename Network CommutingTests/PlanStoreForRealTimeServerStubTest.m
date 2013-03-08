//
//  PlanStoreForRealTimeServerStubTest.m
//  Nimbler SF
//
//  Created by John Canfield on 3/7/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "PlanStoreForRealTimeServerStubTest.h"

@implementation PlanStoreForRealTimeServerStubTest

@synthesize updatePlanWithNewGtfsData;
@synthesize planWouldHaveBeenUpdatedWithNewGtfsData;

// Override for testing to control whether plans get updated upon callback
- (void)updatePlansWithNewGtfsDataIfNeeded
{
    if (updatePlanWithNewGtfsData) {
        [super updatePlansWithNewGtfsDataIfNeeded];
    } else {
        planWouldHaveBeenUpdatedWithNewGtfsData = true;
    }
}

@end
