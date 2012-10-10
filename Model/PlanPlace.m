//
//  PlanPlace.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/29/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "PlanPlace.h"

@implementation PlanPlace

@dynamic name;
@dynamic stopId;
@dynamic stopAgencyId;
@dynamic lat;
@dynamic lng;
@dynamic arrival;
@dynamic departure;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)tpt
{
    // Create empty ObjectMapping to fill and return
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[PlanPlace class]];
        
    // Make the mappings
    if (tpt==OTP_PLANNER) {
        [mapping mapKeyPath:@"name" toAttribute:@"name"];
        [mapping mapKeyPath:@"stopId.id" toAttribute:@"stopId"];
        [mapping mapKeyPath:@"stopId.agencyID" toAttribute:@"stopAgencyId"];
        [mapping mapKeyPath:@"lat" toAttribute:@"lat"];
        [mapping mapKeyPath:@"lon" toAttribute:@"lng"];
        [mapping mapKeyPath:@"arrival" toAttribute:@"arrival"];
        [mapping mapKeyPath:@"departure" toAttribute:@"departure"];
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

// Convenience methods for getting scalar values
- (double)latFloat {
    return [[self lat] doubleValue];
}
- (double)lngFloat {
    return [[self lng] doubleValue];
}

- (NSString *)ncDescription
{
    NSString* desc = [NSString stringWithFormat:
                      @"{PlanPlace Object: name: %@;  stopId: %@;  lat: %f; lng: %f arrival: %@;  departure: %@}",
                      [self name], [self stopId], [self latFloat], [self lngFloat], [self arrival], [self departure]];
    return desc;
}


@end
