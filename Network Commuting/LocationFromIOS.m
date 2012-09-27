//
//  LocationFromIOS.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 9/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LocationFromIOS.h"
#import <AddressBookUI/AddressBookUI.h>

@interface LocationFromIOS ()

// Internal functions
-(NSString *)standardizeFormattedAddress;

@end

@implementation LocationFromIOS

@dynamic placemark;

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
    // Nothing to fill for locationType
}

// Temporary function used for setting a breakpoint only.  Can be deleted.
-(NSString *)shortFormattedAddress {
    return [super shortFormattedAddress];
}

// Reformat the iOS address into a standard formattedAddress (as compatible with Google as possible)
-(NSString *)standardizeFormattedAddress {
    NSMutableString* formattedAddr = [NSMutableString stringWithCapacity:25];
    NSArray* addrLines = [[[self placemark] addressDictionary] objectForKey:@"FormattedAddressLines"];
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
    else { // if cannot get formatted address lines,
        return ABCreateStringWithAddressDictionary([[self placemark] addressDictionary], YES);
    }
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
    if (![super addressComponentDictionary]) {
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
        
        [super setAddressComponentDictionary:newAddrDict];
    }
    return [super addressComponentDictionary];
}
@end
