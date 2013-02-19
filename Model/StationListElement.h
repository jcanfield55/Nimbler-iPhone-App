//
//  StationListElement.h
//  Nimbler Caltrain
//
//  Created by conf on 2/15/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/Restkit.h>
#import "enums.h"
#import "PreloadedStop.h"

@class GtfsStop, Location;

@interface StationListElement : NSManagedObject

@property (nonatomic, retain) NSString * memberOfListId;
@property (nonatomic, retain) NSNumber * sequenceNumber;
@property (nonatomic, retain) NSString * containsList;
@property (nonatomic, retain) NSString * containsListId;
@property (nonatomic, retain) NSString * agency;
@property (nonatomic, retain) PreloadedStop *stop;
@property (nonatomic, retain) Location *location;

+ (RKManagedObjectMapping *)objectMappingforStation:(APIType)apiType;

@end
