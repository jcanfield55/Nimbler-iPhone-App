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
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    [self setSortedItineraries:[[self itineraries] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]]];
}

- (NSDictionary *)serviceStringByAgency
{
    if (!serviceStringByAgency) {
        [self populateserviceStringByAgency];
    }
    return serviceStringByAgency;
}

// Create the serviceStringByAgency set
- (void)populateserviceStringByAgency
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
- (BOOL)doAllserviceStringByAgencyMatchRequestChunk:(PlanRequestChunk *)requestChunk0
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
        NSDate* earliestTime;
        if ([self earliestRequestedDepartTimeDate]) {
            NSDate* earliestRequestedDepartTime = timeOnlyFromDate([self earliestRequestedDepartTimeDate]);
            earliestTime = [earliestRequestedDepartTime earlierDate:firstItineraryTime];
        } else {
            earliestTime = firstItineraryTime;
        }
        
        if ([requestTime compare:earliestTime]==NSOrderedDescending &&
            [requestTime compare:lastItineraryTime]==NSOrderedAscending) {
            // If requestTime is between earliest and last time in the chunk
            return true;
        } else {
            return false;
        }
    }
    else {  // depOrArrive = ARRIVE
        
        // Compute RequestChunk latest time to compare against
        NSDate* latestTime;
        if ([self latestRequestedArriveTimeDate]) {
            NSDate* latestRequestedArriveTime = timeOnlyFromDate([self earliestRequestedDepartTimeDate]);
            latestTime = [latestRequestedArriveTime laterDate:lastItineraryTime];
        } else {
            latestTime = lastItineraryTime;
        }
        
        if ([requestTime compare:firstItineraryTime]==NSOrderedDescending &&
            [requestTime compare:latestTime]==NSOrderedAscending) {
            // If requestTime is between the first and the latest time in the chunk
            return true;
        } else {
            return false;
        }
    }
    
    return false;
}



@end
