//
//  PlanStore.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/19/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "PlanStore.h"
#import "UtilityFunctions.h"

#if FLURRY_ENABLED
#include "Flurry.h"
#endif

@interface PlanStore()
{
    // Variables for internal use
    NSString *planURLResource; // URL resource sent to planner
    NSDateFormatter* dateFormatter; // date formatter for OTP requests
    NSDateFormatter* timeFormatter; // time formatter for OTP requests
    NSMutableDictionary* parametersByPlanURLResource; // Key is the planURLResource, object = request parameters
}

// Internal methods
-(void)requestPlanFromOtpWithParameters:(PlanRequestParameters *)parameters;
-(void)requestMoreItinerariesIfNeeded:(Plan *)matchingPlan parameters:(PlanRequestParameters *)requestParams0;


@end

@implementation PlanStore

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize rkPlanMgr;
@synthesize toFromVC;
@synthesize routeOptionsVC;


// Designated initializer
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkPlanMgr:(RKObjectManager *)rkP
{
    self = [super init];
    if (self) {
        managedObjectContext = moc;
        managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
        rkPlanMgr = rkP;
        parametersByPlanURLResource = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    
    return self;
}

// Requests a plan with the given parameters
// Will get plan from the cache if available and will call OTP if not
// Will call back the newPlanAvailable method on toFromVC when the first plan is available
// Will continue to call OTP iteratively to obtain other itineraries up to the designated max # and time
// After returning the first itinerary, it will call the newPlanAvailable method on routeOptionsVC each
// time it has an update
- (void)requestPlanWithParameters:(PlanRequestParameters *)parameters
{
    
    // Check if we have a stored plan that we can use
    NSArray* matchingPlanArray = [self fetchPlansWithToLocation:[parameters toLocation]
                                                   fromLocation:[parameters fromLocation]];
    
    if (matchingPlanArray && [matchingPlanArray count]>0) {
        Plan* matchingPlan = [matchingPlanArray objectAtIndex:0]; // Take the first matching plan
        
        if ([matchingPlan prepareSortedItinerariesWithMatchesForDate:[parameters originalTripDate]
                                                      departOrArrive:[parameters departOrArrive]]) {
            NSLog(@"Matches found in plan cache");
#if FLURRY_ENABLED
            NSDictionary *flurryParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                          FLURRY_FROM_SELECTED_ADDRESS, [parameters.fromLocation shortFormattedAddress],
                                          FLURRY_TO_SELECTED_ADDRESS, [parameters.toLocation shortFormattedAddress],
                                          nil];
            [Flurry logEvent: FLURRY_ROUTE_FROM_CACHE withParameters:flurryParams];
#endif
            [self requestMoreItinerariesIfNeeded:matchingPlan parameters:parameters];
            PlanRequestStatus status = STATUS_OK;
            if (parameters.planDestination == PLAN_DESTINATION_ROUTE_OPTIONS_VC) {
                [routeOptionsVC newPlanAvailable:matchingPlan status:status];
            } else {
                [toFromVC newPlanAvailable:matchingPlan status:status];
            }
            return;
        }
    }
    // if no appropriate plan in cache, request one from OTP
#if FLURRY_ENABLED
    NSDictionary *flurryParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                  FLURRY_FROM_SELECTED_ADDRESS, [parameters.fromLocation shortFormattedAddress],
                                  FLURRY_TO_SELECTED_ADDRESS, [parameters.toLocation shortFormattedAddress],
                                  nil];
    [Flurry logEvent: FLURRY_ROUTE_NOT_IN_CACHE withParameters:flurryParams];
#endif
    [self requestPlanFromOtpWithParameters:parameters];
}


