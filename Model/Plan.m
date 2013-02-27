//
//  Plan.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Plan.h"
#import "PlanRequestChunk.h"
#import "UtilityFunctions.h"
#import "Leg.h"
#import <CoreData/CoreData.h>
#import "Itinerary.h"
#import "ItineraryFromOTP.h"
#import "nc_AppDelegate.h"
#import "RouteExcludeSettings.h"


@interface Plan (CoreDataGeneratedAccessors)

- (void)addItinerariesObject:(Itinerary *)value;
- (void)removeItinerariesObject:(Itinerary *)value;
- (void)addItineraries:(NSSet *)values;
- (void)removeItineraries:(NSSet *)values;

@end

@implementation Plan

@dynamic date;
@dynamic lastUpdatedFromServer;
@dynamic planId;
@dynamic fromPlanPlace;
@dynamic toPlanPlace;
@dynamic fromLocation;
@dynamic toLocation;
@dynamic itineraries;
@dynamic uniqueItineraryPatterns;
@dynamic requestChunks;
@synthesize userRequestDate;
@synthesize userRequestDepartOrArrive;
@synthesize sortedItineraries;
@synthesize transitCalendar;

+ (RKManagedObjectMapping *)objectMappingforPlanner:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[Plan class]];
    RKManagedObjectMapping* planPlaceMapping = [PlanPlace objectMappingForApi:apiType];
    RKManagedObjectMapping* itineraryMapping = [ItineraryFromOTP  objectMappingForApi:apiType];
    mapping.setDefaultValueForMissingAttributes = TRUE;
    planPlaceMapping.setDefaultValueForMissingAttributes = TRUE;
    itineraryMapping.setDefaultValueForMissingAttributes = TRUE;
    
    // Make the mappings
    if (apiType==OTP_PLANNER) {
        // TODO  Do all the mapping
        [mapping mapKeyPath:@"date" toAttribute:@"date"];
        [mapping mapKeyPath:@"id" toAttribute:@"planId"];
        [mapping mapKeyPath:@"from" toRelationship:@"fromPlanPlace" withMapping:planPlaceMapping];
        [mapping mapKeyPath:@"to" toRelationship:@"toPlanPlace" withMapping:planPlaceMapping];
        [mapping mapKeyPath:@"itineraries" toRelationship:@"itineraries" withMapping:itineraryMapping];

    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    [self setLastUpdatedFromServer:[NSDate date]];    // Set the date
}

- (TransitCalendar *)transitCalendar {
    if (!transitCalendar) {
        transitCalendar = [TransitCalendar transitCalendar];
    }
    return transitCalendar;
}

- (NSArray *)sortedItineraries
{
    if (!sortedItineraries) {
        [self sortItineraries];  // create the itinerary array
    }
    return sortedItineraries;
}

// Create the sorted array of itineraries (sorted by startTimeOnly)
- (void)sortItineraries
{
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTimeOnly" ascending:YES];
    [self setSortedItineraries:[[self itineraries] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]]];
}

// Returns an array of itineraries sorted by date that have the
// StartTimeOnly field between fromTimeOnly to toTimeOnly
// If no matches, then returns 0 element array.  If nil parameters or fetch error, returns nil
- (NSArray *)fetchItinerariesFromTimeOnly:(NSDate *)fromTimeOnly toTimeOnly:(NSDate *)toTimeOnly
{
    if (!fromTimeOnly || !toTimeOnly) {
        return nil;
    }
    NSManagedObjectModel* model = [[[self managedObjectContext] persistentStoreCoordinator] managedObjectModel];
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"ItineraryByPlanAndTimeRange"
                                                substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                       self, @"PLAN",
                                                                       fromTimeOnly, @"TIME_RANGE_FROM",
                                                                       toTimeOnly, @"TIME_RANGE_TO",
                                                                       nil]];
    NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:@"startTimeOnly"
                                                          ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sd1,nil]];
    NSError *error;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (!result) {
        logError(@"Locations -> fetchItinerariesFromTimeOnly",  [NSString stringWithFormat:@"Core data fetch failed with error %@", error]);
        return nil;
    }
    return result;  // Return the array of matches (could be empty)
}

