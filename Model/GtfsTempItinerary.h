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

-(NSDate *)startTime;

-(NSDate *)startTimeAtIndex:(int)index;

-(NSDate *)endTime;

-(BOOL)isFullyBuiltFor:(NSArray *)arrStopTimesArray;

-(BOOL)canMakeConnectionTo:(NSArray *)stopPairArray;

-(void)setToCopyOf:(GtfsTempItinerary *)itin0 fromLegIndex:(int)legIndex;

-(GtfsTempItinerary *)copyItin;

-(void)clearLegsStartingAt:(int)legIndex;
-(int)indexOfFirstScheduledLeg;

-(void)addStopPairArray:(NSArray *)stopPairArray atIndex:(int)legIndex;
-(void)addUnschedLeg:(Leg *)leg atIndex:(int)legIndex;

-(BOOL) buildItinerariesFromArrStopTimesArray:(NSArray *)arrStopTimesArray
                                      putInto:(NSMutableArray *)itinArray
                           startingatLegIndex:(int)legIndex;

// Makes an ItineraryObject based on what's in self
-(Itinerary *)makeItineraryObjectInPlan:(Plan *)plan
                       patternItinerary:(Itinerary *)patternItinerary
                   managedObjectContext:(NSManagedObjectContext *)context
                               tripDate:(NSDate *)tripDate;
@end
