//
//  nc_AppDelegate.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "ToFromViewController.h"
#import "Locations.h"
#import "PlanStore.h"
#import "UberMgr.h"
#import "SupportedRegion.h"
#import <Restkit/RKJSONParserJSONKit.h>
#import "RouteOptionsViewController.h"
#import "RouteDetailsViewController.h"
#import "LegMapViewController.h"
#import "GtfsParser.h"
#import "Agencies.h"
#import "RevealController.h"

@interface nc_AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate,RKRequestDelegate,UIAlertViewDelegate,UITabBarControllerDelegate> {
    Location* currentLocation;
    UITabBarController *_tabBarController;
    BOOL receivedReply;
    BOOL receivedError;
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
    BOOL isSettingRequest;
    NSDictionary* lastGTFSLoadDateByAgency;
    NSDictionary* serviceByWeekdayByAgency;
    NSDictionary* calendarByDateByAgency;
    BOOL isDatePickerOpen;
    NSString *strTweetCountURL;
    BOOL isSettingView;
    UIAlertView *feedbackAlert1;  // First alertView for feedback (asking like vs dislike)
    UIAlertView *feedbackAlert2Likes; // Follow-up alertView if someone likes Nimbler
    UIAlertView *feedbackAlert2Dislikes; // Follow-up alertView if someone dislikes Nimbler
    Plan *testPlan;
    // Used For Automated test.
    NSString *expectedRequestDate;
    BOOL isTestPlan;
    NSMutableString *testLogMutableString;
    Stations *stations;
    NSString *updateDeviceTokenURL;
    RevealController *revealViewController;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (readonly, strong, nonatomic) Locations *locations;
@property (strong, nonatomic) PlanStore *planStore;
@property (strong, nonatomic) UberMgr *uberMgr;
@property (strong, nonatomic) ToFromViewController *toFromViewController;
@property (readonly, strong, nonatomic) CLLocationManager* locationManager;
@property (readonly, strong, nonatomic) CLLocation *locationFromlocManager;

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
@property (nonatomic) BOOL isFeedBackView;
@property (strong, nonatomic) Location *toLoc;
@property (strong, nonatomic) Location *fromLoc;
@property (nonatomic) BOOL isFromBackground;
@property (nonatomic) BOOL isUpdateTime;
@property (nonatomic) BOOL isCalendarByDate;
@property (nonatomic) BOOL isSettingRequest;

@property(strong, nonatomic) NSDictionary* lastGTFSLoadDateByAgency;
@property(strong, nonatomic) NSDictionary* serviceByWeekdayByAgency;
@property(strong, nonatomic) NSDictionary* calendarByDateByAgency;
@property (nonatomic, strong) NSString *timerType;

@property (nonatomic) BOOL isDatePickerOpen;
@property (nonatomic, strong) NSString *strTweetCountURL;
@property (nonatomic) BOOL isSettingView;
@property (nonatomic) BOOL isSettingDetailView;
@property (nonatomic) BOOL isRemoteNotification;
@property (nonatomic) BOOL isNeedToLoadRealData;
@property (nonatomic, strong) Plan *testPlan;
@property (nonatomic) BOOL isTestPlan;
@property (nonatomic,strong)  NSString *expectedRequestDate;
@property (nonatomic) BOOL receivedReply;
@property (nonatomic) BOOL receivedError;
@property (nonatomic,strong) NSMutableString *testLogMutableString;
@property (strong, nonatomic) GtfsParser *gtfsParser;
@property (strong, nonatomic) Stations *stations;
@property (strong, nonatomic) NSString *updateDeviceTokenURL;
@property (nonatomic) BOOL isRouteOptionView;
@property (nonatomic) BOOL isRouteDetailView;
@property (nonatomic, strong) RevealController *revealViewController;
@property (nonatomic) BOOL isNotificationsButtonClicked;

- (NSURL *)applicationDocumentsDirectory;

-(void)setUpTabViewController;   // sets up TabViewController & the child navigation controllers
-(void)suppertedRegion;
-(void)getTwiiterLiveData;
+(nc_AppDelegate *)sharedInstance;
+ (NSString *)getUUID;
-(void)updateBadge:(int)count;
-(BOOL)isNetworkConnectionLive;
-(void)updateTime;
- (NSString *)getAppTypeFromBundleId;
- (NSString *)getAgencyIdsString;
- (NSString *) deviceTokenString;
- (void) updateDeviceToken;

@end