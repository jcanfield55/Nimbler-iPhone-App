//
//  GeocodeRequestParameters.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 9/22/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
// Class containing parameters and information used in a geocoding request

#import <Foundation/Foundation.h>
#import "SupportedRegion.h"
#import "enums.h"

@interface GeocodeRequestParameters : NSObject

@property(strong, nonatomic) SupportedRegion *supportedRegion;  // Region to confine the geocode request to
@property(strong, nonatomic) NSString *rawAddress;  // address to geocode
@property(nonatomic) BOOL isFrom;  // True if this is a From geocode request.
@property(nonatomic) APIType apiType;  // API to use for geocoding

@end