// consolidateIntoSelfPlan
// If plan0 fromLocation and toLocation are the same as referring object's...
// Consolidates plan0 itineraries and PlanRequestChunks into referring Plan
// Then deletes plan0 from the database
- (void)consolidateIntoSelfPlan:(Plan *)plan0
{
    NIMLOG_PERF1(@"consolidateIntoSelfPlans: Check self itineraries valid");
    // Make sure all itineraries in self are still valid GTFS data.  Delete otherwise
    BOOL wereAnyDeleted = false;
    for (Itinerary* itin in [NSSet setWithSet:[self itineraries]]) {
        if (![itin isCurrentVsGtfsFilesIn:[self transitCalendar]] ||
            ![itin startTimeOnly] || ![itin endTimeOnly] ||
            [itin isOvernightItinerary]) {
            // If out of date or if TimeOnly variables not set...
            // Delete all request chunks containing that itinerary (since they may now be outdated)
            wereAnyDeleted = true;
            for (PlanRequestChunk* reqChunk in [itin planRequestChunks]) {
                [[self managedObjectContext] deleteObject:reqChunk];
            }
            // Now delete the itinerary itself
            [self deleteItinerary:itin];
        }
    }
    NIMLOG_PERF1(@"consolidateIntoSelfPlans: Check plan0 itineraries valid");
    // Do the same checking for plan0 itineraries
    for (Itinerary* itin in [NSSet setWithSet:[plan0 itineraries]]) {
        if (![itin isCurrentVsGtfsFilesIn:[self transitCalendar]] ||
            ![itin startTimeOnly] || ![itin endTimeOnly] ||
            [itin isOvernightItinerary]) {
            // If out of date or if TimeOnly variables not set...
            // Delete all request chunks containing that itinerary (since they may now be outdated)
            wereAnyDeleted = true;
            for (PlanRequestChunk* reqChunk in [itin planRequestChunks]) {
                [[self managedObjectContext] deleteObject:reqChunk];
            }
            // Now delete the itinerary itself
            [self deleteItinerary:itin];
        }
    }
    if (wereAnyDeleted) {
        saveContext([self managedObjectContext]);
    }
    
    NIMLOG_PERF1(@"consolidateIntoSelfPlans: Consolidate request chunks");
    // Consolidate requestChunks
    NSMutableSet* chunksConsolidated = [[NSMutableSet alloc] initWithCapacity:10];
    for (PlanRequestChunk* reqChunk0 in [plan0 requestChunks]) {
        for (PlanRequestChunk* selfRequestChunk in [self requestChunks]) {
            if ([reqChunk0 doAllServiceStringByAgencyMatchRequestChunk:selfRequestChunk] &&
                [reqChunk0 doTimesOverlapRequestChunk:selfRequestChunk bufferInSeconds:REQUEST_CHUNK_OVERLAP_BUFFER_IN_SECONDS]) {
                [chunksConsolidated addObject:reqChunk0];
                [selfRequestChunk consolidateIntoSelfRequestChunk:reqChunk0];
            }
        }
    }
    
    // Transfer over requestChunks that were not consolidated
    for (PlanRequestChunk* reqChunkToTransfer in [plan0 requestChunks]) {
        if (![chunksConsolidated containsObject:reqChunkToTransfer]) {
            // Only transfer over PlanRequestChunks that have not already been consolidated
            [reqChunkToTransfer setPlan:self];  
        }
    }
    
    // Transfer over the itineraries getting rid of ones we do not need
    NIMLOG_PERF1(@"consolidateIntoSelfPlans: Transfer and get rid of itineraries we do not need");
    NSSet* itineraries0 = [NSSet setWithSet:[plan0 itineraries]];
    for (Itinerary* itin0 in itineraries0) {
        if ([self addItineraryIfNew:itin0] == ITIN0_OBSOLETE) { // add the itinerary no matter what
            [plan0 deleteItinerary:itin0];   // if itin0 obsolete, also make sure we delete it
        } else {
            [self addToUniqueItinerariesIfNeeded:itin0];
        }
    }
    // Delete plan0
    [[self managedObjectContext] deleteObject:plan0];
    
    saveContext([self managedObjectContext]);
}

// If itin0 is a new itinerary that does not exist in the referencing Plan, then add itin0 the referencing Plan
// If itin0 is the same as an existing itinerary in the referencing Plan, then keep the more current itinerary and delete the older one.
// Note: an itinerary is used as a pattern to create gtfs Request Chunks, it will not be considered obsolete
// Returns the result of the itinerary comparison (see Itinerary.h for enum definition)
- (ItineraryCompareResult) addItineraryIfNew:(Itinerary *)itin0
{
    NSArray* matchingTimeItins = [self fetchItinerariesFromTimeOnly:[itin0 startTimeOnly] toTimeOnly:[itin0 startTimeOnly]];  
    for (Itinerary* itinSelf in matchingTimeItins) {
        ItineraryCompareResult itincompare = [itinSelf compareItineraries:itin0];
        if (itincompare == ITINERARIES_DIFFERENT) {
            continue;
        }
        if (itincompare == ITINERARIES_IDENTICAL) {
            return itincompare;  // two are identical objects, so no duplication
        }
        if (itincompare == ITIN_SELF_OBSOLETE){
            // Make sure all of itinSelf requestChunks over to itin0
            for (PlanRequestChunk* reqChunk in [itinSelf planRequestChunks]) {
                [reqChunk addItinerariesObject:itin0];
                [reqChunk setSortedItineraries:nil];  // Flag for resorting
            }
            // Replace itinSelf with itin0
            [self deleteItinerary:itinSelf];
            [self addItinerary:itin0];
            return itincompare;
        } else if (itincompare == ITIN0_OBSOLETE) {
            // Make sure all of itin0's requestChunks over to itinSelf
            for (PlanRequestChunk* reqChunk in [itin0 planRequestChunks]) {
                [reqChunk addItinerariesObject:itinSelf];
                [reqChunk setSortedItineraries:nil];  // Flag for resorting
            }
            return itincompare;
        } else if (itincompare == ITINERARIES_SAME) {
            return itincompare;
        } else {
            // Unknown returned value, throw an exception
            [NSException raise:@"addItineraryIfNew exception"
                        format:@"Unknown ItineraryCompareResult %d", itincompare];
        }
    }
    // All the itineraries are different, so add itin0
    [self addItinerary:itin0];
    return ITINERARIES_DIFFERENT;
}

