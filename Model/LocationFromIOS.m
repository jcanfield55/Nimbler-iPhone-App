//
//  LocationFromIOS.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 9/20/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "LocationFromIOS.h"
#import "UtilityFunctions.h"
#import <AddressBookUI/AddressBookUI.h>

@interface LocationFromIOS ()

// Internal functions
-(NSString *)standardizeFormattedAddress;

@end

@implementation LocationFromIOS

@dynamic placemark;
@synthesize isLocalSearchResult;
@dynamic  placeName;

static NSMutableDictionary* locationFromIOSAddressMappingDictionary;

// Initializes an empty LocationIOS and its superclass Location using placemark0
// Use this instead of setPlacemark method
- (void)initWithPlacemark:(CLPlacemark *)placemark0 error:(NSError *)error;
{
    [self setPlacemark:placemark0];

    // Set the status code
    if (!error) {
        [self setGeoCoderStatus:@"OK"];
    } else if ([error code]==kCLErrorGeocodeFoundPartialResult) {
        [self setGeoCoderStatus:@"kCLErrorGeocodeFoundPartialResult"];
    } else {
        [self setGeoCoderStatus:[NSString stringWithFormat:@"kCLError Geocode unknown code: %@", [error localizedDescription]]];
    }
    
    // Set the other properties
    [self setFormattedAddress:[self standardizeFormattedAddress]];
    CLLocationCoordinate2D coord = [[placemark0 location] coordinate];
    [self setLatFloat:coord.latitude];
    [self setLngFloat:coord.longitude];
    [self setApiTypeEnum:IOS_GEOCODER];
    [self setExcludeFromSearch:[NSNumber numberWithBool:false]];
    // Nothing to fill for locationType
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
                        NSRange range = [addrLine rangeOfString:@" "];
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
            
            NSRange range;
            int num;
            NSStringCompareOptions options1 = 0;
            range.location = 0;
            range.length = [formattedAddr length];
            num = [formattedAddr replaceOccurrencesOfString:@"Washington D.C.‎ District of Columbia"
                                                 withString:@"Washington"
                                                    options:options1
                                                      range:range];
            
            range.location = 0;
            range.length = [formattedAddr length];
            num = [formattedAddr replaceOccurrencesOfString:@"Washington, DC"
                                                 withString:@"Washington"
                                                    options:options1
                                                      range:range];
            
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
                
                range.location = 0;
                range.length = [formattedAddr length];
                num = [formattedAddr replaceOccurrencesOfString:@"Washington, DC"
                                                     withString:@"Washington"
                                                        options:options1
                                                          range:range];
                // Get rid of random Unicode "left-to-right mark" I found around "California" http://www.fileformat.info/info/unicode/char/200e/index.htm
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


/* Examples of iOS ABCreateStringWithAddressDictionary results (9/26/2012 on iOS6):
 Hull Dr & Laurel St
 San Carlos‎ California‎ 94070
 United States
 */
/* Example of a iOS addressComponentDictionary
 { City = "San Francisco";
 Country = "United States";
 CountryCode = US;
 FormattedAddressLines = (
 "40 Spear St",
 "San Francisco, CA 94105",
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
    if (![super addressComponentDictionary]) {
        if (!locationFromIOSAddressMappingDictionary) {
            locationFromIOSAddressMappingDictionary =
            [NSMutableDictionary dictionaryWithObjectsAndKeys:
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
        
        [super setAddressComponentDictionary:newAddrDict];
    }
    return [super addressComponentDictionary];
}
@end
