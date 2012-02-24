//
//  Leg.m
//  Network Commuting
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Leg.h"
#import "Itinerary.h"
#import "PlanPlace.h"
#import "Step.h"


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
@dynamic route;
@dynamic routeLongName;
@dynamic routeShortName;
@dynamic startTime;
@dynamic tripShortName;
@dynamic from;
@dynamic itinerary;
@dynamic steps;
@dynamic to;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[Leg class]];
    RKManagedObjectMapping* stepsMapping = [Step objectMappingForApi:apiType];
    RKManagedObjectMapping* planPlaceMapping = [PlanPlace objectMappingForApi:apiType];

    // Make the mappings
    if (apiType==OTP_PLANNER) {
        
        [mapping mapKeyPath:@"agencyId" toAttribute:@"agencyId"];
        [mapping mapKeyPath:@"bogusNonTransitLeg" toAttribute:@"bogusNonTransitLeg"];
        [mapping mapKeyPath:@"distance" toAttribute:@"distance"];
        [mapping mapKeyPath:@"duration" toAttribute:@"duration"];
        [mapping mapKeyPath:@"endTime" toAttribute:@"endTime"];
        [mapping mapKeyPath:@"headSign" toAttribute:@"headSign"];
        [mapping mapKeyPath:@"interlineWithPreviousLeg" toAttribute:@"interlineWithPreviousLeg"];
        [mapping mapKeyPath:@"legGeometry.length" toAttribute:@"legGeometryLength"];
        [mapping mapKeyPath:@"legGeometry.points" toAttribute:@"legGeometryPoints"];
        [mapping mapKeyPath:@"mode" toAttribute:@"mode"];
        [mapping mapKeyPath:@"route" toAttribute:@"route"];
        [mapping mapKeyPath:@"routeLongName" toAttribute:@"routeLongName"];
        [mapping mapKeyPath:@"routeShortName" toAttribute:@"routeShortName"];
        [mapping mapKeyPath:@"startTime" toAttribute:@"startTime"];
        [mapping mapKeyPath:@"tripShortName" toAttribute:@"tripShortName"];

        [mapping mapKeyPath:@"steps" toRelationship:@"steps" withMapping:stepsMapping];
        [mapping mapKeyPath:@"from" toRelationship:@"from" withMapping:planPlaceMapping];
        [mapping mapKeyPath:@"to" toRelationship:@"to" withMapping:planPlaceMapping];
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

- (NSString *)ncDescription
{
    NSMutableString* desc = [NSMutableString stringWithFormat:
                             @"{Leg Object: mode: %@;  headSign: %@;  endTime: %@ ... ", [self mode], [self headSign], [self endTime]];
    for (Itinerary *step in [self steps]) {
        [desc appendString:[NSString stringWithFormat:@"\n%@", [step ncDescription]]];
    }
    return desc;
}

@end
