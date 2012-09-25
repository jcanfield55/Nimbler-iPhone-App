//
//  Locations.h
//  Network Commuting
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
//  This is NSManagedObject ABSTRACT class to contain location information for places that the user 
//    has entered or selected.
//  NOTE: LOCATION MUST BE IMPLEMENTED ALONG WITH ONE OF ITS CHILDREN CLASSES, LocationByGoogle OR LocationByIOS
//  Contains the raw address strings entered by the user as well as geocoded information
//  returned by a geocoder.  Also contains frequency that user has chosen the location as 
//  a from or to location, so that these locations can be shown on the dropdown.  

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RawAddress.h"
#import "enums.h"

@class Locations;

@interface Location : NSManagedObject 

@property (nonatomic, strong) NSNumber *apiType;  // APIType enum indicating which service performed the Geocode
@property (nonatomic, strong) NSSet *rawAddresses; // Set containing all the user inputted strings mapped to this location
@property (nonatomic, strong) NSString *geoCoderStatus;  // Returned status from geocoder service (ideally "OK")
@property (nonatomic, strong) NSString *formattedAddress;  // Standardized address string
@property (nonatomic, strong) NSNumber *lat;  // double floating point
@property (nonatomic, strong) NSNumber *lng;  // double floating point

// Type of location (ROOFTOP, APPROXIMATE).  
// If "TOFROM_LIST" then it is placeholder for a list of locations to be chosen by LocationPickerView
@property (nonatomic, strong) NSString *locationType;

@property (nonatomic, strong) NSNumber *toFrequency;   // Frequency requested by user as a To location
@property (nonatomic, strong) NSNumber *fromFrequency;  // Frequency requested by user as a From location
@property (nonatomic, strong) NSDate *dateLastUsed;  // Last time a user created or selected this location
@property (nonatomic, strong) NSString *nickName;  // Alias name for location, e.g. "eBay Whitman Campus" or "Home"
@property (nonatomic, strong) NSString *shortFormattedAddress;  // typically equal to the formatted address minus the postal code and country.  For transit station, also removes city name.  
@property (nonatomic, strong) NSDecimalNumber *preloadVersion; // if a pre-loaded location, shows the version number of the loading (used to determine whether a newer preload version exists). Zero or nil otherwise.  
@property (nonatomic, strong) NSString *memberOfList;  // Name of a list (like 'CaltrainStations') that this location belongs to.  After list name, string will contain a sorting number.  Empty or nil otherwise. 

// Location which is the reverse geocode of the last time current location was used in a plan request.
// nil if there was no reverse geocode was possible or if Self is not a Current Location
@property (nonatomic, strong) Location* reverseGeoLocation;

@property (nonatomic, strong) NSDictionary* addressComponentDictionary; // Dictionary of address components (generated dynamically by subclasses; not stored in Core Data)

// Static variables and methods to retrieve the Locations set wrapper
+ (void)setLocations:(Locations *)loc;


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

- (double)metersFromLocation:(Location *)loc2;  // Returns the distance between the referring object and loc2 in meters
@end

@interface Location (CoreDataGeneratedAccessors)
	- (void)addRawAddressesObject:(NSManagedObject *)object;
@end
