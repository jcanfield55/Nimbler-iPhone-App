//
//  Locations.h
//  Network Commuting
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
//  This is NSManagedObject populated by RestKit to contain location information for 
//  places that the user has entered or selected.  
//  Contains the raw address strings entered by the user as well as geocoded information
//  returned by a geocoder.  Also contains frequency that user has chosen the location as 
//  a from or to location, so that these locations can be shown on the dropdown.  

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import "LatLng.h"
#import "AddressComponent.h"
#import "GeoRectangle.h"
#import "enums.h"

@interface Location : NSManagedObject 

@property (nonatomic, strong) NSSet *rawAddresses; // Set containing all the user inputted strings mapped to this location
@property (nonatomic) APIType apiType;  // enum indicating which service performed the Geocode
@property (nonatomic, strong) NSString * geoCoderStatus;  // Returned status from geocoder service (ideally "OK")
@property (nonatomic, strong) NSArray * types;  // Array of NSStrings with type properties (street address, locality)
@property (nonatomic, strong) NSString * formattedAddress;  // Standardized address string
@property (nonatomic, strong) NSSet * addressComponents;  // Set of AddressComponent items
@property (nonatomic, strong) LatLng * latLng;      // LatLng of the location
@property (nonatomic, strong) NSString * locationType;   // Type of location (ROOFTOP, APPROXIMATE)
@property (nonatomic, strong) GeoRectangle * viewPort;   // Rectangle defining the view for the location
@property (nonatomic) int toFrequency;   // Frequency requested by user as a To location
@property (nonatomic) int fromFrequency;  // Frequency requested by user as a From location
@property (nonatomic, strong) NSString * nickName;  // Alias name for location, e.g. "eBay Whitman Campus" or "Home"

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)gt;

// Convenience methods for flattening lat/lng properties
- (double)lat;   
- (double)lng;
- (void)setLat:(double)lat;
- (void)setLng:(double)lng;

- (void)addRawAddress:(NSString *)value;
- (void)incrementToFrequency;
- (void)incrementFromFrequency;
- (bool)isEquivalent:(Location *)loc2;

@end

