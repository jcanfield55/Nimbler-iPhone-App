//
//  PlanRequestCache.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "PlanRequestCache.h"

@implementation PlanRequestCache

@synthesize requestChunkArray;

// Initializer for an existing (legacy) Plan that does not have any planRequestCache but has a bunch of existing itineraries.  Creates a new PlanRequestChunk for every itinerary in sortedItineraryArray
- (id)initWithRawItineraries:(NSArray *)sortedItineraryArray
{
    self = [super init];

    if (self) {
        requestChunkArray = [[NSMutableArray alloc] initWithCapacity:[sortedItineraryArray count]];
        for (Itinerary* itin in sortedItineraryArray) {
            PlanRequestChunk* requestChunk = [[PlanRequestChunk alloc] init];
            [requestChunk setRequestedTimeDate:[itin startTime]];  // Set request time to startTime of itinerary
            [requestChunk setDepartOrArrive:DEPART];
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
        [requestChunk setRequestedTimeDate:requestDate];  
        [requestChunk setDepartOrArrive:depOrArrive];
        [requestChunk setItineraries:sortedItinArray];
    }
    
    return self;
}

- (NSArray *)relevantRequestChunksForDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive
{
    // Set up what we need to look at date components
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSUInteger calendarComponents = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSWeekdayCalendarUnit;
    NSUInteger timeComponents = NSHourCalendarUnit | NSMinuteCalendarUnit;
    
    // Get the request time (independent of date)
    NSDate *requestTime = [calendar dateFromComponents:[calendar components:calendarComponents fromDate:requestDate]];
    
    NSMutableArray* returnArray = [[NSMutableArray alloc] initWithCapacity:[[self requestChunkArray] count]];
    
    // TODO finish implementation of this method
    return nil;
    
}
@end
