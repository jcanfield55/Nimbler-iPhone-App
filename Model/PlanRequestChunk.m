//
//  PlanRequestChunk.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/20/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "PlanRequestChunk.h"
#import "UtilityFunctions.h"
#import "Constants.h"
#import "Leg.h"


@implementation PlanRequestChunk

@dynamic type;
@dynamic gtfsItineraryPattern;
@dynamic earliestRequestedDepartTimeDate;
@dynamic latestRequestedArriveTimeDate;
@dynamic itineraries;
@dynamic plan;
@dynamic routeExcludeSettings;
@synthesize sortedItineraries;
@synthesize transitCalendar;
@synthesize serviceStringByAgency;

- (void)awakeFromInsert {
    [super awakeFromInsert];
    [self setTransitCalendar:[TransitCalendar transitCalendar]];  // Set transitCalendar object
}

- (TransitCalendar *)transitCalendar
{
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

// Delete requestChunks upon saving that do not have any associated itineraries
- (void)willSave
{
    if (self.isDeleted)
        return;
    if (self.itineraries.count == 0)
        [self.managedObjectContext deleteObject:self];
}

// Create the sorted array of itineraries
- (void)sortItineraries
{
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTimeOnly" ascending:YES];
    [self setSortedItineraries:[[self itineraries] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]]];
}

- (NSDictionary *)serviceStringByAgency
{
    if (!serviceStringByAgency) {
        [self populateServiceStringByAgency];
    }
    return serviceStringByAgency;
}

// Create the serviceStringByAgency set
- (void)populateServiceStringByAgency
{
    NSMutableDictionary* returnedValue = [[NSMutableDictionary alloc] initWithCapacity:10];
    NSDate* requestDate = ([self earliestRequestedDepartTimeDate] ? [self earliestRequestedDepartTimeDate] :
                    [self latestRequestedArriveTimeDate]);
    for (Itinerary* itin in [self sortedItineraries]) {
        for (Leg* leg in [itin sortedLegs]) {
            NSString* agencyId = [leg agencyId];
            if (agencyId && [agencyId length]>0) { // Check if there is an agency for this leg
                if (![returnedValue objectForKey:agencyId]) { // if we do not already have this serviceString
                    NSString* serviceString = [[self transitCalendar] serviceStringForDate:requestDate agencyId:agencyId];
                    if (serviceString) {
                        [returnedValue setObject:serviceString forKey:agencyId];
                    }
                }
            }
        }
    }
    [self setServiceStringByAgency:[NSDictionary dictionaryWithDictionary:returnedValue]];
}

//
// Returns true if all the service days for all the itineraries and legs in referring PlanRequestChunk match
// those in requestChunk0.  Otherwise returns false
//
- (BOOL)doAllServiceStringByAgencyMatchRequestChunk:(PlanRequestChunk *)requestChunk0
{    
    // Enumerate thru all self's agency keys first, and see if service strings match for each agency
    NSEnumerator* enumerator = [[self serviceStringByAgency] keyEnumerator];
    NSString* agencyId;
    while (agencyId = [enumerator nextObject]) {
        NSString* selfServiceString = [[self serviceStringByAgency] objectForKey:agencyId];
        NSString* chunk0ServiceString = [[requestChunk0 serviceStringByAgency] objectForKey:agencyId];
        if (![chunk0ServiceString isEqualToString:selfServiceString]) {
            return false;
        }
    }
    
    // Now enumerate thru all of requestChunk0's agency keys (in order to catch any non-duplicates)
    enumerator = [[requestChunk0 serviceStringByAgency] keyEnumerator];
    while (agencyId = [enumerator nextObject]) {
        NSString* selfServiceString = [[self serviceStringByAgency] objectForKey:agencyId];
        NSString* chunk0ServiceString = [[requestChunk0 serviceStringByAgency] objectForKey:agencyId];
        if (![chunk0ServiceString isEqualToString:selfServiceString]) {
            return false;
        }
    }
    return true;
}

