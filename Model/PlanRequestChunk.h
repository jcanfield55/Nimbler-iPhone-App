//
//  PlanRequestChunk.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/20/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
//
// PlanRequestChunks are individual elements of a PlanRequestCache.
// They contain a contiguous grouping of itineraries
// They also contain the earliest depart request time and the latest arrive-by request time used for these itineraries

#import <Foundation/Foundation.h>
#import "Itinerary.h"
#import "enums.h"
#import "TransitCalendar.h"

@class RouteExcludeSettings;

@interface PlanRequestChunk : NSManagedObject

// Source of the RequestChunk itineraries.  Possible values:
// #define OTP_ITINERARY  0
// #define GTFS_ITINERARY 1
@property (nonatomic) NSNumber *type;

// Set only if type = REQUEST_CHUNK_TYPE_GTFS.  Contains the itinerary pattern used to generate the GTFS itinerary in this request chunk
@property (strong, nonatomic) Itinerary* gtfsItineraryPattern;

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

// The RouteExcludeSettings used when this PlanRequestChunk's itineraries were fetched from OTP
// Only set when type=OTP
@property (strong, nonatomic) RouteExcludeSettings* routeExcludeSettings;

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

// Returns the earliest time for the requestChunk based on depOrArrive
// If DEPART, returns the earlier of earliestRequestedDepartTime or startTimeOnly of the first itinerary leg
// If ARRIVE, returns the endTimeOnly of the first itinerary leg
- (NSDate *)earliestTimeFor:(DepartOrArrive)depOrArrive;

// Returns the latest time for the requestChunk based on depOrArrive
// If ARRIVE, returns the later of latestRequestedArriveTime or endTimeOnly of the last itinerary leg
// If DEPART, returns the startTimeOnly of the last itinerary leg
- (NSDate *)latestTimeFor:(DepartOrArrive)depOrArrive;

// Consolidates requestChunk0 into self
// Assumes that self and requestChunk0 are true for doTimesOverlapRequestChunk: and doAllServiceStringByAgencyMatchRequestChunk:
// Takes the earliestRequestDepartTimeDate of the two and the latestRequestedArriveTimeDate of the two by comparing the time only
// Consolidates itineraries but does not check for duplicates
- (void)consolidateIntoSelfRequestChunk:(PlanRequestChunk *)requestChunk0;
- (void)populateServiceStringByAgency;

@end

@interface PlanRequestChunk (CoreDataGeneratedAccessors)

- (void)addItinerariesObject:(Itinerary *)value;
- (void)removeItinerariesObject:(Itinerary *)value;
- (void)addItineraries:(NSSet *)values;
- (void)removeItineraries:(NSSet *)values;
@end