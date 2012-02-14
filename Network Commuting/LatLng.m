//
//  LatLng.m
//  Network Commuting
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LatLng.h"

@implementation LatLng

@synthesize lat;
@synthesize lng;
@synthesize z;

+ (RKObjectMapping *)objectMappingForApi:(APIType)gt
{
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[LatLng class]];
    
    if (gt==GOOGLE_GEOCODER) {
        [mapping mapKeyPath:@"lat" toAttribute:@"lat"];
        [mapping mapKeyPath:@"lng" toAttribute:@"lng"];
    }
    else {
        // Unknown geocoder type, throw an exception
    }
    
    return mapping;
}

- (id) initWithLat:(double)newlat Lng:(double)newlng 
{
    self = [super init];
    
    lat = newlat;
    lng = newlng;
    z = 0.0;
    return self;
}

// latLng pair string is the format used by OTP geocoder for lat & lng 
- (NSString *)latLngPairStr
{
    return [NSString stringWithFormat:@"%f,%f",lat,lng];
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{LatLng Object:  Lat: %f; Lng: %f; Z: %f}", lat, lng, z];
    return desc;
}

@end
