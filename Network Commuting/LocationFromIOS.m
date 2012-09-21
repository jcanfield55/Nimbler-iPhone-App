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

// Initializes an empty LocationIOS and its superclass Location using placemark0
// Use this instead of setPlacemark method
- (void)initWithPlacemark:(CLPlacemark *)placemark0
{
    [self setPlacemark:placemark0];

    // Set the Location properties
    [self setGeoCoderStatus:@"OK"];  // TODO -- fill in actual status
    [self setFormattedAddress:ABCreateStringWithAddressDictionary([placemark0 addressDictionary], YES)];
    CLLocationCoordinate2D coord = [[placemark0 location] coordinate];
    [self setLatFloat:coord.latitude];
    [self setLngFloat:coord.longitude];
    [self setApiTypeEnum:IOS_GEOCODER];
    // Nothing to fill for locationType
    
}

- (NSDictionary *)addressComponentDictionary
{
    if (![super addressComponentDictionary]) {
        [super setAddressComponentDictionary:[[self placemark] addressDictionary]];
    }
    return [super addressComponentDictionary];
}
@end
