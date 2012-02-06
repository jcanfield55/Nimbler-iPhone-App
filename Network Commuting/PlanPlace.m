//
//  PlanPlace.m
//  Network Commuting
//
//  Created by John Canfield on 1/29/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "PlanPlace.h"

@implementation PlanPlace

@synthesize name;
@synthesize stopId;
@synthesize latLng;
@synthesize arrival;
@synthesize departure;

+ (RKObjectMapping *)objectMappingForApi:(APIType)tpt
{
    // Create empty ObjectMapping to fill and return
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[PlanPlace class]];
    
    // Call on sub-objects for their Object Mappings
    RKObjectMapping* agencyAndIdMapping = [AgencyAndId objectMappingForApi:tpt];
    
    // Make the mappings
    if (tpt==OTP_PLANNER) {
        [mapping mapKeyPath:@"name" toAttribute:@"name"];
        [mapping mapKeyPath:@"stopId" toRelationship:@"stopId" withMapping:agencyAndIdMapping];
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

// Convenience method for flattening lat/lng properties
- (double)lat {
    return [latLng lat];
}

// Convenience method for flattening lat/lng properties
- (double)lng {
    return [latLng lng];
}

// Convenience method for flattening lat/lng properties
- (void)setLat:(double)lat {
    if (!latLng) {   // if latLng does not exist, create it
        latLng = [[LatLng alloc] init];
    }
    [latLng setLat:lat];   // set the lat property
}

// Convenience method for flattening lat/lng properties
- (void)setLng:(double)lng {
    if (!latLng) {   // if latLng does not exist, create it
        latLng = [[LatLng alloc] init];
    }
    [latLng setLng:lng];
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{PlanPlace Object: name: %@;  stopId: %@;  latLng: %@;  arrival: %@;  departure: %@}",
                      name, stopId, latLng, arrival, departure];
    return desc;
}


@end