//
// Returns true if all the service days for all the itineraries and legs in the planRequestChunk match
// the request date.  Otherwise returns false
// If none of the legs in this requestChunk have agencyIds (for example, just walk legs), then returns true
//
- (BOOL)doAllItineraryServiceDaysMatchDate:(NSDate *)requestDate
{
    BOOL allMatch = true;
    NSEnumerator* enumerator = [[self serviceStringByAgency] keyEnumerator];
    NSString* agencyId;
    while (agencyId = [enumerator nextObject]) {
        NSString* requestServiceString = [[self transitCalendar] serviceStringForDate:requestDate agencyId:agencyId];
        if (![requestServiceString isEqualToString:[[self serviceStringByAgency] objectForKey:agencyId]]) {
            allMatch = false;  
            break;
        }
    }
    return allMatch;
}

// Returns the latest timeOnly for the requestChunk based on depOrArrive
// If DEPART, returns the earlier of earliestRequestedDepartTime or startTimeOnly of the first itinerary leg
// If ARRIVE, returns the endTimeOnly of the first itinerary leg
- (NSDate *)earliestTimeFor:(DepartOrArrive)depOrArrive
{
    if (depOrArrive == DEPART) {
        NSDate *firstStartTimeOnly = [[[self sortedItineraries] objectAtIndex:0] startTimeOnly];
        if ([self earliestRequestedDepartTimeDate]) {
            NSDate* earliestRequestedDepartTime = timeOnlyFromDate([self earliestRequestedDepartTimeDate]);
            return [earliestRequestedDepartTime earlierDate:firstStartTimeOnly];
        } else
            return firstStartTimeOnly;
    }
    else { // depOrArrive == ARRIVE
        return [[[self sortedItineraries] objectAtIndex:0] endTimeOnly];
    }
}

// Returns the latest timeOnly for the requestChunk based on depOrArrive
// If ARRIVE, returns the later of latestRequestedArriveTime or endTimeOnly of the last itinerary leg
// If DEPART, returns the startTimeOnly of the last itinerary leg
- (NSDate *)latestTimeFor:(DepartOrArrive)depOrArrive
{
    if (depOrArrive == ARRIVE) {
        NSDate *lastEndTimeOnly = [[[self sortedItineraries] lastObject] endTimeOnly];
        if ([self latestRequestedArriveTimeDate]) {
            NSDate* latestRequestedArriveTime = timeOnlyFromDate([self latestRequestedArriveTimeDate]);
            return [latestRequestedArriveTime laterDate:lastEndTimeOnly];
        } else {
            return lastEndTimeOnly;
        }
    } else { // depOrArrive = DEPART
        return [[[self sortedItineraries] lastObject] startTimeOnly];
    }
}

//
// Returns true if the referring PlanRequestChunk is relevant to the given requestDate and depOrArrive
// Relevant is based being within the time range of the PlanRequestChunk
// Does not check whether the schedule for requestDate matches the schedule day for each leg & itinerary
// Return false if the referring PlanRequestChunk is not relevant
//
- (BOOL)doesCoverTheSameTimeAs:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive
{
    // Get the key times (independent of date)
    NSDate *requestTime = timeOnlyFromDate(requestDate);
    
    if ([requestTime compare:[self earliestTimeFor:depOrArrive]]!=NSOrderedAscending &&
        [requestTime compare:[self latestTimeFor:depOrArrive]]!=NSOrderedDescending) {
        // If requestTime is between earliest and last time in the chunk
        return true;
    } else {
        return false;
    }
}

