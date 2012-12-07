//
//  GtfsRoutes.h
//  RestKit
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsAgency, GtfsTrips;

@interface GtfsRoutes : NSManagedObject

@property (nonatomic, retain) NSString * routeColor;
@property (nonatomic, retain) NSString * routeDesc;
@property (nonatomic, retain) NSString * routeID;
@property (nonatomic, retain) NSString * routeLongname;
@property (nonatomic, retain) NSString * routeShortName;
@property (nonatomic, retain) NSString * routeTextColor;
@property (nonatomic, retain) NSString * routeType;
@property (nonatomic, retain) NSString * routeURL;
@property (nonatomic, retain) GtfsAgency *agency;
@property (nonatomic, retain) NSSet *trips;
@end

@interface GtfsRoutes (CoreDataGeneratedAccessors)

- (void)addTripsObject:(GtfsTrips *)value;
- (void)removeTripsObject:(GtfsTrips *)value;
- (void)addTrips:(NSSet *)values;
- (void)removeTrips:(NSSet *)values;
@end
