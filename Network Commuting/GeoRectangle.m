//
//  GeoRectangle.m
//  Network Commuting
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "GeoRectangle.h"

@implementation GeoRectangle

@synthesize southWest;
@synthesize northEast;

+ (RKObjectMapping *)objectMappingforGeocoder:(GeocoderType)gt
{
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[GeoRectangle class]];
    RKObjectMapping* latLngMapping = [LatLng objectMappingforGeocoder:gt];
    
    if (gt==GOOGLE) {
        [mapping mapKeyPath:@"southwest" toRelationship:@"southWest" 
                        withMapping:latLngMapping];
        [mapping mapKeyPath:@"northeast" toRelationship:@"northEast" 
                withMapping:latLngMapping];
    }
    else {
        // Unknown geocoder type, throw an exception
    }
    
    return mapping;
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{GeoRectangle Object: southWest: %@; northEast: %@}", southWest, northEast];
    return desc;
}


@end