// Remove itin0 from the plan and from Core Data
- (void)deleteItinerary:(Itinerary *)itin0
{
    [self removeItinerariesObject:itin0];
    [[self managedObjectContext] deleteObject:itin0];
    [self setSortedItineraries:nil];  // Resort itineraries
}

// Add itin0 to the plan
- (void)addItinerary:(Itinerary *) itin0
{
    [itin0 setPlan:self];
    [self setSortedItineraries:nil]; // Mark sortedItineraries for re-sorting
}


// Initialization method after a plan is freshly loaded from an OTP request
// Initialization includes creating request chunks, startTimeOnly and endTimeOnly variables, and
// computing uniqueItineraries
- (void)initializeNewPlanFromOTPWithRequestDate:(NSDate *)requestDate
                                 departOrArrive:(DepartOrArrive)depOrArrive
                           routeExcludeSettings:(RouteExcludeSettings *)routeExcludeSettings
{
    PlanRequestChunk* requestChunk = [NSEntityDescription insertNewObjectForEntityForName:@"PlanRequestChunk"
                                                            inManagedObjectContext:[self managedObjectContext]];
    [requestChunk setPlan:self];
    [requestChunk setType:[NSNumber numberWithInt:OTP_ITINERARY]];
    [requestChunk setRouteExcludeSettings:routeExcludeSettings];
    if (depOrArrive == DEPART) {
        [requestChunk setEarliestRequestedDepartTimeDate:requestDate];
    } else { // ARRIVE
        [requestChunk setLatestRequestedArriveTimeDate:requestDate];
    }
    for (Itinerary* itin in [NSSet setWithSet:[self itineraries]]) { // Add all the itineraries to this request chunk
        if ([itin isOvernightItinerary]) {
            [self deleteItinerary:itin];
        } else {
            // Only initialize variables if we did not already delete the itinerary
            [requestChunk addItinerariesObject:itin];
            [itin initializeTimeOnlyVariablesWithRequestDate:requestDate]; // Set startTimeOnly & endTimeOnly
        }
    }
    if ([[requestChunk itineraries] count] == 0) { // if no itineraries, get rid of request chunk
        [[self managedObjectContext] deleteObject:requestChunk];
    }

}



// Looks for matching itineraries for the requestDate and departOrArrive
// routeExcludeSettings specifies which routes / modes the user specifically wants to include/exclude from results
// callBack is called if the method detects that we need more OTP or gtfs itineraries to show the user
// If it finds some, returns TRUE and updates the sortedItineraries property with just those itineraries
// If it does not find any, returns false and leaves sortedItineraries unchanged
- (BOOL)prepareSortedItinerariesWithMatchesForDate:(NSDate *)requestDate
                                    departOrArrive:(DepartOrArrive)depOrArrive
                               RouteExcludeSettings:(RouteExcludeSettings *)routeExcludeSettings
                                          callBack:(id <PlanRequestMoreItinerariesDelegate>)delegate
{
    NSArray* newSortedItineraries=[self returnSortedItinerariesWithMatchesForDate:requestDate
                                                                   departOrArrive:depOrArrive
                                                              RouteExcludeSettings:routeExcludeSettings
                                                                         callBack:delegate
                                                         planMaxItinerariesToShow:PLAN_MAX_ITINERARIES_TO_SHOW
                                                 planBufferSecondsBeforeItinerary:PLAN_BUFFER_SECONDS_BEFORE_ITINERARY
                                                      planMaxTimeForResultsToShow:PLAN_MAX_TIME_FOR_RESULTS_TO_SHOW];
    if (newSortedItineraries) {
        [self setSortedItineraries:newSortedItineraries];
        return true;
    } else {
        return false;
    }
}


