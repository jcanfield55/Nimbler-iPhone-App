//
//  Step.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Step.h"
#import "Leg.h"


@implementation Step

@dynamic absoluteDirection;
@dynamic bogusName;
@dynamic distance;
@dynamic exit;
@dynamic relativeDirection;
@dynamic startLat;
@dynamic startLng;
@dynamic stayOn;
@dynamic streetName;
@dynamic leg;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[Step class]];
        
    // Make the mappings
    if (apiType==OTP_PLANNER) {
        [mapping mapKeyPath:@"absoluteDirection" toAttribute:@"absoluteDirection"];
        [mapping mapKeyPath:@"bogusName" toAttribute:@"bogusName"];
        [mapping mapKeyPath:@"distance" toAttribute:@"distance"];
        [mapping mapKeyPath:@"exit" toAttribute:@"exit"];
        [mapping mapKeyPath:@"relativeDirection" toAttribute:@"relativeDirection"];
        [mapping mapKeyPath:@"lat" toAttribute:@"startLat"];
        [mapping mapKeyPath:@"lon" toAttribute:@"startLng"];
        [mapping mapKeyPath:@"stayOn" toAttribute:@"stayOn"];
        [mapping mapKeyPath:@"streetName" toAttribute:@"streetName"];
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

- (NSString *)ncDescription
{
    NSString* desc = [NSString stringWithFormat:
                             @"{Step Object: streetName: %@;  distance: %@; ... ", [self streetName], [self distance]];
    return desc;
}


@end
