//
//  PlanPlace.h
//  Network Commuting
//
//  Created by John Canfield on 1/29/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

// Place object used in Open Trip Planner plan results

#import <Foundation/Foundation.h>
#import <RestKit/Restkit.h>
#import "LatLng.h"
#import "AgencyAndId.h"
#import "enums.h"

@interface PlanPlace : NSObject

@property(nonatomic,strong) NSString *name;
@property(nonatomic,strong) AgencyAndId *stopId;
@property(nonatomic,strong) LatLng *latLng;
@property(nonatomic,strong) NSDate *arrival;
@property(nonatomic,strong) NSDate *departure;

+ (RKObjectMapping *)objectMappingForApi:(APIType)tpt;

// Convenience methods for flattening lat/lng properties
- (double)lat;   
- (double)lng;
- (void)setLat:(double)lat;
- (void)setLng:(double)lng;

@end
