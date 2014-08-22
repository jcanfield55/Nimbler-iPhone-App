//
//  ItineraryFromUber.m
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import "ItineraryFromUber.h"
#import "LegFromUber.h"


@implementation ItineraryFromUber


+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[ItineraryFromUber class]];
    RKManagedObjectMapping* legMapping = [LegFromUber objectMappingForApi:apiType];
    
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

@end