// Variant of the above method without using an includeExcludeDictionary or callback
- (BOOL)prepareSortedItinerariesWithMatchesForDate:(NSDate *)requestDate
                                    departOrArrive:(DepartOrArrive)depOrArrive
{
    return [self prepareSortedItinerariesWithMatchesForDate:requestDate
                                             departOrArrive:depOrArrive
                                        RouteExcludeSettings:nil
                                                   callBack:nil];
}


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
                           planMaxTimeForResultsToShow:(int)planMaxTimeForResultsToShow
{
    @try {
        NSMutableSet* matchingItineraries = [[NSMutableSet alloc] initWithCapacity:[[self itineraries] count]];

        /*  John (2/25/2013):  work in progress, do not modify
        // Go through unique itineraries and generate any additional GTFS itineraries based on them
        for (Itinerary* uniqueItin in [self uniqueItineraries]) {  // for all uniqueItineraries
            if (!routeExcludeSettings || [routeExcludeSettings isItineraryIncluded:uniqueItin]) {  // if not an excluded itinerary
                for (PlanRequestChunk *reqChunk in [uniqueItin requestChunksCreatedByThisPattern]) { // for all reqChunk patterns it generated
                    if ([reqChunk doAllItineraryServiceDaysMatchDate:requestDate]) { // if reqChunk has relevant service coverage
                        PlanRequestChunk* newReqChunk = [self generateMoreGtfsItinsIfNeededFor:reqChunk
                                                                                   requestDate:requestDate
                                                                         intervalBeforeRequest:planBufferSecondsBeforeItinerary
                                                                          intervalAfterRequest:planMaxTimeForResultsToShow
                                                                                departOrArrive:depOrArrive];
                        // newReqChunk=nil means no new itineraries were added on (original reqChunk covered it)
                        PlanRequestChunk *reqChunkToProcess = (newReqChunk ? newReqChunk : reqChunk);
                                                         
                        for (Itinerary* itin in [reqChunkToProcess sortedItineraries]) { // for all itins in reqChunk
                            if ([itin isCurrentVsGtfsFilesIn:[self transitCalendar]] &&
                                [itin isWithinRequestTime:requestDate
                                    intervalBeforeRequest:planBufferSecondsBeforeItinerary
                                     intervalAfterRequest:planMaxTimeForResultsToShow
                                           departOrArrive:depOrArrive]) {
                                    if (!routeExcludeSettings || [routeExcludeSettings isItineraryIncluded:uniqueItin]) {  // if not an excluded itinerary
                                        [matchingItineraries addObject:itin];
                                    }
                                }
                        }  // end itins in reqChunk loop
                    }
                }  // end reqChunk loop
            }
        }  // end of uniqueItineraries loop
         */
        
        
        // Exclude any Gtfs request chunks that should be excluded per the routeExcludeSettings
        NSMutableSet* reqChunkSet = [NSMutableSet setWithSet:[self requestChunks]];
        if (routeExcludeSettings) {
            for (PlanRequestChunk* reqChunk in [self requestChunks]) {
                if (reqChunk.type.intValue == GTFS_ITINERARY &&
                    reqChunk.gtfsItineraryPattern &&
                    reqChunk.sortedItineraries.count > 0) {
                    if ([routeExcludeSettings isItineraryIncluded:[reqChunk.sortedItineraries objectAtIndex:0]]) {
                        [reqChunkSet removeObject:reqChunk];  // Remove this request chunk from consideration
                    }
                }
            }
        }
        
        // Create a set of all PlanRequestChunks that match the requestDate services and time
        // Iteratively connect PlanRequestChunks together if they are adjacent in time
        NSMutableSet* matchingReqChunks = [[NSMutableSet alloc] initWithCapacity:10];
        NSDate* connectingReqDate = requestDate; // connectingReqDate will move to connect adjoining request chunks
        NSDate* newConnectingReqDate;
        int loopsExecuted = 0;
        do {
            newConnectingReqDate = nil;
            
            // Collect the req
            for (PlanRequestChunk* reqChunk in reqChunkSet) {
                if ([reqChunk doAllItineraryServiceDaysMatchDate:connectingReqDate] &&
                    [reqChunk doesCoverTheSameTimeAs:connectingReqDate departOrArrive:depOrArrive]) {
                    [matchingReqChunks addObject:reqChunk];
                                        
                    // Compute newConnectingReqDate
                    NSDate* possibleNewConnReqDate;
                    if (depOrArrive == DEPART) {
                        NSDate* lastItinTimeOnly = [[[reqChunk sortedItineraries] lastObject] startTimeOnly];
                        possibleNewConnReqDate = addDateOnlyWithTime(dateOnlyFromDate(requestDate),
                                                                     [NSDate dateWithTimeInterval:PLAN_NEXT_REQUEST_TIME_INTERVAL_SECONDS
                                                                                        sinceDate:lastItinTimeOnly]);
                        if (!newConnectingReqDate ||
                            [newConnectingReqDate compare:possibleNewConnReqDate] == NSOrderedAscending) {
                            newConnectingReqDate = possibleNewConnReqDate;
                        }
                    } else { // depOrArrive = ARRIVE
                        NSDate* firstItinEndTimeOnly = [[[reqChunk sortedItineraries] objectAtIndex:0] endTimeOnly];
                        possibleNewConnReqDate = addDateOnlyWithTime(dateOnlyFromDate(requestDate),
                                                                     [NSDate dateWithTimeInterval:(-PLAN_NEXT_REQUEST_TIME_INTERVAL_SECONDS)
                                                                                        sinceDate:firstItinEndTimeOnly]);
                        if (!newConnectingReqDate ||
                            [newConnectingReqDate compare:possibleNewConnReqDate] == NSOrderedDescending) {
                            newConnectingReqDate = possibleNewConnReqDate;
                        }
                    }
                }
            }
            connectingReqDate = newConnectingReqDate;
            loopsExecuted++;
            if (loopsExecuted == 25) {
                logError(@"PlanStore -> returnSortedItinerariesWithMatchesForDate",
                         @"returnSortedItinerariesWithMatchesForDate loopsExecuted unexpectedly reached 25");
            }
        } while (newConnectingReqDate && loopsExecuted < 25);
        
        if ([matchingReqChunks count] == 0) {
            return nil;  // no matches
        }
        // else collect all the itineraries that have valid GTFS data and are in the right time range
        for (PlanRequestChunk* reqChunk in matchingReqChunks) {
            for (Itinerary* itin in [reqChunk itineraries]) {
                // Check that all legs are current with the GTFS file
                
                if ([itin isCurrentVsGtfsFilesIn:[self transitCalendar]] &&
                    ![itin hideItinerary]) { // if itin is valid
                    // Check that the times match the requested time
                    NSDate* requestTimeOnly = timeOnlyFromDate(requestDate);
                    if (depOrArrive == DEPART) {
                        NSDate* requestTimeWithPreBuffer = [requestTimeOnly dateByAddingTimeInterval:(-planBufferSecondsBeforeItinerary)];
                        NSDate* requestTimeWithPostBuffer = [requestTimeOnly dateByAddingTimeInterval:planMaxTimeForResultsToShow];
                        if ([requestTimeWithPreBuffer compare:[itin startTimeOnly]]!=NSOrderedDescending &&
                            [requestTimeWithPostBuffer compare:[itin startTimeOnly]]!=NSOrderedAscending) {
                            // If itin start time is within the two buffer ranges
                            [matchingItineraries addObject:itin];
                        }
                    } else { // depOrArrive = ARRIVE
                        NSDate* requestTimeWithPreBuffer = [requestTimeOnly dateByAddingTimeInterval:(planBufferSecondsBeforeItinerary)];
                        NSDate* requestTimeWithPostBuffer = [requestTimeOnly dateByAddingTimeInterval:-planMaxTimeForResultsToShow];
                        if ([requestTimeWithPreBuffer compare:[itin endTimeOnly]]!=NSOrderedAscending &&
                            [requestTimeWithPostBuffer compare:[itin endTimeOnly]]!=NSOrderedDescending) {
                            // If itin start time is within the two buffer ranges
                            [matchingItineraries addObject:itin];
                        }
                    }
                }
            }
        }
        
        if ([matchingItineraries count] == 0) {
            return nil;
        }
        
        // Exclude any itineraries that are non-optimal or that are OTP itineraries and are part of exclude string
        NSMutableSet *includedItineraries = [NSMutableSet setWithSet:matchingItineraries];
        for (Itinerary* itin1 in matchingItineraries) {
            // Check for excluded OTP itineraries (GTFS itineraries were already checked above)
            // Addded Check to hide the realtime itinerary also if it is in exclude string
            if (routeExcludeSettings && ([itin1 isOTPItinerary] || itin1.isRealTimeItinerary)) {
                if (![routeExcludeSettings isItineraryIncluded:itin1]) {
                    [includedItineraries removeObject:itin1];
                }
            }
        }
        
        // Check for suboptimal itineraries or equivalent itineraries
        NSMutableSet *optimalItineraries = [NSMutableSet setWithSet:includedItineraries];
        
        // TODO:- Realtime Itineraries are removed from this loop so we need to handle realtime itinerary flag also.
        for (Itinerary* itin1 in includedItineraries) {
            for (Itinerary* itin2 in includedItineraries) {
                if (itin1 != itin2) {
                    // Check if equivalent itineraries
                    if(itin1.isRealTimeItinerary || itin2.isRealTimeItinerary){
                        // Do Nothing for RealTime Itinerary
                    }
                    else if ([itin1 isEquivalentRoutesStopsAndScheduledTimingAs:itin2]) {
                        if (itin1.isOTPItinerary && !itin2.isOTPItinerary) {
                            [optimalItineraries removeObject:itin1];  // if equivalent GTFS & OTP itineraries, only show the GTFS one
                        } else if (!itin1.isOTPItinerary && itin2.isOTPItinerary) {
                            // Do nothing, will delete itin2 on the other pass
                        }
                        else if ([optimalItineraries containsObject:itin1] &&
                                 [optimalItineraries containsObject:itin2]) { // both GTFS or both OTP
                            [optimalItineraries removeObject:itin1]; // Remove itin1 if it is the first to be removed
                        }
                    }
                    // if not equivalent, look for sub-optimal itineries
                    else if ([[itin1 startTimeOnly] compare:[itin2 startTimeOnly]] != NSOrderedDescending && 
                        [[itin1 endTimeOnly] compare:[itin2 endTimeOnly]] != NSOrderedAscending) {
                        // itin1 starts earlier or equal and ends later or equal.  Longer duration so remove itin1
                        [optimalItineraries removeObject:itin1];
                    }

                    // No need to compare the other way, because will loop thru all combinations of itin1 & itin2
                }
            }
        }
        
        
        // Sort itineraries (in reverse order if arrive-by itinerary (DE191 fix)
        NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTimeOnly" ascending:(depOrArrive == DEPART)];

        NSArray* returnedItineraries = [optimalItineraries sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]];
        
        // Remove itineraries from returnedItineraries beyond planMaxItinerariesToShow
        if ([returnedItineraries count] > planMaxItinerariesToShow) {
            NSMutableArray* copyOfReturnedItineraries = [NSMutableArray arrayWithArray:returnedItineraries];
            for (int i=planMaxItinerariesToShow; i<[returnedItineraries count]; i++) {
                [copyOfReturnedItineraries removeLastObject]; // remove last itineraries for DEPART or ARRIVE (DE191 fix)
            }
            returnedItineraries = [NSArray arrayWithArray:copyOfReturnedItineraries];
        }
        
        return returnedItineraries;
    }
    @catch (NSException *exception) {
        logException(@"Plan->returnSortedItinerariesWithMatchesForDate:", @"", exception);
    }
}


