//
//  LatLng.h
//  Network Commuting
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "enums.h"

@interface LatLng : NSObject

@property (nonatomic) double lat;
@property (nonatomic) double lng;
@property (nonatomic) double z;

+ (RKObjectMapping *)objectMappingForApi:(APIType)gt;
- (id) initWithLat:(double)newlat Lng:(double)newlng;
- (NSString *)latLngPairStr;
@end
