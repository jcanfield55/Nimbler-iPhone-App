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
#import <CoreData/CoreData.h>

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
    
    // Set the date
    [self setLastUpdatedFromServer:[NSDate date]];
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

// If itin0 is a new itinerary that does not exist in the referencing Plan, then add itin0 the referencing Plan
// If itin0 is the same as an existing itinerary in the referencing Plan, then keep the more current itinerary and delete the older one
// Returns the result of the itinerary comparison (see Itinerary.h for enum definition)
- (ItineraryCompareResult) addItineraryIfNew:(Itinerary *)itin0
{
    for (Itinerary* itin1 in [self sortedItineraries]) {
        ItineraryCompareResult itincompare = [itin1 compareItineraries:itin0];
        if (itincompare == ITINERARIES_DIFFERENT) {
            continue;
        }
        if (itincompare == ITINERARIES_IDENTICAL) {
            return itincompare;  // two are identical objects, so no duplication
        }
        if (itincompare == ITIN_SELF_OBSOLETE){
            [self removeItinerary:itin1];
            [self addItinerary:itin0];
            return itincompare;
        } else if (itincompare == ITIN0_OBSOLETE || itincompare == ITINERARIES_SAME) {
            // In this case, no need to change the referring Plan.  Let caller know that itin0 is old.  
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
- (void)removeItinerary:(Itinerary *)itin0
{
    NSMutableSet* mutableItineraries = [self mutableSetValueForKey:PLAN_ITINERARIES_KEY];
    [mutableItineraries removeObject:itin0];
    [[self managedObjectContext] deleteObject:itin0];
    [self sortItineraries];  // Resort itineraries
}

// Add itin0 to the plan
- (void)addItinerary:(Itinerary *) itin0
{
    NSMutableSet* mutableItineraries = [self mutableSetValueForKey:PLAN_ITINERARIES_KEY];
    [mutableItineraries addObject:itin0];
    [self sortItineraries];  // Resort itineraries
}


// Initialization method after a plan is freshly loaded from an OTP request
- (void)createRequestChunkWithAllItinerariesAndRequestDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive
{
    PlanRequestChunk* requestChunk = [NSEntityDescription insertNewObjectForEntityForName:@"PlanRequestChunk"
                                                            inManagedObjectContext:[self managedObjectContext]];
    if (depOrArrive == DEPART) {
        [requestChunk setEarliestRequestedDepartTimeDate:requestDate];
    } else { // ARRIVE
        [requestChunk setLatestRequestedArriveTimeDate:requestDate];
    }
    for (Itinerary* itin in [self itineraries]) { // Add all the itineraries to this request chunk
        [itin setPlanRequestChunk:requestChunk];
    }
}

// Updates the plan's sorted itineraries to address the new userRequestedDate and departOrArrive
// Returns true if the referring Plan has itineraries that can be displayed to the user for userRequestDate
// Returns false if there are no itineraries in the plan displayable for the user request.
// If false, the plan will be unchanged
- (BOOL)updateItinerariesForUserRequestedDate:(NSDate *)userRequestDate departOrArrive:(DepartOrArrive)depOrArrive
{
    return FALSE;
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


- (PlanRequestChunk *)relevantRequestChunksForDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive
{
    for (PlanRequestChunk* requestChunk in [self requestChunks]) {
        if ([requestChunk isRelevantToRequestDate:requestDate departOrArrive:depOrArrive]) {
            return requestChunk;
        }
    }

    return nil;
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
