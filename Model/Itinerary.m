//
//  Itinerary.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Itinerary.h"
#import "Leg.h"
#import "Plan.h"
#import "UtilityFunctions.h"
#import "nc_AppDelegate.h"
#import "ItineraryFromOTP.h"

// Utility function for sorting sets of itineraries
NSArray *sortedByStartTimeOnly(NSSet* itinerarySet)
{
    NSSortDescriptor* sd = [NSSortDescriptor sortDescriptorWithKey:@"startTimeOnly" ascending:YES];
    return [itinerarySet sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]];
}


@interface Itinerary()
{
    // Internal variables
    NSArray* legDescTitleSortedArr;
    NSArray* legDescSubtitleSortedArr;
    NSArray* legDescToLegMapArray;
}

//Internal methods
- (void)makeLegDescriptionSortedArrays;  

@end

@implementation Itinerary
@dynamic requestChunksCreatedByThisPattern;
@dynamic duration;
@dynamic endTime;
@dynamic endTimeOnly;
@dynamic itineraryCreationDate;
@dynamic startTime;
@dynamic startTimeOnly;
@dynamic legs;
@dynamic plan;
@dynamic uniqueItineraryForPlan;
@dynamic itinId;
@dynamic planRequestChunks;
@dynamic elevationGained;
@dynamic elevationLost;
@dynamic fareInCents;
@dynamic tooSloped;
@dynamic transfers;
@dynamic transitTime;
@dynamic waitingTime;
@dynamic walkDistance;
@dynamic walkTime;
@dynamic startTimeOfLeg;

@synthesize sortedLegs;
@synthesize itinArrivalFlag;
@synthesize isRealTimeItinerary;
@synthesize hideItinerary;
@synthesize tripIdhexString;
@synthesize maximumPredictionDate;
@synthesize status;

static NSDate* midnightTimeOnly;  // represents 24:00 for a timeOnly time

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // Set the date
    [self setItineraryCreationDate:[NSDate date]];
}

// Returns true if itinerary is from OTP
- (BOOL)isOTPItinerary {
    return ([self isKindOfClass:[ItineraryFromOTP class]]);
}

// Returns true if itinerary is from Uber API
- (BOOL)isUberItinerary {
    return ([self isKindOfClass:[ItineraryFromUber class]]);
}

// Returns trues if itinerary is a unique itinerary
- (BOOL)isUniqueItinerary {
    return ([self uniqueItineraryForPlan] != nil);
}

// Create the sorted array of itineraries
- (void)sortLegs
{
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    [self setSortedLegs:[[self legs] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]]];
}

- (NSArray *)sortedLegs
{
    if (!sortedLegs) {
        [self sortLegs];  // create the itinerary array
    }
    return sortedLegs;
}

// Returns the start-time of the first leg if there is one, otherwise returns startTime property
- (NSDate *)startTimeOfFirstLeg
{
    NSDate* firstLegStartTime = [[[self sortedLegs] objectAtIndex:0] startTime];
    if (firstLegStartTime) {
        return firstLegStartTime;
    } else {
        return [self startTime];
    }
}

// Returns the end-time of the last leg if there is one, otherwise returns endTime property
- (NSDate *)endTimeOfLastLeg
{
    NSDate* lastLegEndTime = [[[self sortedLegs] objectAtIndex:([[self sortedLegs] count]-1)] endTime];
    if (lastLegEndTime) {
        return lastLegEndTime;
    } else {
        return [self endTime];
    }
}

// Fixed DE-343
// Store start time of First leg into startTimeOfLeg which is stored in itinerary table and the sort itineraries according to that instead of startTimeOnly.
- (void) initializeLegStartTime{
   self.startTimeOfLeg = timeOnlyFromDate([self startTimeOfFirstLeg]); 
}

