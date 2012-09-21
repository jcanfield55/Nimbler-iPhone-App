//
//  LocationFromGoogle.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 9/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LocationFromGoogle.h"
#import "AddressComponent.h"


@implementation LocationFromGoogle

@dynamic types;
@dynamic viewPort;
@dynamic addressComponents;

//
// Setters and accessors for parent managed object
//
/*
-(NSString *)formattedAddress {
    return [super formattedAddress];
}
-(void)setFormattedAddress:(NSString *)formattedAddress0 {
    [super setFormattedAddress:formattedAddress0];
}
 */


// Returns the mapping used by RestKit to map this object from the specified API
+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)gt;
{
    // Create empty ObjectMapping to fill and return
    RKManagedObjectMapping* locationMapping = [RKManagedObjectMapping mappingForClass:[LocationFromGoogle class]];
    
    // Call on sub-objects for their Object Mappings
    
    RKManagedObjectMapping* addrCompMapping = [AddressComponent objectMappingForApi:gt];
    
    // TODO figure out how to get geoRectangle element to encode correctly
    // RKObjectMapping* geoRectMapping = [GeoRectangle objectMappingForApi:gt];
    
    // Make the mappings
    if (gt==GOOGLE_GEOCODER) {
        [locationMapping mapKeyPath:@"types" toAttribute:@"types"];
        [locationMapping mapKeyPath:@"formatted_address" toAttribute:@"formattedAddress"];
        [locationMapping mapKeyPath:@"address_components" toRelationship:@"addressComponents" withMapping:addrCompMapping];
        [locationMapping mapKeyPath:@"geometry.location.lat" toAttribute:@"latFloat"];
        [locationMapping mapKeyPath:@"geometry.location.lng" toAttribute:@"lngFloat"];
        [locationMapping mapKeyPath:@"geometry.location_type" toAttribute:@"locationType"];
        [locationMapping mapKeyPath:@"toFrequency" toAttribute:@"toFrequencyFloat"];
        [locationMapping mapKeyPath:@"fromFrequency" toAttribute:@"fromFrequencyFloat"];
        [locationMapping mapKeyPath:@"memberOfList" toAttribute:@"memberOfList"];
        // [locationMapping mapKeyPath:@"geometry.viewport" toRelationship:@"viewPort" withMapping:geoRectMapping];
        
    }
    else {
        // TODO Unknown geocoder type, throw an exception
    }
    return locationMapping;
}

// Map Google address components into a standard dictionary format that can be used by Location
// Key will be Google geocoder type key for the longName value
// Key will be Google geocoder type key + (short) for the shortName value
- (NSDictionary *)addressComponentDictionary
{
    if (![super addressComponentDictionary]) {
        NSMutableDictionary* addrCompDict = [NSMutableDictionary dictionaryWithCapacity:
                                             [[self addressComponents] count]];
        for (AddressComponent* addrComp in [self addressComponents]) {
            for (NSString* type in [addrComp types]) {
                if ([addrComp longName] && [[addrComp longName] length]>0) {
                    [addrCompDict setObject:[addrComp longName] forKey:type];
                }
                if ([addrComp shortName] && [[addrComp shortName] length]>0) {
                    [addrCompDict setObject:[addrComp shortName] forKey:[type stringByAppendingString:@"(short)"]];
                }
            }
        }
        [super setAddressComponentDictionary:[NSDictionary dictionaryWithDictionary:addrCompDict]];
    }
    return [super addressComponentDictionary];
}
@end
