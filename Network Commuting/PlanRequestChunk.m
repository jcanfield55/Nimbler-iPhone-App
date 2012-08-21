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

@interface PlanRequestChunk()

// Internal properties holding just the time (not the date) computed using timeOnlyFromDate() function
@property (strong, nonatomic,readonly) NSDate* requestedTime;
@property (strong, nonatomic,readonly) NSDate* firstItineraryTime;
@property (strong, nonatomic,readonly) NSDate* lastItineraryTime;

@end

@implementation PlanRequestChunk

@synthesize requestedTimeDate;
@synthesize departOrArrive;
@synthesize itineraries;
@synthesize requestedTime;
@synthesize firstItineraryTime;
@synthesize lastItineraryTime;

//
// Accessors for derived values
//
- (NSDate *)requestedTime {
    if (!requestedTime) {
        requestedTime = timeOnlyFromDate([self requestedTimeDate]);
    }
    return requestedTime;
}

- (NSDate *)firstItineraryTime {
    if (!firstItineraryTime) {
        firstItineraryTime = timeOnlyFromDate([[[self itineraries] objectAtIndex:0] startTime]);
    }
    return firstItineraryTime;
}

- (NSDate *)lastItineraryTime {
    if (!lastItineraryTime) {
        lastItineraryTime = timeOnlyFromDate([[[self itineraries] lastObject] startTime]);
    }
    return lastItineraryTime;
}

//
// Setters for base values which nil out the related derived value
//
- (void)setRequestedTimeDate:(NSDate *)newTimeDate {
    requestedTime = nil;  // Clear out old value so it can be recomputed
    requestedTimeDate = newTimeDate;
}

- (void)setItineraries:(NSArray *)newItineraries {
    firstItineraryTime = nil; // Clear out old values so it can be recomputed
    lastItineraryTime = nil;
    itineraries = newItineraries;
}

//
// Computes whether referring object has relevant itineraries for a new user request with requestDate and depOrArrive 

- (BOOL)compareVsRequestDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive
{
    // Get the key times (independent of date)
    NSDate *requestTime = timeOnlyFromDate(requestDate);
    
    NSComparisonResult requestTimeVsSelfReqTime = [requestTime compare:[self requestedTime]];
    
    if (depOrArrive==DEPART && [self departOrArrive]==DEPART) {
        NSComparisonResult requestTimeVsLastItinTime = [requestTime compare:[self lastItineraryTime]];
        if (requestTimeVsSelfReqTime==NSOrderedDescending &&
            requestTimeVsLastItinTime==NSOrderedAscending) {
            // If requestTime is between selfRequestedTime and selfLastItinTime
            return true;
        } else if (requestTimeVsSelfReqTime==NSOrderedAscending &&
                   [requestTime timeIntervalSinceDate:[self firstItineraryTime]] <
                   MAX_GAP_BETWEEN_REQUEST_AND_FIRST_CACHED_ININERARY) {
            // else if requestTime is before the first itinerary but within the allowed time gap
            return true;
        } else {
            return false;
        }
    }
    //TODO finish up this part of the implementation
    else if (depOrArrive==DEPART && [self departOrArrive]==ARRIVE) {
        NSComparisonResult requestTimeVsFirstItinTime = [requestTime compare:[self firstItineraryTime]];

        if (requestTimeVsSelfReqTime==NSOrderedAscending &&
            requestTimeVsFirstItinTime==NSOrderedDescending) {
            // If requestTime is between selfFirstItinTime and selfRequestedTime
            return true;
        } else if (requestTimeVsSelfReqTime==NSOrderedAscending &&
                   [requestTime timeIntervalSinceDate:[self firstItineraryTime]] <
                   MAX_GAP_BETWEEN_REQUEST_AND_FIRST_CACHED_ININERARY) {
            // else if requestTime is before the first itinerary but within the allowed time gap
            return true;
        } else {
            return false;
        }
    }
    // TODO finish up this part of the implementation
    
    return false;
}


@end