// Initializes startTimeOnly and endTimeOnly variables based on reqDate
// Computes TimeOnly values using timeOnlyFromDate function
// If either startTime or endTime are on different days than reqDate, then adds/subtracts one day accordingly
// This takes care of requests that cross midnight
- (void)initializeTimeOnlyVariablesWithRequestDate:(NSDate *)reqDate
{
    // Set the startTimeOnly variable
    NSTimeInterval startDayDiff = [dateOnlyFromDate([self startTime]) timeIntervalSinceDate:dateOnlyFromDate(reqDate)];
    if (startDayDiff == 0) {
        [self setStartTimeOnly:timeOnlyFromDate([self startTime])];
    } else {
        [self setStartTimeOnly:[timeOnlyFromDate([self startTime]) dateByAddingTimeInterval:startDayDiff]];
    }
    // Set the endTimeOnly variable
    NSTimeInterval endDayDiff = [dateOnlyFromDate([self endTime]) timeIntervalSinceDate:dateOnlyFromDate(reqDate)];
    if (endDayDiff == 0) {
        [self setEndTimeOnly:timeOnlyFromDate([self endTime])];
    } else {
        [self setEndTimeOnly:[timeOnlyFromDate([self endTime]) dateByAddingTimeInterval:endDayDiff]];
    }
}

// Returns the starting point PlanPlace
- (PlanPlace *)from
{
    return [[[self sortedLegs] objectAtIndex:0] from];
}

// Returns the ending point PlanPlace
- (PlanPlace *)to
{
    return [[[self sortedLegs] objectAtIndex:([sortedLegs count]-1)] to];
}

// Returns true if each leg's starttime is current versus the GTFS file date for that leg's agency
// Otherwise returns false
- (BOOL)isCurrentVsGtfsFilesIn:(TransitCalendar *)transitCalendar
{
    BOOL allLegsMatch = true;
    for (Leg* leg in [self legs]) {
        if ([leg agencyId] && [[leg agencyId] length]>0 &&    // If no agencyId, count as a match
            ![transitCalendar isCurrentVsGtfsFileFor:[leg startTime] agencyId:[leg agencyId]]) {
            allLegsMatch = false;
        }
    }
    return allLegsMatch;
}

// Compares the itineraries to see if they are equivalent in substance
- (ItineraryCompareResult)compareItineraries:(Itinerary *)itin0
{
    if (self == itin0) {
        return ITINERARIES_IDENTICAL;
    }
    else if ([itin0 haveOnlyUnScheduledLeg] && [self haveOnlyUnScheduledLeg]){
        // If both unscheduled, call identical if the legs match in destination regardless of times
        // This is because unscheduled leg times will be adjusted to match request time
        if (![self isEquivalentModesAndStopsAndRouteAs:itin0]) {
            return ITINERARIES_DIFFERENT;
        } else {
            // Itineraries are the same in substance, so indicate which to delete
            if ([[itin0 itineraryCreationDate] isEqualToDate:[self itineraryCreationDate]]) {
                return ITINERARIES_SAME;
            } else if ([[itin0 itineraryCreationDate] compare:[self itineraryCreationDate]] == NSOrderedDescending) {
                return ITIN_SELF_OBSOLETE;
            } else {
                return ITIN0_OBSOLETE;
            }
        }
    }
    else if ([timeOnlyFromDate([itin0 startTimeOfFirstLeg]) isEqualToDate:
                timeOnlyFromDate([self startTimeOfFirstLeg])]) {
        // If the start time is the same, then check if the legs are the same
        NSArray* itin0LegsArray = [itin0 sortedLegs];
        NSArray* selfLegsArray = [self sortedLegs];
        if ([itin0LegsArray count] == [selfLegsArray count]) {
            // if there is the same count of legs
            for (int i=0; i< [itin0LegsArray count]; i++) {
                if (![[itin0LegsArray objectAtIndex:i] isEqualInSubstance:[selfLegsArray objectAtIndex:i]]) {
                    return ITINERARIES_DIFFERENT;
                }
            }
            // Itineraries are the same in substance...
            // If one of the itineraries is used as a pattern for a GTFS request chunk, do not make it obsolete
            if ([[self requestChunksCreatedByThisPattern] count] > 0 &&
                [[itin0 requestChunksCreatedByThisPattern] count] == 0) {
                return ITIN0_OBSOLETE;  // Keep self, since it is pattern and itin0 is not
            }
            else if ([[itin0 requestChunksCreatedByThisPattern] count] > 0 &&
                [[self requestChunksCreatedByThisPattern] count] == 0) {
                return ITIN_SELF_OBSOLETE; // Keep itin0, since it is a pattern and self is not
            }
            else if ([[itin0 requestChunksCreatedByThisPattern] count] > 0 &&
                     [[self requestChunksCreatedByThisPattern] count] > 0) {
                return ITINERARIES_DIFFERENT;  // Both are used as a pattern, so count as different (unlikely event)
            }
            
            // In case that neither are used as a pattern, use the creation date to determine which is obsolete
            if ([[itin0 itineraryCreationDate] isEqualToDate:[self itineraryCreationDate]]) {
                return ITINERARIES_SAME;
            } else if ([[itin0 itineraryCreationDate] compare:[self itineraryCreationDate]] == NSOrderedDescending) {
                return ITIN_SELF_OBSOLETE;
            } else {
                return ITIN0_OBSOLETE;
            }
        } else { // if leg counts not equal
            return ITINERARIES_DIFFERENT;
        }
    } else { // if start-times not the same
        return ITINERARIES_DIFFERENT;
    }
}

