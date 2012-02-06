//
//  Plan.h
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/Restkit.h>
#import "PlanPlace.h"
#import "enums.h"

@interface Plan : NSObject

@property(nonatomic, strong) NSDate *date;
@property(nonatomic,strong) PlanPlace *from;
@property(nonatomic,strong) PlanPlace *to;

+ (RKObjectMapping *)objectMappingforPlanner:(APIType)tpt;

@end
