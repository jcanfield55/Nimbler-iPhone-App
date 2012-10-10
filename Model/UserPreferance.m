//
//  UserPreferance.m
//  Nimbler
//
//  Created by JaY Kumbhani on 7/2/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "UserPreferance.h"


@implementation UserPreferance

@synthesize pushEnable;
@synthesize triggerAtHour;
@synthesize walkDistance;

static UserPreferance* userPrefs;

// Return the singleton object.  Sets to default values if no value already saved
+(UserPreferance *)userPreferance
{
    
    if (!userPrefs) {  // if no static storage of preferences
        // Try to retrieve preferences from permanent storage
        userPrefs = [[UserPreferance alloc] init];
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        userPrefs.pushEnable = [prefs objectForKey:PREFS_IS_PUSH_ENABLE];
        userPrefs.triggerAtHour = [prefs objectForKey:PREFS_PUSH_NOTIFICATION_THRESHOLD];
        userPrefs.walkDistance = [prefs objectForKey:PREFS_MAX_WALK_DISTANCE];
        if (!userPrefs.pushEnable) {  
            // if no preferences retrieved from permanent storage, create new default ones
            [userPrefs setPushEnable:[NSNumber numberWithBool:PREFS_DEFAULT_IS_PUSH_ENABLE]];
            [userPrefs setTriggerAtHour:[NSNumber numberWithInt:PREFS_DEFAULT_PUSH_NOTIFICATION_THRESHOLD]];
            [userPrefs setWalkDistance:[NSNumber numberWithFloat:PREFS_DEFAULT_MAX_WALK_DISTANCE]];
            
            [userPrefs saveUpdates];
        }
    }
    return userPrefs;
}

// Saves changes to permanent storage
-(void)saveUpdates 
{
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[self pushEnable] forKey:PREFS_IS_PUSH_ENABLE];
    [prefs setObject:[self triggerAtHour] forKey:PREFS_PUSH_NOTIFICATION_THRESHOLD];
    [prefs setObject:[self walkDistance] forKey:PREFS_MAX_WALK_DISTANCE];
    [prefs synchronize];
}


@end
