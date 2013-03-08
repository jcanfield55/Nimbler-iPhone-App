//
//  PlanStoreForRealTimeServerStubTest.h
//  Nimbler SF
//
//  Created by John Canfield on 3/7/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//
// Test child class of PlanStore that overrides the callback for calling more objects

#import <CoreData/CoreData.h>
#import "PlanStore.h"

@interface PlanStoreForRealTimeServerStubTest : PlanStore

@property (nonatomic) BOOL updatePlanWithNewGtfsData;   // if false, do not update plan when newGtfsData arrives
@property (nonatomic) BOOL planWouldHaveBeenUpdatedWithNewGtfsData;  // True when updating plan has been skipped when new Gtfs data arrives
@end
