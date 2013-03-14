//
//  GtfsTempItinerary.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 2/15/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "GtfsTempItinerary.h"
#import "GtfsStopTimes.h"
#import "GtfsTrips.h"
#import "UtilityFunctions.h"

@implementation GtfsTempItinerary

@synthesize legInfoArray;
@synthesize minTransferTime;

static int iterationCount;  // non-essential used for performance monitoring only

-(id) initWithMinTransferTime:(NSTimeInterval)time0
{
    self = [super init];
    if (self) {
        legInfoArray = [[NSMutableArray alloc] initWithCapacity:5];
        minTransferTime = time0;
    }
    return self;
}

// Returns endTime of the GtfsTempItinerary based on dateByAddingTimeInterval for the gtfsStops time string
// (plus any unscheduled time at the end of the interary.
-(NSDate *)endTime
{
    if ([legInfoArray count] == 0) {
        return nil;
    }
    NSTimeInterval unscheduledTime = 0.0;
    for (int i=[legInfoArray count]-1; i>=0; i--) {
        id member = [legInfoArray objectAtIndex:i];
        if ([member isKindOfClass:[Leg class]]) { // if unscheduled
            Leg* leg = member;
            unscheduledTime = unscheduledTime + [leg durationTimeInterval];
        } else { // scheduled (get leg endTime and then add unscheduledTime
            NSArray* stopTimesPair = member;
            GtfsStopTimes* endStopTime = [stopTimesPair objectAtIndex:1];
            NSDate* legEndTime = dateFromTimeString(endStopTime.arrivalTime);
            NSDate* endTime = [legEndTime dateByAddingTimeInterval:unscheduledTime];
            return endTime;
        }
    }
    // If all unscheduled legs, return midnight
    return dateFromTimeString(@"00:00:00");
}

// Returns startTime of the GtfsTempItinerary based on dateFromTimeString for the gtfsStops time string
// (plus any unscheduled time at the beginning of the interary)
-(NSDate *)startTime
{
    if ([legInfoArray count] == 0) {
        return nil;
    }
    NSTimeInterval unscheduledTime = 0.0;
    for (int i=0; i<[legInfoArray count]; i++) {
        id member = [legInfoArray objectAtIndex:i];
        if ([member isKindOfClass:[Leg class]]) { // if unscheduled
            Leg* leg = member;
            unscheduledTime = unscheduledTime + [leg durationTimeInterval];;   
        } else { // for scheduled, get leg endTime and then add unscheduledTime
            NSArray* stopTimesPair = member;
            GtfsStopTimes* startStopTime = [stopTimesPair objectAtIndex:0];
            NSDate* legStartTime = dateFromTimeString(startStopTime.departureTime);
            NSDate* startTime = [legStartTime dateByAddingTimeInterval:(-(unscheduledTime+minTransferTime))];
            return startTime;
        }
    }
    // If all unscheduled legs, return midnight
    return dateFromTimeString(@"00:00:00");
}

// Returns startTime of the leg at index based on dateFromTimeString for the gtfsStops time string
// (plus any unscheduled time at the beginning of the interary)
-(NSDate *)startTimeOfLegAtIndex:(int)index
{
    if ([legInfoArray count] == 0) {
        return nil;
    }
    NSTimeInterval unscheduledTime = 0.0;
    NSDate* lastScheduledEndTime = nil;
    for (int i=0; i<[legInfoArray count]; i++) {
        id member = [legInfoArray objectAtIndex:i];
        if ([member isKindOfClass:[Leg class]]) { // if unscheduled
            Leg* leg = member;
            if (i==index) {
                unscheduledTime = [leg durationTimeInterval];  // if this is the start-point we want, reset unscheduledTime
                if (lastScheduledEndTime) { 
                    return lastScheduledEndTime; // if we have a previous scheduled leg, return that endTime
                }
            } else { 
                unscheduledTime = unscheduledTime + [leg durationTimeInterval];
            } 
        } else { // for scheduled, get leg endTime and then add unscheduledTime
            NSArray* stopTimesPair = member;
            if (i < index) { // not yet hit index
                GtfsStopTimes* endStopTime = [stopTimesPair objectAtIndex:1];
                lastScheduledEndTime = dateFromTimeString(endStopTime.arrivalTime);
            } else {
                if (i==index) {
                    unscheduledTime = 0.0;  // if this is the start-point we want, null out unscheduledTime
                }
                GtfsStopTimes* startStopTime = [stopTimesPair objectAtIndex:0];
                NSDate* legStartTime = dateFromTimeString(startStopTime.departureTime);
                NSDate* startTime = [legStartTime dateByAddingTimeInterval:(-(unscheduledTime+minTransferTime))];
                return startTime;
            }
        }
    }
    // If all unscheduled legs, return midnight
    return dateFromTimeString(@"00:00:00");
}

