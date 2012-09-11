//
//  Plan.m
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Plan.h"
#import "PlanRequestChunk.h"
#import "UtilityFunctions.h"
#import "Leg.h"
#import <CoreData/CoreData.h>
#import "Logging.h"


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
    RKManagedObjectMapping* itineraryMapping = [Itinerary objectMappingForApi:apiType];
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

// Create the sorted array of itineraries
- (void)sortItineraries
{
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    [self setSortedItineraries:[[self itineraries] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]]];
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
    NIMLOG_PERF1(@"consolidateIntoSelfPlans: Transfer and get rid of itineraries we do not need");
    for (PlanRequestChunk* reqChunkToTransfer in [plan0 requestChunks]) {
        if (![chunksConsolidated containsObject:reqChunkToTransfer]) {
            // Only transfer over PlanRequestChunks that have not already been consolidated
            [reqChunkToTransfer setPlan:self];  
        }
    }
    
    // Transfer over the itineraries getting rid of ones we do not need
    NSSet* itineraries0 = [NSSet setWithSet:[plan0 itineraries]];
    for (Itinerary* itin0 in itineraries0) {
        if ([self addItineraryIfNew:itin0] == ITIN0_OBSOLETE) { // add the itinerary no matter what
            [plan0 deleteItinerary:itin0];   // if itin0 obsolete, also make sure we delete it
        }
    }
    // Delete plan0
    [[self managedObjectContext] deleteObject:plan0];
    
    saveContext([self managedObjectContext]);
}

// If itin0 is a new itinerary that does not exist in the referencing Plan, then add itin0 the referencing Plan
// If itin0 is the same as an existing itinerary in the referencing Plan, then keep the more current itinerary and delete the older one
// Returns the result of the itinerary comparison (see Itinerary.h for enum definition)
- (ItineraryCompareResult) addItineraryIfNew:(Itinerary *)itin0
{
    NSSet* selfItineraries = [NSSet setWithSet:[self itineraries]];  // Make a copy since I will be deleting some
    for (Itinerary* itinSelf in selfItineraries) {
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
- (void)createRequestChunkWithAllItinerariesAndRequestDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive
{
    PlanRequestChunk* requestChunk = [NSEntityDescription insertNewObjectForEntityForName:@"PlanRequestChunk"
                                                            inManagedObjectContext:[self managedObjectContext]];
    [requestChunk setPlan:self];
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
}



// prepareSortedItinerariesWithMatchesForDate  -- part of Plan Caching (US78) implementation
// Looks for matching itineraries for the requestDate and departOrArrive
// If it finds some, returns TRUE and updates the sortedItineraries property with just those itineraries
// If it does not find any, returns false and leaves sortedItineraries unchanged
- (BOOL)prepareSortedItinerariesWithMatchesForDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive
{
    NSArray* newSortedItineraries=[self returnSortedItinerariesWithMatchesForDate:requestDate
                                                                   departOrArrive:depOrArrive
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

// TODO make it so that Arrive itineraries either show a smaller number of sort in reverse order

// returnSortedItinerariesWithMatchesForDate  -- part of Plan Caching (US78) implementation
// Helper routine called by prepareSortedItinerariesWithMatchesForDate
// Looks for matching itineraries for the requestDate and departOrArrive
// If it finds some, returns a sorted array of the matching itineraries
// Returned array will have no more than planMaxItinerariesToShow itineraries, spanning no more
// than planMaxTimeForResultsToShow seconds.
// It will include itineraries starting up to planBufferSecondsBeforeItinerary before requestDate
// If there are no matching itineraries, returns nil
- (NSArray *)returnSortedItinerariesWithMatchesForDate:(NSDate *)requestDate
                                        departOrArrive:(DepartOrArrive)depOrArrive
                              planMaxItinerariesToShow:(int)planMaxItinerariesToShow
                      planBufferSecondsBeforeItinerary:(int)planBufferSecondsBeforeItinerary
                           planMaxTimeForResultsToShow:(int)planMaxTimeForResultsToShow
{
    NSMutableSet* matchingItineraries = [[NSMutableSet alloc] initWithCapacity:[[self itineraries] count]];
    
    // Create a set of all PlanRequestChunks that match the requestDate services and time
    // Iteratively connect PlanRequestChunks together if they are adjacent in time
    NSMutableSet* matchingReqChunks = [[NSMutableSet alloc] initWithCapacity:10];
    NSDate* connectingReqDate = requestDate; // connectingReqDate will move to connect adjoining request chunks
    NSDate* newConnectingReqDate;
    int loopsExecuted = 0;
    do {
        newConnectingReqDate = nil;
        for (PlanRequestChunk* reqChunk in [self requestChunks]) {
            if ([reqChunk doAllItineraryServiceDaysMatchDate:connectingReqDate] &&
                [reqChunk doesCoverTheSameTimeAs:connectingReqDate departOrArrive:depOrArrive]) {
                [matchingReqChunks addObject:reqChunk];
                
                // Compute newConnectingReqDate
                NSDate* possibleNewConnReqDate;
                if (depOrArrive == DEPART) {
                    NSDate* lastItinTimeOnly = [[[reqChunk sortedItineraries] lastObject] startTimeOnly];
                    possibleNewConnReqDate = addDateOnlyWithTimeOnly(dateOnlyFromDate(requestDate),
                                                                     [NSDate dateWithTimeInterval:PLAN_NEXT_REQUEST_TIME_INTERVAL_SECONDS
                                                                                        sinceDate:lastItinTimeOnly]);
                    if (!newConnectingReqDate ||
                        [newConnectingReqDate compare:possibleNewConnReqDate] == NSOrderedAscending) {
                        newConnectingReqDate = possibleNewConnReqDate;
                    }
                } else { // depOrArrive = ARRIVE
                    NSDate* firstItinEndTimeOnly = [[[reqChunk sortedItineraries] objectAtIndex:0] endTimeOnly];
                    possibleNewConnReqDate = addDateOnlyWithTimeOnly(dateOnlyFromDate(requestDate),
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
            NSLog(@"returnSortedItinerariesWithMatchesForDate loopsExecuted unexpectedly reached 25");
        }
    } while (newConnectingReqDate && loopsExecuted < 25);
    
    if ([matchingReqChunks count] == 0) {
        return nil;  // no matches
    }
    // else collect all the itineraries that have valid GTFS data and are in the right time range
    for (PlanRequestChunk* reqChunk in matchingReqChunks) {
        for (Itinerary* itin in [reqChunk itineraries]) {
            // Check that all legs are current with the GTFS file
            
            if ([itin isCurrentVsGtfsFilesIn:[self transitCalendar]]) { // if itin is valid
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

    // Sort itineraries
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTimeOnly" ascending:YES];
    NSArray* returnedItineraries = [matchingItineraries sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]];
    
    // Remove itineraries from returnedItineraries beyond planMaxItinerariesToShow
    if ([returnedItineraries count] > planMaxItinerariesToShow) {
        NSMutableArray* copyOfReturnedItineraries = [NSMutableArray arrayWithArray:returnedItineraries];
        for (int i=planMaxItinerariesToShow; i<[returnedItineraries count]; i++) {
            if (depOrArrive == DEPART) {
                [copyOfReturnedItineraries removeLastObject]; // remove last itineraries for DEPART requests
            } else {
                [copyOfReturnedItineraries removeObjectAtIndex:0]; // remove first itineraries for ARRIVE requests
            }
        }
        returnedItineraries = [NSArray arrayWithArray:copyOfReturnedItineraries];
    }
    
    return returnedItineraries;
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

@end