- (NSString *)itinerarySummaryStringForWidth:(CGFloat)width Font:(UIFont *)font
{
    NSMutableString *returnString = [NSMutableString stringWithCapacity:30];
    BOOL isFirstLegToDisplay = true;
    BOOL isFirstScheduledLegToDisplay = true;
    for (Leg* leg in [self sortedLegs]) {
        if ([leg mode] && [[leg mode] length] > 0) {
            if ([leg isBike] && [[leg distance] floatValue] > 650.0) { // include bike legs if >650 meters (about 0.4 miles)
                if (!isFirstLegToDisplay) {
                    [returnString appendString:@" -> "];
                } else {
                    isFirstLegToDisplay = false;
                }
                [returnString appendString:stringByTruncatingToWidth([leg summaryTextWithTime:false],
                                                                     width, font)];
            }
            else if ([leg isScheduled]) {  // skip Walk legs
                BOOL includeTime=false;
                if (isFirstScheduledLegToDisplay && ![[leg startTime] isEqualToDate:[self startTimeOfFirstLeg]]) {
                    includeTime = true;  // Include time if first non-walk leg has a different start-time than itinerary
                }
                isFirstScheduledLegToDisplay = false;
                if (!isFirstLegToDisplay) {
                    [returnString appendString:@" -> "];
                } else {
                    isFirstLegToDisplay = false;
                }
                [returnString appendString:stringByTruncatingToWidth([leg summaryTextWithTime:includeTime],
                                                                     width, font)];
            }
        }
    }
    return returnString;
}

// Returns a sorted array of the title strings to show itinerary details as needed
// for display a route details view.  Might have more elements than legs in the itinerary.
// Adds a start and/or end point if needed.  Modifies the first and last walking
// leg if needed.
- (NSArray *)legDescriptionTitleSortedArray
{
    //DE - 170 Fixed
    //Added To load leg data only when we have data to load.
    if(!legDescTitleSortedArr || [nc_AppDelegate sharedInstance].isNeedToLoadRealData){
        [self makeLegDescriptionSortedArrays];
        [nc_AppDelegate sharedInstance].isNeedToLoadRealData = NO;
    }
    return legDescTitleSortedArr;
}

// Same as above, but returns the subtitles
- (NSArray *)legDescriptionSubtitleSortedArray
{
    //DE - 170 Fixed
    //Added To load leg data only when we have data to load.
    if(!legDescSubtitleSortedArr || [nc_AppDelegate sharedInstance].isNeedToLoadRealData){
        [self makeLegDescriptionSortedArrays];
        [nc_AppDelegate sharedInstance].isNeedToLoadRealData = NO;
    }
    return legDescSubtitleSortedArr;
}

