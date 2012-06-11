//
//  Location.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Location.h"
#import "Locations.h"
#import "Constants.h"

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

// Convenience setters and accessors for scalars
- (APIType)apiTypeEnum {
    APIType a = (APIType) [[self apiType] intValue];
    return a;
}
- (void)setApiTypeEnum:(APIType)apiType0 {
    [self setApiType:[NSNumber numberWithInt:apiType0]];
}
- (double)latFloat {
    return [[self lat] doubleValue];
}
- (void)setLatFloat:(double)lat0 {
    [self setLat:[NSNumber numberWithDouble:lat0]];
}
- (double)lngFloat {
    return [[self lng] doubleValue];
}
- (void)setLngFloat:(double)lng0 {
    [self setLng:[NSNumber numberWithDouble:lng0]];
}
- (double)toFrequencyFloat {
    return [[self toFrequency] doubleValue];
}
- (void)setToFrequencyFloat:(double)toFreq0 {
    [self setToFrequency:[NSNumber numberWithDouble:toFreq0]];
}
- (double)fromFrequencyFloat {
    return [[self fromFrequency] doubleValue];
}
- (void)setFromFrequencyFloat:(double)fromFreq0 {
    [self setFromFrequency:[NSNumber numberWithDouble:fromFreq0]];
}

// TODO create a method or sub-class to handle getting lat/lng for Current Location

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
        [locationMapping mapKeyPath:@"geometry.location.lat" toAttribute:@"latFloat"];
        [locationMapping mapKeyPath:@"geometry.location.lng" toAttribute:@"lngFloat"];
        [locationMapping mapKeyPath:@"geometry.location_type" toAttribute:@"locationType"];
        [locationMapping mapKeyPath:@"toFrequency" toAttribute:@"toFrequencyFloat"];
        [locationMapping mapKeyPath:@"fromFrequency" toAttribute:@"fromFrequencyFloat"];
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

- (void)prepareForDeletion {
    [locations setAreLocationsChanged:YES];  // alert locations wrapper that it's cache is stale
}

// Add a raw address string to this Location in a way that will be maintained by Core Data
- (void)addRawAddressString:(NSString *)value {

    NSMutableSet *rawAddresses = [self mutableSetValueForKey:@"rawAddresses"]; // Get Raw Addresses set
    
     RawAddress *rawAddr = [NSEntityDescription insertNewObjectForEntityForName:@"RawAddress" inManagedObjectContext:[self managedObjectContext]];  // Create a new RawAddress object
    [rawAddr setRawAddressString:value];  // Set the raw address string
    [rawAddresses addObject:rawAddr];  // add it to the RawAddresses set for this location
}

- (void)incrementToFrequency {
    if ([self toFrequencyFloat] < TINY_FLOAT) { // if this is the first use...
        [self setFromFrequencyFloat:1.0];  // insure this location will be visible in the from list as well 
        [self setToFrequencyFloat:2.0];   // but give more weight to this location in the to list
    }
    else {
        [self setToFrequencyFloat:([self toFrequencyFloat]+1.0)];
    }
}

- (void)incrementFromFrequency {
    if ([self fromFrequencyFloat] < TINY_FLOAT) { // if this is the first use...
        [self setToFrequencyFloat:1.0];  // insure this location will be visible in the to list as well 
        [self setFromFrequencyFloat:2.0];   // but give more weight to this location in the from list
    }
    else {
        [self setFromFrequencyFloat:([self fromFrequencyFloat]+1.0)];
    }
}

// latLng pair string is the format used by OTP geocoder for lat & lng 
- (NSString *)latLngPairStr
{
    return [NSString stringWithFormat:@"%f,%f",[self latFloat],[self lngFloat]];
}

