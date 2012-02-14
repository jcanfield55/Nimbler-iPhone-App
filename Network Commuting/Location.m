//
//  Locations.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Location.h"
#import "Locations.h"


@implementation Location

@dynamic rawAddresses;
@dynamic apiType;
@dynamic geoCoderStatus;
@dynamic types;
@dynamic formattedAddress;
@dynamic addressComponents;
@dynamic lat;
@dynamic lng;
@dynamic locationType;
@dynamic viewPort;
@dynamic toFrequency;
@dynamic fromFrequency;
@dynamic dateLastUsed;
@dynamic nickName;

// Static variables and methods to retrieve the Locations set wrapper
static Locations *locations;

+ (void)setLocations:(Locations *)loc {
    locations = loc;
}
+ (Locations *)locations {
    return locations;
}

// Returns the mapping used by RestKit to map this object from the specified API
+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)gt;
{
    // Create empty ObjectMapping to fill and return
    RKManagedObjectMapping* locationMapping = [RKManagedObjectMapping mappingForClass:[Location class]];
    
    // Call on sub-objects for their Object Mappings

    RKManagedObjectMapping* addrCompMapping = [AddressComponent objectMappingForApi:gt];

    // TODO figure out how to get geoRectangle element to encode correctly
    // RKObjectMapping* geoRectMapping = [GeoRectangle objectMappingForApi:gt];
    
    // Make the mappings
    if (gt==GOOGLE_GEOCODER) {
        [locationMapping mapKeyPath:@"types" toAttribute:@"types"];
        [locationMapping mapKeyPath:@"formatted_address" toAttribute:@"formattedAddress"];
        [locationMapping mapKeyPath:@"address_components" toRelationship:@"addressComponents" withMapping:addrCompMapping];
        [locationMapping mapKeyPath:@"geometry.location.lat" toAttribute:@"lat"];
        [locationMapping mapKeyPath:@"geometry.location.lng" toAttribute:@"lng"];
        [locationMapping mapKeyPath:@"geometry.location_type" toAttribute:@"locationType"];
        // [locationMapping mapKeyPath:@"geometry.viewport" toRelationship:@"viewPort" withMapping:geoRectMapping];
        
    }
    else {
        // TODO Unknown geocoder type, throw an exception
    }
    return locationMapping;
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // Alert locations wrapper that it's cache is stale
    [locations setAreLocationsChanged:YES];
    
    // Set the date
    [self setPrimitiveValue:[NSDate date] forKey:@"dateLastUsed"];
    
    // Add the locations object as an observer for changes so it can resort its cache
    [self addObserver:locations forKeyPath:@"dateLastUsed" options:NSKeyValueObservingOptionNew context:nil];
}

// Add a raw address string to this Location in a way that will be maintained by Core Data
- (void)addRawAddressString:(NSString *)value {

    NSMutableSet *rawAddresses = [self mutableSetValueForKey:@"rawAddresses"]; // Get Raw Addresses set
    
     RawAddress *rawAddr = [NSEntityDescription insertNewObjectForEntityForName:@"RawAddress" inManagedObjectContext:[self managedObjectContext]];  // Create a new RawAddress object
    [rawAddr setRawAddressString:value];  // Set the raw address string
    [rawAddresses addObject:rawAddr];  // add it to the RawAddresses set for this location
}

- (void)incrementToFrequency {
    if ([self toFrequency] == 0) { // if this is the first use...
        [self setFromFrequency:1];  // insure this location will be visible in the from list as well 
        [self setToFrequency:2];   // but give more weight to this location in the to list
    }
    else {
        [self setToFrequency:([self toFrequency]+1)];
    }
}

- (void)incrementFromFrequency {
    if ([self fromFrequency] == 0) { // if this is the first use...
        [self setToFrequency:1];  // insure this location will be visible in the to list as well 
        [self setFromFrequency:2];   // but give more weight to this location in the from list
    }
    else {
        [self setFromFrequency:([self fromFrequency]+1)];
    }
}

// latLng pair string is the format used by OTP geocoder for lat & lng 
- (NSString *)latLngPairStr
{
    return [NSString stringWithFormat:@"%f,%f",[self lat],[self lng]];
}

// Method to see whether two locations are effectively equivalent
// If they have the exact same formatted address, or they are within ~0.05 miles 
// For example, it is 233 feet between 1350 and 1315 Hull Drive
// 1350 Hull Lat: 37.510594; Lng: -122.268646;
// 1315 Hull Lat: 37.510811; Lng: -122.267816; 
// Difference is ~0.0008.  Rather than compute exact distince, simply use a surrounding box calculation
- (bool)isEquivalent:(Location *)loc2
{
    if ([[self formattedAddress] isEqualToString:[loc2 formattedAddress]]) {
        return true;
    }
    double lat2 = [loc2 lat];
    double lng2 = [loc2 lng];
    if ((fabs([self lat] - lat2) < 0.0008) && (fabs([self lng] - lng2) < 0.0008)) {
        return true;
    }
    else
        return false;
}

// TODO Do something about description method to avoid overloading warning.  
/*
- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{Location Object:  apiType: %d;  rawAddresses: %@;  geoCoderStatus: %@;  types: %@;  formatted address: %@;  addressComponents: %@;  latLng: %@;  locationType: %@;  viewPort: %@;  toFrequency %d;  fromFrequency %d;  nickName: %@}",
                      apiType, rawAddresses, geoCoderStatus, types, formattedAddress, addressComponents, 
                      latLng, locationType, viewPort, toFrequency, fromFrequency, nickName];
    return desc;
}
 */
@end
