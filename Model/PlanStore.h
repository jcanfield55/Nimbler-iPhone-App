//
//  PlanStore.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/19/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

// This object is a wrapper for access and manipulating the set of Plan managed objects
// in Core Data

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "Plan.h"
#import "RouteOptionsViewController.h"
#import "ToFromViewController.h"
#import "PlanRequestParameters.h"


@interface PlanStore : NSObject <RKObjectLoaderDelegate,RKRequestDelegate, PlanRequestMoreItinerariesDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) RKObjectManager *rkPlanMgr;  // RestKit object manager for trip planning
@property (unsafe_unretained, nonatomic) ToFromViewController *toFromVC;
@property (unsafe_unretained, nonatomic) RouteOptionsViewController *routeOptionsVC;

// Designated initializer
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkPlanMgr:(RKObjectManager *)rkP;

// Requests a plan with the given parameters
// Will get plan from the cache if available and will call OTP if not
// Will call back the newPlanAvailable method on toFromVC when the first plan is available
// Will continue to call OTP iteratively to obtain other itineraries up to the designated max # and time
// After returning the first itinerary, it will call the newPlanAvailable method on routeOptionsVC each
// time it has an update
- (void)requestPlanWithParameters:(PlanRequestParameters *)parameters;

// Fetches array of plans going to the same to & from Location
// Normally will return just one plan, but could return more if the plans have not been consolidated
- (NSArray *)fetchPlansWithToLocation:(Location *)toLocation fromLocation:(Location *)fromLocation;


// Takes a new plan and consolidates it with other plans going to the same to & from locations.
// Returns the consolidated plan
- (Plan *)consolidateWithMatchingPlans:(Plan *)plan0;

- (void)clearCache;
-(void)requestPlanFromOtpWithParameters:(PlanRequestParameters *)parameters;

// get the route name string like KT,caltrain-loc etc from plan
- (NSArray *) getUniqueRouteName:(Plan *)plan;
@end