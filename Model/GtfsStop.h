//
//  GtfsStop.h
//  Nimbler Caltrain
//
//  Created by macmini on 06/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GtfsStop : NSManagedObject

@property (nonatomic, retain) NSString * stopID;
@property (nonatomic, retain) NSString * stopName;
@property (nonatomic, retain) NSString * stopDesc;
@property (nonatomic, retain) NSNumber * stopLat;
@property (nonatomic, retain) NSNumber * stopLon;
@property (nonatomic, retain) NSString * zoneID;
@property (nonatomic, retain) NSString * stopURL;

@end
