//
//  GtfsCalendar.h
//  Nimbler Caltrain
//
//  Created by macmini on 06/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GtfsCalendar : NSManagedObject

@property (nonatomic, retain) NSString * serviceID;
@property (nonatomic, retain) NSNumber * monday;
@property (nonatomic, retain) NSNumber * sunday;
@property (nonatomic, retain) NSNumber * tuesday;
@property (nonatomic, retain) NSNumber * wednesday;
@property (nonatomic, retain) NSNumber * thursday;
@property (nonatomic, retain) NSNumber * friday;
@property (nonatomic, retain) NSNumber * saturday;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * endDate;

@end