// This array has the same # of elements as the above title and subtitle arrays.
// For the same element as the title or subtitle array, this array maps back to the corresponding leg
// if there is one.  If there was an added start or endpoint, the first or last element will return
// NSNull
- (NSArray *)legDescriptionToLegMapArray
{
    if (!legDescToLegMapArray) {
        [self makeLegDescriptionSortedArrays];
    }
    return legDescToLegMapArray;
}

// Returns the number of itinerary rows there are
// This equals the number of rows in the legDescriptionTitleSortedArray.
- (int)itineraryRowCount {
    return [[self legDescriptionToLegMapArray] count];
}

// Internal method for creating the makeLegDescription title, subtitle, and LegMap arrays
- (void)makeLegDescriptionSortedArrays
{
    NSArray* legsArray = [self sortedLegs];
    NSMutableArray* titleArray = [[NSMutableArray alloc] initWithCapacity:[legsArray count]+2];
    NSMutableArray* subtitleArray = [[NSMutableArray alloc] initWithCapacity:[legsArray count]+2];
    NSMutableArray* legMapArray = [[NSMutableArray alloc] initWithCapacity:[legsArray count]+2];
    
    for (int i=0; i < [legsArray count]; i++) {
        Leg* leg = [legsArray objectAtIndex:i];
        @try {
            if (i==0) { // First leg of itinerary
                // If first leg is a scheduled one, insert a startpoint entry (US124 implementation)
                if ([leg isScheduled]) {
                    [titleArray addObject:
                     [NSString stringWithFormat:@"%@%@", ROUTE_STARTPOINT_PREFIX, [self fromAddressString]]];
                    [subtitleArray addObject:@""];
                    [legMapArray addObject:[NSNull null]];
                }
                // Now insert first leg text
                [titleArray addObject:[leg directionsTitleText:FIRST_LEG]];
                [subtitleArray addObject:[leg directionsDetailText:FIRST_LEG]];
                [legMapArray addObject:leg];
                
                // If there is only one leg, and it is a scheduled one, insert an endpoint (US124)
                if ([legsArray count] == 1 && [leg isScheduled]) {
                    [titleArray addObject:
                     [NSString stringWithFormat:@"%@%@", ROUTE_ENDPOINT_PREFIX, [self toAddressString]]];
                    [subtitleArray addObject:@""];
                    [legMapArray addObject:[NSNull null]];
                }
            }
            else if (i == [legsArray count]-1) { // Last leg of itinerary
                // Insert last leg text
                [titleArray addObject:[leg directionsTitleText:LAST_LEG]];
                [subtitleArray addObject:[leg directionsDetailText:LAST_LEG]];
                [legMapArray addObject:leg];
                
                // If last leg is a scheduled one, insert an endpoint entry (US124)
                if ([leg isScheduled]) {
                    [titleArray addObject:
                     [NSString stringWithFormat:@"%@%@", ROUTE_ENDPOINT_PREFIX, [self toAddressString]]];
                    [subtitleArray addObject:@""];
                    [legMapArray addObject:[NSNull null]];
                }
            }
            else { // Middle leg
                [titleArray addObject:[leg directionsTitleText:MIDDLE_LEG]];
                [subtitleArray addObject:[leg directionsDetailText:MIDDLE_LEG]];
                [legMapArray addObject:leg];
            }
        }
        @catch (NSException *exception) {
            logException(@"Itinerary->makeLegDescriptionSortedArrays",
                         [NSString stringWithFormat:@"i= %d, [legsArray count] = %d, [leg mode] = %@, [leg startTime] = %@",
                          i, [legsArray count], [leg mode], [leg startTime]],
                         exception);
        }
    }
    
    // Return non-mutable arrays
    legDescTitleSortedArr = [NSArray arrayWithArray:titleArray];
    legDescSubtitleSortedArr = [NSArray arrayWithArray:subtitleArray];
    legDescToLegMapArray = [NSArray arrayWithArray:legMapArray];
}

