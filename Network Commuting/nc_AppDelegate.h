//
//  nc_AppDelegate.h
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "ToFromViewController.h"
#import "Locations.h"
#import "PlanStore.h"
#import "SupportedRegion.h"
#import <Restkit/RKJSONParserJSONKit.h>
#import "RouteOptionsViewController.h"
#import "RouteDetailsViewController.h"
#import "LegMapViewController.h"

@interface nc_AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate,RKRequestDelegate,UIAlertViewDelegate,UITabBarControllerDelegate> {
    Location* currentLocation;
    UITabBarController *_tabBarController;
    
    NSNumber *FBSource; 
    NSString *FBDate;
    NSString *FBToAdd;
    NSString *FBSFromAdd;
    NSString *FBUniqueId;
    BOOL isTwitterView;
    BOOL isToFromView;
    Location *toLoc;
    Location *fromLoc;
    NSTimer *continueGetTime;
    BOOL isFromBackground;
    BOOL isUpdateTime;
    BOOL isServiceByWeekday;
    BOOL isCalendarByDate;
    BOOL isSettingSavedSuccessfully;
    BOOL isSettingRequest;
    NSDictionary* lastGTFSLoadDateByAgency;
    NSDictionary* serviceByWeekdayByAgency;
    NSDictionary* calendarByDateByAgency;
    BOOL isDatePickerOpen;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;

@property (readonly, strong, nonatomic) Locations *locations;
@property (readonly, strong, nonatomic) PlanStore *planStore;
@property (readonly, strong, nonatomic) ToFromViewController *toFromViewController;
@property (readonly, strong, nonatomic) CLLocationManager* locationManager;

// Properties for Core Data
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSTimer *timerTweeterGetData;
@property (strong, nonatomic) NSTimer *continueGetTime;
@property (strong, nonatomic)  NSUserDefaults *prefs;
@property (strong, nonatomic)  UITabBarController *tabBarController;

// property for Feedback
@property (strong, nonatomic) NSNumber *FBSource; 
@property (strong, nonatomic) NSString *FBDate;
@property (strong, nonatomic) NSString *FBToAdd;
@property (strong, nonatomic) NSString *FBSFromAdd;
@property (strong, nonatomic) NSString *FBUniqueId;
@property (strong, nonatomic) CustomBadge *twitterCount;
@property (nonatomic) BOOL isTwitterView;
@property (nonatomic) BOOL isToFromView;
@property (strong, nonatomic) Location *toLoc;
@property (strong, nonatomic) Location *fromLoc;
@property (nonatomic) BOOL isFromBackground;
@property (nonatomic) BOOL isUpdateTime;
@property (nonatomic) BOOL isServiceByWeekday;
@property (nonatomic) BOOL isCalendarByDate;
@property (nonatomic) BOOL     isSettingSavedSuccessfully;
@property (nonatomic) BOOL isSettingRequest;

@property(strong, nonatomic) NSDictionary* lastGTFSLoadDateByAgency;
@property(strong, nonatomic) NSDictionary* serviceByWeekdayByAgency;
@property(strong, nonatomic) NSDictionary* calendarByDateByAgency;
@property (nonatomic, strong) NSString *timerType;

@property (nonatomic) BOOL isDatePickerOpen;

- (NSURL *)applicationDocumentsDirectory;

-(void)suppertedRegion;
-(void)getTwiiterLiveData;
-(void)upadateDefaultUserValue;
+(nc_AppDelegate *)sharedInstance; 
+ (NSString *)getUUID;
-(void)updateBadge:(int)count;
-(void)isNetworkConnectionLive;
-(void)updateTime;
-(void)serviceByWeekday;
-(void)calendarByDate;
- (void)saveSetting;
@end