// Given a particular request timing and reqChunk, determine whether more GTFS itineraries need to be
// generated.  If so, generate them.
// If more itineraries were added to reqChunk, returns reqChunk
// If a new reqChunk was created for the itineraries, returns that new reqChunk
// If no new itineraries were created, returns nil.
-(PlanRequestChunk *)generateMoreGtfsItinsIfNeededFor:(PlanRequestChunk *)reqChunk
                                          requestDate:(NSDate *)requestDate
                                intervalBeforeRequest:(NSTimeInterval)intervalBeforeRequest
                                 intervalAfterRequest:(NSTimeInterval)intervalAfterRequest
                                       departOrArrive:(DepartOrArrive)depOrArrive
{
    PlanRequestChunk* newReqChunk = nil;
    NSDate* requestTimeOnly = timeOnlyFromDate(requestDate);
    NSDate* requestRangeFrom;
    NSDate* requestRangeTo;
    if (depOrArrive == DEPART) {
        requestRangeFrom = [requestTimeOnly dateByAddingTimeInterval:(-intervalBeforeRequest)];
        requestRangeTo = [requestTimeOnly dateByAddingTimeInterval:intervalAfterRequest];
    } else { // depOrArrive = ARRIVE
        requestRangeFrom = [requestTimeOnly dateByAddingTimeInterval:(intervalBeforeRequest)];
        requestRangeTo = [requestTimeOnly dateByAddingTimeInterval:-intervalAfterRequest];
    }
    
    NSDate* chunkEarliest = [reqChunk earliestTimeFor:depOrArrive];
    NSDate* chunkLatest = [reqChunk latestTimeFor:depOrArrive];
    
    NSDate* earlyRequestTo = nil; // The early request goes from requestRangeFrom to earlyRequestTo
    NSDate* lateRequestFrom = nil; // The late request goes from lateRequestFrom to requestRangeTo
    
    // Calculate the early request if necessary
    if ([requestRangeFrom compare:chunkEarliest] == NSOrderedAscending) {
        if ([requestRangeTo compare:chunkEarliest] == NSOrderedAscending) {
            earlyRequestTo = requestRangeTo;  // chunkEarliest is later than the entire requestRange, request entire range
        } else {
            earlyRequestTo = chunkEarliest; // chunkEarliest is within the requestRange, request part of range
        }
        newReqChunk = [[[nc_AppDelegate sharedInstance] gtfsParser]
                       generateItineraryFromItineraryPattern:[reqChunk gtfsItineraryPattern]
                       tripDate:requestDate
                       fromTimeOnly:requestRangeFrom
                       toTimeOnly:earlyRequestTo
                       Plan:self
                       Context:self.managedObjectContext];
        [reqChunk consolidateIntoSelfRequestChunk:newReqChunk];
        
    } // else, no need for an early request

    if ([requestRangeTo compare:chunkLatest] == NSOrderedDescending) {
        if ([requestRangeFrom compare:chunkLatest] == NSOrderedDescending) {
            lateRequestFrom = requestRangeFrom;  // chunkLatest is earlier than the entire requestRange, request entire range
        } else {
            lateRequestFrom = requestRangeFrom;  // chunkLatest is within the requestRange, request part of range
        }
        newReqChunk = [[[nc_AppDelegate sharedInstance] gtfsParser]
                       generateItineraryFromItineraryPattern:[reqChunk gtfsItineraryPattern]
                       tripDate:requestDate
                       fromTimeOnly:requestRangeFrom
                       toTimeOnly:earlyRequestTo
                       Plan:self
                       Context:self.managedObjectContext];
        [reqChunk consolidateIntoSelfRequestChunk:newReqChunk];
    }
    
    // TODO: figure out whether there is a new requestChunk and return it if needed
    
    return nil;
}


