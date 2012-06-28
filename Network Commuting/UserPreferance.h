//
//  UserPreferance.h
//  Nimbler
//
//  Created by JaY Kumbhani on 6/28/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import <CoreData/CoreData.h>
#import "enums.h"

@interface UserPreferance : NSManagedObject

@property (nonatomic) int triggerPushAtHour;
@property (nonatomic) Boolean pushEnable;
@property (nonatomic) float walkDistance;

-(void)setPushEnable:(Boolean)pushEnables;
-(void)setTriggerPushAtHour:(int)triggerPushAtHours;
-(void)setWalkDistance:(float)walkDistances;
@end
