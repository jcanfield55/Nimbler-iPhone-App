//
//  GeoRectangle.h
//  Network Commuting
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LatLng.h"
#import <RestKit/RestKit.h>
#import "enums.h"

@interface GeoRectangle : NSObject

@property (nonatomic, strong) LatLng * southWest;
@property (nonatomic, strong) LatLng * northEast;

+ (RKObjectMapping *)objectMappingForApi:(APIType)gt;

@end
