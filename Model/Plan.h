//
//  Plan.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/Restkit.h>
#import "PlanPlace.h"
#import "Itinerary.h"
#import "Location.h"
#import "PlanRequestChunk.h"
#import "TransitCalendar.h"
#import "PlanRequestParameters.h"
#import "enums.h"

@class RouteExcludeSettings;

@protocol PlanRequestMoreItinerariesDelegate

@required
/**
 * Callback routines that returnSortedItinerariesWithMatchesForDate calls when it detects the need for 
 * more OTP or GTFS itineraries
 */
-(void)requestMoreOTPItinerariesFor:(Plan *)plan withParameters:(PlanRequestParameters *)parameters;
-(void)requestMoreGTFSItinerariesFor:(Plan *)plan itineraryPattern:(Itinerary *)itineraryPattern tripDate:(NSDate *)tripDate;
@end


@interface Plan : NSManagedObject

@property(nonatomic, strong) NSDate *date;  // Date returned by OTP for the original OTP call
@property(nonatomic, strong) NSDate *lastUpdatedFromServer; // last time any part of the Plan was updated from the server (does not mean every aspect of the plan is current to that date)
#define PLAN_LAST_UPDATED_FROM_SERVER_KEY   @"lastUpdatedFromServer"
@property(nonatomic, retain) NSString *planId;
@property(nonatomic,strong) PlanPlace *fromPlanPlace;
@property(nonatomic,strong) PlanPlace *toPlanPlace;
@property(nonatomic,strong) NSSet *itineraries;
#define PLAN_ITINERARIES_KEY       @"itineraries"  
@property(nonatomic,strong) NSSet *uniqueItineraryPatterns;  // Subset of itineraries that are a unique routing pattern
@property(nonatomic,strong) Location *fromLocation;
@property(nonatomic,strong) Location *toLocation;
@property (strong, nonatomic) NSSet *requestChunks; // PlanRequestChunks associated with the Plan

@property(nonatomic,strong,readonly) NSDate* userRequestDate; // Latest requested date by user (could be for cached recall)
@property(nonatomic,readonly) DepartOrArrive userRequestDepartOrArrive; // Latest DepartOrArrive (could be for cached call)
@property(nonatomic,strong) NSArray *sortedItineraries;  // Array of ordered itineraries (not stored in Core Data) relevant to the userRequestDate and userRequestDepartOrArrive.  Could be subset if a cached call
@property(nonatomic, strong) TransitCalendar* transitCalendar;



// Methods

+ (RKManagedObjectMapping *)objectMappingforPlanner:(APIType)tpt;


// Add itin0 to the plan (without any checking, see above to check first)
- (void)addItinerary:(Itinerary *) itin0;

// Delete itin0 from the plan and from Core Data
- (void)deleteItinerary:(Itinerary *)itin0;

- (NSString *)ncDescription;
- (void)sortItineraries;  // Create the sorted array of itineraries (sorted by startTimeOnly)


// Returns an array of itineraries sorted by date that have the
// StartTimeOnly field between fromTimeOnly to toTimeOnly
// If no matches, then returns 0 element array.  If nil parameters or fetch error, returns nil
- (NSArray *)fetchItinerariesFromTimeOnly:(NSDate *)fromTimeOnly toTimeOnly:(NSDate *)toTimeOnly;

//
// Plan Request Cache management
//

// consolidateIntoSelfPlan
// If plan0 fromLocation and toLocation are the same as referring object's...
// Consolidates plan0 itineraries and PlanRequestChunks into referring Plan
// Then deletes plan0 from the database
- (void)consolidateIntoSelfPlan:(Plan *)plan0;

// If itin0 is a new itinerary that does not exist in the referencing Plan, then add itin0 the referencing Plan
// If itin0 is the same as an existing itinerary in the referencing Plan, then keep the more current itinerary and delete the older one
// Returns the result of the itinerary comparison (see Itinerary.h for enum definition)
- (ItineraryCompareResult) addItineraryIfNew:(Itinerary *)itin0;


// Initialization method after a plan is freshly loaded from an OTP request
// Initialization includes creating request chunks, startTimeOnly and endTimeOnly variables, and
// computing uniqueItineraries
- (void)initializeNewPlanFromOTPWithRequestDate:(NSDate *)requestDate
                                 departOrArrive:(DepartOrArrive)depOrArrive
                           routeExcludeSettings:(RouteExcludeSettings *)routeExcludeSettings;

// Looks for matching itineraries for the requestDate and departOrArrive
// routeExcludeSettings specifies which routes / modes the user specifically wants to include/exclude from results
// callBack is called if the method detects that we need more OTP or gtfs itineraries to show the user
// If it finds some, returns TRUE and updates the sortedItineraries property with just those itineraries
// If it does not find any, returns false and leaves sortedItineraries unchanged
- (BOOL)prepareSortedItinerariesWithMatchesForDate:(NSDate *)requestDate
                                    departOrArrive:(DepartOrArrive)depOrArrive
                               RouteExcludeSettings:(RouteExcludeSettings *)routeExcludeSettings
                                          callBack:(id <PlanRequestMoreItinerariesDelegate>)delegate;


// Variant of the above method without using an includeExcludeDictionary or callback
- (BOOL)prepareSortedItinerariesWithMatchesForDate:(NSDate *)requestDate
                                    departOrArrive:(DepartOrArrive)depOrArrive;


// returnSortedItinerariesWithMatchesForDate  -- part of Plan Caching (US78) implementation
// returnSortedItinerariesWithMatchesForDate  -- part of Plan Caching (US78) implementation
// Helper routine called by prepareSortedItinerariesWithMatchesForDate
// Looks for matching itineraries for the requestDate and departOrArrive
// routeExcludeSettings specifies which routes / modes the user specifically wants to include/exclude from results
// callBack is called if the method detects that we need more OTP or gtfs itineraries to show the user
// If it finds some itineraries, returns a sorted array of the matching itineraries
// Returned array will have no more than planMaxItinerariesToShow itineraries, spanning no more
// than planMaxTimeForResultsToShow seconds.
// It will include itineraries starting up to planBufferSecondsBeforeItinerary before requestDate
// If there are no matching itineraries, returns nil
- (NSArray *)returnSortedItinerariesWithMatchesForDate:(NSDate *)requestDate
                                        departOrArrive:(DepartOrArrive)depOrArrive
                                   RouteExcludeSettings:(RouteExcludeSettings *)routeExcludeSettings
                                              callBack:(id <PlanRequestMoreItinerariesDelegate>)delegate
                              planMaxItinerariesToShow:(int)planMaxItinerariesToShow
                      planBufferSecondsBeforeItinerary:(int)planBufferSecondsBeforeItinerary
                           planMaxTimeForResultsToShow:(int)planMaxTimeForResultsToShow;


// Variant of the above method without using an includeExcludeDictionary or callback
- (NSArray *)returnSortedItinerariesWithMatchesForDate:(NSDate *)requestDate
                                        departOrArrive:(DepartOrArrive)depOrArrive
                              planMaxItinerariesToShow:(int)planMaxItinerariesToShow
                      planBufferSecondsBeforeItinerary:(int)planBufferSecondsBeforeItinerary
                           planMaxTimeForResultsToShow:(int)planMaxTimeForResultsToShow;

// Returns unique Itineraries array from plan sorted by StartDates
- (NSArray *)uniqueItineraries;

// Generate 16 character random string and set it as legId for scheduled leg.
- (void) setLegsId;

// Remove duplicate itineraries from plan
- (void) removeDuplicateItineraries;

- (NSDictionary *) returnUniqueButtonTitle;
@end

