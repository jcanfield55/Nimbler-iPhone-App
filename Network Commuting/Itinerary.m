//
//  Itinerary.m
//  Network Commuting
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Itinerary.h"
#import "Leg.h"
#import "Plan.h"

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
@dynamic duration;
@dynamic elevationGained;
@dynamic elevationLost;
@dynamic endTime;
@dynamic fareInCents;
@dynamic itineraryCreationDate;
@dynamic startTime;
@dynamic tooSloped;
@dynamic transfers;
@dynamic transitTime;
@dynamic waitingTime;
@dynamic walkDistance;
@dynamic walkTime;
@dynamic legs;
@dynamic plan;
@dynamic itinId;
@dynamic planRequestChunk;
@synthesize sortedLegs;
@synthesize itinArrivalFlag;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[Itinerary class]];
    RKManagedObjectMapping* legMapping = [Leg objectMappingForApi:apiType];
    
    // Make the mappings
    if (apiType==OTP_PLANNER) {
        
        [mapping mapKeyPath:@"id" toAttribute:@"itinId"];
        [mapping mapKeyPath:@"duration" toAttribute:@"duration"];
        [mapping mapKeyPath:@"elevationGained" toAttribute:@"elevationGained"];
        [mapping mapKeyPath:@"elevationLost" toAttribute:@"elevationLost"];
        [mapping mapKeyPath:@"endTime" toAttribute:@"endTime"];
        [mapping mapKeyPath:@"fare.fare.regular.cents" toAttribute:@"fareInCents"];
        [mapping mapKeyPath:@"startTime" toAttribute:@"startTime"];
        [mapping mapKeyPath:@"tooSloped" toAttribute:@"tooSloped"];
        [mapping mapKeyPath:@"transfers" toAttribute:@"transfers"];
        [mapping mapKeyPath:@"transitTime" toAttribute:@"transitTime"];
        [mapping mapKeyPath:@"waitingTime" toAttribute:@"waitingTime"];
        [mapping mapKeyPath:@"walkDistance" toAttribute:@"walkDistance"];
        [mapping mapKeyPath:@"walkTime" toAttribute:@"walkTime"];
        
        [mapping mapKeyPath:@"legs" toRelationship:@"legs" withMapping:legMapping];
        [mapping performKeyValueValidation];
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}


- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // Set the date
    [self setItineraryCreationDate:[NSDate date]];
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

// Compares the itineraries to see if they are equivalent in substance
- (ItineraryCompareResult)compareItineraries:(Itinerary *)itin0
{
    if (self == itin0) {
        return ITINERARIES_IDENTICAL;
    } else if ([[itin0 startTimeOfFirstLeg] isEqualToDate:[self startTimeOfFirstLeg]]) {
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
            if ([[itin0 itineraryCreationDate] isEqualToDate:[self itineraryCreationDate]]) {
                return ITINERARIES_SAME;
            } else if ([[itin0 itineraryCreationDate] laterDate:[self itineraryCreationDate]] == [itin0 itineraryCreationDate]) {
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

// Returns a sorted array of the title strings to show itinerary details as needed
// for display a route details view.  Might have more elements than legs in the itinerary.  
// Adds a start and/or end point if needed.  Modifies the first and last walking
// leg if needed. 
- (NSArray *)legDescriptionTitleSortedArray
{
    if (!legDescTitleSortedArr) {
        [self makeLegDescriptionSortedArrays];
    }
    return legDescTitleSortedArr;
}

// Same as above, but returns the subtitles
- (NSArray *)legDescriptionSubtitleSortedArray
{
    if (!legDescSubtitleSortedArr) {
        [self makeLegDescriptionSortedArrays];
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
        if (i==0) { // First leg of itinerary
            // If first leg is not a walking leg, insert a startpoint entry (US124 implementation)
            if (![[leg mode] isEqualToString:@"WALK"]) {
                [titleArray addObject:
                 [NSString stringWithFormat:@"%@%@", ROUTE_STARTPOINT_PREFIX, [self fromAddressString]]];
                [subtitleArray addObject:@""];
                [legMapArray addObject:[NSNull null]];
            }
            // Now insert first leg text
            [titleArray addObject:[leg directionsTitleText:FIRST_LEG]];
            [subtitleArray addObject:[leg directionsDetailText:FIRST_LEG]];
            [legMapArray addObject:leg];
            
            // If there is only one leg, and it is not a walking one, insert an endpoint (US124)
            if ([legsArray count] == 1 && ![[leg mode] isEqualToString:@"WALK"]) {
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

            // If last leg is not a walking leg, insert an endpoint entry (US124)
            if (![[leg mode] isEqualToString:@"WALK"]) {
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
    NSLog(@"Distance between fromLocation and fromPlanPlace = %f meters", distance);
    
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
    NSLog(@"Distance between toLocation and toPlanPlace = %f meters", distance);
    
    // If distance in meters is small enough, use the toLocation...
    if (distance < 40.0) {
        return [toLocation shortFormattedAddress];
    }
    // otherwise, use the planPlace string from OTP
    return [[self to] name];
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

@end
