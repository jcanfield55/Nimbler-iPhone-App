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

@interface PlanPlace : NSManagedObject

@property(nonatomic,strong) NSString *name;
@property(nonatomic,strong) NSString *stopId;
@property(nonatomic,strong) NSString *stopAgencyId;
@property(nonatomic,strong) NSNumber *lat;
@property(nonatomic,strong) NSNumber *lng;
@property(nonatomic,strong) NSDate *arrival;
@property(nonatomic,strong) NSDate *departure;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)tpt;

// Convenience methods for flattening lat/lng properties
- (double)latFloat;   
- (double)lngFloat;

- (NSString *)ncDescription;
@end
