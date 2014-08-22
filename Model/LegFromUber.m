//
//  LegFromUber.m
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import "LegFromUber.h"

@implementation LegFromUber

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[Leg class]];
    
    // Make the mappings
    if (apiType==OTP_PLANNER) {
        
        [mapping mapKeyPath:@"agencyId" toAttribute:@"agencyId"];
        [mapping mapKeyPath:@"id" toAttribute:@"legId"];
        [mapping mapKeyPath:@"bogusNonTransitLeg" toAttribute:@"bogusNonTransitLeg"];
        [mapping mapKeyPath:@"distance" toAttribute:@"distance"];
        [mapping mapKeyPath:@"duration" toAttribute:@"duration"];
        [mapping mapKeyPath:@"endTime" toAttribute:@"endTime"];
        [mapping mapKeyPath:@"headsign" toAttribute:@"headSign"];
        //[mapping mapKeyPath:@"interlineWithPreviousLeg" toAttribute:@"interlineWithPreviousLeg"];
        [mapping mapKeyPath:@"legGeometry.length" toAttribute:@"legGeometryLength"];
        [mapping mapKeyPath:@"legGeometry.points" toAttribute:@"legGeometryPoints"];
        [mapping mapKeyPath:@"rentedBike" toAttribute:@"rentedBike"];
        [mapping mapKeyPath:@"mode" toAttribute:@"mode"];
        [mapping mapKeyPath:@"routeId" toAttribute:@"routeId"];
        [mapping mapKeyPath:@"route" toAttribute:@"route"];
        [mapping mapKeyPath:@"routeLongName" toAttribute:@"routeLongName"];
        [mapping mapKeyPath:@"routeShortName" toAttribute:@"routeShortName"];
        [mapping mapKeyPath:@"startTime" toAttribute:@"startTime"];
        [mapping mapKeyPath:@"tripId" toAttribute:@"tripId"];
        [mapping mapKeyPath:@"agencyName" toAttribute:@"agencyName"];

    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

@end