// Requests for a new plan from OTP
-(void)requestPlanFromOtpWithParameters:(PlanRequestParameters *)parameters
{
    // Create the date formatters we will use to output the date & time
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    }
    if (!timeFormatter) {
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    }
    
    // Build the parameters into a resource string
    NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                            @"fromPlace", [[parameters fromLocation] latLngPairStr],
                            @"toPlace", [[parameters toLocation] latLngPairStr],
                            @"date", [dateFormatter stringFromDate:[parameters thisRequestTripDate]],
                            @"time", [timeFormatter stringFromDate:[parameters thisRequestTripDate]],
                            @"arriveBy", (([parameters departOrArrive] == ARRIVE) ? @"true" : @"false"),
                            @"maxWalkDistance", [NSNumber numberWithInt:[parameters maxWalkDistance]],
                            nil];
    
    parameters.serverCallsSoFar = parameters.serverCallsSoFar + 1;
    // TODO handle changes to maxWalkDistance with plan caching
    
    planURLResource = [@"plan" appendQueryParams:params];
    [parametersByPlanURLResource setObject:parameters forKey:planURLResource];
    NSLog(@"Plan resource: %@", planURLResource);
    
    // Call the trip planner
    [rkPlanMgr loadObjectsAtResourcePath:planURLResource delegate:self];
}


// Delegate methods for when the RestKit has results from the Planner
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects
{
    {
        NSInteger statusCode = [[objectLoader response] statusCode];
        NSLog(@"Planning HTTP status code = %d", statusCode);
        PlanRequestParameters* parameters;
        @try {
            if (objects && [objects objectAtIndex:0]) {
                Plan* plan = [objects objectAtIndex:0];
                NSString* resourcePath = [objectLoader resourcePath];
                parameters = [parametersByPlanURLResource objectForKey:resourcePath];
                
                // Initialize the rest of the Plan and save context
                [plan setToLocation:[parameters toLocation]];
                [plan setFromLocation:[parameters fromLocation]];
                [plan createRequestChunkWithAllItinerariesAndRequestDate:[parameters thisRequestTripDate]
                                                          departOrArrive:[parameters departOrArrive]];
                saveContext(managedObjectContext);  // Save location and request chunk changes
                plan = [self consolidateWithMatchingPlans:plan]; // Consolidate plans & save context
                
                // Now format the itineraries of the consolidated plan
                [plan prepareSortedItinerariesWithMatchesForDate:[parameters originalTripDate] departOrArrive:[parameters departOrArrive]];
                [self requestMoreItinerariesIfNeeded:plan parameters:parameters];
                
                // Call-back the appropriate RouteOptions VC with the new plan
                if (parameters.planDestination == PLAN_DESTINATION_ROUTE_OPTIONS_VC) {
                    [routeOptionsVC newPlanAvailable:plan status:STATUS_OK];  
                } else {
                    [toFromVC newPlanAvailable:plan status:STATUS_OK];
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Exception while parsing TP response plan: %@", exception);
            if (parameters && parameters.planDestination == PLAN_DESTINATION_TO_FROM_VC) {
                [toFromVC newPlanAvailable:nil status:GENERIC_EXCEPTION];
            }
            // else if not a toFromViewController request, do not bother the user
        }
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    NSLog(@"Error received from RKObjectManager: %@", error);
    [toFromVC newPlanAvailable:nil status:GENERIC_EXCEPTION];
}

// Checks if more itineraries are needed for this plan, and if so requests them from the server
-(void)requestMoreItinerariesIfNeeded:(Plan *)plan parameters:(PlanRequestParameters *)requestParams0
{
    if (requestParams0.serverCallsSoFar >= PLAN_MAX_SERVER_CALLS_PER_REQUEST) {
        return; // Return if we have already made the max number of calls
    }
    // Request sortedItineraries array with extremely large limits
    NSArray* testItinArray = [plan returnSortedItinerariesWithMatchesForDate:requestParams0.originalTripDate
                                                              departOrArrive:requestParams0.departOrArrive
                                                    planMaxItinerariesToShow:1000
                                            planBufferSecondsBeforeItinerary:PLAN_BUFFER_SECONDS_BEFORE_ITINERARY
                                                 planMaxTimeForResultsToShow:(1000*60*60)];
    if (!testItinArray) {
        NSLog(@"No sortedItineraries in plan in requestMoreItinerariesIfNeeded");
        return; // return if there are no matching itineraries in the original request
    }
    PlanRequestParameters* params = [PlanRequestParameters copyOfPlanRequestParameters:requestParams0];
    NSDate* firstItinTimeOnly = timeOnlyFromDate([[testItinArray objectAtIndex:0] startTime]);
    NSDate* lastItinTimeOnly = timeOnlyFromDate([[testItinArray lastObject] startTime]);
    if ([testItinArray count] < PLAN_MAX_ITINERARIES_TO_SHOW &&
        [lastItinTimeOnly timeIntervalSinceDate:firstItinTimeOnly] < PLAN_MAX_TIME_FOR_RESULTS_TO_SHOW) {
        // If we are below our max parameters
        params.planDestination = PLAN_DESTINATION_ROUTE_OPTIONS_VC;
        if (params.departOrArrive == DEPART) {
            params.thisRequestTripDate = addDateOnlyWithTimeOnly(dateOnlyFromDate(params.thisRequestTripDate),
                                                      [NSDate dateWithTimeInterval:PLAN_NEXT_REQUEST_TIME_INTERVAL_SECONDS
                                                                         sinceDate:lastItinTimeOnly]);
        } else { // departOrArrive = ARRIVE
            NSDate* firstItinEndTimeOnly = timeOnlyFromDate([[testItinArray objectAtIndex:0] endTime]);
            params.thisRequestTripDate = addDateOnlyWithTimeOnly(dateOnlyFromDate(params.thisRequestTripDate),
                                                      [NSDate dateWithTimeInterval:(-PLAN_NEXT_REQUEST_TIME_INTERVAL_SECONDS)
                                                                         sinceDate:firstItinEndTimeOnly]);
        }
        NSLog(@"Requesting additional plan with parameters: %@", params);
        [self requestPlanFromOtpWithParameters:params];
    }
}


// Fetches array of plans going to the same to & from Location from the cache
// Normally will return just one plan, but could return more if the plans have not been consolidated
// Plans are sorted starting with the latest (most current) plan first
- (NSArray *)fetchPlansWithToLocation:(Location *)toLocation fromLocation:(Location *)fromLocation
{
    if (!fromLocation || !toLocation) {
        return nil;
    }
    NSDictionary* fetchParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [fromLocation formattedAddress],@"FROM_FORMATTED_ADDRESS",
                                     [toLocation formattedAddress], @"TO_FORMATTED_ADDRESS", nil];
    NSFetchRequest* request = [managedObjectModel
                               fetchRequestFromTemplateWithName:@"PlansByToAndFromLocations"
                               substitutionVariables:fetchParameters];
    NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:PLAN_LAST_UPDATED_FROM_SERVER_KEY
                                                          ascending:NO]; // Later plan first
    [request setSortDescriptors:[NSArray arrayWithObject:sd1]];
    
    NSError *error;
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error];
    if (!result) {
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]];
    }
    return result;  // Return the array of matches (could be empty)
}


