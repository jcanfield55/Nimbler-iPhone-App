//
//  IntermediateStops.m
//  Nimbler SF
//
//  Created by macmini on 19/03/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "IntermediateStops.h"
#import "Leg.h"


@implementation IntermediateStops

@dynamic arrivalTime;
@dynamic departureTime;
@dynamic lat;
@dynamic lon;
@dynamic name;
@dynamic stopAgencyId;
@dynamic stopId;
@dynamic leg;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)tpt
{
    // Create empty ObjectMapping to fill and return
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[IntermediateStops class]];
    
    // Make the mappings
    if (tpt==OTP_PLANNER) {
        [mapping mapKeyPath:@"arrival" toAttribute:@"arrivalTime"];
        [mapping mapKeyPath:@"departure" toAttribute:@"departureTime"];
        [mapping mapKeyPath:@"stopId.agencyId" toAttribute:@"stopAgencyId"];
        [mapping mapKeyPath:@"stopId.id" toAttribute:@"stopId"];
        [mapping mapKeyPath:@"lat" toAttribute:@"lat"];
        [mapping mapKeyPath:@"lon" toAttribute:@"lon"];
        [mapping mapKeyPath:@"name" toAttribute:@"name"];
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

@end
