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


@implementation PlanRequestChunk

@dynamic earliestRequestedDepartTimeDate;
@dynamic latestRequestedArriveTimeDate;
@dynamic itineraries;
@synthesize sortedItineraries;

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


// TODO Make sure that I do not combine itineraries in chunks across days


//
// Returns true if the referring PlanRequestChunk is relevant to the given requestDate and depOrArrive
// Relevant is based being within the time range of the PlanRequestChunk
// This does not check whether the schedule for requestDate matches the itineraries schedule day
// Return false if the referring PlanRequestChunk is not relevant
//
- (BOOL)isRelevantToRequestDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive
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
