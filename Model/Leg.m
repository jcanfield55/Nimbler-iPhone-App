//
//  Leg.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Leg.h"
#import "Itinerary.h"
#import "Step.h"
#import "UtilityFunctions.h"
#import "KeyObjectStore.h"
#import "LocalConstants.h"
#import "IntermediateStops.h"

@interface Leg() 
// Private instance methods
+(NSDictionary *)agencyDisplayNameByAgencyId;
#define AGENCY_DISPLAY_NAME_BY_AGENCYID_KEY @"agencyDisplayNameByAgencyIdKey"

@end

@implementation Leg

@dynamic agencyId;
@dynamic bogusNonTransitLeg;
@dynamic distance;
@dynamic duration;
@dynamic endTime;
@dynamic headSign;
@dynamic interlineWithPreviousLeg;
@dynamic legGeometryLength;
@dynamic legGeometryPoints;
@dynamic mode;
@dynamic routeId;
@dynamic route;
@dynamic routeLongName;
@dynamic routeShortName;
@dynamic startTime;
@dynamic tripShortName;
@dynamic from;
@dynamic itinerary;
@dynamic steps;
@dynamic to;
@dynamic legId;
@dynamic tripId;
@dynamic agencyName;
@dynamic intermediateStops;

@synthesize realStartTime;
@synthesize realEndTime;
@synthesize sortedSteps;
@synthesize polylineEncodedString;
@synthesize arrivalTime,arrivalFlag,timeDiffInMins;
@synthesize predictions;
@synthesize isRealTimeLeg;
@synthesize prediction;
@synthesize timeDiff;
@synthesize realTripId;

static NSDictionary* __agencyDisplayNameByAgencyId;

// Returns leg duration as an NSTimeInterval
-(NSTimeInterval)durationTimeInterval
{
    return [[self duration] doubleValue]/1000.0;
}

// Create the sorted array of itineraries
- (void)sortSteps
{
    //Edited by Sitanshu Joshi
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"absoluteDirection" ascending:YES];
    [self setSortedSteps:[[self steps] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]]];
}

- (NSArray *)sortedSteps
{
    if (!sortedSteps) {
        [self sortSteps];  // create the itinerary array
    }
    return sortedSteps;
}

+ (NSDictionary *)agencyDisplayNameByAgencyId
{
    if (!__agencyDisplayNameByAgencyId) { // if not already set, check in database
        KeyObjectStore* store = [KeyObjectStore keyObjectStore];
        __agencyDisplayNameByAgencyId = [store objectForKey:AGENCY_DISPLAY_NAME_BY_AGENCYID_KEY];
        if (!__agencyDisplayNameByAgencyId) {  // if not stored in the database, create it
            __agencyDisplayNameByAgencyId = AGENCY_SHORT_NAME_BY_AGENCY_ID_DICTIONARY;
            [store setObject:__agencyDisplayNameByAgencyId forKey:AGENCY_DISPLAY_NAME_BY_AGENCYID_KEY];
        }
    }
    return __agencyDisplayNameByAgencyId;
}

// Getter to create (if needed) and return the polylineEncodedString object corresponding to the legGeometryPoints
- (PolylineEncodedString *)polylineEncodedString
{
    if (!polylineEncodedString) {
        polylineEncodedString = [[PolylineEncodedString alloc] initWithEncodedString:[self legGeometryPoints]];
    }
    return polylineEncodedString;
}

