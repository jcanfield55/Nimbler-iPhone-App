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
@synthesize rawAddresses;
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

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{Location Object:  geocoderType: %d;  rawAddresses: %@;  geoCoderStatus: %@;  types: %@;  formatted address: %@;  addressComponents: %@;  latLng: %@;  locationType: %@;  viewPort: %@;  toFrequency %d;  fromFrequency %d;  nickName: %@}",
                      geocoderType, rawAddresses, geoCoderStatus, types, formattedAddress, addressComponents, 
                      latLng, locationType, viewPort, toFrequency, fromFrequency, nickName];
    return desc;
}
@end
