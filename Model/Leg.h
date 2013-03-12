//
//  Leg.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import "PlanPlace.h"
#import "enums.h"
#import "PolylineEncodedString.h"

typedef enum {
    FIRST_LEG,
    MIDDLE_LEG,
    LAST_LEG
} LegPositionEnum;

typedef enum {
    REALTIME_LEG,
    SCHEDULED_LEG,
} LegType;

@class Itinerary, PlanPlace, Step;

@interface Leg : NSManagedObject 

// See this URL for documentation on the elements: http://www.opentripplanner.org/apidoc/data_ns0.html#leg
// This URL has example data http://groups.google.com/group/opentripplanner-dev/msg/4535900a5d18e61f?
@property (nonatomic, retain) NSString * agencyId;
@property (nonatomic, retain) NSString * legId;
@property (nonatomic, retain) NSNumber * bogusNonTransitLeg;
@property (nonatomic, retain) NSNumber * distance; // distance in meters
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSString * headSign;
@property (nonatomic, retain) NSNumber * interlineWithPreviousLeg;
@property (nonatomic, retain) NSNumber * legGeometryLength;
@property (nonatomic, retain) NSString * legGeometryPoints;
@property (nonatomic, retain) NSString * mode;
@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, retain) NSString * route;
@property (nonatomic, retain) NSString * routeLongName;
@property (nonatomic, retain) NSString * routeShortName;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSString * tripShortName;
@property (nonatomic, retain) PlanPlace *from;
@property (nonatomic, retain) Itinerary *itinerary;
@property (nonatomic, retain) NSSet *steps;
@property (nonatomic, retain) NSString * tripId;
@property (nonatomic, retain) NSString * agencyName;
@property (nonatomic, retain) PlanPlace *to;
@property (nonatomic, strong) NSArray *sortedSteps;
@property (nonatomic, strong) PolylineEncodedString *polylineEncodedString;
@property (nonatomic) BOOL isRealTimeLeg;

@property (nonatomic, retain) NSString *arrivalTime;
@property (nonatomic, retain) NSString *arrivalFlag;
@property (nonatomic, retain) NSString *timeDiffInMins;
@property (nonatomic, retain) NSDate *realStartTime;
@property (nonatomic, retain) NSDate *realEndTime;
@property (nonatomic, retain) NSArray *predictions;
@property (nonatomic, strong) NSDictionary *prediction;
@property (nonatomic) int timeDiff;
@property (nonatomic, strong) NSString *realTripId;

- (NSArray *)sortedSteps;
- (NSString *)summaryTextWithTime:(BOOL)includeTime;  // Returns a single-line summary of the leg useful for RouteOptionsView details
- (NSString *)directionsTitleText:(LegPositionEnum)legPosition;
- (NSString *)directionsDetailText:(LegPositionEnum)legPosition;
- (NSString *)ncDescription;
- (BOOL)isWalk;
- (BOOL)isBike;
- (BOOL)isBus;
- (BOOL)isHeavyTrain; // Note: legs that are isHeavyTrain=true are also isTrain=true
- (BOOL)isTrain;
-(BOOL)isFerry;

// Returns leg duration as an NSTimeInterval
-(NSTimeInterval)durationTimeInterval;

// return false if leg is walk or bicycle otherwise return true.
-(BOOL)isScheduled;

// True if the main characteristics of referring Leg is equal to leg0
- (BOOL)isEqualInSubstance:(Leg *)leg0;

// Compare Two Legs whether they have the same routes and start and endpoints
// If Leg is walk then compatr TO&From location lat/Lng and distance.
// Does not compare times (this test is primarily for determining unique itineraries).
// If leg is not walk then compare modes, TO&From Location Lat/Lng and agencyname.
// If legs are equal then return yes otherwise return no
- (BOOL) isEquivalentModeAndStopsAs:(Leg *)leg;

// Set the newly generated leg attributes from old leg.
- (void) setNewlegAttributes:(Leg *)leg;

// return startTime only from real time if exists otherwise return leg starttime only.
- (NSDate *) getApplicableStartTime;

// return endTime only from real time if exists otherwise return leg endtime only.
- (NSDate *) getApplicableEndTime;

// return the leg at offset from current leg and sorted legs
-(Leg *) getLegAtOffsetFromListOfLegs:(NSArray *)sortedLegs offset:(int) offset;

// Calculate time difference in minutes for leg.
- (int) calculatetimeDiffInMins:(double)epochTime;

// return arrival time flag for leg.
- (int) calculateArrivalTimeFlag:(int)timeDifference;

// set timediffInMins,realStartTime,realEndTime and arrivalFlag for leg from realTime data.
- (void) setRealTimeParametersUsingEpochTime:(double)epochTime;

- (BOOL) isEquivalentModeAndStopsAndRouteAs:(Leg *)leg;

@end

@interface Leg (CoreDataGeneratedAccessors)

- (void)addStepsObject:(Step *)value;
- (void)removeStepsObject:(Step *)value;
- (void)addSteps:(NSSet *)values;
- (void)removeSteps:(NSSet *)values;
@end
