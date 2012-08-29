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

// TODO add deletion of itineraries whose GTFS file has expired

// consolidateIntoSelfPlan
// If plan0 fromLocation and toLocation are the same as referring object's...
// Consolidates plan0 itineraries and PlanRequestChunks into referring Plan
// Then deletes plan0 from the database
- (void)consolidateIntoSelfPlan:(Plan *)plan0
{
    // Make sure all itineraries in self are still valid GTFS data.  Delete otherwise
    NSSet* selfItineraries = [NSSet setWithSet:[self itineraries]];
    for (Itinerary* itin in selfItineraries) {
        if (![itin isCurrentVsGtfsFilesIn:[self transitCalendar]]) {
            [self deleteItinerary:itin];
        }
    }
    
    // Consolidate requestChunks
    NSMutableSet* chunksConsolidated = [[NSMutableSet alloc] initWithCapacity:10];
    for (PlanRequestChunk* reqChunk0 in [plan0 requestChunks]) {
        for (PlanRequestChunk* selfRequestChunk in [self requestChunks]) {
            if ([reqChunk0 doAllServiceStringByAgencyMatchRequestChunk:selfRequestChunk] &&
                [reqChunk0 doTimesOverlapRequestChunk:selfRequestChunk]) {
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
    NSSet* itineraries0 = [NSSet setWithSet:[plan0 itineraries]];
    for (Itinerary* itin0 in itineraries0) {
        if (![itin0 isCurrentVsGtfsFilesIn:[self transitCalendar]]) {
            [plan0 deleteItinerary:itin0];  // delete itin0 if it is no longer current vs GTFS files
        } else {
            if ([self addItineraryIfNew:itin0] == ITIN0_OBSOLETE) { // add the itinerary no matter what
                [plan0 deleteItinerary:itin0];   // if itin0 obsolete, also make sure we delete it
            }
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
    for (Itinerary* itin in [self itineraries]) { // Add all the itineraries to this request chunk
        [requestChunk addItinerariesObject:itin];
    }
}


/*  TODO  Rewrite and combine the next two methods to reflect PlanRequestChunk being part of CoreData

// Initializer for an existing (legacy) Plan that does not have any planRequestCache but has a bunch of existing itineraries.  Creates a new PlanRequestChunk for every itinerary in sortedItineraryArray
- (id)initWithRawItineraries:(NSArray *)sortedItineraryArray
{
    self = [super init];
    
    if (self) {
        requestChunkArray = [[NSMutableArray alloc] initWithCapacity:[sortedItineraryArray count]];
        for (Itinerary* itin in sortedItineraryArray) {
            PlanRequestChunk* requestChunk = [[PlanRequestChunk alloc] init];
            [requestChunk setEarliestRequestedDepartTimeDate:[itin startTime]];  // Set request time to startTime of itinerary
            [requestChunk setItineraries:[NSArray arrayWithObject:itin]];
            [requestChunkArray addObject:requestChunk];
        }
    }
    return self;
}

// Initializer for a new plan fresh from a OTP request
// Creates one PlanRequestChunk with all the itineraries as part of it
- (id)initWithRequestDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive sortedItineraries:(NSArray *)sortedItinArray
{
    self = [super init];
    
    if (self) {
        
        requestChunkArray = [[NSMutableArray alloc] initWithCapacity:[sortedItinArray count]];
        PlanRequestChunk* requestChunk = [[PlanRequestChunk alloc] init];
        if (depOrArrive == DEPART) {
            [requestChunk setEarliestRequestedDepartTimeDate:requestDate];
        } else { // ARRIVE
            [requestChunk setLatestRequestedArriveTimeDate:requestDate];
        }
        [requestChunk setItineraries:sortedItinArray];
        [requestChunkArray addObject:requestChunk];
    }
    
    return self;
}
 */

// TODO Make a way to get rid of itineraries that are from old GTFS files

// prepareSortedItinerariesWithMatchesForDate  -- part of Plan Caching (US78) implementation
// Looks for matching itineraries for the requestDate and departOrArrive
// If it finds some, returns TRUE and updates the sortedItineraries property with just those itineraries
// If it does not find any, returns false and leaves sortedItineraries unchanged
- (BOOL)prepareSortedItinerariesWithMatchesForDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive
{
    NSMutableSet* matchingItineraries = [[NSMutableSet alloc] initWithCapacity:[[self itineraries] count]];
    
    // Create a set of all PlanRequestChunks that match the requestDate services and time
    NSMutableSet* matchingReqChunks = [[NSMutableSet alloc] initWithCapacity:10];
    for (PlanRequestChunk* reqChunk in [self requestChunks]) {
        if ([reqChunk doAllItineraryServiceDaysMatchDate:requestDate] &&
            [reqChunk doesCoverTheSameTimeAs:requestDate departOrArrive:depOrArrive]) {
            [matchingReqChunks addObject:reqChunk];
        }
    }
    
    if ([matchingReqChunks count] == 0) {
        return false;  // no matches
    }
    // else collect all the itineraries that have valid GTFS data and are in the right time range
    for (PlanRequestChunk* reqChunk in matchingReqChunks) {
        for (Itinerary* itin in [reqChunk itineraries]) {
            // Check that all legs are current with the GTFS file

            if ([itin isCurrentVsGtfsFilesIn:[self transitCalendar]]) { // if itin is valid
                // Check that the times match the requested time
                NSDate* requestTimeOnly = timeOnlyFromDate(requestDate);
                if (depOrArrive == DEPART) {
                    NSDate* requestTimeWithPreBuffer = [requestTimeOnly dateByAddingTimeInterval:(-PLAN_BUFFER_SECONDS_BEFORE_ITINERARY)];
                    NSDate* requestTimeWithPostBuffer = [requestTimeOnly dateByAddingTimeInterval:PLAN_MAX_TIME_FOR_RESULTS_TO_SHOW];
                    NSDate* itinStartTimeOnly = timeOnlyFromDate([itin startTime]);
                    if ([requestTimeWithPreBuffer compare:itinStartTimeOnly]!=NSOrderedDescending &&
                        [requestTimeWithPostBuffer compare:itinStartTimeOnly]!=NSOrderedAscending) {
                        // If itin start time is within the two buffer ranges
                        [matchingItineraries addObject:itin];
                    }
                } else { // depOrArrive = ARRIVE
                    NSDate* itinEndTimeOnly = timeOnlyFromDate([itin endTime]);
                    NSDate* requestTimeWithPreBuffer = [requestTimeOnly dateByAddingTimeInterval:(PLAN_BUFFER_SECONDS_BEFORE_ITINERARY)];
                    NSDate* requestTimeWithPostBuffer = [requestTimeOnly dateByAddingTimeInterval:-PLAN_MAX_TIME_FOR_RESULTS_TO_SHOW];
                    if ([requestTimeWithPreBuffer compare:itinEndTimeOnly]!=NSOrderedAscending &&
                        [requestTimeWithPostBuffer compare:itinEndTimeOnly]!=NSOrderedDescending) {
                        // If itin start time is within the two buffer ranges
                        [matchingItineraries addObject:itin];
                    }
                }
            }
        }
    }
    if ([matchingItineraries count] == 0) {
        return false;
    }
    // else
    if ([matchingItineraries count] < PLAN_MAX_ITINERARIES_TO_SHOW) {
        // NSDate* nextRequestDate = [reqChunk nextRequestDateFor:requestDate];
        // TODO Make a plan request for nextRequestDate
    }
    
    // Sort and set sortedItineraries
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTimeOnly" ascending:YES];
    [self setSortedItineraries:[matchingItineraries sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]]];
    return true;
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
