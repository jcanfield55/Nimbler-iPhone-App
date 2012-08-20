//
//  PlanStore.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/19/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

// This object is a wrapper for access and manipulating the set of Plan managed objects
// in Core Data

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "Plan.h"

@interface PlanStore : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) RKObjectManager *rkPlanMgr;  // RestKit object manager for trip planning

// Designated initializer
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkPlanMgr:(RKObjectManager *)rkP;

// Fetches array of plans going to the same to & from Location
// Normally will return just one plan, but could return more if the plans have not been consolidated
- (NSArray *)fetchPlansWithToLocation:(Location *)toLocation fromLocation:(Location *)fromLocation;


// Takes a new plan and consolidates it with other plans going to the same to & from locations.
// Returns the consolidated plan
- (Plan *)consolidateWithMatchingPlans:(Plan *)plan0;

@end