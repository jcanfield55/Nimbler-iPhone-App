//
//  nc_AppDelegate.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "nc_AppDelegate.h"
#import "RevealController.h"
#import "UtilityFunctions.h"
#import "Logging.h"
#import "LocationFromGoogle.h"
#import "ToFromViewController.h"
#import "twitterViewController.h"
#import "SettingInfoViewController.h"
#import "FeedBackForm.h"
#import "UserPreferance.h"
#import "Reachability.h"
#import "KeyObjectStore.h"
#import "RealTimeManager.h"
#import "StationListElement.h"
#import "RouteExcludeSetting.h"
#if TEST_FLIGHT_ENABLED
#import "TestFlightSDK1-1/TestFlight.h"
#import "ZipArchive.h"
#import "UIDevice-Hardware.h"
#endif
#if FLURRY_ENABLED
#import "Flurry.h"
#endif

#define BTN_EXIT        @"Exit fromApp"
#define BTN_OK          @"Ok"
#define BTN_CANCEL      @"Continue"


@interface nc_AppDelegate() {
    // Internal variables
    BOOL isTwitterLivaData;
    BOOL isRegionSupport;
    BOOL currentLocationNeededForDirectionsSource;
    BOOL currentLocationNeededForDirectionsDestination;
    BOOL mkDirectionsRequestInProgress;
    
    RKClient* rkTpClient;  // RKClient for calling TP Server
}

@end

static nc_AppDelegate *appDelegate;

@implementation nc_AppDelegate

@synthesize twitterCount;
@synthesize locations;
@synthesize planStore;
@synthesize locationManager;
@synthesize toFromViewController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize window = _window;
@synthesize timerTweeterGetData;
@synthesize prefs;
@synthesize tabBarController = _tabBarController;
@synthesize isTwitterView;
@synthesize isToFromView;
@synthesize toLoc;
@synthesize fromLoc;
@synthesize continueGetTime;
@synthesize isFromBackground;
@synthesize isUpdateTime;
@synthesize isCalendarByDate;
@synthesize isSettingRequest;
@synthesize lastGTFSLoadDateByAgency;
@synthesize serviceByWeekdayByAgency;
@synthesize calendarByDateByAgency;
@synthesize timerType;
@synthesize isDatePickerOpen;
@synthesize strTweetCountURL;
@synthesize isSettingView;
@synthesize isSettingDetailView;
@synthesize isRemoteNotification;
@synthesize isNeedToLoadRealData;
@synthesize testPlan;
@synthesize expectedRequestDate;
@synthesize isTestPlan;
@synthesize receivedReply;
@synthesize receivedError;
@synthesize testLogMutableString;
@synthesize gtfsParser;
@synthesize stations;
@synthesize updateDeviceTokenURL;
@synthesize isFeedBackView;
@synthesize isRouteOptionView;
@synthesize isRouteDetailView;
@synthesize locationFromlocManager;
@synthesize revealViewController;
@synthesize isNotificationsButtonClicked;



// Feedback parameters
@synthesize FBDate,FBToAdd,FBSource,FBSFromAdd,FBUniqueId;
twitterViewController *twitterView;
SettingInfoViewController *settingView;
FeedBackForm *fbView;

+(nc_AppDelegate *)sharedInstance
{
    if(appDelegate == nil){
        appDelegate = (nc_AppDelegate *)[[UIApplication sharedApplication] delegate];
        
    }
    return appDelegate;
}
+(NSString *)getUUID
{
    CFUUIDRef UUID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef stringID = CFUUIDCreateString(kCFAllocatorDefault, UUID);
    CFRelease(UUID);
    return (__bridge_transfer NSString *)stringID;
}

