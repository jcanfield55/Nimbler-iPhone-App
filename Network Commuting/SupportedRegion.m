//
//  bayArea.m
//  Nimbler
//
//  Created by JaY Kumbhani on 5/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SupportedRegion.h"

@implementation SupportedRegion

@synthesize lowerLeftLatitude;
@synthesize lowerLeftLongitude;
@synthesize maxLatitude;
@synthesize maxLongitude;
@synthesize minLatitude;
@synthesize minLongitude;
@synthesize transitModes;
@synthesize upperRightLatitude;
@synthesize upperRightLongitude;


+ (RKManagedObjectMapping *)objectMappingforRegion:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[SupportedRegion class]];
    // Make the mappings
    if (apiType==BAYAREA_PLANNER) {
        // TODO  Do all the mapping       
        [mapping mapKeyPath:@"lowerLeftLatitude" toAttribute:@"lowerLeftLatitude"];
        [mapping mapKeyPath:@"lowerLeftLongitude" toAttribute:@"lowerLeftLongitude" ];        
        [mapping mapKeyPath:@"maxLatitude" toAttribute:@"maxLatitude" ];
        [mapping mapKeyPath:@"maxLongitude" toAttribute:@"maxLongitude"];
        [mapping mapKeyPath:@"minLatitude" toAttribute:@"minLatitude"];
        [mapping mapKeyPath:@"minLongitude" toAttribute:@"minLongitude" ];        
        [mapping mapKeyPath:@"transitModes" toAttribute:@"transitModes" ];
        [mapping mapKeyPath:@"upperRightLatitude" toAttribute:@"upperRightLatitude"];
        [mapping mapKeyPath:@"upperRightLongitude" toAttribute:@"upperRightLongitude"];
        
    } else {
        // TODO Unknown Another type, throw an exception
    }
    return mapping;
}
@end
