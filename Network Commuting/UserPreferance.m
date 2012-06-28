//
//  UserPreferance.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/28/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "UserPreferance.h"

@implementation UserPreferance

@synthesize triggerPushAtHour,walkDistance,pushEnable;


-(void)setPushEnable:(Boolean)pushEnables
{
    pushEnable = pushEnables;
}

-(void)setTriggerPushAtHour:(int)triggerPushAtHours
{
    triggerPushAtHour = triggerPushAtHours;
}

-(void)setWalkDistance:(float)walkDistances
{
    walkDistance = walkDistances;
}

@end
