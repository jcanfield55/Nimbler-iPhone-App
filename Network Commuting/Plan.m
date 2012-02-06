//
//  Plan.m
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Plan.h"

@implementation Plan

@synthesize date;
@synthesize from;
@synthesize to;

+ (RKObjectMapping *)objectMappingforPlanner:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[Plan class]];

    RKObjectMapping* planPlaceMapping = [PlanPlace objectMappingForApi:apiType];

    // Make the mappings
    if (apiType==OTP_PLANNER) {
        // TODO  Do all the mapping
        [mapping mapKeyPath:@"date" toAttribute:@"date"];
        [mapping mapKeyPath:@"from" toRelationship:@"from" withMapping:planPlaceMapping];
        [mapping mapKeyPath:@"to" toRelationship:@"to" withMapping:planPlaceMapping];

    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{Plan Object: date: %@;  from: %@;  to: %@}",date, from, to];
    return desc;
}

@end