- (void) unzipZipFileToApplicationDocumentDirectory{
#if GENERATING_SEED_DATABASE
    return ;
#endif
    
     NSString *dbPath = [NSString stringWithFormat:@"%@/%@",[[self applicationDocumentsDirectory] path],COREDATA_DB_FILENAME];
    // Remove the Caltrain 1.16 or previous version app database
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
        BOOL isOldDBDeleted = [[NSUserDefaults standardUserDefaults] objectForKey:@"oldDbDeleted"];
        if(!isOldDBDeleted && [[NSFileManager defaultManager] fileExistsAtPath:dbPath]){
            [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
            [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"oldDbDeleted"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    if(![[NSFileManager defaultManager] fileExistsAtPath:dbPath]){
        NSString *strPath;
        if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
            strPath = [[NSBundle mainBundle] pathForResource:@"store101_Caltrain" ofType:@"zip"];
        }
        else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
            strPath = [[NSBundle mainBundle] pathForResource:@"store101_DC" ofType:@"zip"];
        }
        else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:PORTLAND_BUNDLE_IDENTIFIER]){
            strPath = [[NSBundle mainBundle] pathForResource:@"store101_Portland" ofType:@"zip"];
        }
        else{
           strPath = [[NSBundle mainBundle] pathForResource:@"store101" ofType:@"zip"]; 
        }
        // Unzip file to document directory folder
        ZipArchive *zipArchive = [[ZipArchive alloc] init];
        [zipArchive UnzipOpenFile:strPath];
        [zipArchive UnzipFileTo:[[self applicationDocumentsDirectory] path] overWrite:YES];
        [zipArchive UnzipCloseFile];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"oldDbDeleted"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

// This methods will prevent document directory backups to icloud
-(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    const char* filePath = [[URL path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
    if (&NSURLIsExcludedFromBackupKey == nil) {
        // iOS 5.0.1 and lower
        u_int8_t attrValue = 1;
        int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        return result == 0;
        
    }
    else {
        // First try and remove the extended attribute if it is present
        int result = getxattr(filePath, attrName, NULL, sizeof(u_int8_t), 0, 0);
        if (result != -1) {
            // The attribute exists, we need to remove it
            int removeResult = removexattr(filePath, attrName, 0);
            if (removeResult == 0) {
            }
        }
        
        // Set the new key
        NSError *error = nil;
        [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
        return error == nil;
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if AUTOMATED_TESTING_SKIP_NCAPPDELEGATE
    return YES;    // If Automated testing with alternative persistent store, skip NC_AppDelegate altogether and do all setup in test area
#endif
    NIMLOG_EVENT1(@"nc_AppDelegate didFinishLaunchingWithOptions started");
    [self unzipZipFileToApplicationDocumentDirectory];
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    prefs = [NSUserDefaults standardUserDefaults];
    [UserPreferance userPreferance];  // Saves default user preferences to server if needed
    
    // Call suppertedRegion for getting boundry of bay area region
    [self suppertedRegion];
    
    if ([[UserPreferance userPreferance] pushEnable]) {
        [[UIApplication sharedApplication]
         registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeAlert |
          UIRemoteNotificationTypeBadge |
          UIRemoteNotificationTypeSound)];
    }
    else{
        [[UserPreferance userPreferance] performSelector:@selector(saveToServer) withObject:nil afterDelay:0.0];
    }
    NSDate *lastSaveDate = [[NSUserDefaults standardUserDefaults] objectForKey:CURRENT_DATE];
    NSDate *todayDate = dateOnlyFromDate([NSDate date]);
    if(!lastSaveDate || ![lastSaveDate isEqualToDate:todayDate]){
        NSDate *todayDate = dateOnlyFromDate([NSDate date]);
        [[NSUserDefaults standardUserDefaults] setObject:todayDate forKey:CURRENT_DATE];
        //[[nc_AppDelegate sharedInstance] updateTime];
        [[nc_AppDelegate sharedInstance] performSelector:@selector(updateTime) withObject:nil afterDelay:1.0];
    }
    
    NSDate *lastAgenciesSaveDate = [[NSUserDefaults standardUserDefaults] objectForKey:CURRENT_DATE_AGENCIES];
    if(!lastAgenciesSaveDate || ![lastAgenciesSaveDate isEqualToDate:todayDate]){
        NSDate *todayDate = dateOnlyFromDate([NSDate date]);
        [[NSUserDefaults standardUserDefaults] setObject:todayDate forKey:CURRENT_DATE];
        //[[Agencies agencies] updateAgenciesFromServer];
        [[Agencies agencies] performSelector:@selector(updateAgenciesFromServer) withObject:nil afterDelay:2.0];
    }
    
    // Get TransitCalendar updates
    //[self getTwiiterLiveData];
    [self performSelector:@selector(getTwiiterLiveData) withObject:nil afterDelay:4.0];
    if (timerTweeterGetData == nil) {
        timerTweeterGetData =   [NSTimer scheduledTimerWithTimeInterval:TWEET_COUNT_POLLING_INTERVAL target:self selector:@selector(getTwiiterLiveData) userInfo:nil repeats: YES];
    }
    
    // US-163 set-up for feedback reminders (also DE-238 fix)
    NSDate *date = [NSDate date];
    if (![prefs objectForKey:DATE_OF_FIRST_USE]) { // if this is the first time using the app
        [prefs setObject:date forKey:DATE_OF_FIRST_USE];
        [prefs setObject:date forKey:DATE_OF_USE];
        [prefs setInteger:1 forKey:DAYS_COUNT];
        [prefs setBool:YES forKey:FEEDBACK_REMINDER_PENDING];
        [prefs setInteger:DAYS_TO_SHOW_FEEDBACK_ALERT_NUMBER forKey:DAYS_TO_SHOW_FEEDBACK_ALERT];
        [prefs synchronize];
    }
    
    // Configure the RestKit RKClient object for Geocoding and trip planning
    RKLogConfigureByName("RestKit", CUSTOM_RK_LOG_LEVELS);
    RKLogConfigureByName("RestKit/Network/Cache", CUSTOM_RK_LOG_LEVELS);
    RKLogConfigureByName("RestKit/Network/Reachability", CUSTOM_RK_LOG_LEVELS);
    
    // Set default time zone
    id localTimeZone = [NSTimeZone timeZoneWithName:DEFAULT_TIME_ZONE];
    if (localTimeZone) {
        [NSTimeZone setDefaultTimeZone:localTimeZone];
    }
    
    RKObjectManager* rkGeoMgr = [RKObjectManager objectManagerWithBaseURL:GEO_RESPONSE_URL];
    // Trimet base URL is http://rtp.trimet.org/opentripplanner-api-webapp/ws/
    
    RKObjectManager *rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:TRIP_PROCESS_URL];
    rkTpClient = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    
    // Fixed:- DE-306
    //http://stackoverflow.com/questions/9463259/restkit-disable-caching
    rkTpClient.cachePolicy = RKRequestCachePolicyNone;
    
    // Other URLs:
    // Trimet base URL is http://rtp.trimet.org/opentripplanner-api-webapp/ws/
    // NY City demo URL is http://demo.opentripplanner.org/opentripplanner-api-webapp/ws/
    
    // Add the CoreData managed object store
    
    RKManagedObjectStore *rkMOS;
    @try {
        rkMOS = [RKManagedObjectStore objectStoreWithStoreFilename:COREDATA_DB_FILENAME];
        [rkGeoMgr setObjectStore:rkMOS];
        [rkPlanMgr setObjectStore:rkMOS];
        
        // Get the NSManagedObjectContext from restkit
        __managedObjectContext = [rkMOS managedObjectContext];
        
        // Create initial view controller
        toFromViewController = [[ToFromViewController alloc] initWithNibName:@"ToFromViewController" bundle:nil];
        [toFromViewController setRkGeoMgr:rkGeoMgr];    // Pass the geocoding RK object
        [toFromViewController setRkPlanMgr:rkPlanMgr];    // Pass the planning RK object
        
        
        // Turn on location manager
        locationManager = [[CLLocationManager alloc] init];
        [locationManager setDelegate:self];
        [locationManager startUpdatingLocation];
        
        // Initialize the Locations class and store "Current Location" into the database if not there already
        locations = [[Locations alloc] initWithManagedObjectContext:[self managedObjectContext] rkGeoMgr:rkGeoMgr];
        [toFromViewController setLocations:locations];
        
        // Initialize the planStore, KeyObjectStore, Stations, ToFromViewController, RouteExcludeSettings, and toFromViewController
        planStore = [[PlanStore alloc] initWithManagedObjectContext:[self managedObjectContext]
                                                          rkPlanMgr:rkPlanMgr rkTpClient:rkTpClient];
        stations =  [[Stations alloc] initWithManagedObjectContext:[self managedObjectContext]
                                                         rkPlanMgr:rkPlanMgr];
        [KeyObjectStore setUpWithManagedObjectContext:[self managedObjectContext]];
        [RouteExcludeSettings setManagedObjectContext:[self managedObjectContext]];
        [toFromViewController setPlanStore:planStore];
        
        // Initialize The GtfsParser and TransitCalendar
        gtfsParser = [[GtfsParser alloc] initWithManagedObjectContext:self.managedObjectContext
                                                           rkTpClient:rkTpClient];
        [[TransitCalendar transitCalendar] setRkTpClient:rkTpClient];
        [[Agencies agencies] setRkTpClient:rkTpClient];
        
        // Initialize the RealTimeManager
        [[RealTimeManager realTimeManager] setRkTpClient:rkTpClient];
        
#if GENERATING_SEED_DATABASE
        // Pre-load stations location files
        if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
            NSDecimalNumber* caltrainVersion = [NSDecimalNumber decimalNumberWithString:CALTRAIN_PRELOAD_VERSION_NUMBER];
            NSDecimalNumber* bartVersion = [NSDecimalNumber decimalNumberWithString:BART_PRELOAD_VERSION_NUMBER];
            [locations preLoadIfNeededFromFile:CALTRAIN_PRELOAD_LOCATION_FILE_CALTRAIN_APPLICATION latestVersionNumber:caltrainVersion testAddress:CALTRAIN_PRELOAD_TEST_ADDRESS];
            [locations preLoadIfNeededFromFile:BART_BACKGROUND_PRELOAD_LOCATION_FILE latestVersionNumber:bartVersion testAddress:BART_PRELOAD_TEST_ADDRESS];
            NSArray *arrlocations = [locations locationsWithFormattedAddress:STATION_LIST];
            if(!arrlocations || [arrlocations count] == 0){
               Location *loc = [stations generateNewTempLocationForAllStationString:ALL_STATION];
            }
        }
        else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
            NSDecimalNumber* wMataVersion = [NSDecimalNumber decimalNumberWithString:WMATA_PRELOAD_VERSION_NUMBER];
            [locations preLoadIfNeededFromFile:WMATA_PRELOAD_LOCATION_FILE latestVersionNumber:wMataVersion testAddress:WMATA_PRELOAD_TEST_ADDRESS];
            NSArray *arrlocations = [locations locationsWithFormattedAddress:STATION_LIST];
            if(!arrlocations || [arrlocations count] == 0){
              Location *loc =  [stations generateNewTempLocationForAllStationString:ALL_STATION];
            }
        }
        else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:PORTLAND_BUNDLE_IDENTIFIER]){
            NSDecimalNumber* caltrainVersion = [NSDecimalNumber decimalNumberWithString:PORTLAND_PRELOAD_VERSION_NUMBER];
            [stations preLoadIfNeededFromFile:PORTLAND_PRELOAD_LOCATION_FILE latestVersionNumber:caltrainVersion testAddress:PORTLAND_PRELOAD_TEST_ADDRESS];
            NSArray *arrlocations = [locations locationsWithFormattedAddress:STATION_LIST];
            if(!arrlocations || [arrlocations count] == 0){
               Location *loc = [stations generateNewTempLocationForAllStationString:ALL_STATION];
            }
        }
        else {
            if([[NSUserDefaults standardUserDefaults] floatForKey:CALTRAIN_PRELOAD_LOCATION_FILE] < [CALTRAIN_PRELOAD_VERSION_NUMBER floatValue]){
                [stations removeStationListElementByAgency:CALTRAIN];
                NSDecimalNumber* caltrainVersion = [NSDecimalNumber decimalNumberWithString:CALTRAIN_PRELOAD_VERSION_NUMBER];
                [stations preLoadIfNeededFromFile:CALTRAIN_PRELOAD_LOCATION_FILE latestVersionNumber:caltrainVersion testAddress:CALTRAIN_PRELOAD_TEST_ADDRESS];
            }
            if([[NSUserDefaults standardUserDefaults] floatForKey:BART_PRELOAD_LOCATION_FILE] < [BART_PRELOAD_VERSION_NUMBER floatValue]){
                [stations removeStationListElementByAgency:BART];
                NSDecimalNumber* bartVersion = [NSDecimalNumber decimalNumberWithString:BART_PRELOAD_VERSION_NUMBER];
                [stations preLoadIfNeededFromFile:BART_PRELOAD_LOCATION_FILE latestVersionNumber:bartVersion testAddress:BART_PRELOAD_TEST_ADDRESS];
            }
            if([[NSUserDefaults standardUserDefaults] floatForKey:SFMUNI_PRELOAD_LOCATION_FILE] < [SFMUNI_PRELOAD_VERSION_NUMBER floatValue]){
                [stations removeStationListElementByAgency:SF_MUNI];
                NSDecimalNumber* sfMuniVersion = [NSDecimalNumber decimalNumberWithString:SFMUNI_PRELOAD_VERSION_NUMBER];
                [stations preLoadIfNeededFromFile:SFMUNI_PRELOAD_LOCATION_FILE latestVersionNumber:sfMuniVersion testAddress:SFMUNI_PRELOAD_TEST_ADDRESS];
            }
            NSArray *arrlocations1 = [locations locationsWithFormattedAddress:@"SF-Muni Station List"];
            if(!arrlocations1 || [arrlocations1 count] == 0){
                Location *loc = [stations generateNewTempLocationForAllStationString:@"muni_st_list"];
                loc.toFrequency = [NSNumber numberWithFloat:26.0];
                loc.fromFrequency = [NSNumber numberWithFloat:26.0];
            }
            
            NSArray *arrlocations2 = [locations locationsWithFormattedAddress:@"Caltrain Station List"];
            if(!arrlocations2 || [arrlocations2 count] == 0){
               Location *loc = [stations generateNewTempLocationForAllStationString:@"caltrain_st_list"];
                loc.toFrequency = [NSNumber numberWithFloat:28.0];
                loc.fromFrequency = [NSNumber numberWithFloat:28.0];
            }
            
            NSArray *arrlocations3 = [locations locationsWithFormattedAddress:@"Bart Station List"];
            if(!arrlocations3 || [arrlocations3 count] == 0){
               Location *loc = [stations generateNewTempLocationForAllStationString:@"bart_st_list"];
                loc.toFrequency = [NSNumber numberWithFloat:27.0];
                loc.fromFrequency = [NSNumber numberWithFloat:27.0];
            }
        }
        saveContext(self.managedObjectContext);
#endif
        [toFromViewController setStations:stations];
    }@catch (NSException *exception) {
        logException(@"ncAppDelegate->didFinishLaunchingWithOptions #1", @"", exception);
    }
    
    // Set a CFUUID (unique identifier) for this device and this app, if doesn't exist already:
    
    NSString* cfuuidString = [prefs objectForKey:DEVICE_CFUUID];
    if (cfuuidString == nil) {  // if the CFUUID not created, create it
        cfuuidString = [nc_AppDelegate getUUID];
        [prefs setValue:cfuuidString forKey:DEVICE_CFUUID];
        [prefs synchronize];
        NIMLOG_EVENT1(@"DEVICE_CFUUID  - - - - - - - %@", cfuuidString);
    }
    
    // Call TestFlightApp SDK
