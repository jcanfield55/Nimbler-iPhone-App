//
//  Step.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/Restkit.h>
#import "enums.h"

@class Leg;

@interface Step : NSManagedObject

// See this URL for documentation on the elements: http://www.opentripplanner.org/apidoc/data_ns0.html#walkStep
// This URL has example data http://groups.google.com/group/opentripplanner-dev/msg/4535900a5d18e61f?

@property (nonatomic, retain) NSString * absoluteDirection;
@property (nonatomic, retain) NSNumber * bogusName;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) NSString * exit;
@property (nonatomic, retain) NSString * relativeDirection;
@property (nonatomic, retain) NSNumber * startLat;
@property (nonatomic, retain) NSNumber * startLng;
@property (nonatomic, retain) NSNumber * stayOn;
@property (nonatomic, retain) NSString * streetName;
@property (nonatomic, retain) Leg *leg;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType;

- (NSString *)ncDescription;

@end
