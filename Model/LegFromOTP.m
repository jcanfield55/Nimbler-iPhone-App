//
//  LegFromOTP.m
//  Nimbler Caltrain
//
//  Created by macmini on 30/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LegFromOTP.h"
#import "Step.h"
#import "PlanPlace.h"
#import "KeyObjectStore.h"
#import "UtilityFunctions.h"
#import "Itinerary.h"
#import "IntermediateStops.h"

@implementation LegFromOTP

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[Leg class]];
    RKManagedObjectMapping* stepsMapping = [Step objectMappingForApi:apiType];
    RKManagedObjectMapping* planPlaceMapping = [PlanPlace objectMappingForApi:apiType];
    RKManagedObjectMapping* intermediateStops = [IntermediateStops objectMappingForApi:apiType];
    
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
        [mapping mapKeyPath:@"tripShortName" toAttribute:@"tripShortName"];
        [mapping mapKeyPath:@"startTime" toAttribute:@"startTime"];
        [mapping mapKeyPath:@"tripId" toAttribute:@"tripId"];
        [mapping mapKeyPath:@"agencyName" toAttribute:@"agencyName"];
        
        [mapping mapKeyPath:@"steps" toRelationship:@"steps" withMapping:stepsMapping];
        [mapping mapKeyPath:@"from" toRelationship:@"from" withMapping:planPlaceMapping];
        [mapping mapKeyPath:@"to" toRelationship:@"to" withMapping:planPlaceMapping];
        [mapping mapKeyPath:@"intermediateStops" toRelationship:@"intermediateStops" withMapping:intermediateStops];
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

@end
