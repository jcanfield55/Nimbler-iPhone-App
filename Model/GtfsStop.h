//
//  GtfsStop.h
//  RestKit
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsStopTimes;

@interface GtfsStop : NSManagedObject

@property (nonatomic, retain) NSString * stopDesc;
@property (nonatomic, retain) NSString * stopID;
@property (nonatomic, retain) NSNumber * stopLat;
@property (nonatomic, retain) NSNumber * stopLon;
@property (nonatomic, retain) NSString * stopName;
@property (nonatomic, retain) NSString * stopURL;
@property (nonatomic, retain) NSString * zoneID;
@property (nonatomic, retain) NSSet *stopTimes;
@end

@interface GtfsStop (CoreDataGeneratedAccessors)

- (void)addStopTimesObject:(GtfsStopTimes *)value;
- (void)removeStopTimesObject:(GtfsStopTimes *)value;
- (void)addStopTimes:(NSSet *)values;
- (void)removeStopTimes:(NSSet *)values;
@end
