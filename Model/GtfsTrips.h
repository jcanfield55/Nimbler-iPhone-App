//
//  GtfsTrips.h
//  Nimbler Caltrain
//
//  Created by macmini on 06/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

@class GtfsCalendar, GtfsRoutes;

@interface GtfsTrips : NSManagedObject

@property (nonatomic, retain) NSString * tripID;
@property (nonatomic, retain) NSString * routeID;
@property (nonatomic, retain) NSString * serviceID;
@property (nonatomic, retain) NSString * tripHeadSign;
@property (nonatomic, retain) NSString * directionID;
@property (nonatomic, retain) NSString * blockID;
@property (nonatomic, retain) NSString * shapeID;
@property (nonatomic, retain) NSSet *calendar;
@property (nonatomic, retain) GtfsRoutes *route;

@end

@interface GtfsTrips (CoreDataGeneratedAccessors)


- (void)addCalendarObject:(GtfsCalendar *)value;
- (void)removeCalendarObject:(GtfsCalendar *)value;
- (void)addCalendar:(NSSet *)values;
- (void)removeCalendar:(NSSet *)values;
@end
