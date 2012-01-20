//
//  Locations.h
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/Restkit.h>
#import "LatLng.h"
#import "AddressComponent.h"
#import "GeoRectangle.h"
#import "enums.h"

@interface Location : NSObject {
    NSMutableSet * rawAddresses; // Set containing all the user inputted strings mapped to this location
}

@property (nonatomic) GeocoderType geocoderType;  // enum indicating which service performed the Geocode
@property (nonatomic, strong) NSString * geoCoderStatus;  // Returned status from geocoder service (ideally "OK")
@property (nonatomic, strong) NSArray * types;  // Array of NSStrings with type properties (street address, locality)
@property (nonatomic, strong) NSString * formattedAddress;  // Standardized address string
@property (nonatomic, strong) NSArray * addressComponents;  // Array of AddressComponent items
@property (nonatomic, strong) LatLng * latLng;  // LatLng of the location
@property (nonatomic, strong) NSString * locationType;   // Type of location (ROOFTOP, APPROXIMATE)
@property (nonatomic, strong) GeoRectangle * viewPort;   // Rectangle defining the view for the location
@property (nonatomic) int toFrequency;   // Frequency requested by user as a To location
@property (nonatomic) int fromFrequency;  // Frequency requested by user as a From location
@property (nonatomic, strong) NSString * nickName;     // Alias name for location, e.g. "eBay Whitman Campus" or "Home"

+ (RKObjectMapping *)objectMappingforGeocoder:(GeocoderType)gt;
- (bool)isMatchingRawAddress:(NSString *)rawAddr;
- (void)addRawAddress:(NSString *)rawAddr;
- (bool)isEquivalent:(Location *)loc2;

@end
