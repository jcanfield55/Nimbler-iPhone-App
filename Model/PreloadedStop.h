//
//  PreloadedStop.h
//  Nimbler Caltrain
//
//  Created by macmini on 15/02/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import <Restkit/RKJSONParserJSONKit.h>
#import "enums.h"

@class StationListElement;

@interface PreloadedStop : NSManagedObject

@property (nonatomic, retain) NSString * formattedAddress;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSString * stopId;
@property (nonatomic, retain) StationListElement *stationListElement;

+ (RKManagedObjectMapping *)objectMappingforStop:(APIType)apiType;

@end
