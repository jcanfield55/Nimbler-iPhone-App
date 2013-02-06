//
//  LocationFromIOS.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 9/20/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
// Subclass of Location used for geocoding and placemarks received from CLGeocoder or other IOS methods

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "Location.h"


@interface LocationFromIOS : Location

@property (nonatomic, retain) CLPlacemark* placemark;  // Placemark returned from CLGeocoder

// Initializes an empty LocationIOS and its superclass Location using placemark0
// Use this instead of setPlacemark method
// Status will be "OK" if error==nil, otherwise it will be marked with the error
- (void)initWithPlacemark:(CLPlacemark *)placemark0 error:(NSError *)error;

@end