#if TEST_FLIGHT_ENABLED
#ifdef TEST_FLIGHT_UIDS
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
    [TestFlight takeOff:@"cce4b61c-e0ee-49da-9770-91f3204078d4"];
#endif
    // Call to Flurry SDK
#if FLURRY_ENABLED
    [Flurry startSession:FLURRY_API_KEY];
    [Flurry setUserID:cfuuidString];
    [Flurry logEvent:FLURRY_APPDELEGATE_START];
#endif
    
    //Log App in facebook so we can track referrals from Facebook advertisements
    NIMLOG_PERF2(@"Facebook SDK with ID: %@", FB_APP_ID);
    [FBSettings publishInstall:FB_APP_ID];
    NIMLOG_PERF2(@"Finished calling FB SDK");
    
    [self addSkipBackupAttributeToItemAtURL:[self applicationDocumentsDirectory]];
    
    // Create an instance of a UINavigationController and put toFromViewController as the first view
    @try {
        
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        twitterView = [[twitterViewController alloc] initWithNibName:@"twitterViewController" bundle:nil];
        SettingInfoViewController *settingsView;
        FeedBackForm *feedbackView;
        if([UIScreen mainScreen].bounds.size.height == IPHONE5HEIGHT){
            settingsView = [[SettingInfoViewController alloc] initWithNibName:@"SettingViewController_SF_568h" bundle:nil];
            feedbackView = [[FeedBackForm alloc] initWithNibName:@"FeedBackForm_568h" bundle:nil];
        }
        else{
            settingsView = [[SettingInfoViewController alloc] initWithNibName:@"SettingViewController_SF" bundle:nil];
            feedbackView = [[FeedBackForm alloc] initWithNibName:@"FeedBackForm" bundle:nil];
        }
        
        self.tabBarController = [[RXCustomTabBar alloc] init];
        
        UINavigationController *navController1 = [[UINavigationController alloc] initWithRootViewController:toFromViewController];
        
        UINavigationController *tweetController = [[UINavigationController alloc] initWithRootViewController:twitterView];
        UINavigationController *settingController = [[UINavigationController alloc] initWithRootViewController:settingsView];
        UINavigationController *fbController = [[UINavigationController alloc] initWithRootViewController:feedbackView];
        self.tabBarController.viewControllers = [NSArray arrayWithObjects:tweetController,settingController,fbController, nil];
        
        revealViewController = [[RevealController alloc] initWithFrontViewController:navController1 rearViewController:self.tabBarController];
         self.window.rootViewController = revealViewController;
        [self.window makeKeyAndVisible];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->didFinishLaunchingWithOptions #2", @"", exception);
    }
    return YES;
}

- (void)setUpTabViewController
{
    /*
     These is for navigation controller
     
     UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:toFromViewController];
     self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
     [[self window] setRootViewController:navController];
     
     */
    
    // This is for TabBar controller
    //[self.window makeKeyAndVisible];
    self.tabBarController = [[RXCustomTabBar alloc] init];
    if([[UIScreen mainScreen] bounds].size.height == 568){
        //            if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
        //                settingView = [[SettingInfoViewController alloc] initWithNibName:@"SettingInfoViewController_568h" bundle:nil];
        //            }
        //            else{
        settingView = [[SettingInfoViewController alloc] initWithNibName:@"SettingViewController_SF_568h" bundle:nil];
        //}
        fbView = [[FeedBackForm alloc] initWithNibName:@"FeedBackForm_568h" bundle:nil];
    }
    else{
        //            if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
        //                settingView = [[SettingInfoViewController alloc] initWithNibName:@"SettingInfoViewController" bundle:nil];
        //            }
        //            else{
        settingView = [[SettingInfoViewController alloc] initWithNibName:@"SettingViewController_SF" bundle:nil];
        //}
        fbView = [[FeedBackForm alloc] initWithNibName:@"FeedBackForm" bundle:nil];
    }
    twitterView = [[twitterViewController alloc] initWithNibName:@"twitterViewController" bundle:nil];
    
    UINavigationController *toFromController = [[UINavigationController alloc] initWithRootViewController:toFromViewController];
    UINavigationController *tweetController = [[UINavigationController alloc] initWithRootViewController:twitterView];
    UINavigationController *settingController = [[UINavigationController alloc] initWithRootViewController:settingView];
    UINavigationController *fbController = [[UINavigationController alloc] initWithRootViewController:fbView];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:toFromController,tweetController,settingController,fbController, nil];
    
}


- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    //    if (viewController == toFromViewController) {
    //
    //    } else if(viewController == twitterView){
    //
    //    } else if(viewController == fbView){
    //
    //    } else if(viewController == settingView){
    //
    //    }
}

// Location Manager update callback
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    @try {
        if (!currentLocation) {
            NSArray* matchingLocations = [locations locationsWithFormattedAddress:CURRENT_LOCATION];
            if ([matchingLocations count] == 0) { // if current location not in db
                matchingLocations = [locations locationsWithLocationName:CURRENT_LOCATION];
                if([matchingLocations count]==0){
                    currentLocation = [locations newEmptyLocation];
                    [currentLocation setFormattedAddress:CURRENT_LOCATION];
                    [currentLocation setFromFrequencyFloat:CURRENT_LOCATION_STARTING_FROM_FREQUENCY];
                    [currentLocation setToFrequencyFloat:CURRENT_LOCATION_STARTING_FROM_FREQUENCY];
                    [toFromViewController reloadTables]; // DE30 fix (1 of 2)
                    [locations setIsLocationServiceEnable:TRUE];
                }
                else {
                    currentLocation = [matchingLocations objectAtIndex:0];
                    [locations setIsLocationServiceEnable:TRUE];
                }
                
            }
            else {
                currentLocation = [matchingLocations objectAtIndex:0];
                [locations setIsLocationServiceEnable:TRUE];
            }
            
            locationFromlocManager = newLocation;
            
            // Set the coordinates (DE215, DE217 fix)
            [currentLocation setLatFloat:[newLocation coordinate].latitude];
            [currentLocation setLngFloat:[newLocation coordinate].longitude];
            
            [toFromViewController setCurrentLocation:currentLocation];
            if (![toFromViewController fromLocation]) {  // only if fromLocation is not set, set to currentLocation mode (DE197 fix)
                [toFromViewController setIsCurrentLocationMode:TRUE];
            }
            
            if (currentLocationNeededForDirectionsDestination || currentLocationNeededForDirectionsSource) {
                // If we have are waiting for currentLocation to execute a directions request
                // Set the appropriate currentLocations
                if (currentLocationNeededForDirectionsSource) {
                    [[toFromViewController fromTableVC] newDirectionsRequestLocation:currentLocation];
                    currentLocationNeededForDirectionsSource = NO;
                }
                if (currentLocationNeededForDirectionsDestination) {
                    [[toFromViewController toTableVC] newDirectionsRequestLocation:currentLocation];
                    currentLocationNeededForDirectionsDestination = NO;
                }
                // Execute the request
                [toFromViewController getRouteForMKDirectionsRequest];
            }
            
            logEvent(FLURRY_CURRENT_LOCATION_AVAILABLE, nil, nil, nil, nil, nil, nil, nil, nil);
        }
        else {
            [locations setIsLocationServiceEnable:TRUE];
            [currentLocation setLatFloat:[newLocation coordinate].latitude];
            [currentLocation setLngFloat:[newLocation coordinate].longitude];
        }
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->locationManager: didUpdateToLocation", @"", exception);
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([[error domain] isEqualToString: kCLErrorDomain] && [error code] == kCLErrorDenied) {
        // The user denied your app access to location information.
        [locations setIsLocationServiceEnable:FALSE];
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
    if(actionsheet){
        [actionsheet dismissWithClickedButtonIndex:-1 animated:NO];
    }
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    // saveContext(gtfsParser.backgroundMOC);  John: cannot use MOC across threads
    saveContext([self managedObjectContext]);
    [locationManager stopUpdatingLocation];
    
    //Reload ToFromViewController
    if(self.isToFromView){
        self.toLoc = locations.tempSelectedToLocation;
        self.fromLoc = locations.tempSelectedFromLocation;
        locations.isLocationSelected = true;
        [toFromViewController setEditMode:NO_EDIT];
        toFromViewController.toTableVC.txtField.text = NULL_STRING;
        toFromViewController.fromTableVC.txtField.text = NULL_STRING;
        /* Not need in Latest UI
        [toFromViewController.toTableVC toFromTyping:toFromViewController.toTableVC.txtField forEvent:nil];
        [toFromViewController.toTableVC textSubmitted:toFromViewController.toTableVC.txtField forEvent:nil];
        [toFromViewController.fromTableVC toFromTyping:toFromViewController.fromTableVC.txtField forEvent:nil];
        [toFromViewController.fromTableVC textSubmitted:toFromViewController.fromTableVC.txtField forEvent:nil];
         */
    }
    // US 177 Implementation
    RXCustomTabBar *rxCustomTabBar = (RXCustomTabBar *)self.tabBarController;
    [[NSUserDefaults standardUserDefaults] setInteger:rxCustomTabBar.selectedIndex forKey:LAST_SELECTED_TAB_INDEX];
    // Fixed DE-231
    if(self.toLoc.formattedAddress){
        [[NSUserDefaults standardUserDefaults]setObject:self.toLoc.formattedAddress forKey:LAST_TO_LOCATION];
    }
    if(self.fromLoc.formattedAddress){
        [[NSUserDefaults standardUserDefaults]setObject:self.fromLoc.formattedAddress forKey:LAST_FROM_LOCATION];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Close Keyboard
    [UIView setAnimationsEnabled:YES];
    [self.tabBarController.view endEditing:YES];
    
    
    // Flush tweeter timer
    [timerTweeterGetData invalidate];
    timerTweeterGetData = nil;
    
    if(toFromViewController.continueGetTime != nil){
        timerType =TIMER_TYPE;
    }
    [toFromViewController.continueGetTime invalidate];
    toFromViewController.continueGetTime = nil;
    [toFromViewController.routeOptionsVC.timerGettingRealDataByItinerary invalidate];
    toFromViewController.routeOptionsVC.timerGettingRealDataByItinerary = nil;
    isFromBackground = YES;
    
    [toFromViewController.routeOptionsVC.routeDetailsVC.timer invalidate];
    toFromViewController.routeOptionsVC.routeDetailsVC.timer = nil;
    
    [toFromViewController.routeOptionsVC.timerRealtime invalidate];
    toFromViewController.routeOptionsVC.timerRealtime = nil;
}

// DE-238 Fixed
- (void)showFeedBackAlertIfNeeded{
    //US-163 Implementation
    NSDate *appLastUseDate = [[NSUserDefaults standardUserDefaults] objectForKey:DATE_OF_USE];
    int ndaysCount = [[NSUserDefaults standardUserDefaults] integerForKey:DAYS_COUNT];
    int daysToShowAlert = [[NSUserDefaults standardUserDefaults]integerForKey:DAYS_TO_SHOW_FEEDBACK_ALERT];
    appLastUseDate = dateOnlyFromDate(appLastUseDate);
    NSDate *todayDate = dateOnlyFromDate([NSDate date]);
    if(![appLastUseDate isEqualToDate:todayDate]){
        [[NSUserDefaults standardUserDefaults] setObject:todayDate forKey:DATE_OF_USE];
        [[NSUserDefaults standardUserDefaults] setInteger:ndaysCount + 1  forKey:DAYS_COUNT];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:FEEDBACK_REMINDER_PENDING]){
        if(ndaysCount >= daysToShowAlert){
            actionsheet = [[UIActionSheet alloc] initWithTitle:FEED_BACK_SHEET_TITLE delegate:self cancelButtonTitle:NO_THANKS_BUTTON_TITLE destructiveButtonTitle:nil otherButtonTitles:APPSTORE_FEEDBACK_BUTTON_TITLE,NIMBLER_FEEDBACK_BUTTON_TITLE,REMIND_ME_LATER_BUTTON_TITLE, nil];
            actionsheet.cancelButtonIndex = actionsheet.numberOfButtons - 1;
            [actionsheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    
    // Check the date and if it is not today's date we will make request.
    // Previously comparing string with date so changed the logic to compare date.
    
    // Part Of DE-286 Fixed.
    NSString *deviceToken = [[nc_AppDelegate sharedInstance] deviceTokenString];
    NSString *dummyToken = [[NSUserDefaults standardUserDefaults] objectForKey:DUMMY_TOKEN_ID];
    BOOL isTokenUpdated = [[NSUserDefaults standardUserDefaults] boolForKey:DEVICE_TOKEN_UPDATED];
    if(!isTokenUpdated && dummyToken && ![deviceToken isEqualToString:dummyToken]){
        [self updateDeviceToken];
    }
    
    
    NSDate *todayDate = dateOnlyFromDate([NSDate date]);
    NSDate *currentDate = [[NSUserDefaults standardUserDefaults] objectForKey:CURRENT_DATE];
    NSDate *currentDateAgencies = [[NSUserDefaults standardUserDefaults] objectForKey:CURRENT_DATE_AGENCIES];
    if(!currentDate){
        [[nc_AppDelegate sharedInstance] performSelector:@selector(updateTime) withObject:nil afterDelay:0.5];
    }
    else{
        NSDate *currentDateOnly = dateOnlyFromDate(currentDate);
        if(![todayDate isEqualToDate:currentDateOnly]){
            [[nc_AppDelegate sharedInstance] performSelector:@selector(updateTime) withObject:nil afterDelay:0.5];
        }
    }
    
    if(!currentDateAgencies){
        [[Agencies agencies] performSelector:@selector(updateAgenciesFromServer) withObject:nil afterDelay:0.5];
    }
    else{
        NSDate *currentDateOnly = dateOnlyFromDate(currentDateAgencies);
        if(![todayDate isEqualToDate:currentDateOnly]){
            [[Agencies agencies] performSelector:@selector(updateAgenciesFromServer) withObject:nil afterDelay:0.5];
        }
    }
    if(actionsheet){
        [actionsheet dismissWithClickedButtonIndex:-1 animated:NO];
    }
    if(self.isTwitterView){
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        [twitterView getAdvisoryData];
    }
    else{
        [self getTwiiterLiveData];
    }
    [toFromViewController updateTripDate];
    [locationManager startUpdatingLocation];
    
    if (timerTweeterGetData == nil) {
        timerTweeterGetData =   [NSTimer scheduledTimerWithTimeInterval:TWEET_COUNT_POLLING_INTERVAL target:self selector:@selector(getTwiiterLiveData) userInfo:nil repeats: YES];
    }
    if(self.isToFromView){
        [toFromViewController.toTableVC markAndUpdateSelectedLocation:self.toLoc];
        [toFromViewController.fromTableVC markAndUpdateSelectedLocation:self.fromLoc];
    }
    if(isFromBackground && !self.isToFromView && !self.isTwitterView && !self.isSettingView && !self.isFeedBackView && !self.isSettingDetailView){
        // Fixed DE-329
        toFromViewController.routeOptionsVC.timerGettingRealDataByItinerary =   [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:toFromViewController.routeOptionsVC selector:@selector(decrementCounter) userInfo:nil repeats: YES];
        
    }
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    if([userPrefs isSaveToServerNeeded]){
        [userPrefs saveToServer];  // Save settings to server if they have not been already
    }
    
    toFromViewController.routeOptionsVC.routeDetailsVC.count = 119;
    toFromViewController.routeOptionsVC.remainingCount = 119;
    toFromViewController.routeOptionsVC.timerRealtime = [NSTimer scheduledTimerWithTimeInterval:0 target:toFromViewController.routeOptionsVC selector:@selector(requestServerForRealTime) userInfo:nil repeats: NO];
    
//    toFromViewController.routeOptionsVC.routeDetailsVC.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:toFromViewController.routeOptionsVC.routeDetailsVC selector:@selector(progressViewProgress) userInfo:nil repeats:YES];
    
    //    sleep(2);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{

    //US-163 Implementation
    [self showFeedBackAlertIfNeeded];
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    //    [self showFeedBackAlertIfNeeded];
    if(![self isNetworkConnectionLive]){
        logEvent(FLURRY_ALERT_NO_NETWORK, FLURRY_ALERT_LOCATION, @"applicationDidBecomeActive", nil, nil, nil, nil, nil, nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_TITLE message:NO_NETWORK_ALERT delegate:self cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil];
        [alert show];
    }
    
    if (mkDirectionsRequestInProgress) {
        mkDirectionsRequestInProgress = FALSE; // mark this false for next time, but do not set to remembered settings this time
    }
    else {  // only restore remembered settings if not a mkDirectionsRequestInProgress (DE235 fix)
        // US 177 Implementation
        if(isRemoteNotification){
            RXCustomTabBar *rxCustomTabBar = (RXCustomTabBar *)self.tabBarController;
            if (rxCustomTabBar.selectedIndex != 1) {
                [rxCustomTabBar selectTab:1];
            }
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:LAST_SELECTED_TAB_INDEX];
            [[NSUserDefaults standardUserDefaults] synchronize];
            isRemoteNotification = NO;
        }
        else{
            RXCustomTabBar *rxCustomTabBar = (RXCustomTabBar *)self.tabBarController;
            int lastSelectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:LAST_SELECTED_TAB_INDEX];
            if (rxCustomTabBar.selectedIndex != lastSelectedIndex) {
                [rxCustomTabBar selectTab:lastSelectedIndex];
            }
        }
        NSString *strToFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_TO_LOCATION];
        NSString *strFromFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_FROM_LOCATION];
        if (strToFormattedAddress) {
            NSArray* toLocations = [locations locationsWithFormattedAddress:strToFormattedAddress];
            if (toLocations && [toLocations count]>0) {
                if([toLocations count]>1){
                    Location *toLocation = [self findHighestFrequencyToLocation:toLocations];
                    if ([toLocation isCurrentLocation] && !toFromViewController.currentLocation) {
                        // If toLocation == currentLocation, but currentLocation not yet set,
                        // keep toLocation == nil and set it when currentLocaiton service available (updated DE-233 Attempted Fix)
                    } else {
                        [toFromViewController.toTableVC markAndUpdateSelectedLocation:toLocation];
                    }
                }
                else{
                    if ([[toLocations objectAtIndex:0] isCurrentLocation] && !toFromViewController.currentLocation) {
                        // If toLocation == currentLocation, but currentLocation not yet set,
                        // keep toLocation == nil and set it when currentLocaiton service available (updated DE-233 Attempted Fix)
                    } else {
                        [toFromViewController.toTableVC markAndUpdateSelectedLocation:[toLocations objectAtIndex:0]];
                    }
                }
                
            }
        }
        if (strFromFormattedAddress) {
            NSArray* fromLocations = [locations locationsWithFormattedAddress:strFromFormattedAddress];
            if (fromLocations && [fromLocations count]>0) {
                if([fromLocations count]>1){
                    Location *fromLocation = [self findHighestFrequencyFromLocation:fromLocations];
                    if ([fromLocation isCurrentLocation] && !toFromViewController.currentLocation) {
                        // If toLocation == currentLocation, but currentLocation not yet set,
                        // keep toLocation == nil and set it when currentLocaiton service available (updated DE-233 Attempted Fix)
                    } else {
                        [toFromViewController.fromTableVC markAndUpdateSelectedLocation:fromLocation];
                    }
                }
                else{
                    if ([[fromLocations objectAtIndex:0] isCurrentLocation] && !toFromViewController.currentLocation) {
                        // If fromLocation == currentLocation, but currentLocation not yet set,
                        // keep toLocation == nil and set it when currentLocaiton service available (updated DE-233 Attempted Fix)
                    } else {
                        [toFromViewController.fromTableVC markAndUpdateSelectedLocation:[fromLocations objectAtIndex:0]];
                    }
                }
            }
        }
    }
}

