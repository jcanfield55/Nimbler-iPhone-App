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
#import "PlanRequestParameters.h"
#import "UberMgr.h"

typedef enum {
    NO_MORE_ITINERARIES_REQUESTED,
    MORE_ITINERARIES_REQUESTED_SAME_EXCLUDES,     // Indicates no changes to the RouteExcludeSettings compared to the previous request
    MORE_ITINERARIES_REQUESTED_DIFFERENT_EXCLUDES, // Indicates this is the first OTP request for these parameters, or this request has different RouteExcludeSettings than the last
    MORE_ITINERARIES_REQUESTED_NO_EXCLUDES  // Indicates that no excludes have been chosen
} MoreItineraryStatus;

@interface PlanStore : NSObject <RKObjectLoaderDelegate,RKRequestDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) RKObjectManager *rkPlanMgr;  // RestKit object manager for trip planning
@property (strong, nonatomic) NSMutableSet* plansWaitingForGtfsData;  // Set of plans with outstanding gtfsParsingRequests
@property (strong,nonatomic)  RKClient *rkTPClient;
@property (strong, nonatomic) NSString *legsURL;
@property (strong, nonatomic) NSArray *fromToStopID;
@property (nonatomic) BOOL stopTimesLoadSuccessfully;
@property (nonatomic, strong) NSDictionary *legLegIdDictionary;
@property (nonatomic, strong) UberMgr *uberMgr;

// Designated initializer
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkPlanMgr:(RKObjectManager *)rkP rkTpClient:(RKClient *)rkTpClient;

// Requests a plan with the given parameters
// Will get plan from the cache if available and will call OTP if not
// Will call back the newPlanAvailable method on toFromVC when the first plan is available
// Will continue to call OTP iteratively to obtain other itineraries up to the designated max # and time
// After returning the first itinerary, it will call the newPlanAvailable method on routeOptionsVC each
// time it has an update
- (void)requestPlanWithParameters:(PlanRequestParameters *)parameters;

// Checks if more itineraries are needed for this plan, and if so requests them from the server
-(MoreItineraryStatus)requestMoreItinerariesIfNeeded:(Plan *)plan parameters:(PlanRequestParameters *)requestParams0;

// Fetches array of plans going to the same to & from Location
// Normally will return just one plan, but could return more if the plans have not been consolidated
- (NSArray *)fetchPlansWithToLocation:(Location *)toLocation fromLocation:(Location *)fromLocation;


// Takes a new plan and consolidates it with other plans going to the same to & from locations.
// Returns the consolidated plan
- (Plan *)consolidateWithMatchingPlans:(Plan *)plan0;

- (void)clearCache;
- (void)clearCacheForBikePref;

// Requests for a new plan from OTP using parameters
// If exclSettingArray is nil, will not exclude any routes in the OTP request
// To exclude routes, set exclSettingArray to an array of RouteExcludeSetting objects as returned by RouteExcludeSettings -> excludeSettingsForPlan
-(void)requestPlanFromOtpWithParameters:(PlanRequestParameters *)parameters
               routeExcludeSettingArray:(NSArray *)exclSettingArray;

// Called when there is an update of gtfsData
// Checks whether any plans with outstanding gtfsParsingRequests now have all the data they need.
// If so, updates those plans (using prepareSortedItinaries) and calls their planDestination
- (void)updatePlansWithNewGtfsDataIfNeeded;

- (void) requestStopTimesForItineraryPatterns:(NSDate *)tripDate Plan:(Plan *)plan;
@end