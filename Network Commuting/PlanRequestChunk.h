//
//  PlanRequestChunk.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
//
// PlanRequestChunks are individual elements of a PlanRequestCache.
// They contain a contiguous grouping of itineraries
// They also contain the earliest depart request time and the latest arrive-by request time used for these itineraries

#import <Foundation/Foundation.h>
#import "Itinerary.h"
#import "enums.h"

@interface PlanRequestChunk : NSObject

// Earliest requested departure time/date used in requesting the itineraries in this RequestChunk.
// nil if only arrive-by requests have been used so far
@property (strong, nonatomic) NSDate* earliestRequestedDepartTimeDate;

// Latest requested arrival time/date used in requesting the itineraries in this RequestChunk.
// nil if only depart requests have been used so far
@property (strong, nonatomic) NSDate* latestRequestedArriveTimeDate;

// Set of itineraries that are part of this PlanRequestChunk
@property (strong, nonatomic) NSArray* itineraries;

// Sorted array of itineraries (generated, not stored in Core Data)
@property (strong, nonatomic) NSArray* sortedItineraries;

//
// Methods
//

- (void)sortItineraries;   // Create the sorted array of itineraries

// Returns true if the referring PlanRequestChunk is relevant to the given requestDate and depOrArrive
// Relevant is based on being an equivalent schedule day and being within the time range of the PlanRequestChunk
// Return false if the referring PlanRequestChunk is not relevant
- (BOOL)isRelevantToRequestDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive;

@end