#pragma mark - Check and return High Frequency Location

-(Location *)findHighestFrequencyToLocation:(NSArray *)toLocation
{
    Location *highFrToLocation;
    double tofrequency = 0;
    double highfrequency = 0;
    int toLocationNumber = 0;
    for(int i=0;i<[toLocation count];i++){
        highFrToLocation = [toLocation objectAtIndex:i];
        tofrequency = [highFrToLocation.toFrequency doubleValue];
        if (tofrequency > highfrequency) {
            highfrequency = tofrequency;
            toLocationNumber = i;
        }
    }
    highFrToLocation = [toLocation objectAtIndex:toLocationNumber];
    
  return highFrToLocation;
}

-(Location *)findHighestFrequencyFromLocation:(NSArray *)fromLocation
{
    Location *highFrFromLocation;
    double fromfrequency = 0;
    double highfrequency = 0;
    int fromLocationNumber = 0;
    for(int i=0;i<[fromLocation count];i++){
        highFrFromLocation = [fromLocation objectAtIndex:i];
        fromfrequency = [highFrFromLocation.fromFrequency doubleValue];
        if (fromfrequency > highfrequency) {
            highfrequency = fromfrequency;
            fromLocationNumber = i;
        }
    }
    highFrFromLocation = [fromLocation objectAtIndex:fromLocationNumber];
    
  return highFrFromLocation;
}
- (void)applicationWillTerminate:(UIApplication *)application
{
    NIMLOG_PERF1(@"Will Terminate Called");
    // Saves changes in the application's managed object context before the application terminates.
    // saveContext(gtfsParser.backgroundMOC); // John: cannot use managedObjectContexts across threads
    saveContext([self managedObjectContext]);
}


