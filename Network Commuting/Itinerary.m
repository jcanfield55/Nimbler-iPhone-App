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
@synthesize sortedLegs;
@synthesize itinArrivalFlag;

// TODO Add an awake method to populate itineraryCreationDate

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
    return [[sortedLegs objectAtIndex:([sortedLegs count]-1)] to];
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
    if (distance < 20.0) {
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
