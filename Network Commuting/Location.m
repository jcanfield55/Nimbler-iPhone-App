//
//  Locations.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Location.h"


@implementation Location

@synthesize geocoderType;
@synthesize geoCoderStatus;
@synthesize types;
@synthesize formattedAddress;
@synthesize addressComponents;
@synthesize latLng;
@synthesize locationType;
@synthesize viewPort;
@synthesize toFrequency;
@synthesize fromFrequency;
@synthesize nickName;

+ (RKObjectMapping *)objectMappingforGeocoder:(GeocoderType)gt;
{
    // Create empty ObjectMapping to fill and return
    RKObjectMapping* locationMapping = [RKObjectMapping mappingForClass:[Location class]];
    
    // Call on sub-objects for their Object Mappings
    RKObjectMapping* addrCompMapping = [AddressComponent objectMappingforGeocoder:gt];
    RKObjectMapping* latLngMapping = [LatLng objectMappingforGeocoder:gt];
    RKObjectMapping* geoRectMapping = [GeoRectangle objectMappingforGeocoder:gt];
    
    // Make the mappings
    if (gt==GOOGLE) {
        [locationMapping mapKeyPath:@"types" toAttribute:@"types"];
        [locationMapping mapKeyPath:@"formatted_address" toAttribute:@"formattedAddress"];
        [locationMapping mapKeyPath:@"address_components" toRelationship:@"addressComponents" 
                        withMapping:addrCompMapping];
        [locationMapping mapKeyPath:@"geometry.location" toRelationship:@"latLng" 
                        withMapping:latLngMapping];
        [locationMapping mapKeyPath:@"geometry.location_type" toAttribute:@"locationType"];
        [locationMapping mapKeyPath:@"geometry.viewport" toRelationship:@"viewPort" 
                        withMapping:geoRectMapping];

    }
    else {
        // Unknown geocoder type, throw an exception
    }
    return locationMapping;
}

- (bool)isMatchingRawAddress:(NSString *)rawAddr
{
    return ([rawAddresses member:rawAddr] != nil);
}

- (void)addRawAddress:(NSString *)rawAddr
{
    [rawAddresses addObject:rawAddr];
}

// Method to see whether two locations are effectively equivalent
// If they have the exact same formatted address, or they are within ~0.05 miles 
// For example, it is 233 feet between 1350 and 1315 Hull Drive
// 1350 Hull Lat: 37.510594; Lng: -122.268646;
// 1315 Hull Lat: 37.510811; Lng: -122.267816; 
// Difference is ~0.0008.  Rather than compute exact distince, simply use a surrounding box calculation
- (bool)isEquivalent:(Location *)loc2
{
    if ([formattedAddress isEqualToString:[loc2 formattedAddress]]) {
        return true;
    }
    float lat2 = [[loc2 latLng] lat];
    float lng2 = [[loc2 latLng] lng];
    if ((fabs([latLng lat] - lat2) < 0.0008) && (fabs([latLng lng] - lng2) < 0.0008)) {
        return true;
    }
    else
        return false;
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{Location Object:  geocoderType: %d;  rawAddresses: %@;  geoCoderStatus: %@;  types: %@;  formatted address: %@;  addressComponents: %@;  latLng: %@;  locationType: %@;  viewPort: %@;  toFrequency %d;  fromFrequency %d;  nickName: %@}",
                      geocoderType, rawAddresses, geoCoderStatus, types, formattedAddress, addressComponents, 
                      latLng, locationType, viewPort, toFrequency, fromFrequency, nickName];
    return desc;
}
@end