// Returns true if self has same length as arrStopTimesArray (meaning all the legs are built out)
-(BOOL)isFullyBuiltFor:(NSArray *)arrStopTimesArray
{
    if ([legInfoArray count] == [arrStopTimesArray count]) {
        return true;
    }
    return false;
}

// Returns true if the self can make the connection to stopPairArray (i.e. there is a least minTransferTime time gap between them)
-(BOOL)canMakeConnectionTo:(NSArray *)stopPairArray 
{
    NSDate* endTime = [self.endTime dateByAddingTimeInterval:minTransferTime];  // endTime of the legInfoArray so far
    GtfsStopTimes* startStopTime = [stopPairArray objectAtIndex:0];
    NSDate* legStartTime = dateFromTimeString(startStopTime.departureTime);
    return ([endTime compare:legStartTime] != NSOrderedDescending);
}

// Updates the contents of self's legInfoArray to that of itin0, startig at legIndex
-(void)setToCopyOf:(GtfsTempItinerary *)itin0 fromLegIndex:(int)legIndex
{
    for (int i=legIndex; i < self.legInfoArray.count; i++) {
        if (i<itin0.legInfoArray.count) {
            [self.legInfoArray replaceObjectAtIndex:i withObject:[[itin0 legInfoArray] objectAtIndex:i]];
        }
    }
}

// Creates and returns a copy of self
-(GtfsTempItinerary *)copyItin
{
    GtfsTempItinerary* copy = [[GtfsTempItinerary alloc] initWithMinTransferTime:minTransferTime];
    for (id member in [self legInfoArray]) {
        [[copy legInfoArray] addObject:member];
    }
    return copy;
}

// Removes everything from self's legInfoArray at and beyond legIndex
-(void)clearLegsStartingAt:(int)legIndex
{
    int originalArrayCount = [legInfoArray count];
    for (int i=legIndex; i<originalArrayCount; i++) {
        [legInfoArray removeObjectAtIndex:legIndex]; // Keep on removing at same spot the required # of times
    }
}


-(void)addStopPairArray:(NSArray *)stopPairArray atIndex:(int)legIndex
{
    if (legIndex == self.legInfoArray.count) {
        [self.legInfoArray addObject:stopPairArray];
    } else if (legIndex < self.legInfoArray.count) {
        [self.legInfoArray replaceObjectAtIndex:legIndex withObject:stopPairArray];
    } else {
        logError(@"GtfsTempItinerary -> addStopPairArray", @"Exceeded legInfoArray size");
    }
}

-(void)addUnschedLeg:(Leg *)leg atIndex:(int)legIndex
{
    if (legIndex == self.legInfoArray.count) { // legIndex one farther than current array elements
        [self.legInfoArray addObject:leg];
    } else if (legIndex < self.legInfoArray.count) {
        [self.legInfoArray replaceObjectAtIndex:legIndex withObject:leg];
    } else {
        logError(@"GtfsTempItinerary -> addLegArray", @"Exceeded legInfoArray size");
    }
}

