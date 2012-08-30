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

// Returns true if all the service days for all the itineraries and legs in referring PlanRequestChunk match
// those in requestChunk0.  Otherwise returns false
- (BOOL)doAllServiceStringByAgencyMatchRequestChunk:(PlanRequestChunk *)requestChunk0;

// Returns true if all the service days for all the itineraries and legs in the planRequestChunk match
// the request date.  Otherwise returns false
// If none of the legs in this requestChunk have agencyIds (for example, just walk legs), then returns true
- (BOOL)doAllItineraryServiceDaysMatchDate:(NSDate *)requestDate;

// Returns true if the referring PlanRequestChunk is relevant to the given requestDate and depOrArrive
// Relevant is based on being an equivalent schedule day and being within the time range of the PlanRequestChunk
// Return false if the referring PlanRequestChunk is not relevant
- (BOOL)doesCoverTheSameTimeAs:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive;

// Returns true if self and requestChunk0 have overlapping times, and thus are candidates for consolidation
// bufferInSeconds is the max amount that two chunks can be non-overlapping and still return true
- (BOOL)doTimesOverlapRequestChunk:(PlanRequestChunk *)requestChunk0 bufferInSeconds:(NSTimeInterval)bufferInSeconds;

// Returns a date/time that can be used to make a next request to OTP for getting additional itineraries
// The returned date will be the same day as requestDate, but will have a time equal to 1 minute past
// the startTime of the last itinerary in the referring PlanRequestChunk
-(NSDate *)nextRequestDateFor:(NSDate *)requestDate;

// itinerary (whichever's time is earliest)
// If earliestRequestedDepartTime is nil, returns the time-only portion of the startTime of the first itinerary
- (NSDate *)earliestTime;

// Returns the time-only portion of the latestRequestedArriveTime or the startTime of the last itinerary
// (whichever time is latest)
// If latestRequestedArriveTime is nil, returns the time-only portion of the startTime fo the last itinerary
- (NSDate *)latestTime;

// Consolidates requestChunk0 into self
// Assumes that self and requestChunk0 are true for doTimesOverlapRequestChunk: and doAllServiceStringByAgencyMatchRequestChunk:
// Takes the earliestRequestDepartTimeDate of the two and the latestRequestedArriveTimeDate of the two by comparing the time only
// Consolidates itineraries but does not check for duplicates
- (void)consolidateIntoSelfRequestChunk:(PlanRequestChunk *)requestChunk0;

@end

@interface PlanRequestChunk (CoreDataGeneratedAccessors)

- (void)addItinerariesObject:(Itinerary *)value;
- (void)removeItinerariesObject:(Itinerary *)value;
- (void)addItineraries:(NSSet *)values;
- (void)removeItineraries:(NSSet *)values;
@end