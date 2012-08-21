//
//  Plan.h
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/Restkit.h>
#import "PlanPlace.h"
#import "Itinerary.h"
#import "Location.h"
#import "PlanRequestCache.h"
#import "enums.h"

@interface Plan : NSManagedObject

@property(nonatomic, strong) NSDate *date;  // Date returned by OTP for the original OTP call
@property(nonatomic, strong) NSDate *lastUpdatedFromServer; // last time any part of the Plan was updated from the server (does not mean every aspect of the plan is current to that date)
#define PLAN_LAST_UPDATED_FROM_SERVER_KEY   @"lastUpdatedFromServer"
@property(nonatomic, retain) NSString *planId;
@property(nonatomic,strong) PlanPlace *fromPlanPlace;
@property(nonatomic,strong) PlanPlace *toPlanPlace;
@property(nonatomic,strong) NSSet *itineraries;
#define PLAN_ITINERARIES_KEY       @"itineraries"   
@property(nonatomic,strong) Location *fromLocation;
@property(nonatomic,strong) Location *toLocation;
@property(nonatomic,strong,readonly) PlanRequestCache *planRequestCache;  // Use this property instead of planRequestCacheRaw
@property(nonatomic,strong) PlanRequestCache *planRequestCacheRaw; // Use planRequestCache instead of this property
@property(nonatomic,strong,readonly) NSDate* userRequestDate; // Latest requested date by user (could be for cached recall)
@property(nonatomic,readonly) DepartOrArrive userRequestDepartOrArrive; // Latest DepartOrArrive (could be for cached call)
@property(nonatomic,strong) NSArray *sortedItineraries;  // Array of ordered itineraries (not stored in Core Data) relevant to the userRequestDate and userRequestDepartOrArrive.  Could be subset if a cached call


// Methods

+ (RKManagedObjectMapping *)objectMappingforPlanner:(APIType)tpt;

// If itin0 is a new itinerary that does not exist in the referencing Plan, then add itin0 the referencing Plan
// If itin0 is the same as an existing itinerary in the referencing Plan, then keep the more current itinerary and delete the older one
// Returns the result of the itinerary comparison (see Itinerary.h for enum definition)
- (ItineraryCompareResult) addItineraryIfNew:(Itinerary *)itin0;

// Add itin0 to the plan (without any checking, see above to check first)
- (void)addItinerary:(Itinerary *) itin0;

// Remove itin0 from the plan and from Core Data
- (void)removeItinerary:(Itinerary *)itin0;

// Initialization method after a plan is freshly loaded from an OTP request
- (void)initPlanRequestCacheWithRequestDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive;


- (NSString *)ncDescription;
- (void)sortItineraries;  // Re-sorts the itineraries array
@end
