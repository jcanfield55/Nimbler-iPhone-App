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
#import "TransitCalendar.h"

@interface PlanRequestChunk : NSManagedObject

// Earliest requested departure time/date used in requesting the itineraries in this RequestChunk.
// nil if only arrive-by requests have been used so far
@property (strong, nonatomic) NSDate* earliestRequestedDepartTimeDate;

// Latest requested arrival time/date used in requesting the itineraries in this RequestChunk.
// nil if only depart requests have been used so far
@property (strong, nonatomic) NSDate* latestRequestedArriveTimeDate;

// Set of itineraries that are part of this PlanRequestChunk
@property (strong, nonatomic) NSSet* itineraries;

// Plan this PlanRequestChunk belongs to
@property (strong, nonatomic) Plan* plan;

// Sorted array of itineraries (generated, not stored in Core Data)
@property (strong, nonatomic) NSArray* sortedItineraries;

@property (strong, nonatomic) TransitCalendar *transitCalendar; // Not stored in Core Data

// Dictionary with keys for every agencyId in each leg in itineraries.
// Object is the serviceString corresponding to the agency and this objects request date (obtained from
// TransitCalendar serviceStringForDate:agencyId:
@property (strong, nonatomic) NSDictionary* serviceStringByAgency;

//
// Methods
//

- (void)sortItineraries;   // Create the sorted array of itineraries

// Returns true if all the service days for all the itineraries and legs in the planRequestChunk match
// the request date.  Otherwise returns false
- (BOOL)doAllItineraryServiceDaysMatchDate:(NSDate *)requestDate;

// Returns true if the referring PlanRequestChunk is relevant to the given requestDate and depOrArrive
// Relevant is based on being an equivalent schedule day and being within the time range of the PlanRequestChunk
// Return false if the referring PlanRequestChunk is not relevant
- (BOOL)doesCoverTheSameTimeAs:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive;

@end
