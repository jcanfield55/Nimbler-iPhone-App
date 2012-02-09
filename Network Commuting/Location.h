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

@interface Location : NSManagedObject {
    NSMutableSet * rawAddresses; // Set containing all the user inputted strings mapped to this location
    APIType apiType;  // enum indicating which service performed the Geocode
    NSString * geoCoderStatus;  // Returned status from geocoder service (ideally "OK")
    NSArray * types;  // Array of NSStrings with type properties (street address, locality)
    NSString * formattedAddress;  // Standardized address string
    NSArray * addressComponents;  // Array of AddressComponent items
    LatLng * latLng;  // LatLng of the location
    NSString * locationType;   // Type of location (ROOFTOP, APPROXIMATE)
    GeoRectangle * viewPort;   // Rectangle defining the view for the location
    int toFrequency;   // Frequency requested by user as a To location
    int fromFrequency;  // Frequency requested by user as a From location
    NSString * nickName;     // Alias name for location, e.g. "eBay Whitman Campus" or "Home"

}

@property (nonatomic) APIType apiType;  
@property (nonatomic, strong) NSString * geoCoderStatus;  
@property (nonatomic, strong) NSArray * types;  
@property (nonatomic, strong) NSString * formattedAddress;  
@property (nonatomic, strong) NSArray * addressComponents;  
@property (nonatomic, strong) LatLng * latLng;
@property (nonatomic, strong) NSString * locationType;   
@property (nonatomic, strong) GeoRectangle * viewPort;   
@property (nonatomic) int toFrequency;   
@property (nonatomic) int fromFrequency;  
@property (nonatomic, strong) NSString * nickName;     

// Convenience methods for flattening lat/lng properties
- (double)lat;   
- (double)lng;
- (void)setLat:(double)lat;
- (void)setLng:(double)lng;

- (void)incrementToFrequency;
- (void)incrementFromFrequency;
+ (RKObjectMapping *)objectMappingForApi:(APIType)gt;
- (bool)isMatchingRawAddress:(NSString *)rawAddr;
- (void)addRawAddress:(NSString *)rawAddr;
- (bool)isEquivalent:(Location *)loc2;

@end
