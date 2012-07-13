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
#import "AddressComponent.h"
#import "RawAddress.h"
#import "GeoRectangle.h"
#import "enums.h"

@class Locations;

@interface Location : NSManagedObject 

@property (nonatomic, strong) NSSet *rawAddresses; // Set containing all the user inputted strings mapped to this location
@property (nonatomic, strong) NSNumber *apiType;  // APIType enum indicating which service performed the Geocode
@property (nonatomic, strong) NSString *geoCoderStatus;  // Returned status from geocoder service (ideally "OK")
@property (nonatomic, strong) NSArray *types;  // Array of NSStrings with type properties (street address, locality)
@property (nonatomic, strong) NSString *formattedAddress;  // Standardized address string
@property (nonatomic, strong) NSSet *addressComponents;  // Set of AddressComponent items
@property (nonatomic, strong) NSNumber *lat;  // double floating point
@property (nonatomic, strong) NSNumber *lng;  // double floating point

// Type of location (ROOFTOP, APPROXIMATE).  
// If "TOFROM_LIST" then it is placeholder for a list of locations to be chosen by LocationPickerView
@property (nonatomic, strong) NSString *locationType;   

@property (nonatomic, strong) GeoRectangle *viewPort;   // Rectangle defining the view for the location
@property (nonatomic, strong) NSNumber *toFrequency;   // Frequency requested by user as a To location
@property (nonatomic, strong) NSNumber *fromFrequency;  // Frequency requested by user as a From location
@property (nonatomic, strong) NSDate *dateLastUsed;  // Last time a user created or selected this location
@property (nonatomic, strong) NSString *nickName;  // Alias name for location, e.g. "eBay Whitman Campus" or "Home"
@property (nonatomic, strong) NSString *shortFormattedAddress;  // typically equal to the formatted address minus the postal code and country.  For transit station, also removes city name.  
@property (nonatomic, strong) NSDecimalNumber *preloadVersion; // if a pre-loaded location, shows the version number of the loading (used to determine whether a newer preload version exists). Zero or nil otherwise.  
@property (nonatomic, strong) NSString *memberOfList;  // Name of a list (like 'CaltrainStations') that this location belongs to.  After list name, string will contain a sorting number.  Empty or nil otherwise. 

// Static variables and methods to retrieve the Locations set wrapper
+ (void)setLocations:(Locations *)loc;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)gt;

// Convenience methods for accessing and setting scalar properties
- (APIType)apiTypeEnum;
- (void)setApiTypeEnum:(APIType)apiType0;
- (double)latFloat;
- (void)setLatFloat:(double)lat0;
- (double)lngFloat;
- (void)setLngFloat:(double)lng0;
- (double)toFrequencyFloat;
- (void)setToFrequencyFloat:(double)toFreq0;
- (double)fromFrequencyFloat;
- (void)setFromFrequencyFloat:(double)fromFreq0;

- (void)addRawAddressString:(NSString *)value;
- (void)incrementToFrequency;
- (void)incrementFromFrequency;
- (NSString *)latLngPairStr;
- (BOOL)isMatchingTypedString:(NSString *)str;
- (BOOL)isEquivalent:(Location *)loc2;

@end

@interface Location (CoreDataGeneratedAccessors)
	- (void)addRawAddressesObject:(NSManagedObject *)object;
@end
