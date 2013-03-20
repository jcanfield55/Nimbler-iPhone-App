//
//  IntermediateStops.h
//  Nimbler SF
//
//  Created by macmini on 19/03/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/Restkit.h>
#import "enums.h"

@class Leg;

@interface IntermediateStops : NSManagedObject

@property (nonatomic, retain) NSNumber * arrivalTime;
@property (nonatomic, retain) NSNumber * departureTime;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * stopAgencyId;
@property (nonatomic, retain) NSString * stopId;
@property (nonatomic, retain) Leg *leg;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)tpt;

@end