// Returns true if the receiver's formatted address is a substring match with str.  
// Substring match is computed by doing a compare of all the atoms in str against number, street, city, airport, etc
- (BOOL)isMatchingTypedString:(NSString *)str
{
    // check for nil or empty string, and if so return true
    if (!str || [str length]==0) {
        return TRUE;   
    }
    
    // check for a straight, case insensitive prefix match against the formatted address
    if ([self formattedAddress] &&
        [[self formattedAddress] rangeOfString:str options:NSCaseInsensitiveSearch].location == 0) {  
        return TRUE;  // if str is a prefix of formatted address, return true 
    }
    
    // Otherwise, check whether the atom matches against address components
    NSArray *strAtoms = [str componentsSeparatedByCharactersInSet:
                        [NSCharacterSet characterSetWithCharactersInString:@" ,."]];
    NSMutableArray *matches = [NSMutableArray arrayWithCapacity:[strAtoms count]]; // will hold results
    NSSet *addrComponents = [self addressComponents];
    if (addrComponents && [addrComponents count]>0) {
        for (int i=0; i<[strAtoms count]; i++) {  // iterate through string's atoms
            NSString *atom = [strAtoms objectAtIndex:i];
            [matches addObject:@"No match"];
            if (!atom || [atom length] == 0) { // if no or empty string...
                [matches replaceObjectAtIndex:i withObject:@"Match"]; // count as match
            }
            else { 
                for (AddressComponent *ac in addrComponents) {  // iterate through address components
                    for (NSString *type in [ac types]) {  // iterate through component types
                        if ([type isEqualToString:@"route"] ||
                            [type isEqualToString:@"intersection"] ||
                            [type isEqualToString:@"locality"] ||
                            [type isEqualToString:@"airport"]) { // for these types, do a substring compare
                            if ([ac longName] && [[ac longName] length]>0 && 
                                [[ac longName] rangeOfString:atom options:NSCaseInsensitiveSearch].location != NSNotFound) {
                                [matches replaceObjectAtIndex:i withObject:@"Match"];
                                goto getNextAtom;
                            }
                            if ([ac shortName] && [[ac shortName] length]>0 && 
                                [[ac shortName] rangeOfString:atom options:NSCaseInsensitiveSearch].location != NSNotFound) {
                                [matches replaceObjectAtIndex:i withObject:@"Match"];
                                goto getNextAtom;
                            }
                        }
                        else { // for all others do a prefix compare
                            NSRange range1 = [[ac longName] rangeOfString:atom options:NSCaseInsensitiveSearch];   // compare vs longName
                            if (![ac longName] || [[ac longName] length] == 0) {
                                range1.location = NSNotFound;  // disqualify match if no LongName string
                            }
                            NSRange range2 = [[ac shortName] rangeOfString:atom options:NSCaseInsensitiveSearch];   // compare vs shortName
                            if (![ac shortName] || [[ac shortName] length] == 0) {
                                range2.location = NSNotFound;  // disqualify match if no shortName string
                            }
                            if (range1.location == 0 || range2.location == 0) { // Make sure it is a prefix only
                                if ([type isEqualToString:@"street_number"]) {
                                    [matches replaceObjectAtIndex:i withObject:@"Match"];
                                    goto getNextAtom;
                                }
                                else { 
                                    // any other type object match is an optional match, one that does not 
                                    // disqualify the overall match, but in itself is not enough to make a match
                                    [matches replaceObjectAtIndex:i withObject:@"Optional match"];
                                }
                            }
                        }

                    }
                }
            }
        getNextAtom:
            [matches count];   // No op (needed for goto label)
        }
        // No go through matches array and see if there is at least one "Match" and no "No match"es
        BOOL required_match = NO;
        for (NSString *match in matches) {
            if ([match isEqualToString:@"No match"]) {
                return NO;
            }
            else if ([match isEqualToString:@"Match"]) {
                required_match = YES;  
            }
        }
        if (required_match) {
            return YES;  // there was at least one "Match" so return true
        }
        else {
            return NO;  
        }
    }
    else {  // if there are no address components, do a simple prefix match on the formatted address
        return [[self formattedAddress] hasPrefix:str];
    }
}

// returns the formatted address minus everything after the postal code
- (NSString *)shortFormattedAddress  
{
    if (![self formattedAddress]) {
        return NULL;  
    }
    NSString* addr = [NSMutableString stringWithString:[self formattedAddress]];
    NSString* postalCode = [[[[self addressComponents] objectsPassingTest:^(id obj,BOOL *stop){
        AddressComponent* ac = obj;
        if ([[ac types] containsObject:@"postal_code"]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }] anyObject] shortName];  // Returns the short postal code
    if (postalCode && [postalCode length] > 0) {
        NSRange range = [addr rangeOfString:postalCode options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            NSString* returnString = [addr substringToIndex:range.location];
            if ([returnString length] > 0) { // check to make sure we have something to return (DE25 fix)
                return returnString;  // return up to but not including postal_code
            }
        }
    }
    return addr;  // postal code not found or in the front of string, return whole string
}

// Method to see whether two locations are effectively equivalent
// If they have the exact same formatted address, or they are within ~0.05 miles 
// For example, it is 233 feet between 1350 and 1315 Hull Drive
// 1350 Hull Lat: 37.510594; Lng: -122.268646;
// 1315 Hull Lat: 37.510811; Lng: -122.267816; 
// Difference is ~0.0008.  Rather than compute exact distince, simply use a surrounding box calculation
- (BOOL)isEquivalent:(Location *)loc2
{
    if ([[self formattedAddress] isEqualToString:[loc2 formattedAddress]]) {
        return true;
    }
    double lat2 = [loc2 latFloat];
    double lng2 = [loc2 lngFloat];
    if ((fabs([self latFloat] - lat2) < 0.0008) && (fabs([self lngFloat] - lng2) < 0.0008)) {
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