// Returns a nicely formatted address string for the starting point, if available
// US87 implementation
- (NSString *)fromAddressString
{
    // Check and make sure that the plan from Location is close to the endpoint of the last leg
    Location* fromLocation = [[self plan] fromLocation];
    CLLocation *locA = [[CLLocation alloc] initWithLatitude:[fromLocation latFloat]
                                                  longitude:[fromLocation lngFloat]];
    CLLocation *locB = [[CLLocation alloc] initWithLatitude:[[self from] latFloat]
                                                  longitude:[[self from] lngFloat]];
    CLLocationDistance distance = [locA distanceFromLocation:locB];
    NIMLOG_DEBUG1(@"Distance between fromLocation and fromPlanPlace = %f meters", distance);
    
    // If distance in meters is small enough, use the fromLocation...
    if (distance < 20.0) {
        return [fromLocation shortFormattedAddress];
    }
    // otherwise, use the planPlace string from OTP
    return [[self from] name];
}

// Returns a nicely formatted address string for the end point, if available
// US87 implementation
- (NSString *)toAddressString
{
    // Check and make sure that the plan to Location is close to the endpoint of the last leg
    Location* toLocation = [[self plan] toLocation];
    CLLocation *locA = [[CLLocation alloc] initWithLatitude:[toLocation latFloat]
                                                  longitude:[toLocation lngFloat]];
    CLLocation *locB = [[CLLocation alloc] initWithLatitude:[[self to] latFloat]
                                                  longitude:[[self to] lngFloat]];
    CLLocationDistance distance = [locA distanceFromLocation:locB];
    NIMLOG_EVENT1(@"Distance between toLocation and toPlanPlace = %f meters", distance);
    
    // If distance in meters is small enough, use the toLocation...
    if (distance < 40.0) {
        return [toLocation shortFormattedAddress];
    }
    // otherwise, use the planPlace string from OTP
    return [[self to] name];
}

// Returns true if self is an itinerary that goes past 3:00am and is >=3 hours in length
// Workaround for OTP tendency to generate itineraries that go overnight past the end of service for
// Caltrain and other agencies.  Robust solution will be to fix OTP
- (BOOL)isOvernightItinerary
{
    if ([[self endTime] timeIntervalSinceDate:[self startTime]] > (3.0*60*60)) { // if time interval > 3 hours
        NSDateComponents* components3am = [[NSDateComponents alloc] init];
        [components3am setHour:3];
        [components3am setMinute:0];
        NSDate* time3am = [[NSCalendar currentCalendar] dateFromComponents:components3am];
        NSDate* dateTime3am = addDateOnlyWithTime(dateOnlyFromDate([self endTime]),time3am);
        if ([dateTime3am compare:[self startTime]] == NSOrderedDescending &&
            [dateTime3am compare:[self endTime]] == NSOrderedAscending) {
            // If self spans 3am...
            return true;
        }
    }
    return false;
}

- (NSString *)ncDescription
{
    NSMutableString* desc = [NSMutableString stringWithFormat:
                             @"{Itinerary Object: duration: %@;  startTime: %@;  endTime: %@ ... ", [self duration], [self startTime], [self endTime]];
    for (Itinerary *leg in [self legs]) {
        [desc appendString:[NSString stringWithFormat:@"\n %@", [leg ncDescription]]];
    }
    return desc;
}

