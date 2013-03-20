//
//  GtfsStopTimes.h
//  RestKit
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsStop, GtfsTrips;

@interface GtfsStopTimes : NSManagedObject

@property (nonatomic, retain) NSString * arrivalTime;
@property (nonatomic, retain) NSString * departureTime;
@property (nonatomic, retain) NSString * dropOffType;
@property (nonatomic, retain) NSString * pickUpType;
@property (nonatomic, retain) NSString * shapeDistTravelled;
@property (nonatomic, retain) NSString * stopID;
@property (nonatomic, retain) NSString * stopSequence;
@property (nonatomic, retain) NSString * tripID;
@property (nonatomic, retain) NSString * agencyID;
@property (nonatomic, retain) NSNumber * departureTimeInterval;
@property (nonatomic, retain) NSNumber * arrivalTimeInterval;

@end
