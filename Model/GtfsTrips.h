//
//  GtfsTrips.h
//  RestKit
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsCalendar, GtfsRoutes, GtfsStopTimes;

@interface GtfsTrips : NSManagedObject

@property (nonatomic, retain) NSString * blockID;
@property (nonatomic, retain) NSString * directionID;
@property (nonatomic, retain) NSString * routeID;
@property (nonatomic, retain) NSString * serviceID;
@property (nonatomic, retain) NSString * shapeID;
@property (nonatomic, retain) NSString * tripHeadSign;
@property (nonatomic, retain) NSString * tripID;
@property (nonatomic, retain) GtfsCalendar *calendar;
@property (nonatomic, retain) GtfsRoutes *route;
@property (nonatomic, retain) NSSet *stopTimes;
@end

@interface GtfsTrips (CoreDataGeneratedAccessors)

- (void)addStopTimesObject:(GtfsStopTimes *)value;
- (void)removeStopTimesObject:(GtfsStopTimes *)value;
- (void)addStopTimes:(NSSet *)values;
- (void)removeStopTimes:(NSSet *)values;
@end
