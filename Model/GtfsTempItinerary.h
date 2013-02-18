//
//  GtfsTempItinerary.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 2/15/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Leg.h"
#import "Plan.h"

@interface GtfsTempItinerary : NSObject

// Array whose index corresponds to the legs of the patternItinerary it is based off of
// Array contains either a StopTimePair (for scheduled legs) or Leg 
@property(strong, nonatomic) NSMutableArray *legInfoArray;

// minTransferTime needed before starting a scheduled leg
@property(nonatomic) NSTimeInterval minTransferTime;


// Methods

-(id) initWithMinTransferTime:(NSTimeInterval)time0;

// Returns startTime of the GtfsTempItinerary based on dateFromTimeString for the gtfsStops time string
// (plus any unscheduled time at the beginning of the interary)
-(NSDate *)startTime;

// Returns startTime of the leg at index based on dateFromTimeString for the gtfsStops time string
// (plus any unscheduled time at the beginning of the interary)
-(NSDate *)startTimeOfLegAtIndex:(int)index;

// Returns endTime of the GtfsTempItinerary based on dateByAddingTimeInterval for the gtfsStops time string
// (plus any unscheduled time at the end of the interary.
-(NSDate *)endTime;

// Returns true if self has same length as arrStopTimesArray (meaning all the legs are built out)
-(BOOL)isFullyBuiltFor:(NSArray *)arrStopTimesArray;

// Returns true if the self can make the connection to stopPairArray (i.e. there is a least minTransferTime time gap between them)
-(BOOL)canMakeConnectionTo:(NSArray *)stopPairArray;

// Updates the contents of self's legInfoArray to that of itin0, startig at legIndex
-(void)setToCopyOf:(GtfsTempItinerary *)itin0 fromLegIndex:(int)legIndex;

// Creates and returns a copy of self
-(GtfsTempItinerary *)copyItin;

// Removes everything from self's legInfoArray at and beyond legIndex
-(void)clearLegsStartingAt:(int)legIndex;

-(void)addStopPairArray:(NSArray *)stopPairArray atIndex:(int)legIndex;
-(void)addUnschedLeg:(Leg *)leg atIndex:(int)legIndex;

// Returns the index of the first scheduled leg in self's legInfoArray
-(int)indexOfFirstScheduledLeg;


// This is the main method for the class
// Takes all the itinerary pattern and gtfs schedules in arrStopTimesArray and
// returns itinArray with a GtfsTempItinerary for each optimal itinerary that can be generated based
// on that pattern.
// arrStopTimesArray is an array up to three dimensions:
// First index is legIndex, which corresponds to each leg in the itinerary pattern
// If a leg is unscheduled, then it will point to the patternLeg
// If a leg is scheduled, then it will point to a sorted array of StopPairArrays corresponding to possible gtfs trips for that leg
// Each stop pair array is 2 elements long with a GtfsStopTime for the beginning and end of a trip
-(BOOL) buildItinerariesFromArrStopTimesArray:(NSArray *)arrStopTimesArray
                                      putInto:(NSMutableArray *)itinArray
                           startingatLegIndex:(int)legIndex;

// Makes an ItineraryObject based on what's in self
-(Itinerary *)makeItineraryObjectInPlan:(Plan *)plan
                       patternItinerary:(Itinerary *)patternItinerary
                   managedObjectContext:(NSManagedObjectContext *)context
                               tripDate:(NSDate *)tripDate;
@end
