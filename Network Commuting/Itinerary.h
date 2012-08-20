//
//  Itinerary.h
//  Network Commuting
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/Restkit.h>
#import "PlanPlace.h"
#import "enums.h"

@class Leg, Plan;

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
@property (nonatomic, retain) NSNumber * elevationGained;
@property (nonatomic, retain) NSNumber * elevationLost;
@property (nonatomic, retain) NSDate   * endTime;  // raw end time from OTP
@property (nonatomic, retain) NSNumber * fareInCents;
@property (nonatomic, retain) NSDate * itineraryCreationDate; // Time this itinerary was loaded or last updated
@property (nonatomic, retain) NSDate * startTime;  // raw start time from OTP
@property (nonatomic, retain) NSNumber * tooSloped;
@property (nonatomic, retain) NSNumber * transfers;
@property (nonatomic, retain) NSNumber * transitTime;
@property (nonatomic, retain) NSNumber * waitingTime;
@property (nonatomic, retain) NSNumber * walkDistance;
@property (nonatomic, retain) NSNumber * walkTime;
@property (nonatomic, retain) NSString * itinId;

@property (nonatomic, retain) NSString *itinArrivalFlag;

@property (nonatomic, retain) NSSet *legs;
@property (nonatomic, retain) Plan *plan;
@property (nonatomic, strong) NSArray *sortedLegs; // Array of legs sorted by startTime (not stored in Core Data)

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType;

- (PlanPlace *)from;
- (PlanPlace *)to;
- (NSString *)ncDescription;

// Compares the itineraries to see if they are equivalent in substance
- (ItineraryCompareResult)compareItineraries:(Itinerary *)itin0;

// Returns the start-time of the first leg if there is one, otherwise returns startTime property
- (NSDate *)startTimeOfFirstLeg;

// Returns the end-time of the last leg if there is one, otherwise returns endTime property
- (NSDate *)endTimeOfLastLeg;

// Returns a nicely formatted address string for the starting point, if available
- (NSString *)fromAddressString;

// Returns a nicely formatted address string for the end point, if available
- (NSString *)toAddressString;

// Returns a sorted array of the title strings to show itinerary details as needed
// for display a route details view.  Might have more elements than legs in the itinerary.  
// Adds a start and/or end point if needed.  Modifies the first and last walking
// leg if needed.  
- (NSArray *)legDescriptionTitleSortedArray;

// Same as above but containing the corresponding subtitles
- (NSArray *)legDescriptionSubtitleSortedArray;

// This array has the same # of elements as the above title and subtitle arrays.  
// For the same element as the title or subtitle array, this array maps back to the corresponding leg
// if there is one.  If there was an added start or endpoint, the first or last element will return
// NSNull  
- (NSArray *)legDescriptionToLegMapArray;

// Returns the number of itinerary rows there are 
// This equals the number of rows in the legDescriptionTitleSortedArray.  
- (int)itineraryRowCount;

@end

@interface Itinerary (CoreDataGeneratedAccessors)

- (void)addLegsObject:(Leg *)value;
- (void)removeLegsObject:(Leg *)value;
- (void)addLegs:(NSSet *)values;
- (void)removeLegs:(NSSet *)values;
@end