// Variant of the above method without using an includeExcludeDictionary or callback
- (NSArray *)returnSortedItinerariesWithMatchesForDate:(NSDate *)requestDate
                                        departOrArrive:(DepartOrArrive)depOrArrive
                              planMaxItinerariesToShow:(int)planMaxItinerariesToShow
                      planBufferSecondsBeforeItinerary:(int)planBufferSecondsBeforeItinerary
                           planMaxTimeForResultsToShow:(int)planMaxTimeForResultsToShow
{
    return [self returnSortedItinerariesWithMatchesForDate:requestDate
                                            departOrArrive:depOrArrive
                             RouteExcludeSettings:nil
                                                  callBack:nil
                                  planMaxItinerariesToShow:planMaxItinerariesToShow
                          planBufferSecondsBeforeItinerary:planBufferSecondsBeforeItinerary
                               planMaxTimeForResultsToShow:planMaxTimeForResultsToShow];
}

// Detects whether date returned by REST API is >1,000 years in the future.  If so, the value is likely being returned in milliseconds from 1970, rather than seconds from 1970, in which we correct the date by dividing by the timeSince1970 value by 1,000
// Comment out for now, since it is not being used
/*
- (BOOL)validateDate:(__autoreleasing id *)ioValue error:(NSError *__autoreleasing *)outError
{
    if ([*ioValue isKindOfClass:[NSDate class]]) {
        NSDate* ioDate = *ioValue;
        NSDate* farFutureDate = [NSDate dateWithTimeIntervalSinceNow:(60.0*60*24*365*1000)]; // 1,000 years in future
        if ([ioDate laterDate:farFutureDate]==ioDate) {   // if date is >1,000 years in future, divide time since 1970 by 1000
            NSDate* newDate = [NSDate dateWithTimeIntervalSince1970:([ioDate timeIntervalSince1970] / 1000.0)];
            NSLog(@"[self date] = %@", [self date]);
            NSLog(@"New Date = %@", newDate);
            *ioValue = newDate;
            NSLog(@"New ioValue = %@", *ioValue);
            NSLog(@"[self date] = %@", [self date]);
        }
        return YES;
    }
    return NO;
} */

