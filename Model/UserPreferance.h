//
//  UserPreferance.h
//  Nimbler
//
//  Created by JaY Kumbhani on 7/2/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
// Singleton object that stores and accesses the user preferences in NSUserDefaults

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

NSString* tpBoolToStr(BOOL boolValue);  // Function to translate from settings bool values to strings used to send to server
BOOL tpStrToBool(NSObject* stringValue);  // Function to translate from settings NSString/NSNumber values from server to boolean

@interface UserPreferance : NSObject <RKRequestDelegate>

@property(nonatomic) BOOL pushEnable;
@property(nonatomic) int pushNotificationThreshold;
@property(nonatomic) double walkDistance;
@property(nonatomic) BOOL sfMuniAdvisories;
@property(nonatomic) BOOL bartAdvisories;
@property(nonatomic) BOOL acTransitAdvisories;
@property(nonatomic) BOOL caltrainAdvisories;
@property(nonatomic) BOOL urgentNotificationSound;
@property(nonatomic) BOOL standardNotificationSound;
@property(nonatomic) BOOL notificationMorning;
@property(nonatomic) BOOL notificationMidday;
@property(nonatomic) BOOL notificationEvening;
@property(nonatomic) BOOL notificationNight;
@property(nonatomic) BOOL notificationWeekend;
@property(nonatomic) int transitMode;
@property(nonatomic) double bikeDistance;
@property(nonatomic) double fastVsSafe;
@property(nonatomic) double fastVsFlat;
@property(nonatomic,readonly) double bikeTriangleFlat; // Derived from fastVsFlat
@property(nonatomic,readonly) double bikeTriangleQuick; // Derived from fastVsFlat an fastVsSafe
@property(nonatomic,readonly) double bikeTriangleBikeFriendly; // Derived from fastVsSafe

-(BOOL)isSaveToServerNeeded;  // Returns true if there are changes that still need to be save to server
+(UserPreferance *)userPreferance;  // Return the singleton object.  Sets to default values if no value already saved
-(void)saveUpdates;   // Saves changes to permanent storage on device
-(void)saveToServer;  // Save changes to server

@end
