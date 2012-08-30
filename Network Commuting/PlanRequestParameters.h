//
//  PlanRequestParameters.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/29/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
// Class containing the elements needed to make a plan request


#import <Foundation/Foundation.h>
#import "Location.h"

@interface PlanRequestParameters : NSObject

@property (strong, nonatomic) Location* fromLocation;
@property (strong, nonatomic) Location* toLocation;
@property (strong, nonatomic) NSDate* tripDate;
@property (nonatomic) DepartOrArrive departOrArrive;
@property (nonatomic) int maxWalkDistance;

@end
