//
//  UserPreferance.h
//  Nimbler
//
//  Created by JaY Kumbhani on 7/2/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
// Singleton object that stores and accesses the user preferences in NSUserDefaults

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UserPreferance : NSObject

@property (nonatomic, retain) NSNumber * pushEnable;
@property (nonatomic, retain) NSNumber * triggerAtHour;
@property (nonatomic, retain) NSNumber * walkDistance;

+(UserPreferance *)userPreferance;  // Return the singleton object.  Sets to default values if no value already saved
-(void)saveUpdates;   // Saves changes to permanent storage


@end
