//
//  LocationFromLocalSearch.m
//  Nimbler SF
//
//  Created by Gunjan ribadiya on 5/2/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "LocationFromLocalSearch.h"
#import "UtilityFunctions.h"
#import <AddressBookUI/AddressBookUI.h>

@implementation LocationFromLocalSearch

@synthesize placemark;
@synthesize isLocalSearchResult;
@synthesize placeName;
@synthesize formattedAddress;
@synthesize shortFormattedAddress;
@synthesize addressComponentDictionary;
@synthesize lat;
@synthesize lng;

static NSMutableDictionary* locationFromIOSAddressMappingDictionary;

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

// Initializes an empty LocationIOS and its superclass Location using placemark0
// Use this instead of setPlacemark method
- (void)initWithPlacemark:(CLPlacemark *)placemark0 error:(NSError *)error;
{
    [self setPlacemark:placemark0];
    
    // Set the status code
    // Set the other properties
    [self setFormattedAddress:[self standardizeFormattedAddress]];
    CLLocationCoordinate2D coord = [[placemark0 location] coordinate];
    [self setLatFloat:coord.latitude];
    [self setLngFloat:coord.longitude];
}

// Reformat the iOS address into a standard formattedAddress (as compatible with Google as possible)
-(NSString *)standardizeFormattedAddress {
    NSMutableString* formattedAddr = [NSMutableString stringWithCapacity:25];
    NSArray* addrLines = [[[self placemark] addressDictionary] objectForKey:@"FormattedAddressLines"];
    @try {
        if (addrLines && [addrLines isKindOfClass:[NSArray class]] && [addrLines count]>0) {
            for (int i=0; i<[addrLines count]; i++) {
                NSString* addrLine = [addrLines objectAtIndex:i];
                if (i==[addrLines count]-1) {  // if the last line, modify the country if needed
                    if ([addrLine isEqualToString:@"United States"]) {
                        addrLine = @"USA";
                    }
                    else if([addrLine isEqualToString:@"Washington D.C.‎ District of Columbia"]){
                        addrLine = @"Washington";
                    }
                }
                if (i==[addrLines count]-2) { // if this is the 2nd to last line, the one with zipcode
                    // Remove +4 if it is a Zip+4
                    if ([addrLine length]>5 &&
                        [[addrLine substringFromIndex:([addrLine length]-5)] intValue] < 0) {
                        // if the end of the line looks like a negative number '-1234'
                        // then it is a zip+4 and remove it from the line
                        addrLine = [addrLine substringToIndex:([addrLine length]-5)];
                    }
                    // Remove any double spaces (like between the state and zipcode)
                    BOOL doAnotherLoop = true;
                    for (int j=0; (doAnotherLoop && j<5); j++) {
                        NSRange range = [addrLine rangeOfString:@"  "];
                        if (range.location == NSNotFound) {
                            doAnotherLoop = false;
                        } else {
                            // Remove the extra space
                            addrLine = [[addrLine substringToIndex:range.location] stringByAppendingString:
                                        [addrLine substringFromIndex:(range.location + 1)]];
                        }
                    }
                }
                [formattedAddr appendString:addrLine];
                if (i<[addrLines count]-1) {  // if not the last line
                    [formattedAddr appendString:@", "];
                }
            }
            return [NSString stringWithString:formattedAddr];
        }
        else { // if cannot get formatted address lines, try our best for California addresses
            formattedAddr = [NSMutableString
                             stringWithString:ABCreateStringWithAddressDictionary([[self placemark] addressDictionary], YES)];
            
            NSStringCompareOptions options1 = 0;
            NSRange range;
            range.length = 37;  // Enough length to get to " California 94070-0001 United States"
            int rangeLocation = [formattedAddr length] - range.length;
            if (rangeLocation>=0) {
                range.location = rangeLocation;
            } else { // if there is not enough length, go for full string
                range.location = 0;
                range.length = [formattedAddr length];
            }
            
            if (formattedAddr) {
                int num;
                num = [formattedAddr replaceOccurrencesOfString:@" California"
                                                     withString:@", CA"
                                                        options:options1
                                                          range:range];
                
                range.length = 15;  // Enough length to get to "\nUnited States"
                if (formattedAddr.length >= range.length) {
                    range.location = formattedAddr.length - range.length;
                    num = [formattedAddr replaceOccurrencesOfString:@"\nUnited States"
                                                         withString:@", USA"
                                                            options:options1
                                                              range:range];
                }
                range.location = 0;
                range.length = [formattedAddr length];
                num = [formattedAddr replaceOccurrencesOfString:@"\n"
                                                     withString:@", "
                                                        options:options1
                                                          range:range];
                
                range.location = 0;
                range.length = [formattedAddr length];
                num = [formattedAddr replaceOccurrencesOfString:@"Washington D.C.‎ District of Columbia"
                                                     withString:@"Washington"
                                                        options:options1
                                                          range:range];
                
                // Get rid of random Unicode "left-to-right mark" I found around "California"  http://www.fileformat.info/info/unicode/char/200e/index.htm
                range.length = [formattedAddr length];
                num = [formattedAddr replaceOccurrencesOfString:@"\u200e"
                                                     withString:@""
                                                        options:options1
                                                          range:range];
                
                
                if ([formattedAddr length]>5 &&
                    [[formattedAddr substringFromIndex:([formattedAddr length]-5)] intValue] < 0) {
                    // if the end of the line looks like a negative number '-1234'
                    // then it is a zip+4 and remove it from the line
                    range.length = 5;
                    range.location = formattedAddr.length - range.length;
                    [formattedAddr replaceCharactersInRange:range withString:@""];
                }
            }
            return [NSString stringWithString:formattedAddr];
        }
    }
    @catch (NSException *exception) {
        logException(@"LocationFromIOS->standardizeFormattedAddress",
                     [NSString stringWithFormat:@" formattedAddr: %@\n addrLines: %@", formattedAddr, addrLines],
                     exception);
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

/* Examples of iOS ABCreateStringWithAddressDictionary results (9/26/2012 on iOS6):
 Hull Dr & Laurel St
 San Carlos‎ California‎ 94070
 United States
 */
/*  Example of a iOS addressComponentDictionary
 { City = "San Francisco";
 Country = "United States";
 CountryCode = US;
 FormattedAddressLines =     (
 "40 Spear St",
 "San Francisco, CA  94105",
 "United States"
 );
 State = California;
 Street = "40 Spear St";
 SubAdministrativeArea = "San Francisco";
 SubLocality = "South Beach";
 SubThoroughfare = 40;
 Thoroughfare = "Spear St";
 ZIP = 94105;}
 
 { City = "San Carlos";
 Country = "United States";
 CountryCode = US;
 FormattedAddressLines =     (
 "Hull Dr & Laurel St",
 "San Carlos, CA  94070",
 "United States"
 );
 State = California;
 Street = "Hull Dr & Laurel St";
 SubAdministrativeArea = "San Mateo";
 SubLocality = "Bay Area";
 Thoroughfare = "Hull Dr";
 ZIP = 94070;}
 
 {City = "San Francisco";
 Country = "United States";
 CountryCode = US;
 FormattedAddressLines =     (
 "San Francisco International Airport",
 "San Francisco, CA  94128",
 "United States"
 );
 State = California;
 SubAdministrativeArea = "San Mateo";
 SubLocality = "Bay Area";
 ZIP = 94128;}
 
 // Burlingame Caltrain station
 {City = "San Mateo";
 Country = "United States";
 CountryCode = US;
 FormattedAddressLines =     (
 "41 S Railroad Ave",
 "San Mateo, CA  94401-3209",
 "United States"
 );
 PostCodeExtension = 3209;
 State = California;
 Street = "41 S Railroad Ave";
 SubAdministrativeArea = "San Mateo";
 SubLocality = "Downtown Burlingame";
 SubThoroughfare = 41;
 Thoroughfare = "S Railroad Ave";
 ZIP = 94401;}
 */

// Returns an addressComponentDictionary using the same key names as LocationFromGoogle where possible
- (NSDictionary *)addressComponentDictionary
{
        if (!locationFromIOSAddressMappingDictionary) {
            locationFromIOSAddressMappingDictionary =
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"locality",@"City",
             @"country",@"Country",
             @"country(short)",@"CountryCode",
             @"administrative_area_level_1",@"State",
             @"administrative_area_level_2",@"SubAdministrativeArea",
             @"neighborhood",@"SubLocality",
             @"street_number",@"SubThoroughfare",
             @"route",@"Thoroughfare",
             @"postal_code",@"ZIP",
             nil];
        }
        
        NSDictionary* addrDict = [[self placemark] addressDictionary];
        NSMutableDictionary* newAddrDict = [[NSMutableDictionary alloc] initWithCapacity:[addrDict count]];
        
        // Go through and remove anything that is not a string object (for example, "FormattedAddressLines")
        NSEnumerator* enumerator = [addrDict keyEnumerator];
        NSString* type;
        while (type = [enumerator nextObject]) {  // enumerate thru all the type strings in the dictionary
            NSString* value = [addrDict objectForKey:type];
            if ([value isKindOfClass:[NSString class]]) {
                // only add elements that are strings
                NSString* key = [locationFromIOSAddressMappingDictionary objectForKey:type];
                if (!key) {
                    key = type; // if no translation for type, use type itself
                }
                [newAddrDict setObject:value forKey:key];
            }
        }
        
    return newAddrDict;
}

- (BOOL)isEqual:(LocationFromLocalSearch*)tempLocation {
    if(!tempLocation)
        return NO;
    if(!self.formattedAddress || !tempLocation.formattedAddress)
        return NO;
    if ([self.formattedAddress isEqualToString:tempLocation.formattedAddress])
        return YES;
    return NO;
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    if(!self.formattedAddress)
        result = prime * result + 0;
    else
        result = prime * result + [self.formattedAddress hash];
    return result;
}
@end
