//
//  SupportedRegion.m
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SupportedRegion.h"
#import "Constants.h"

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

// loads default min & max supported region values from constants.h file
- (id)initWithDefault
{
    self = [super init];
    if (self) {
        maxLatitude = [NSNumber numberWithDouble:[MAX_LAT doubleValue]];
        maxLongitude = [NSNumber numberWithDouble:[MAX_LONG doubleValue]];
        minLatitude = [NSNumber numberWithDouble:[MIN_LAT doubleValue]];
        minLongitude = [NSNumber numberWithDouble:[MIN_LONG doubleValue]];
    }
    return self;
}

// Returns true if the given lat/lng are in the supported region
- (BOOL)isInRegionLat:(double)lat Lng:(double)lng
{
    BOOL result = ((lat>=[minLatitude doubleValue]) && (lng>=[minLongitude doubleValue]) &&
                   (lat<=[maxLatitude doubleValue]) && (lng<=[maxLongitude doubleValue]));
    return result;
}
@end