- (NSString *)ncDescription
{
    NSMutableString* desc = [NSMutableString stringWithFormat:
                      @"{Plan Object: date: %@;  from: %@;  to: %@; ", [self date], [[self fromPlanPlace] ncDescription], [[self toPlanPlace] ncDescription]];
    for (Itinerary *itin in [self itineraries]) {
        [desc appendString:[NSString stringWithFormat:@"\n %@", [itin ncDescription]]];
    }
    return desc;
}

// Returns unique Itineraries array from plan sorted by StartDates
- (NSArray *)uniqueItineraries{
    if (![self uniqueItineraryPatterns] || [[self uniqueItineraryPatterns] count] == 0) {
        [self setUniqueItineraryPatterns:[NSSet setWithArray:[self computeUniqueItineraries]]];
    }
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTimeOnly" ascending:YES];
    return [[self uniqueItineraryPatterns] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]];
}

// Re-calculate uniqueItineraries from scratch and store in CoreData
// Given two equivalent itineraries, will choose the itinerary that is a pattern for others to keep as unique
- (NSArray *)computeUniqueItineraries{
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTimeOnly" ascending:YES];
    NSMutableArray *arrItineraries = [[NSMutableArray alloc] initWithArray:[[self itineraries]
                                                                            sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]]];
    int i;
    for(i=0; i < [arrItineraries count];i++){
        for(int j=i+1;j<[arrItineraries count];j++){
            Itinerary *itin1 = (Itinerary*)[arrItineraries objectAtIndex:i];
            Itinerary *itin2 = (Itinerary*)[arrItineraries objectAtIndex:j];
            BOOL isEquivalentitinerary = [itin1 isEquivalentModesAndStopsAs:itin2];
            if(isEquivalentitinerary){
                if (![itin2 isUniqueItinerary] && [[itin2 requestChunksCreatedByThisPattern] count] == 0) {
                    [arrItineraries removeObjectAtIndex:j];
                    i = i-1;
                    break;
                } else if (![itin1 isUniqueItinerary] && [[itin1 requestChunksCreatedByThisPattern] count]== 0) {
                    [arrItineraries removeObjectAtIndex:i];
                    break;
                } else {  // both itineraries are unique or have generated reqChunks
                    logError(@"Plan -> computeUniqueItineraries", @"two unique itineraries that are equivalent");
                    // This should be a rare case... keep both for now
                }
            }
        }
    }
    return arrItineraries;
}

