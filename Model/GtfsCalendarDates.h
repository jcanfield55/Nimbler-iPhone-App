//
//  GtfsCalendarDates.h
//  RestKit
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsCalendar;

@interface GtfsCalendarDates : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * exceptionType;
@property (nonatomic, retain) NSString * serviceID;
@property (nonatomic, retain) GtfsCalendar *calendar;

@end