- (BOOL) isEquivalentModesAndStopsAndRouteAs:(Itinerary *)itinerary{
    NSArray *arrItinerary1 = [self sortedLegs];
    NSArray *arrItinerary2 = [itinerary sortedLegs];
    if([arrItinerary1 count] == [arrItinerary2 count]){
        for(int i=0;i<[arrItinerary1 count];i++){
            Leg *leg1 = [arrItinerary1 objectAtIndex:i];
            Leg *leg2 = [arrItinerary2 objectAtIndex:i];
            if(![leg1 isEquivalentModeAndStopsAndRouteAs:leg2]){
                return NO;
            }
        }
        return YES;
    }
    else{
        return NO;
    }
}

// Compare Two Itineraries whether they have the same modes, agencies, and stops. 
// Does not compare times (this test is primarily for determining unique itineraries).
// This match itinerary like leg by leg if all match the return yes otherwise return no.
- (BOOL) isEquivalentModesAndStopsAs:(Itinerary *)itinerary{
    NSArray *arrItinerary1 = [self sortedLegs];
    NSArray *arrItinerary2 = [itinerary sortedLegs];
    if([arrItinerary1 count] == [arrItinerary2 count]){
        for(int i=0;i<[arrItinerary1 count];i++){
            Leg *leg1 = [arrItinerary1 objectAtIndex:i];
            Leg *leg2 = [arrItinerary2 objectAtIndex:i];
            if(![leg1 isEquivalentModeAndStopsAs:leg2]){
                return NO;
            }
        }
        return YES;
    }
    else{
        return NO;
    }
}

// Compare Two Itineraries whether they have the same routes and start & endpoints
// Compares times just for scheduled legs (not for unscheduled legs)
// This match itinerary like leg by leg if all match the return yes otherwise return no.
- (BOOL)isEquivalentRoutesStopsAndScheduledTimingAs:(Itinerary *)itinerary
{
    NSArray *arrItinerary1 = [self sortedLegs];
    NSArray *arrItinerary2 = [itinerary sortedLegs];
    if([arrItinerary1 count] == [arrItinerary2 count]){
        for(int i=0;i<[arrItinerary1 count];i++){
            Leg *leg1 = [arrItinerary1 objectAtIndex:i];
            Leg *leg2 = [arrItinerary2 objectAtIndex:i];
            if (leg1.isScheduled && leg2.isScheduled && ![leg1 isEqualInSubstance:leg2]) {
                return NO;  // Compare times just for scheduled legs
            } else if(![leg1 isEquivalentModeAndStopsAs:leg2]){
                return NO;  // Otherwise compare just routes, start & endpoints
            }
        }
        return YES;
    }
    else{
        return NO;
    }
}

// Set Itinerary RealTime from Legs RealTime
// If itinerary has one scheduled leg then itinerary realtime is same as scheduled leg realtime.
// If itinerary have more than one scheduled leg then check if one leg is early and other is delayed then realtime for itinerary is time slipage else if all flag have same realtime then itinerary realtime is same as scheduled legs realtime else leg is not delayed or early then itinerary real time is ontime.
- (void) setArrivalFlagFromLegsRealTime{
    BOOL delayed = false;
    BOOL early = false;
    BOOL ontime = false;
    for(int i=0;i<[[self sortedLegs] count];i++){
        Leg *leg = [[self sortedLegs] objectAtIndex:i];
        if([leg isScheduled]){
            if([[leg arrivalFlag]intValue] == DELAYED)
                delayed = true;
            if([[leg arrivalFlag] intValue] == EARLY)
                early = true;
            if([[leg arrivalFlag] intValue] == ON_TIME)
                ontime = true;
        }
    }
    if(ontime && delayed && early)
       [self setItinArrivalFlag:[NSString stringWithFormat:@"%d",ITINERARY_TIME_SLIPPAGE]];
    else if(ontime && delayed)
        [self setItinArrivalFlag:[NSString stringWithFormat:@"%d",ITINERARY_TIME_SLIPPAGE]];
    else if(ontime && early)
        [self setItinArrivalFlag:[NSString stringWithFormat:@"%d",ITINERARY_TIME_SLIPPAGE]];
    else if(delayed && early)
        [self setItinArrivalFlag:[NSString stringWithFormat:@"%d",ITINERARY_TIME_SLIPPAGE]];
    else if(ontime)
        [self setItinArrivalFlag:[NSString stringWithFormat:@"%d",ON_TIME]];
    else if(delayed)
        [self setItinArrivalFlag:[NSString stringWithFormat:@"%d",DELAYED]];
    else if(early)
        [self setItinArrivalFlag:[NSString stringWithFormat:@"%d",EARLY]];
}

