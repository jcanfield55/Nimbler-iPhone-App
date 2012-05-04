//
//  AgencyAndId.m
//  Network Commuting
//
//  Created by John Canfield on 1/29/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

// Object class for Open Trip Planner AgencyAndId class

#import "AgencyAndId.h"

@implementation AgencyAndId

@synthesize agency;
@synthesize id;

+ (RKObjectMapping *)objectMappingForApi:(APIType)tpt
{
    // Create empty ObjectMapping to fill and return
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[AgencyAndId class]];
    
    // Make the mappings
    if (tpt==OTP_PLANNER) {
        [mapping mapKeyPath:@"agency" toAttribute:@"agency"];
        [mapping mapKeyPath:@"id" toAttribute:@"id"];
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{Agency: %@;  Id: %@}",
                      agency, id];
    return desc;
}

@end