#pragma mark - Directions request URL handler from iOS6

//
// Directions request URL handler from iOS6
// US156 implementation
//
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    MKDirectionsRequest* directionsInfo;
    @try {
        if ([MKDirectionsRequest isDirectionsRequestURL:url]) {
            directionsInfo = [[MKDirectionsRequest alloc] initWithContentsOfURL:url];
            
            // Go to TripPlanner tab if we are not there already
            RXCustomTabBar *rxCustomTabBar = (RXCustomTabBar *)self.tabBarController;
            if (rxCustomTabBar.selectedIndex != 0) {
                [rxCustomTabBar selectTab:0];
            }
            // If not at ToFromViewController on the Nav Controller, pop to home
            if ([[toFromViewController navigationController] visibleViewController] != toFromViewController) {
                [[toFromViewController navigationController] popToRootViewControllerAnimated:NO];
            }
            
            mkDirectionsRequestInProgress = YES;
            
            // Create & set the source location
            Location* sourceLoc;
            if ([[directionsInfo source] isCurrentLocation]) {
                sourceLoc = currentLocation;
                if (!currentLocation) {
                    currentLocationNeededForDirectionsSource = YES;
                }
            } else {
                MKPlacemark* sourcePlacemark = [[directionsInfo source] placemark];
                if (sourcePlacemark) {
                    sourceLoc = [locations newLocationFromIOSWithPlacemark:sourcePlacemark error:nil ];
                }
            }
            if (sourceLoc) {
                [[toFromViewController fromTableVC] newDirectionsRequestLocation:sourceLoc];
            }
            
            // Create & set the destination location
            Location* destinationLoc;
            if ([[directionsInfo destination] isCurrentLocation]) {
                destinationLoc = currentLocation;
                if (!currentLocation) {
                    currentLocationNeededForDirectionsDestination = YES;
                }
            } else {
                MKPlacemark* destinationPlacemark = [[directionsInfo destination] placemark];
                if (destinationPlacemark) {
                    destinationLoc = [locations newLocationFromIOSWithPlacemark:destinationPlacemark error:nil];
                }
            }
            if (destinationLoc) {
                [[toFromViewController toTableVC] newDirectionsRequestLocation:destinationLoc];
            }
            
            // Check if we need current location but it is not available... part of DE194 fix
            if (!currentLocation &&
                ([[directionsInfo source] isCurrentLocation] || [[directionsInfo destination] isCurrentLocation])) {
                CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
                
                if (status == kCLAuthorizationStatusDenied) {
                    NSString* msg;
                    if([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
                        msg = ALERT_LOCATION_SERVICES_DISABLED_MSG;
                    } else {
                        msg = ALERT_LOCATION_SERVICES_DISABLED_MSG_V6;
                    }
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ALERT_LOCATION_SERVICES_DISABLED_TITLE message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    return YES;
                }
                else if (status == kCLAuthorizationStatusRestricted) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ALERT_LOCATION_SERVICES_DISABLED_TITLE message:ALERT_LOCATION_SERVICES_RESTRICTED_MSG delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    return YES;
                }
                // else if not available yet, but authorized or not yet determined, then wait
                // and the route will be requested once Current Location is available
            }
            
            // If we have everything we need, request the route
            if (sourceLoc && destinationLoc) {
                [toFromViewController getRouteForMKDirectionsRequest];
            }
            return YES;
        }
        return NO;
        
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->application: openURL", @"MKDirectionRequest handler", exception);
    }
}



