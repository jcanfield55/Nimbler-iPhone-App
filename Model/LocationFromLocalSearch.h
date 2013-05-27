//
//  LocationFromLocalSearch.h
//  Nimbler SF
//
//  Created by Gunjan ribadiya on 5/2/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "LocationFromIOS.h"

@interface LocationFromLocalSearch : NSObject


@property (nonatomic, strong) CLPlacemark* placemark;  // Placemark returned from CLGeocoder
@property (nonatomic) BOOL isLocalSearchResult;
@property (nonatomic, strong) NSString *formattedAddress;  // Standardized address string
//For Local Search
@property (nonatomic , strong)NSString *placeName;

@property (nonatomic, strong) NSString *shortFormattedAddress;  // typically equal to the formatted address minus the postal code and country.  For transit station, also removes city name. 

@property (nonatomic, strong) NSDictionary* addressComponentDictionary; // Dictionary of address components (generated dynamically by subclasses; not stored in Core Data)

@property (nonatomic, strong) NSNumber *lat;  // double floating point
@property (nonatomic, strong) NSNumber *lng;  // double floating point

// Initializes an empty LocationIOS and its superclass Location using placemark0
// Use this instead of setPlacemark method
// Status will be "OK" if error==nil, otherwise it will be marked with the error
- (void)initWithPlacemark:(CLPlacemark *)placemark0 error:(NSError *)error;

// Internal functions
-(NSString *)standardizeFormattedAddress;

@end
