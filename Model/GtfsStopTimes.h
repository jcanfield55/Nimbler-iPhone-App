//
//  GtfsStopTimes.h
//  Nimbler Caltrain
//
//  Created by macmini on 06/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsStop, GtfsTrips;

@interface GtfsStopTimes : NSManagedObject

@property (nonatomic, retain) NSString * tripID;
@property (nonatomic, retain) NSString * arrivalTime;
@property (nonatomic, retain) NSString * departureTime;
@property (nonatomic, retain) NSString * stopID;
@property (nonatomic, retain) NSString * stopSequence;
@property (nonatomic, retain) NSString * pickUpTime;
@property (nonatomic, retain) NSString * dropOfTime;
@property (nonatomic, retain) NSString * shapeDistTravelled;
@property (nonatomic, retain) GtfsTrips *trips;
@property (nonatomic, retain) GtfsStop *stop;

@end