-(int)indexOfFirstScheduledLeg
{
    for (int i=0; i<[self.legInfoArray count]; i++) {
        id member = [self.legInfoArray objectAtIndex:i];
        if (![member isKindOfClass:[Leg class]]) { // Scheduled leg
            return i;
        }
    }
    logError(@"GtfsTempItinerary --> indexOfFirstScheduledLeg", @"Unexpected unscheduled itinerary");
    return 0;
}

// This is the main method for the class
// Takes all the itinerary pattern and gtfs schedules in arrStopTimesArray and
// returns itinArray with a GtfsTempItinerary for each optimal itinerary that can be generated based
// on that pattern.
// arrStopTimesArray is an array up to three dimensions:
// First index is legIndex, which corresponds to each leg in the itinerary pattern
// If a leg is unscheduled, then it will point to the patternLeg
// If a leg is scheduled, then it will point to a sorted array of StopPairArrays corresponding to possible gtfs trips for that leg
// Each stop pair array is 2 elements long with a GtfsStopTime for the beginning and end of a trip
//
// Implementation note:  this method is recursive.  It builds out all the itineraries by recursively
// calling itself for each subsequent legIndex
-(BOOL) buildItinerariesFromArrStopTimesArray:(NSArray *)arrStopTimesArray
                                     putInto:(NSMutableArray *)itinArray
                             startingatLegIndex:(int)legIndex
{
    @try {
        if (iterationCount++ % 25 == 0) {
            NIMLOG_PERF2(@"TempItinerary iteration: %d, legIndex: %d", iterationCount, legIndex);
        }
        NSArray* arrStopTimes = [arrStopTimesArray objectAtIndex:legIndex];
        if (![arrStopTimes isKindOfClass:[Leg class]]) { // if this index is a scheduled leg
            GtfsTempItinerary* bestItinSoFar=nil;
            for (int i = [arrStopTimes count]-1; i>=0; i--) { // go through stoptimes backwards
                GtfsTempItinerary* itin2=nil;
                NSArray* stopPairArray = [arrStopTimes objectAtIndex:i];
                if ([self isFullyBuiltFor:arrStopTimesArray]) {
                    // if this itinerary is fully built out, create a new copy
                    itin2 = [self copyItin];
                } else {
                    itin2 = self;
                }
                
                [itin2 clearLegsStartingAt:legIndex];  // Make sure there are no legs at LegIndex or beyond from previous iterations
                if ([itin2 canMakeConnectionTo:stopPairArray]) {
                    [itin2 addStopPairArray:stopPairArray atIndex:legIndex];
                    BOOL connectionPossible = false;
                    int nextLegIndex = legIndex + 1;
                    if (nextLegIndex < [arrStopTimesArray count]) {
                        connectionPossible = [itin2 buildItinerariesFromArrStopTimesArray:arrStopTimesArray
                                                                                  putInto:itinArray
                                                                       startingatLegIndex:nextLegIndex];
                    } else { // we are at the end of the itinerary already
                        connectionPossible = true;
                    }
                    
                    if (!connectionPossible) {
                        continue;  // loop to next stopPairArray
                    }
                    
                    // Compare itineraries only if this is the first scheduled leg
                    if (self==itin2) {
                        bestItinSoFar = self;
                    }
                    else if (fabs([[bestItinSoFar startTime] timeIntervalSinceDate:[itin2 startTime]]) < SMALL_TIME_THRESHOLD) { // startTimes ~equal
                        if ([[bestItinSoFar endTime] compare:[itin2 endTime]] != NSOrderedAscending) { // itin2 has earlier or equal endTime
                            bestItinSoFar = itin2;
                        }
                    }
                    else { // itin2 has an earlier start-time (due to ordering of arrStopTimes)
                        if ([[bestItinSoFar endTime] timeIntervalSinceDate:[itin2 endTime]] > SMALL_TIME_THRESHOLD) { // itin2 has earlier endTime
                            [itinArray addObject:bestItinSoFar]; // Keep bestItinSoFar
                            bestItinSoFar = itin2;  // Search anew with bestItinSoFar = itin2
                        }
                    }
                } else { // can't make connection at this index
                    break;
                }
            } // reached end of loop
            if (!bestItinSoFar) {
                return false; // no connections possible
            } else {
                if (legIndex == [self indexOfFirstScheduledLeg]) { // Only add to list if this is the first scheduled leg index
                    [itinArray addObject:bestItinSoFar]; // Keep this itinerary
                } else {
                    [self setToCopyOf:bestItinSoFar fromLegIndex:legIndex]; // use bestItinSoFar as the self we return to the previous call
                }
                return true;
            }
        } else { // legIndex points to an unscheduled leg
            Leg* unscheduledLeg = [arrStopTimesArray objectAtIndex:legIndex];
            [self addUnschedLeg:unscheduledLeg atIndex:legIndex];
            int nextLegIndex = legIndex + 1;
            if (nextLegIndex < [arrStopTimesArray count]) {
                BOOL connectionPossible = [self buildItinerariesFromArrStopTimesArray:arrStopTimesArray
                                                                              putInto:itinArray
                                                                   startingatLegIndex:nextLegIndex];
                return connectionPossible;
            } else { // we are at the end of the itinerary already
                return true;
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"GtfsTempItinerary->buildItinerariesFromArrStopTimesArray", @"", exception);
        return false;
    }
}

// Makes an ItineraryObject based on what's in self
-(Itinerary *)makeItineraryObjectInPlan:(Plan *)plan
                       patternItinerary:(Itinerary *)patternItinerary
                   managedObjectContext:(NSManagedObjectContext *)context
                               tripDate:(NSDate *)tripDate
{
    @try {
        Itinerary* newItinerary = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:context];
        newItinerary.plan = plan;
        for (int i=0; i<[legInfoArray count]; i++) {
            Leg* patternLeg = [[patternItinerary sortedLegs] objectAtIndex:i];
            Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
            [newleg setNewlegAttributes:patternLeg];
            newleg.itinerary = newItinerary;
            id member = [legInfoArray objectAtIndex:i];
            if ([member isKindOfClass:[Leg class]]) { // unscheduled leg
                newleg.startTime = addDateOnlyWithTime(dateOnlyFromDate(tripDate), [self startTimeOfLegAtIndex:i]);
                newleg.endTime = [newleg.startTime dateByAddingTimeInterval:[patternLeg durationTimeInterval]];
            } else { // scheduled leg
                NSArray* stopPairArray = member;
                GtfsStopTimes *fromStopTime = [stopPairArray objectAtIndex:0];
                GtfsStopTimes *toStopTime = [stopPairArray objectAtIndex:1];
                
                newleg.startTime = addDateOnlyWithTime(dateOnlyFromDate(tripDate),
                                                       dateFromTimeString(fromStopTime.departureTime));
                newleg.endTime = addDateOnlyWithTime(dateOnlyFromDate(tripDate),
                                                     dateFromTimeString(toStopTime.departureTime));

                newleg.tripId = fromStopTime.tripID;
                newleg.headSign = fromStopTime.trips.tripHeadSign;
            }
            newleg.duration = [NSNumber numberWithDouble:[newleg.endTime timeIntervalSinceDate:newleg.startTime] * 1000];
        }
        newItinerary.startTime = addDateOnlyWithTime(dateOnlyFromDate(tripDate), self.startTime);
        newItinerary.startTimeOnly = self.startTime;
        newItinerary.endTime = addDateOnlyWithTime(dateOnlyFromDate(tripDate), self.endTime);
        newItinerary.endTimeOnly = self.endTime;
        newItinerary.duration = [NSNumber numberWithDouble:[newItinerary.startTime timeIntervalSinceDate:newItinerary.endTime] * 1000];
        
        return newItinerary;
    }
    @catch (NSException *exception) {
        logException(@"GtfsTempItinerary->makeItineraryObject", @"", exception);
        return nil;
    }
}

@end