// return the conflict leg from sorted legs of itinerary
- (Leg *) conflictLegFromItinerary{
    for(int i=1;i<[[self sortedLegs] count];i++){
        Leg *currentLeg = [[self sortedLegs] objectAtIndex:i];
        Leg *previousLeg = [[self sortedLegs] objectAtIndex:i-1];
        Leg *nextLeg = nil;
        if([[self sortedLegs] count] > i+1)
            nextLeg = [[self sortedLegs] objectAtIndex:i+1];
        
        if (nextLeg && [[currentLeg getApplicableEndTime] compare:[nextLeg getApplicableStartTime]] == NSOrderedDescending)
            return currentLeg;
        else if(previousLeg && [[previousLeg getApplicableEndTime] compare:[currentLeg getApplicableStartTime]] == NSOrderedDescending)
            return currentLeg;
    }
    return nil;
}

// Adjust the legs in itinerary if possible otherwise return conflictleg.
// First Find the conflict leg from itinerary the check if next leg and it is scheduled then return conflict leg.
// Find next to next leg if it is then check if new computed end date comes after start date then return leg.
// then compute realtime data for next leg from conflict leg realtime.
- (Leg *) adjustLegsIfRequired{
    Leg *leg = [self conflictLegFromItinerary];
    if([leg.arrivalFlag intValue] == EARLY){
        Leg *previousLeg = [leg getLegAtOffsetFromListOfLegs:self.sortedLegs offset:-1];
        if(!previousLeg || [previousLeg isScheduled])
            return leg;
        Leg *previousToPreviousLeg = [leg getLegAtOffsetFromListOfLegs:self.sortedLegs offset:-2];
        if(previousToPreviousLeg){
            NSDate *startDate = previousLeg.startTime;
            NSDate *endDate = timeOnlyFromDate(previousToPreviousLeg.endTime);
            NSDate *newEndDate = timeOnlyFromDate([endDate dateByAddingTimeInterval:[leg.timeDiffInMins intValue]*60]);
            if ([newEndDate compare:startDate] == NSOrderedDescending)
                return leg;
        }
        int diffInMin = [leg.timeDiffInMins intValue];
        if(diffInMin < 0)
            diffInMin = - diffInMin;
        previousLeg.timeDiffInMins = leg.timeDiffInMins;
        previousLeg.arrivalFlag = leg.arrivalFlag;
        previousLeg.arrivalTime = [previousLeg.endTime dateByAddingTimeInterval:diffInMin * 60];
        return nil;
    }
    else{
        Leg *nextLeg = [leg getLegAtOffsetFromListOfLegs:self.sortedLegs offset:1];
        if(!nextLeg || [nextLeg isScheduled])
            return leg;
        Leg *nextToNextLeg = [leg getLegAtOffsetFromListOfLegs:self.sortedLegs offset:2];
        if(nextToNextLeg){
            NSDate *endDate = nextLeg.endTime;
            NSDate *startDate = timeOnlyFromDate(nextToNextLeg.startTime);
            NSDate *newEndDate = timeOnlyFromDate([endDate dateByAddingTimeInterval:[leg.timeDiffInMins intValue]*60]);
            if ([newEndDate compare:startDate] == NSOrderedDescending)
                return leg;
        }
        int diffInMin = [leg.timeDiffInMins intValue];
        nextLeg.timeDiffInMins = leg.timeDiffInMins;
        nextLeg.arrivalFlag = leg.arrivalFlag;
        nextLeg.arrivalTime = [nextLeg.endTime dateByAddingTimeInterval:diffInMin * 60];
        return nil;
    }
}

