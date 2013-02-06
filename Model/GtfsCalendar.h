//
//  GtfsCalendar.h
//  RestKit
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsCalendarDates, GtfsTrips;

@interface GtfsCalendar : NSManagedObject

@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSNumber * friday;
@property (nonatomic, retain) NSNumber * monday;
@property (nonatomic, retain) NSNumber * saturday;
@property (nonatomic, retain) NSString * serviceID;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSNumber * sunday;
@property (nonatomic, retain) NSNumber * thursday;
@property (nonatomic, retain) NSNumber * tuesday;
@property (nonatomic, retain) NSNumber * wednesday;
@property (nonatomic, retain) NSSet *calendarDates;
@property (nonatomic, retain) NSSet *trips;
@end

@interface GtfsCalendar (CoreDataGeneratedAccessors)

- (void)addCalendarDatesObject:(GtfsCalendarDates *)value;
- (void)removeCalendarDatesObject:(GtfsCalendarDates *)value;
- (void)addCalendarDates:(NSSet *)values;
- (void)removeCalendarDates:(NSSet *)values;
- (void)addTripsObject:(GtfsTrips *)value;
- (void)removeTripsObject:(GtfsTrips *)value;
- (void)addTrips:(NSSet *)values;
- (void)removeTrips:(NSSet *)values;
@end