#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    @try {
        if (__managedObjectContext != nil)
        {
            return __managedObjectContext;
        }
        
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil)
        {
            __managedObjectContext = [[NSManagedObjectContext alloc] init];
            [__managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
        return __managedObjectContext;
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->managedObjectContext", @"", exception);    }
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    @try {
        if (__managedObjectModel != nil)
        {
            return __managedObjectModel;
        }
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Network_Commuting" withExtension:@"momd"];
        __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        return __managedObjectModel;
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->managedObjectModel", @"", exception);    }
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    @try {
        if (__persistentStoreCoordinator != nil)
        {
            return __persistentStoreCoordinator;
        }
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Network_Commuting.sqlite"];
        
        NSError *error = nil;
        __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSMutableDictionary *pragmaOptions = [NSMutableDictionary dictionary];
        [pragmaOptions setObject:@"OFF" forKey:@"synchronous"];
        [pragmaOptions setObject:@"MEMORY" forKey:@"journal_mode"];
        NSDictionary *storeOptions =
        [NSDictionary dictionaryWithObject:pragmaOptions forKey:NSSQLitePragmasOption];
        if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:storeOptions error:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             
             Typical reasons for an error here include:
             * The persistent store is not accessible;
             * The schema for the persistent store is incompatible with current managed object model.
             Check the error message to determine what the actual problem was.
             
             
             If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
             
             If you encounter schema incompatibility errors during development, you can reduce their frequency by:
             * Simply deleting the existing store:
             [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
             
             * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
             [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
             
             Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
             
             */
            logError(@"nc_AppDelegate->persistentStoreCoordinator", [NSString stringWithFormat:@"Error %@", error]);
            abort();
        }
        
        return __persistentStoreCoordinator;
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->persistentStoreCoordinator", @"", exception);
    }
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

-(void)suppertedRegion
{
    @try {
        isRegionSupport = TRUE;
        // DE - 181 Fixed
        RKClient *client = [RKClient clientWithBaseURL:TRIP_GENERATE_URL];
        client.cachePolicy = RKRequestCachePolicyNone;
        [RKClient setSharedClient:client];
        [[RKClient sharedClient]  get:METADATA_URL delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->suppertedRegion", @"", exception);
    }
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
    NSString *strRequestURL = request.resourcePath;
    isFromBackground = NO;
    @try {
        if ([request isGET]) {
            NSError *error = nil;
            if (error == nil)
            {
                RKJSONParserJSONKit* rkParser = [RKJSONParserJSONKit new];
                NSDictionary *tempResponseDictionary = [rkParser objectFromString:[response bodyAsString] error:nil];
                if([tempResponseDictionary objectForKey:APPLICATION_TYPE] != nil){
                    [[NSUserDefaults standardUserDefaults] setObject:[tempResponseDictionary objectForKey:APPLICATION_TYPE] forKey:APPLICATION_TYPE];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    // Call suppertedRegion for getting boundry of bay area region
                }
                //Added To Solve DE-162,174,182
                else if ([strRequestURL isEqualToString:strTweetCountURL]) {
                    isTwitterLivaData = false;
                    NIMLOG_EVENT1(@"Twitter response received");
                    NSDictionary  *tweeterCountParser = [rkParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [(NSDictionary*)tweeterCountParser objectForKey:@"errCode"];
                    //                NSString *allNew = [(NSDictionary*)tweeterCountParser objectForKey:@"allNew"];
                    if ([respCode intValue]== RESPONSE_SUCCESSFULL) {
                        if(!self.isTwitterView){
                            NIMLOG_TWITTER1(@"Twitter count: %@",[(NSDictionary*)tweeterCountParser objectForKey:TWEET_COUNT]);
                            NSString *tweeterCount = [(NSDictionary*)tweeterCountParser objectForKey:TWEET_COUNT];
                            int badge = [tweeterCount  intValue];
                            [[nc_AppDelegate sharedInstance] updateBadge:badge];
                            if (badge > 0) {
                                [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:[NSString stringWithFormat:@"%d",badge]];
                            } else {
                                [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
                            }
                        }
                        else{
                            [twitterView getAdvisoryData];
                        }
                    }
                }
                // DE- 181 Fixed
                // Checking resourcePath instead of checking for BOOL variable isRegionSupport.
                else if([strRequestURL isEqualToString:METADATA_URL]){
                    NIMLOG_EVENT1(@"Loaded SupportedRegion response");
                    NSDictionary  *regionParser = [rkParser objectFromString:[response bodyAsString] error:nil];
                    NIMLOG_OBJECT1(@"regionParser =%@",regionParser);
                    SupportedRegion *region = [[SupportedRegion alloc] init];
                    isRegionSupport = false;
                    BOOL maxLatitutedLoaded = false;
                    for (id key in regionParser) {
                        if ([key isEqualToString:@"upperRightLatitude"]) {
                            [region setUpperRightLatitude:[regionParser objectForKey:key]];
                        } else if ([key isEqualToString:@"upperRightLongitude"]){
                            [region setUpperRightLongitude:[regionParser objectForKey:key]];
                        } else if ([key isEqualToString:@"minLongitude"]){
                            [region setMinLongitude:[regionParser objectForKey:key] ];
                        } else if ([key isEqualToString:@"minLatitude"]){
                            [region setMinLatitude:[regionParser objectForKey:key] ];
                        } else if ([key isEqualToString:@"maxLongitude"]){
                            [region setMaxLongitude:[regionParser objectForKey:key] ];
                        } else if ([key isEqualToString:@"maxLatitude"]){
                            [region setMaxLatitude:[regionParser objectForKey:key] ];
                            maxLatitutedLoaded = true;
                        } else if ([key isEqualToString:@"lowerLeftLongitude"]){
                            [region setLowerLeftLongitude:[regionParser objectForKey:key] ];
                        } else if ([key isEqualToString:@"lowerLeftLatitude"]){
                            [region setLowerLeftLatitude:[regionParser objectForKey:key] ];
                        }
                    }
                    if (maxLatitutedLoaded) { //
                        [toFromViewController setSupportedRegion:region];
                    }
                }
                else if([strRequestURL isEqualToString:updateDeviceTokenURL]){
                    NSDictionary *tempResponseDictionary = [rkParser objectFromString:[response bodyAsString] error:nil];
                    if([[tempResponseDictionary objectForKey:RESPONSE_CODE] intValue] != RESPONSE_RETRY){
                        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:DUMMY_TOKEN_ID];
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEVICE_TOKEN_UPDATED];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->didLoadResponse", @"catching TPServer Response", exception);
    }
}


#pragma mark Nimbler push notification

- (void)applicationDidFinishLaunching:(UIApplication *)application {
#if PREFS_DEFAULT_IS_PUSH_ENABLE
    [[UIApplication sharedApplication]
     registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert |
      UIRemoteNotificationTypeBadge |
      UIRemoteNotificationTypeSound)];
#endif
}

// Part Of DE-286 Fixed.
- (void) updateDeviceToken{
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    client.cachePolicy = RKRequestCachePolicyNone;
    [RKClient setSharedClient:client];
    NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                            
                            DEVICE_TOKEN, [[nc_AppDelegate sharedInstance] deviceTokenString],
                            APPLICATION_TYPE,[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],DUMMY_TOKEN_ID,[[NSUserDefaults standardUserDefaults] objectForKey:DUMMY_TOKEN_ID],APPLICATION_VERSION,[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                            nil];
    NSString *updateURL = [UPDATE_DEVICE_TOKEN appendQueryParams:params];
    updateDeviceTokenURL = updateURL;
    [[RKClient sharedClient] get:updateURL delegate:self];
}
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    @try {
        NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: NULL_STRING] stringByReplacingOccurrencesOfString: @">" withString: NULL_STRING] stringByReplacingOccurrencesOfString: @" " withString: @""];
        [prefs setObject:token forKey:DEVICE_TOKEN];
        [prefs synchronize];
        // Part Of DE-286 Fixed.
        if([prefs objectForKey:DUMMY_TOKEN_ID]){
            [self updateDeviceToken];
        }
        [[UserPreferance userPreferance] performSelector:@selector(saveToServer) withObject:nil afterDelay:3.0];
        NIMLOG_PERF2(@"deviceTokenString: %@",token);
        [UIApplication sharedApplication].applicationIconBadgeNumber = BADGE_COUNT_ZERO;
        logEvent(FLURRY_PUSH_AVAILABLE,
                 FLURRY_NOTIFICATION_TOKEN, token,
                 nil, nil, nil, nil, nil, nil);
        
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->didRegisterForRemoteNotificationsWithDeviceToken", @"", exception);
    }
}


- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    @try {
        NSString *str = [NSString stringWithFormat: @"Error: %@", err];
        NIMLOG_ERR1(@"didFail To Register For RemoteNotifications With Error: %@",str);
        prefs = [NSUserDefaults standardUserDefaults];
        //NSString *dummyToken = [NSString stringWithFormat:@"SF%@",generateRandomString(64)];
        NSString  *token = @"26d906c5c273446d5f40d2c173ddd3f6869b2666b1c7afd5173d69b6629def70";
        [prefs setObject:token forKey:DEVICE_TOKEN];
        [[UserPreferance userPreferance] performSelector:@selector(saveToServer) withObject:nil afterDelay:3.0];
        //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler Push Alert" message:@"your device couldn't connect with apple. Please reinstall application" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        //    [alert show];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->didFailToRegisterForRemoteNotificationWithError", @"", exception);
    }
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    isRemoteNotification = YES;
    [actionsheet dismissWithClickedButtonIndex:-1 animated:NO];
    @try {
        for (id key in userInfo) {
            NIMLOG_EVENT1(@"didReceiveRemoteNotification key: %@, value: %@", key, [userInfo objectForKey:key]);
        }
        NSString *isUrgent = [userInfo valueForKey:@"isUrgent"];
        NSString *message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
        NSString *badge = [[userInfo valueForKey:@"aps"] valueForKey:@"badge"];
        prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:badge forKey:TWEET_COUNT];
        
        if ([isUrgent isEqualToString:@"true"]) {
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
                if([UserPreferance userPreferance].urgentNotificationSound){
                    AudioServicesPlaySystemSound(1015);
                }
            }
            UIAlertView *dataAlert = [[UIAlertView alloc] initWithTitle:APP_TITLE
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil,nil];
            
            [dataAlert show];
        }
        else {
            // Redirect to Twitter Page View
            if(self.isFromBackground){
                RXCustomTabBar *rxCustomTabBar = (RXCustomTabBar *)self.tabBarController;
                [rxCustomTabBar selectTab:1];
                [twitterView getAdvisoryData];
            }
            else{
                [self getTwiiterLiveData];
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->didReceiveRemoteNotification", @"", exception);
    }
}

-(void)alertView: (UIAlertView *)UIAlertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *btnName = [UIAlertView buttonTitleAtIndex:buttonIndex];
    if ([btnName isEqualToString:BTN_OK]) {
        [self.tabBarController setSelectedIndex:1];
    } else if([btnName isEqualToString:BTN_EXIT]){
        exit(0);
    }
}

-(void)updateTime{
    @try {
        isUpdateTime = YES;
        [[TransitCalendar transitCalendar] updateFromServer];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->updateTime", @"", exception);
    }
}



#pragma mark Twitter Live count request
-(void)getTwiiterLiveData{
    @try {
        NSString *strAgencyIDs = [self getAgencyIdsString];
        //DE-290 Fixed
        if(strAgencyIDs.length > 0 && [[nc_AppDelegate sharedInstance] deviceTokenString]){
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:DEVICE_TOKEN, [[nc_AppDelegate sharedInstance] deviceTokenString],APPLICATION_TYPE,[self getAppTypeFromBundleId],AGENCY_IDS,strAgencyIDs,APPLICATION_VERSION,[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"], nil];
            isTwitterLivaData = TRUE;
            NSString *twitCountReq = [TWEET_COUNT_URL appendQueryParams:params];
            strTweetCountURL = twitCountReq;
            NIMLOG_EVENT1(@"twitter count req: %@", twitCountReq);
            [rkTpClient  get:twitCountReq delegate:self];
        }
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->getTwiiterLiveData", @"", exception);    }
}


// update badge
-(void)updateBadge:(int)count
{
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] != 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] != 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] != 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] != 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_WMATA_ADV] intValue] != 1){ 
            count = 0;
        }
    int tweetConut =count;
    [twitterCount removeFromSuperview];
    twitterCount = [[CustomBadge alloc] init];
    twitterCount = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d",tweetConut]];
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
        [twitterCount setFrame:CGRectMake(25,8,twitterCount.frame.size.width,twitterCount.frame.size.height)];
    }
    else{
        [twitterCount setFrame:CGRectMake(25,8,twitterCount.frame.size.width,twitterCount.frame.size.height)];
    }
    if (tweetConut == 0) {
        [twitterCount setHidden:YES];
    } else {
         [toFromViewController.navigationController.navigationBar addSubview:twitterCount];
        if(toFromViewController.navigationController.topViewController == toFromViewController){
            [twitterCount setHidden:NO];
        }
        else{
            [twitterCount setHidden:YES];
        }
    }
}