// Returns a single-line summary of the leg useful for RouteOptionsView details
// If includeTime == true, then include a time at the beginning of the summary text
- (NSString *)summaryTextWithTime:(BOOL)includeTime
{
    @try {
    NSMutableString* summary = [NSMutableString stringWithString:@""];
    if (includeTime) {
        //Part Of DE-229 Implementation
        if([self.arrivalFlag intValue] == DELAYED) {
            NSDate* realTimeArrivalTime = [[self startTime]
                                           dateByAddingTimeInterval:[timeDiffInMins floatValue]*60.0];
            if(realTimeArrivalTime){
              [summary appendFormat:@"%@ ", superShortTimeStringForDate(realTimeArrivalTime)];  
            }
            else{
                [summary appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
            }
        }
        else if([self.arrivalFlag intValue] == EARLY){
            NSDate* realTimeArrivalTime = [[self startTime]
                                           dateByAddingTimeInterval:[timeDiffInMins floatValue]*(-60.0)];
            if(realTimeArrivalTime){
                [summary appendFormat:@"%@ ", superShortTimeStringForDate(realTimeArrivalTime)];
            }
            else{
                [summary appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
            }
        }
        else{
            [summary appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
        }
        
    }
    if (self.isBike) {
        return @"Bike";
    }
    NSString* shortAgencyName = [[Leg agencyDisplayNameByAgencyId] objectForKey:[self agencyId]];
    if (!shortAgencyName) {
        shortAgencyName = [self mode];  // Use generic mode instead if name not available
    }
    [summary appendFormat:@"%@", shortAgencyName];
    if ([[self mode] isEqualToString:@"BUS"]) {
        [summary appendString:@" Bus"];
    }
    else if ([[self mode] isEqualToString:OTP_TRAM_MODE]) {
        [summary appendString:@" Tram"];
    }
    if (![[self agencyId] isEqualToString:@"BART"] && ![[self agencyId] isEqualToString:CALTRAIN_AGENCY_ID]) { // don't add BART route name because too long
        [summary appendFormat:@" %@", [self route]];
    }
    
    // US-184 Implementation
    if ([[self agencyId] isEqualToString:CALTRAIN_AGENCY_ID]) {
        NSRange range;
        NSString *strTrainNumber;
        NSString *strHeadSign = [self headSign];
        NSArray *headSignComponent = [strHeadSign componentsSeparatedByString:CALTRAIN_TRAIN];
        if([headSignComponent count] > 1){
            strTrainNumber = [headSignComponent objectAtIndex:1];
            if(!strTrainNumber){
                [summary appendFormat:@" %@", [self route]];
            }
            else{
                if([strTrainNumber rangeOfString:@")" options:NSCaseInsensitiveSearch].location != NSNotFound){
                    range = [strTrainNumber rangeOfString:@")"];
                    strTrainNumber = [strTrainNumber substringToIndex:range.location];
                    NSString * strTemp = [strTrainNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSString *strFullTrainNumber = [NSString stringWithFormat:@"#%@",strTemp];
                    [summary appendFormat:@" %@", strFullTrainNumber];
                    
                }
            }
        }
        else{
            [summary appendFormat:@" %@", [self route]];
        }
    }
    return summary;
    }
    @catch (NSException *exception) {
        logException(@"Leg->summaryTextWithTime:", @"", exception);
        return @"";
    }
}

// Returns title text for RouteDetailsView
// US121 and US124 implementation
- (NSString *)directionsTitleText:(LegPositionEnum)legPosition
{
    @try {
    NSMutableString *titleText=[NSMutableString stringWithString:@""];
        NSString* walkOrBikeString = nil;
        if (self.isWalk) {
            walkOrBikeString = @"Walk";
        } else if (self.isBike) {
            walkOrBikeString = @"Bike";
        }
    if (walkOrBikeString) {
        if (legPosition == FIRST_LEG) {    // US124 implementation
            // Part Of DE-229 & US-169 Implementation
            if([self.arrivalFlag intValue] == DELAYED) {
                NSDate* realTimeArrivalTime = [[self startTime]
                                               dateByAddingTimeInterval:[timeDiffInMins floatValue]*60.0];
                if(realTimeArrivalTime){
                    [titleText appendFormat:@"%@ %@ to %@",
                     superShortTimeStringForDate(realTimeArrivalTime),
                     walkOrBikeString,
                     [[self to] name]];
                }
                else{
                    [titleText appendFormat:@"%@ %@ to %@",
                     superShortTimeStringForDate([self startTime]),
                     walkOrBikeString,
                     [[self to] name]];
                }
                
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
                NSDate* realTimeArrivalTime = [[self startTime]
                                               dateByAddingTimeInterval:[timeDiffInMins floatValue]*(-60.0)];
                if(realTimeArrivalTime){
                    [titleText appendFormat:@"%@ %@ to %@",
                     superShortTimeStringForDate(realTimeArrivalTime),
                     walkOrBikeString,
                     [[self to] name]];
                }
                else{
                    [titleText appendFormat:@"%@ %@ to %@",
                     superShortTimeStringForDate([self startTime]),
                     walkOrBikeString,
                     [[self to] name]];
                }
                
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else {
                [titleText appendFormat:@"%@ %@ to %@",
                 superShortTimeStringForDate([[self itinerary] startTime]),
                 walkOrBikeString,
                 [[self to] name]];
            }
            
        }
        else if (legPosition == LAST_LEG) {   // US124 implementation
            if([self.arrivalFlag intValue] == DELAYED) {
                NSDate* realTimeArrivalTime = [[self endTime]
                                               dateByAddingTimeInterval:[timeDiffInMins floatValue]*60.0];
                if(realTimeArrivalTime){
                    [titleText appendFormat:@"%@ Arrive at %@",
                     superShortTimeStringForDate(realTimeArrivalTime),
                     [[self itinerary] toAddressString]];
                }
                else{
                    [titleText appendFormat:@"%@ Arrive at %@",
                     superShortTimeStringForDate([self endTime]),
                     [[self itinerary] toAddressString]];
                }
                
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
                NSDate* realTimeArrivalTime = [[self endTime]
                                               dateByAddingTimeInterval:[timeDiffInMins floatValue]*(-60.0)];
                if(realTimeArrivalTime){
                    [titleText appendFormat:@"%@ Arrive at %@",
                     superShortTimeStringForDate(realTimeArrivalTime),
                     [[self itinerary] toAddressString]];
                }
                else{
                    [titleText appendFormat:@"%@ Arrive at %@",
                     superShortTimeStringForDate([self endTime]),
                     [[self itinerary] toAddressString]];
                }
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else {
                [titleText appendFormat:@"%@ Arrive at %@",
                 superShortTimeStringForDate([[self itinerary] endTime]),
                 [[self itinerary] toAddressString]];
            }
        }
        else {
            [titleText appendFormat:@"%@ to %@", walkOrBikeString, [[self to] name]];
        }
    }
    else {  
        BOOL areRealTimeUpdates = NO;
        
        // if not walking, check for real-time updates:
        if([self arrivalTime]) {
            areRealTimeUpdates = YES;
            NIMLOG_EVENT1(@"Real-time flag: %@, scheduled arrival: %@, real-time arrival: %@, diff: %@", 
                  [self arrivalFlag], superShortTimeStringForDate([self startTime]),
                  [self arrivalTime],  timeDiffInMins);

            if([self.arrivalFlag intValue] == DELAYED) {
                NSDate* realTimeArrivalTime = [[self startTime] 
                                               dateByAddingTimeInterval:[timeDiffInMins floatValue]*60.0];
                if(realTimeArrivalTime){
                   [titleText appendFormat:@"%@ ", superShortTimeStringForDate(realTimeArrivalTime)]; 
                }
                else{
                    [titleText appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
                }
                
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
                NSDate* realTimeArrivalTime = [[self startTime] 
                                               dateByAddingTimeInterval:[timeDiffInMins floatValue]*(-60.0)];
                if(realTimeArrivalTime){
                  [titleText appendFormat:@"%@ ", superShortTimeStringForDate(realTimeArrivalTime)];  
                }
                else{
                   [titleText appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
                }
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else {
                [titleText appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
            }
        }
        else {
            // add the departure time (US 121 implementation)
            [titleText appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
        }
            
        if ([[self mode] isEqualToString:@"BUS"]) {
            [titleText appendString:@"Bus "];
        }
        else if ([[self mode] isEqualToString:OTP_TRAM_MODE]) {
            [titleText appendString:@"Tram "];
        }
        
        BOOL isShortName = false;
        if ([self routeShortName] && [[self routeShortName] length]>0) {
            [titleText appendFormat:@"%@", [self routeShortName]];
            isShortName = true;
        }
        if ([self routeLongName] && [[self routeLongName] length]>0) {
            if (isShortName) {
                [titleText appendFormat:@" - "];
            }
            if ([[self agencyId] isEqualToString:@"BART"]) {
                [titleText appendString:@"BART"];  // special case for BART -- just show "BART" rather than route name
            } else {
                [titleText appendFormat:@"%@", [self routeLongName]];
            }
        }
        if ([self headSign] && [[self headSign] length]>0) {
            [titleText appendFormat:@" to %@", [self headSign]];
        }
        if (areRealTimeUpdates) {
            if ([self.arrivalFlag intValue] == ON_TIME) {
                [titleText appendString:@" (On-Time)"];
            }
            else if([self.arrivalFlag intValue] == DELAYED) {
                [titleText appendString:@" (Delayed)"];
            }
            else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
                [titleText appendString:@" (Early)"];
            }
        }
    }
    return titleText;
    }
    @catch (NSException *exception) {
        logException(@"Leg->directionsTitleText:", @"", exception);
        return @"";
    }
}

- (NSString *)directionsDetailText:(LegPositionEnum)legPosition
{
    @try {
    NSString *subTitle;
    if (self.isWalk || self.isBike) {
        if (legPosition == FIRST_LEG) {
            subTitle = [NSString stringWithFormat:@"From %@ (%@)",
                        [[self itinerary] fromAddressString], 
                        distanceStringInMilesFeet([[self distance] floatValue])];
        } else {
            subTitle = [NSString stringWithFormat:@"About %@, %@", 
                        durationString([[self duration] floatValue]), 
                        distanceStringInMilesFeet([[self distance] floatValue])];
        }
    }
    else {
        // Part Of DE-229 & US-169 Implementation
        if([self.arrivalFlag intValue] == DELAYED) {
            NSDate* realTimeArrivalTime = [[self endTime]
                                           dateByAddingTimeInterval:[timeDiffInMins floatValue]*60.0];
            if(realTimeArrivalTime){
                subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                            superShortTimeStringForDate(realTimeArrivalTime),
                            [[self to] name]];
            }
            else{
                subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                            superShortTimeStringForDate([self endTime]),
                            [[self to] name]];
            }
            NIMLOG_EVENT1(@"Updated time: %@", subTitle);
        }
        else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
            NSDate* realTimeArrivalTime = [[self endTime]
                                           dateByAddingTimeInterval:[timeDiffInMins floatValue]*(-60.0)];
            if(realTimeArrivalTime){
                subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                            superShortTimeStringForDate(realTimeArrivalTime),
                            [[self to] name]];
            }
            else{
                subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                            superShortTimeStringForDate([self endTime]),
                            [[self to] name]];
            }
            NIMLOG_EVENT1(@"Updated time: %@", subTitle);
        }
        else {
            subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                        superShortTimeStringForDate([self endTime]),
                        [[self to] name]];
        }
                    
    }
    return subTitle;
    }
@catch (NSException *exception) {
    logException(@"Leg->directionsDetailText", @"", exception);
    return @"";
}
}


//Implemented by Sitanshu Joshi
-(BOOL)isWalk
{
    if ([[self mode] isEqualToString:OTP_WALK_MODE]) {   
        return true;   
    }
    return false;
}

-(BOOL)isBike{
    if ([[self mode] isEqualToString:OTP_BIKE_MODE]) {
        return true;
    }
    return false;
}


-(BOOL)isHeavyTrain
{
    if ([[self mode] isEqualToString:OTP_RAIL_MODE] && [[self agencyId] isEqualToString:CALTRAIN_AGENCY_ID]) {
        return true;
    } else {
        return false;
    }
}

-(BOOL)isTrain
{
    if ([[self mode] isEqualToString:OTP_RAIL_MODE] || [[self mode] isEqualToString:OTP_TRAM_MODE] ||
        [[self mode] isEqualToString:OTP_SUBWAY_MODE] || [[[self mode] lowercaseString] isEqualToString:OTP_CABLE_CAR]) {
        return true;
    } // else
    return false;
}
-(BOOL)isBus
{
    if ([[self mode] isEqualToString:@"BUS"]) {   
        return true;   
    } 
    return false;
}
-(BOOL)isSubway
{
    if ([[self mode] isEqualToString:OTP_SUBWAY_MODE]) {   
        return true;   
    } 
    return false; 
}
-(BOOL)isFerry
{
    if ([[[self mode] lowercaseString] isEqualToString:OTP_FERRY]) {
        return true;
    }
    return false;
}

// return false if leg is walk or bicycle otherwise return true.
-(BOOL)isScheduled{
    if (self.isWalk || self.isBike)
        return false;
    return true;
}
// True if the main characteristics of referring Leg is equal to leg0
// Compares timeOnly components of startTime and of endTime, to name, and from name
- (BOOL)isEqualInSubstance:(Leg *)leg0
{
    if ([timeOnlyFromDate([leg0 startTime]) isEqualToDate:timeOnlyFromDate([self startTime])] &&
        [timeOnlyFromDate([leg0 endTime]) isEqualToDate:timeOnlyFromDate([self endTime])] &&
        [[[leg0 from] name] isEqualToString:[[self from] name]] &&
        [[[leg0 to] name] isEqualToString:[[self to] name]] &&
        [[leg0 route] isEqualToString:[self route]]) {
        return TRUE;
    } else {
        return FALSE;
    }
}

// Compare Two Legs whether they have the same routes and start and endpoints
// If Leg is walk then compatr TO&From location lat/Lng and distance.
// Does not compare times (this test is primarily for determining unique itineraries).
// If leg is not walk then compare modes, TO&From Location Lat/Lng and agencyname.
// If legs are equal then return yes otherwise return no
- (BOOL) isEquivalentModeAndStopsAs:(Leg *)leg{
    if((self.isWalk && leg.isWalk) || (self.isBike && leg.isBike)){
        if([self.to.lat doubleValue] != [leg.to.lat doubleValue] || [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] !=[leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue] || [self.distance doubleValue] != [leg.distance doubleValue]){
            return NO;
        }
        return YES;
    }
    else if([self.mode isEqualToString:leg.mode]){
        if(![self.agencyName isEqualToString:leg.agencyName] || [self.to.lat doubleValue] != [leg.to.lat doubleValue] ||  [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] != [leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue] || ![self.routeId isEqualToString:leg.routeId]){
            return NO;
        }
        return YES;
    }
    else{
        return NO;
    }
}

- (BOOL) isEquivalentModeAndStopsAndRouteAs:(Leg *)leg{
    if((self.isWalk && leg.isWalk) || (self.isBike && leg.isBike)){
        if([self.to.lat doubleValue] != [leg.to.lat doubleValue] || [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] !=[leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue] || [self.distance doubleValue] != [leg.distance doubleValue]){
            return NO;
        }
        return YES;
    }
    else if([self.mode isEqualToString:leg.mode]){
        if(![self.agencyName isEqualToString:leg.agencyName] || [self.to.lat doubleValue] != [leg.to.lat doubleValue] ||  [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] != [leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue] || ![self.routeId isEqualToString:leg.routeId]){
            return NO;
        }
        return YES;
    }
    else{
        return NO;
    }
}
- (NSString *)ncDescription
{
    NSMutableString* desc = [NSMutableString stringWithFormat:
                             @"{Leg Object: mode: %@;  headSign: %@;  endTime: %@ ... ", [self mode], [self headSign], [self endTime]];
    for (Step *step in [self steps]) {
        [desc appendString:[NSString stringWithFormat:@"\n%@", [step ncDescription]]];
    }
    return desc;
}

// Set the newly generated leg attributes from old leg
- (void) setNewlegAttributes:(Leg *)leg{
    self.agencyId = leg.agencyId;
    self.agencyName = leg.agencyName;
    self.distance = leg.distance;
    self.duration = leg.duration;
    self.headSign = leg.headSign;
    self.legGeometryLength = leg.legGeometryLength;
    self.legGeometryPoints = leg.legGeometryPoints;
    self.mode = leg.mode;
    self.routeId = leg.routeId;
    self.route = leg.route;
    self.routeLongName = leg.routeLongName;
    self.routeShortName = leg.routeShortName;
    self.tripShortName = leg.tripShortName;
    self.tripId = leg.tripId;
    self.headSign = leg.headSign;
    
    PlanPlace* from = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:self.managedObjectContext];
    from.lat = leg.from.lat;
    from.lng = leg.from.lng;
    from.name = leg.from.name;
    from.stopId = leg.from.stopId;
    self.from = from;
    
    
    PlanPlace * toPlace = [NSEntityDescription insertNewObjectForEntityForName:@"PlanPlace" inManagedObjectContext:self.managedObjectContext];
    toPlace.lat = leg.to.lat;
    toPlace.lng = leg.to.lng;
    toPlace.name = leg.to.name;
    toPlace.stopId = leg.to.stopId;
    self.to = toPlace;
    
    self.steps = leg.steps;
    self.sortedSteps = leg.sortedSteps;
    self.polylineEncodedString = leg.polylineEncodedString;
}

// return startTime only from real time if exists otherwise return leg starttime only. 
- (NSDate *) getApplicableStartTime{
    if(self.realStartTime){
       NSDate *realStartTimeOnly = self.realStartTime;
        return realStartTimeOnly;
    }
    else{
        NSDate *startTimeOnly = self.startTime;
        return startTimeOnly;
    }
}

// return endTime only from real time if exists otherwise return leg endtime only.
- (NSDate *) getApplicableEndTime{
    if(self.realEndTime){
         NSDate *realEndTimeOnly = self.realEndTime;
        return realEndTimeOnly;
    }
    else{
         NSDate *endTimeOnly = self.endTime;
        return endTimeOnly;
    }
}

// return the leg at offset from current leg and sorted legs
-(Leg *) getLegAtOffsetFromListOfLegs:(NSArray *)sortedLegs offset:(int) offset{
    Leg *newLeg = nil;
    for(int i=0;i<[sortedLegs count];i++){
        if([[sortedLegs objectAtIndex:i] isEqual:self]){
            if( i+offset >= 0 && i+offset < [sortedLegs count])
                newLeg = [sortedLegs objectAtIndex:i+offset];
        }
    }
    return newLeg;
}

// Calculate time difference in minutes for leg.

- (int) calculatetimeDiffInMins:(double)epochTime{
    NSDate *realTimeDate = [NSDate dateWithTimeIntervalSince1970:(epochTime/1000.0)];
    double millisecondsSchedule = ([timeOnlyFromDate(self.startTime) timeIntervalSince1970])*1000.0;
    double millisecondsRealTime = ([timeOnlyFromDate(realTimeDate) timeIntervalSince1970])*1000.0;
    double timeDiffInMilliSeconds = millisecondsRealTime - millisecondsSchedule;
    int timeDiffInMinutes = timeDiffInMilliSeconds/(60*1000);
    return timeDiffInMinutes;
}

// return arrival time flag for leg.
- (int) calculateArrivalTimeFlag:(int)timeDifference{
    if(timeDifference >= -2 && timeDifference <= 2)
        return ON_TIME;
    else if(timeDifference < -2)
        return EARLY;
    else
        return DELAYED;
}

// set timediffInMins,realStartTime,realEndTime and arrivalFlag for leg from realTime data.
//- (void) setRealTimeParametersUsingEpochTime:(double)epochTime{
//    int timeDiffs = [self calculatetimeDiffInMins:epochTime];
//    self.arrivalFlag = [NSString stringWithFormat:@"%d",[self calculateArrivalTimeFlag:timeDiffs]];
//    if(timeDiffs < 0)
//        timeDiffs = -timeDiffs;
//    self.timeDiffInMins = [NSString stringWithFormat:@"%d",timeDiff];
//    self.realStartTime = [NSDate dateWithTimeIntervalSince1970:(epochTime/1000.0)];
//    self.arrivalTime = [NSDate dateWithTimeIntervalSince1970:(epochTime/1000.0)];
//    self.realEndTime = [[self endTime] dateByAddingTimeInterval:([self.timeDiffInMins intValue]*60*1000)];
//}

@end