// If itin0 is unique compare to all other of self's unique itineraries, then add it to the uniqueItinerary list
// If itin0 is not unique, then clear its uniqueItineraryForPlan field
- (BOOL)addToUniqueItinerariesIfNeeded:itin0
{
    if (![itin0 isOTPItinerary]) {
        return false;   // Only OTP itineraries can be unique
    }
    NSArray* uniqueItinArray = [self uniqueItineraries];
    BOOL isItin0Unique = true;
    for (Itinerary* uniqueItin in uniqueItinArray) {
        if ([uniqueItin isEquivalentModesAndStopsAs:itin0]) {
            isItin0Unique = false;
        }
    }
    if (isItin0Unique) {
        [itin0 setUniqueItineraryForPlan:self];  // add to unique itineraries
    } else {
        [itin0 setUniqueItineraryForPlan:nil];   // declare it not to be a unique itinerary
    }
    return isItin0Unique;
}

// Generate 16 character random string and set it as legId for scheduled leg.
- (void) setLegsId{
    for(int i=0;i<[[self uniqueItineraries] count];i++){
        Itinerary *itinerary = [[self uniqueItineraries] objectAtIndex:i];
        for(int j=0;j<[[itinerary sortedLegs] count];j++){
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:j];
            if([leg isScheduled] && !leg.legId)
                leg.legId = generateRandomString();
        }
    }
}

- (void) removeDuplicateItineraries{
    for(int i=0;i<[[self sortedItineraries] count];i++){
        for(int j=i+1;j<[[self sortedItineraries] count];j++){
            Itinerary *itinerary1 = [[self sortedItineraries] objectAtIndex:i];
            Itinerary *itinerary2 = [[self sortedItineraries] objectAtIndex:j];
            if([[itinerary1 sortedLegs] count] == [[itinerary2 sortedLegs] count]){
                NSDate *startDate1 = timeOnlyFromDate([itinerary1 startTimeOfFirstLeg]);
                NSDate *startDate2 = timeOnlyFromDate([itinerary2 startTimeOfFirstLeg]);
                NSDate *endDate1 = timeOnlyFromDate([itinerary1 endTimeOfLastLeg]);
                NSDate *endDate2 = timeOnlyFromDate([itinerary2 endTimeOfLastLeg]);
                if([startDate1 isEqualToDate:startDate2] && [endDate1 isEqualToDate:endDate2]){
                    if(![itinerary2 isRealTimeItinerary])
                        [self deleteItinerary:itinerary2];
                }
            }
        }
    }
}

- (NSDictionary *) returnUniqueButtonTitle{
    NSMutableDictionary *dictButtonTitles = [[NSMutableDictionary alloc] init];
    for(int i=0;i<[[self sortedItineraries] count];i++){
        Itinerary *itinerary = [[self sortedItineraries] objectAtIndex:i];
        for(int j=0;j<[itinerary.sortedLegs count];j++){
            Leg *leg = [itinerary.sortedLegs objectAtIndex:j];
            if([leg isScheduled]){
                if([[leg agencyName] isEqualToString:SFMUNI_AGENCY_NAME]){
                    NSString *strButtonTitle = [NSString stringWithFormat:@"%@-%@",returnShortAgencyName([leg agencyName]),[leg mode]];
                    [dictButtonTitles setObject:PLAN_ROUTE_INCLUDE forKey:strButtonTitle];
                }
                else{
                    NSString *strButtonTitle = returnShortAgencyName([leg agencyName]);
                    [dictButtonTitles setObject:PLAN_ROUTE_INCLUDE forKey:strButtonTitle];
                }
            }
        }
    }
    return dictButtonTitles;
}

@end
