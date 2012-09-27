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
#import <CoreLocation/CoreLocation.h>

@implementation Location

@dynamic apiType;
@dynamic rawAddresses;
@dynamic geoCoderStatus;
@dynamic formattedAddress;
@dynamic lat;
@dynamic lng;
@dynamic locationType;
@dynamic toFrequency;
@dynamic fromFrequency;
@dynamic dateLastUsed;
@dynamic nickName;
@dynamic preloadVersion;
@dynamic memberOfList;
@synthesize shortFormattedAddress;
@synthesize reverseGeoLocation;
@synthesize addressComponentDictionary;

// Static variables and methods to retrieve the Locations set wrapper
static Locations *locations;

+ (void)setLocations:(Locations *)loc {
    locations = loc;
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
    if ([self toFrequencyFloat] < TOFROM_FREQUENCY_VISIBILITY_CUTOFF) { // if this is the first use...
        [self setFromFrequencyFloat:([self fromFrequencyFloat]+ 1.0)];  // insure this location will be visible in the from list as well 
        [self setToFrequencyFloat:([self toFrequencyFloat]+2.0)];   // but give more weight to this location in the to list
    }
    else {
        [self setToFrequencyFloat:([self toFrequencyFloat]+1.0)];
    }
}

- (void)incrementFromFrequency {
    if ([self fromFrequencyFloat] < TOFROM_FREQUENCY_VISIBILITY_CUTOFF) { // if this is the first use...
        [self setToFrequencyFloat:([self toFrequencyFloat]+1.0)];  // insure this location will be visible in the to list as well 
        [self setFromFrequencyFloat:([self fromFrequencyFloat]+2.0)];   // but give more weight to this location in the from list
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
    NSDictionary *addrComponents = [self addressComponentDictionary];
    if (addrComponents && [addrComponents count]>0) {
        for (int i=0; i<[strAtoms count]; i++) {  // iterate through string's atoms
            NSString *atom = [strAtoms objectAtIndex:i];
            [matches addObject:@"No match"];
            if (!atom || [atom length] == 0) { // if no or empty string...
                [matches replaceObjectAtIndex:i withObject:@"Match"]; // count as match
            }
            else {
                NSEnumerator* enumerator = [addrComponents keyEnumerator];
                NSString* type;
                while (type = [enumerator nextObject]) {  // enumerate thru all the type strings in the dictionary
                    NSString* name = [addrComponents objectForKey:type];
                    if ([type isEqualToString:@"route"] ||
                        [type isEqualToString:@"intersection"] ||
                        [type isEqualToString:@"locality"] ||
                        [type isEqualToString:@"airport"] ||
                        [type isEqualToString:@"route(short)"] ||
                        [type isEqualToString:@"intersection(short)"] ||
                        [type isEqualToString:@"locality(short)"] ||
                        [type isEqualToString:@"airport(short)"]) { // for these types, do a substring compare
                        if (name && [name length]>0 &&
                            [name rangeOfString:atom options:NSCaseInsensitiveSearch].location != NSNotFound) {
                            [matches replaceObjectAtIndex:i withObject:@"Match"];
                            goto getNextAtom;
                        }
                    }
                    else { // for all others do a prefix compare
                        NSRange range1 = [name rangeOfString:atom options:NSCaseInsensitiveSearch];   // compare vs longName
                        if (!name || [name length] == 0) {
                            range1.location = NSNotFound;  // disqualify match if no LongName string
                        }
                        if (range1.location == 0) { // Make sure it is a prefix only
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

// Returns the formatted address minus everything after the postal code
// Also take out ", CA" if it is at the end (don't need to show California for Bay Area app)
// For pre-loaded transit stations (like Caltrain), show only the transit station name
- (NSString *)shortFormattedAddress  
{
    if (shortFormattedAddress) {
        return shortFormattedAddress;  // Return the property if it has already been created
    }
    // Otherwise, compute the shortFormattedAddress
    NSString* addr = [self formattedAddress];
    if (!addr) {
        shortFormattedAddress = nil;  
    }
    else {
        // Find whether it is a train station (
        NSString* trainStationName = [[self addressComponentDictionary] objectForKey:@"train_station(short)"];
        if (!trainStationName) {
            trainStationName = [[self addressComponentDictionary] objectForKey:@"train_station"];
        }
        if (trainStationName && [trainStationName length] >0) {
            // if a train station, return just the train_station name
            shortFormattedAddress = trainStationName;
        }
        else {
            // Find the postal code
            NSString* postalCode = [[self addressComponentDictionary] objectForKey:@"postal_code"];
            NSString* returnString;
            if (postalCode && [postalCode length] > 0) {
                NSRange range = [addr rangeOfString:postalCode options:NSBackwardsSearch];
                if (range.location != NSNotFound) {
                    returnString = [addr substringToIndex:range.location]; // Clip from postal code on
                }
            }
            if (returnString && [returnString length] > 0) { // check to make sure we have something to return (DE25 fix)
                if ([returnString hasSuffix:@", CA "]) { // Get rid of final ", CA"
                    returnString = [returnString substringToIndex:([returnString length]-5)];
                }
                shortFormattedAddress = returnString;
            }
            
            else if ([addr hasSuffix:@", CA, USA"]) { // If not postal code, but ends with CA, USA, clip that
                returnString = [addr substringToIndex:([addr length]-9)];
                shortFormattedAddress = returnString;
            }
            else {
                shortFormattedAddress = addr;  // postal code not found or in the front of string, return whole string
            }
        }
    }
    return shortFormattedAddress;
}

// Returns the distance between the referring object and loc2 in meters
- (double)metersFromLocation:(Location *)loc2
{
    // Check and make sure that the plan from Location is close to the endpoint of the last leg
    CLLocation *loc2Coord = [[CLLocation alloc] initWithLatitude:[loc2 latFloat]
                                                  longitude:[loc2 lngFloat]];
    CLLocation *locSelfCoord = [[CLLocation alloc] initWithLatitude:[self latFloat]
                                                  longitude:[self lngFloat]];
    CLLocationDistance distance = [loc2Coord distanceFromLocation:locSelfCoord];
    return distance;
}

// Used for currentLocation.  True if there is a reverseGeoLocation and it is within
// the time or distance thresholds to be considered still fresh
- (BOOL)isReverseGeoValid
{
    if (![self reverseGeoLocation]) {
        return false;
    }
    else if ([[[self reverseGeoLocation] dateLastUsed] timeIntervalSinceNow] > -(REVERSE_GEO_TIME_THRESHOLD) ||
             [self metersFromLocation:[self reverseGeoLocation]]<REVERSE_GEO_DISTANCE_THRESHOLD) {
        return true;
    }
    return false;
}

// true if receiver is CurrentLocation
- (BOOL)isCurrentLocation
{
    if ([[self formattedAddress] isEqualToString:CURRENT_LOCATION]) {
        return true;
    }
    return false;
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

@end
