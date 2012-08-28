//
//  PlanRequestChunk.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "PlanRequestChunk.h"
#import "UtilityFunctions.h"
#import "Constants.h"
#import "Leg.h"


@implementation PlanRequestChunk

@dynamic earliestRequestedDepartTimeDate;
@dynamic latestRequestedArriveTimeDate;
@dynamic itineraries;
@dynamic plan;
@synthesize sortedItineraries;
@synthesize transitCalendar;
@synthesize serviceStringByAgency;

- (void)awakeFromInsert {
    [super awakeFromInsert];
    [self setTransitCalendar:[TransitCalendar transitCalendar]];  // Set transitCalendar object
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
            NSString* serviceString = [transitCalendar serviceStringForDate:requestDate agencyId:agencyId];
            [returnedValue setObject:serviceString forKey:agencyId];
        }
    }
    [self setServiceStringByAgency:[NSDictionary dictionaryWithDictionary:returnedValue]];
}

// TODO Make sure that I do not combine itineraries in chunks across days 

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
        if (chunk0ServiceString && ![chunk0ServiceString isEqualToString:selfServiceString]) {
            // if chunk0 has a service string for that agency, and it does not match...
            return false;
        }
    }
    
    // Now enumerate thru all of requestChunk0's agency keys (in order to catch any non-duplicates)
    enumerator = [[requestChunk0 serviceStringByAgency] keyEnumerator];
    while (agencyId = [enumerator nextObject]) {
        NSString* selfServiceString = [[self serviceStringByAgency] objectForKey:agencyId];
        NSString* chunk0ServiceString = [[requestChunk0 serviceStringByAgency] objectForKey:agencyId];
        if (selfServiceString && ![chunk0ServiceString isEqualToString:selfServiceString]) {
            // if self has a service string for that agency, and it does not match...
            return false;
        }
    }
    return true;
}

//
// Returns true if all the service days for all the itineraries and legs in the planRequestChunk match
// the request date.  Otherwise returns false
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

// Returns the time-only portion of the earliestRequestedDepartTimeDate or the startTime of the first
// itinerary (whichever's time is earliest)
// If earliestRequestedDepartTime is nil, returns the time-only portion of the startTime of the first itinerary
- (NSDate *)earliestTime
{
    NSDate *firstItineraryTime = timeOnlyFromDate([[[self sortedItineraries] objectAtIndex:0] startTime]);
    if ([self earliestRequestedDepartTimeDate]) {
        NSDate* earliestRequestedDepartTime = timeOnlyFromDate([self earliestRequestedDepartTimeDate]);
        return [earliestRequestedDepartTime earlierDate:firstItineraryTime];
    } else
        return firstItineraryTime;
}

// Returns the time-only portion of the latestRequestedArriveTime or the startTime of the last itinerary
// (whichever time is latest)
// If latestRequestedArriveTime is nil, returns the time-only portion of the startTime fo the last itinerary
- (NSDate *)latestTime
{
    NSDate *lastItineraryTime = timeOnlyFromDate([[[self sortedItineraries] lastObject] startTime]);
    if ([self latestRequestedArriveTimeDate]) {
        NSDate* latestRequestedArriveTime = timeOnlyFromDate([self earliestRequestedDepartTimeDate]);
        return [latestRequestedArriveTime laterDate:lastItineraryTime];
    } else {
        return lastItineraryTime;
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
    NSDate *lastItineraryTime = timeOnlyFromDate([[[self sortedItineraries] lastObject] startTime]);
    NSDate *firstItineraryTime = timeOnlyFromDate([[[self sortedItineraries] objectAtIndex:0] startTime]);
    
    if (depOrArrive==DEPART) {
        
        // Compute RequestChunk earliest time to compare against
        if ([requestTime compare:[self earliestTime]]!=NSOrderedAscending &&
            [requestTime compare:lastItineraryTime]!=NSOrderedDescending) {
            // If requestTime is between earliest and last time in the chunk
            return true;
        } else {
            return false;
        }
    }
    else {  // depOrArrive = ARRIVE
        
        if ([requestTime compare:firstItineraryTime]!=NSOrderedAscending &&
            [requestTime compare:[self latestTime]]!=NSOrderedDescending) {
            // If requestTime is between the first and the latest time in the chunk
            return true;
        } else {
            return false;
        }
    }
}

// Returns true if self and requestChunk0 have overlapping times, and thus are candidates for consolidation
- (BOOL)doTimesOverlapRequestChunk:(PlanRequestChunk *)requestChunk0
{
    // If self earliestTime is within the range for requestChunk0, return true
    if ([[self earliestTime] compare:[requestChunk0 earliestTime]]!=NSOrderedAscending &&
        [[self earliestTime] compare:[requestChunk0 latestTime]]!=NSOrderedDescending) {
        return true;
    }
    // If self latestTime is within the range for requestChunk0, return true
    if ([[self latestTime] compare:[requestChunk0 earliestTime]]!=NSOrderedAscending &&
        [[self latestTime] compare:[requestChunk0 latestTime]]!=NSOrderedDescending) {
        return true;
    }
    // If neither earliest or latest overlaps requestChunk0, return false
    return false;
}

// Returns a date/time that can be used to make a next request to OTP for getting additional itineraries
// The returned date will be the same day as requestDate, but will have a time equal to 1 minute past
// the startTime of the last itinerary in the referring PlanRequestChunk
-(NSDate *)nextRequestDateFor:(NSDate *)requestDate
{
    NSDate* newRequestTime = [[[[self sortedItineraries] lastObject] startTime] dateByAddingTimeInterval:60.0];
    NSDate* returnValue = addDateOnlyWithTimeOnly(requestDate, newRequestTime);
    return returnValue;
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
