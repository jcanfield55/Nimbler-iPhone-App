//
//  LocationFromIOS.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 9/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LocationFromIOS.h"
#import <AddressBookUI/AddressBookUI.h>


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
    [self setFormattedAddress:ABCreateStringWithAddressDictionary([placemark0 addressDictionary], YES)];
    CLLocationCoordinate2D coord = [[placemark0 location] coordinate];
    [self setLatFloat:coord.latitude];
    [self setLngFloat:coord.longitude];
    [self setApiTypeEnum:IOS_GEOCODER];
    // Nothing to fill for locationType
}

-(NSString *)shortFormattedAddress {
    return [super shortFormattedAddress];
}

/*  Example of a iOS addressComponentDictionary
 City = "San Francisco";
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
 ZIP = 94105;
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
