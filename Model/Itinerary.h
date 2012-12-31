//
//  Itinerary.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/Restkit.h>
#import "PlanPlace.h"
#import "TransitCalendar.h"
#import "enums.h"

@class Leg, Plan, PlanRequestChunk;

@interface Itinerary : NSManagedObject

typedef enum {
    ITINERARIES_DIFFERENT,
    ITINERARIES_IDENTICAL,  // identical per the == operator (i.e. same object, same memory)
    ITINERARIES_SAME,       // different objects but effectively same content
    ITIN0_OBSOLETE,
    ITIN_SELF_OBSOLETE
} ItineraryCompareResult;

// See this URL for documentation on the elements: http://www.opentripplanner.org/apidoc/data_ns0.html#itinerary
// This URL has example data http://groups.google.com/group/opentripplanner-dev/msg/4535900a5d18e61f?
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSDate   * endTime;  // raw end time from OTP
@property (nonatomic, retain) NSDate *endTimeOnly; // Time only portion of endTime (computed with timeOnlyfromDate function).  Adds/subtracts 1 day if part of overnight request
@property (nonatomic, retain) NSDate * itineraryCreationDate; // Time this itinerary was loaded or last updated
@property (nonatomic, retain) NSDate * startTime;  // raw start time from OTP
@property (nonatomic, retain) NSDate * startTimeOnly;  // Time only portion of StartTime (computed with timeOnlyfromDate function).  Adds / subtracts 1 day if part of overnight request
@property (nonatomic, retain) NSString * itinId;
@property (nonatomic, retain) NSSet* planRequestChunks; // set of PlanRequestChunks this itinerary is part of
@property (nonatomic, retain) NSString *itinArrivalFlag;

@property (nonatomic, retain) NSSet *legs;
@property (nonatomic, retain) Plan *plan;
@property (nonatomic, strong) NSArray *sortedLegs; // Array of legs sorted by startTime (not stored in Core Data)

// Compare Two Itineraries
// This match itinerary like leg by leg if all match the return yes otherwise return no.

- (BOOL) isEquivalentItinerariAs:(Itinerary *)itinerary;
@end

@interface Itinerary (CoreDataGeneratedAccessors)

- (void)addLegsObject:(Leg *)value;
- (void)removeLegsObject:(Leg *)value;
- (void)addLegs:(NSSet *)values;
- (void)removeLegs:(NSSet *)values;
@end
