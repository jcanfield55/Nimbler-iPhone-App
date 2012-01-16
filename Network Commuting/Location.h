//
//  ToFromLocations.h
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject

@property (nonatomic, retain) NSString * normAddress;
@property (nonatomic, retain) NSNumber * geoLat;
@property (nonatomic, retain) NSNumber * geoLong;
@property (nonatomic, retain) NSNumber * toFrequency;
@property (nonatomic, retain) NSNumber * fromFrequency;
@property (nonatomic, retain) NSNumber * isGeocoded;
@property (nonatomic, retain) NSString * rawAddress;
@property (nonatomic, retain) NSString * name;

@end