- (BOOL)containsBikeLeg{
    for(int i=0;i<[self.sortedLegs count];i++){
        Leg *leg = [self.sortedLegs objectAtIndex:i];
        if([leg isBike])
            return true;
    }
    return false;
}

- (BOOL)containsUnscheduledLeg{
    for(int i=0;i<[self.sortedLegs count];i++){
        Leg *leg = [self.sortedLegs objectAtIndex:i];
        if([leg isWalk])
            return true;
    }
    return false;
}
// return true if itinerary have only unscheduled leg.
- (BOOL) haveOnlyUnScheduledLeg{
    for(int i=0;i<[self.sortedLegs count];i++){
        Leg *leg = [self.sortedLegs objectAtIndex:i];
        if([leg isScheduled])
            return false;
    }
    return true;
}

// Returns true if the itinerary is valid given the requestTime, buffer time intervals before & after
// the request, and the depOrArrive.
// Note, for arrive requests, intervalBeforeRequest actually is the buffer time after the request date (slack for being late)
- (BOOL) isWithinRequestTime:(NSDate *)requestTime
       intervalBeforeRequest:(NSTimeInterval)intervalBeforeRequest
        intervalAfterRequest:(NSTimeInterval)intervalAfterRequest
              departOrArrive:(DepartOrArrive)depOrArrive
{
    NSDate* requestTimeOnly = timeOnlyFromDate(requestTime);
    if (depOrArrive == DEPART) {
        NSDate* requestTimeWithPreBuffer = [requestTimeOnly dateByAddingTimeInterval:(-intervalBeforeRequest)];
        NSDate* requestTimeWithPostBuffer = [requestTimeOnly dateByAddingTimeInterval:intervalAfterRequest];
        if ([requestTimeWithPreBuffer compare:[self startTimeOnly]]!=NSOrderedDescending &&
            [requestTimeWithPostBuffer compare:[self startTimeOnly]]!=NSOrderedAscending) {
            // If itin start time is within the two buffer ranges
            return true;
        }
    } else { // depOrArrive = ARRIVE
        NSDate* requestTimeWithPreBuffer = [requestTimeOnly dateByAddingTimeInterval:(intervalBeforeRequest)];
        NSDate* requestTimeWithPostBuffer = [requestTimeOnly dateByAddingTimeInterval:-intervalAfterRequest];
        if ([requestTimeWithPreBuffer compare:[self endTimeOnly]]!=NSOrderedAscending &&
            [requestTimeWithPostBuffer compare:[self endTimeOnly]]!=NSOrderedDescending) {
            // If itin start time is within the two buffer ranges
            return true;
        }
    }
    return false;
}

// Returns true if all the itinerary's legs' serviceDays match the serviceDays for requestDate
- (BOOL)doAllServiceDaysMatchDate:(NSDate *)requestDate
{
    TransitCalendar* transitCalendar = [TransitCalendar transitCalendar];
    if (!midnightTimeOnly) {
        NSCalendar* currentCalendar = [NSCalendar currentCalendar];
        NSDateComponents* midnightTimeComponents = [[NSDateComponents alloc] init];
        [midnightTimeComponents setDay:2];
        midnightTimeOnly = [currentCalendar dateFromComponents:midnightTimeComponents];
    }
    if ([self.startTimeOnly compare:midnightTimeOnly] != NSOrderedAscending) {
        // handle past midnight case by adjusting requestDate to be a day later
        requestDate = [requestDate dateByAddingTimeInterval:(24*60*60)];  // add one day
    }
    for (Leg* leg in [self sortedLegs]) {
        NSString* agencyId = [leg agencyId];
        if (agencyId && [agencyId length]>0 &&
            ![transitCalendar isEquivalentServiceDayFor:requestDate And:[leg startTime] agencyId:agencyId]) { // Check if there is an agency for this leg
            return false;
        }
    }
    return true;
}

@end