-(BOOL)isNetworkConnectionLive
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    
    if(remoteHostStatus == NotReachable) {
        return NO;
    }
    else{
        return YES;
    }
}

// ActoinSheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString* buttonResponse;
    if(buttonIndex == 0){
        buttonResponse = @"App Store feedback";
        //Fixed DE-326
        NSURL *url = [[NSURL alloc] initWithString:NIMBLER_REVIEW_URL];
        [[UIApplication sharedApplication] openURL:url];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FEEDBACK_REMINDER_PENDING];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if(buttonIndex == 1){
        buttonResponse = @"Nimbler feedback";
        FeedBackForm *feedBackForm;
        if ([UIScreen mainScreen].bounds.size.height == IPHONE5HEIGHT) {
            feedBackForm = [[FeedBackForm alloc] initWithNibName:@"FeedBackFormPopUp_568h" bundle:nil];
        }
        else{
            feedBackForm = [[FeedBackForm alloc] initWithNibName:@"FeedBackFormPopUp" bundle:nil];
        }
        feedBackForm.isViewPresented = true;
        [self.toFromViewController presentModalViewController:feedBackForm animated:YES];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FEEDBACK_REMINDER_PENDING];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if(buttonIndex == 2){
        buttonResponse = @"Remind me later";
        [[NSUserDefaults standardUserDefaults] setInteger:20 forKey:DAYS_TO_SHOW_FEEDBACK_ALERT];
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:DAYS_COUNT];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if(buttonIndex == [actionSheet cancelButtonIndex]){
        buttonResponse = @"No thanks";
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:FEEDBACK_REMINDER_PENDING];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    logEvent(FLURRY_APPSTORE_FEEDBACK_REMINDER_ACTION, FLURRY_APPSTORE_FB_REMINDER_USER_SELECTION, buttonResponse, nil, nil, nil, nil, nil, nil);
}

// Get Application Type from Bundle Identifier
- (NSString *)getAppTypeFromBundleId{
    NSString *strAppType;
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
        strAppType = CALTRAIN_APP_TYPE;
    }
    else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
        strAppType = WMATA_APP_TYPE;
    }
    else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:PORTLAND_BUNDLE_IDENTIFIER]){
        strAppType = PORTLAND_APP_TYPE;
    }
    else{
        strAppType = SFMUNI_APP_TYPE;
    }
    return strAppType;
}

// Part Of US-168 Implementation.
// Return The Enabled Agency Ids
- (NSString *)getAgencyIdsString{
    NSMutableString *strMutableAgencyIds = [[NSMutableString alloc] init];
    NSString *strAgencyIds;
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_WMATA_ADV] intValue] == 1){
            [strMutableAgencyIds appendFormat:@"%@,",WMATA_AGENCY_FEED_ID];
        }
    }
    else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:PORTLAND_BUNDLE_IDENTIFIER]){
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_TRIMET_ADV] intValue] == 1){
            [strMutableAgencyIds appendFormat:@"%@,",TRIMET_AGENCY_FEED_ID];
        }
    }
    else{
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1){
            [strMutableAgencyIds appendFormat:@"%@,",SFMUNI_AGENCY_FEED_ID];
        }
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1){
            [strMutableAgencyIds appendFormat:@"%@,",BART_AGENCY_FEED_ID];
        }
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1){
            [strMutableAgencyIds appendFormat:@"%@,",ACTRANSIT_AGENCY_FEED_ID];
        }
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
            [strMutableAgencyIds appendFormat:@"%@,",CALTRAIN_AGENCY_FEED_ID];
        }
    }
    int nLength = [strMutableAgencyIds length];
    if(nLength > 0){
        strAgencyIds = [strMutableAgencyIds substringToIndex:nLength-1];
    }
    else{
        strAgencyIds = strMutableAgencyIds;
    }
    return strAgencyIds;
}

- (NSString *) deviceTokenString{
    // Return Hard Coded Token for iPhone or ipad simulator
    if([[[UIDevice currentDevice] platformString] isEqualToString:SIMULATOR_IPHONE_NAMESTRING] || [[[UIDevice currentDevice] platformString] isEqualToString:SIMULATOR_IPAD_NAMESTRING]){
        NSString  *token = @"26d906c5c273446d5f40d2c173ddd3f6869b2666b1c7afd5173d69b6629def70";
        return token;
    }
    
    NSString *deviceToken = [prefs objectForKey:DEVICE_TOKEN];
    if(deviceToken){
        return deviceToken;
    }
    else{
        NSString *dummyToken = [prefs objectForKey:DUMMY_TOKEN_ID];
        if(!dummyToken){
            dummyToken = [NSString stringWithFormat:@"SF%@",generateRandomString(64)];
            //Fixed DE-327
            if(![[NSUserDefaults standardUserDefaults] boolForKey:DEVICE_TOKEN_UPDATED]){
                [prefs setObject:dummyToken forKey:DUMMY_TOKEN_ID];
            }
        }
        return dummyToken;   
    }
}
@end