// Takes a new plan and consolidates it with other plans going to the same to & from locations.
// Assumes that plan0 is a newly retrieved Plan (and thus is newer than any of its matching plans)
// Returns the consolidated plan
- (Plan *)consolidateWithMatchingPlans:(Plan *)plan0
{
    NSArray *matches = [self fetchPlansWithToLocation:[plan0 toLocation]
                                         fromLocation:[plan0 fromLocation]];
    if (!matches || [matches count]==0) {
        return plan0;
    }
    else {
        Plan* consolidatedPlan = nil;
        for (int i=0; i<[matches count]; i++) {
            Plan* plan1 = [matches objectAtIndex:i];
            if (plan0 != plan1) {  // if this is actually a different object
                if (!consolidatedPlan) {
                    // Since matches is sorted most recent to oldest, the first plan in matches that is
                    // not identical to plan0 is the plan we want to consolidate into
                    consolidatedPlan = plan1;
                    
                    // consolidate from plan0 into consolidatedPlan, delete plan0
                    [consolidatedPlan consolidateIntoSelfPlan:plan0];
                }
                else {
                    // if there are yet other plan1's beyond consolidatedPlan, then consolidate them into consolidatePlan
                    [consolidatedPlan consolidateIntoSelfPlan:plan1];
                }
            }
        }
        if (consolidatedPlan) {
            return consolidatedPlan;
        } else {
            return plan0;  // return plan0 if no different matches were found
        }
    }
}

@end