// Returns true if self and requestChunk0 have overlapping times, and thus are candidates for consolidation
// bufferInSeconds is the max amount that two chunks can be non-overlapping and still return true
- (BOOL)doTimesOverlapRequestChunk:(PlanRequestChunk *)requestChunk0 bufferInSeconds:(NSTimeInterval)bufferInSeconds;
{
    for (int i=0; i < 2; i++) { // Go thru two times, once for DEPART and then for ARRIVE
        DepartOrArrive depOrArrive = (i==0 ? DEPART : ARRIVE);
        
        NSDate* earliestTime0MinusBuffer=[[requestChunk0 earliestTimeFor:depOrArrive] dateByAddingTimeInterval:(-bufferInSeconds)];
        NSDate* latestTime0PlusBuffer = [[requestChunk0 latestTimeFor:depOrArrive] dateByAddingTimeInterval:bufferInSeconds];
        // If self earliestTime is within the range for requestChunk0, return true
        if ([[self earliestTimeFor:depOrArrive] compare:earliestTime0MinusBuffer]!=NSOrderedAscending &&
            [[self earliestTimeFor:depOrArrive] compare:latestTime0PlusBuffer]!=NSOrderedDescending) {
            return true;
        }
        // If self latestTime is within the range for requestChunk0, return true
        if ([[self latestTimeFor:depOrArrive] compare:earliestTime0MinusBuffer]!=NSOrderedAscending &&
            [[self latestTimeFor:depOrArrive] compare:latestTime0PlusBuffer]!=NSOrderedDescending) {
            return true;
        }
        // Now check it in the other direction (whether requestChunk0 times are within the range of self times)
        NSDate* earliestTimeSelfMinusBuffer=[[self earliestTimeFor:depOrArrive] dateByAddingTimeInterval:(-bufferInSeconds)];
        NSDate* latestTimeSelfPlusBuffer = [[self latestTimeFor:depOrArrive] dateByAddingTimeInterval:bufferInSeconds];
        if ([[requestChunk0 earliestTimeFor:depOrArrive] compare:earliestTimeSelfMinusBuffer]!=NSOrderedAscending &&
            [[requestChunk0 earliestTimeFor:depOrArrive] compare:latestTimeSelfPlusBuffer]!=NSOrderedDescending) {
            return true;
        }
        // If self latestTime is within the range for requestChunk0, return true
        if ([[requestChunk0 latestTimeFor:depOrArrive] compare:earliestTimeSelfMinusBuffer]!=NSOrderedAscending &&
            [[requestChunk0 latestTimeFor:depOrArrive] compare:latestTimeSelfPlusBuffer]!=NSOrderedDescending) {
            return true;
        }
    }
    // If none of the above are true, return false
    return false;
}

// Consolidates requestChunk0 into self
// Assumes that self and requestChunk0 are true for doTimesOverlapRequestChunk: and doAllServiceStringByAgencyMatchRequestChunk:
// Takes the earliestRequestDepartTimeDate of the two and the latestRequestedArriveTimeDate of the two by comparing the time only
// Consolidates itineraries but does not check for duplicates
- (void)consolidateIntoSelfRequestChunk:(PlanRequestChunk *)requestChunk0 
{
    // Update earliestRequestedDepartTimeDate
    if ([requestChunk0 earliestRequestedDepartTimeDate]) {
        NSDate* earliestRequestedDepartTimeOnly0 = timeOnlyFromDate([requestChunk0 earliestRequestedDepartTimeDate]);
        if ([self earliestRequestedDepartTimeDate]) {
            NSDate* selfEarliestRequestedDepartTimeOnly = timeOnlyFromDate([self earliestRequestedDepartTimeDate]);
            if ([earliestRequestedDepartTimeOnly0 compare:selfEarliestRequestedDepartTimeOnly]==NSOrderedAscending) {
                [self setEarliestRequestedDepartTimeDate:[requestChunk0 earliestRequestedDepartTimeDate]];
            }
        } else {
            [self setEarliestRequestedDepartTimeDate:[requestChunk0 earliestRequestedDepartTimeDate]];
        }
    }
    
    // Update latestRequestedArriveTimeDate
    if ([requestChunk0 latestRequestedArriveTimeDate]) {
        NSDate* latestRequestedArriveTimeOnly0 = timeOnlyFromDate([requestChunk0 latestRequestedArriveTimeDate]);
        if ([self latestRequestedArriveTimeDate]) {
            NSDate* selfLatestRequestedArriveTimeOnly = timeOnlyFromDate([self latestRequestedArriveTimeDate]);
            if ([latestRequestedArriveTimeOnly0 compare:selfLatestRequestedArriveTimeOnly]==NSOrderedDescending) {
                [self setLatestRequestedArriveTimeDate:[requestChunk0 latestRequestedArriveTimeDate]];
            }
        } else {
            [self setLatestRequestedArriveTimeDate:[requestChunk0 latestRequestedArriveTimeDate]];
        }
    }
    
    // Move itineraries from requestChunk0 to self
    //
    NSSet* itinerariesToTransfer = [NSSet setWithSet:[requestChunk0 itineraries]]; // make a copy so since I will be modifying requestChunk0 itineraries
    for (Itinerary* itin0 in itinerariesToTransfer) {
        [requestChunk0 removeItinerariesObject:itin0];
        [self addItinerariesObject:itin0];
    }
    
    // Update derived variables
    [self sortItineraries];
    [self populateServiceStringByAgency];
}

@end
