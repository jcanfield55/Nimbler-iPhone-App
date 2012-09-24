//
//  nc_AppDelegate.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "nc_AppDelegate.h"
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
#if TEST_FLIGHT_ENABLED
#import "TestFlightSDK1-1/TestFlight.h"
#endif
#if FLURRY_ENABLED
#import "Flurry.h"
#endif

#define BTN_EXIT        @"Exit fromApp"
#define BTN_OK          @"Ok"
#define BTN_CANCEL      @"Continue"
#define ALERT_NETWORK   @"Please check your wifi or data connection!" 

BOOL isTwitterLivaData = FALSE; 
BOOL isRegionSupport = FALSE;

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
@synthesize isServiceByWeekday;
@synthesize isCalendarByDate;
@synthesize isSettingSavedSuccessfully;
@synthesize isSettingRequest;
@synthesize lastGTFSLoadDateByAgency;
@synthesize serviceByWeekdayByAgency;
@synthesize calendarByDateByAgency;
@synthesize timerType;


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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [[UIApplication sharedApplication]
     registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert | 
      UIRemoteNotificationTypeBadge | 
      UIRemoteNotificationTypeSound)];
    
    prefs = [NSUserDefaults standardUserDefaults];
    
    // Configure the RestKit RKClient object for Geocoding and trip planning
    RKLogConfigureByName("RestKit", CUSTOM_RK_LOG_LEVELS);
    RKLogConfigureByName("RestKit/Network/Cache", CUSTOM_RK_LOG_LEVELS);
    RKLogConfigureByName("RestKit/Network/Reachability", CUSTOM_RK_LOG_LEVELS);

    
    RKObjectManager* rkGeoMgr = [RKObjectManager objectManagerWithBaseURL:GEO_RESPONSE_URL];
    // Trimet base URL is http://rtp.trimet.org/opentripplanner-api-webapp/ws/
    
    RKObjectManager *rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:TRIP_PROCESS_URL];

    
    // Other URLs:
    // Trimet base URL is http://rtp.trimet.org/opentripplanner-api-webapp/ws/
    // NY City demo URL is http://demo.opentripplanner.org/opentripplanner-api-webapp/ws/
    
    // Add the CoreData managed object store

    RKManagedObjectStore *rkMOS;
    @try {
        rkMOS = [RKManagedObjectStore objectStoreWithStoreFilename:@"store.data"];
        [rkGeoMgr setObjectStore:rkMOS];
        [rkPlanMgr setObjectStore:rkMOS];
        
        // Call suppertedRegion for getting boundry of bay area region
        [self suppertedRegion];
        
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
        
        // Initialize the planStore and KeyObjectStore
        planStore = [[PlanStore alloc] initWithManagedObjectContext:[self managedObjectContext]
                                                          rkPlanMgr:rkPlanMgr];
        [toFromViewController setPlanStore:planStore];
        [KeyObjectStore setUpWithManagedObjectContext:[self managedObjectContext]];
        
        //
        // Temporary code for converting Locations to LocationsFromGoogle
        //
        /*
        NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
        NSError *error;
        NSArray* allLocations = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        if (!allLocations) {
            [NSException raise:@"Fetching all Locations failed" format:@"Reason: %@", [error localizedDescription]];
        }
        for (Location* loc in allLocations) {
            if (![loc isDeleted]) { // only if not already deleted
                if ([loc apiTypeEnum]==GOOGLE_GEOCODER &&
                    ![loc isKindOfClass:[LocationFromGoogle class]]) {
                    LocationFromGoogle* loc2 = (LocationFromGoogle *)loc;
                    NSLog(@"Class = %@", [loc2 class]);
                }
            }
        }
        */
        
        // Pre-load stations location files
        NSDecimalNumber* version = [NSDecimalNumber decimalNumberWithString:PRELOAD_VERSION_NUMBER];
        BOOL newVer = [locations preLoadIfNeededFromFile:PRELOAD_LOCATION_FILE latestVersionNumber:version];
        
        // Temporary code inserted 9/7/12 to do a one-time delete of plans that do not have
        // itineraries with startTimeOnly and endTimeOnly set (should only happen for code apps before 9/7)
        // Code also consolidates all locations (addressing many duplicate ones from DE152)
        if (newVer) {
            // Clean up the locations
            NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Location"];
            NSError *error;
            NSArray* allLocations = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
            if (!allLocations) {
                [NSException raise:@"Fetching all Locations failed" format:@"Reason: %@", [error localizedDescription]];
            }
            for (Location* loc in allLocations) {
                if (![loc isDeleted]) { // only if not already deleted
                    if ([[loc formattedAddress] isEqualToString:@"California, USA"] ||
                        [[loc formattedAddress] isEqualToString:@"United States"] ||
                        [[loc formattedAddress] isEqualToString:@"Santa Clara, CA, USA"] ||
                        [[loc formattedAddress] isEqualToString:@"San Mateo, CA, USA"] ||
                        [[loc formattedAddress] isEqualToString:@"San Francisco, CA, USA"]) {
                        [locations removeLocation:loc];  // remove any of these generic county, state, country locations
                    } else {
                        // Consolidate locations
                        [locations consolidateWithMatchingLocations:loc keepThisLocation:true];
                    }
                }
            }
            
            // Clean up the plans
            fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Plan"];
            NSArray* allPlans = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
            if (!allPlans) {
                [NSException raise:@"Fetching all Plans failed" format:@"Reason: %@", [error localizedDescription]];
            }
            NSMutableSet* deleteSet = [[NSMutableSet alloc] initWithCapacity:[allPlans count]];
            for (Plan* plan in allPlans) {
                if ([[plan itineraries] count] == 0 ||
                    ![plan fromLocation] || [[plan fromLocation] isDeleted] ||
                    ![plan toLocation] || [[plan toLocation] isDeleted]) {
                    [deleteSet addObject:plan];  // add plan for deletion if any of its key parameters are null
                } else {
                    for (Itinerary* itin in [plan itineraries]) {
                        if (![itin startTimeOnly] || ![itin endTimeOnly]) {
                            // If these values were never set when the plan was created
                            [deleteSet addObject:plan];  // add the plan for deletion
                            break;
                        }
                    }
                }
            }
            // Now delete the plans
            for (Plan* plan in deleteSet) {
                [[self managedObjectContext] deleteObject:plan];
            }
            
            // Save changes
            saveContext([self managedObjectContext]);
        }  // End of temporary code
        
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
    [TestFlight takeOff:@"48a90a98948864a11c80bd2ecd7a7e5c_ODU5MzMyMDEyLTA1LTA3IDE5OjE3OjUwLjMxMDUyMg"];
#endif
    // Call to Flurry SDK
#if FLURRY_ENABLED
    [Flurry startSession:@"WWV2WN4JMY35D4GYCPDJ"];
    [Flurry setUserID:cfuuidString];
    [Flurry logEvent:FLURRY_APPDELEGATE_START];
#endif
    
    // Create an instance of a UINavigationController and put toFromViewController as the first view
    @try {
        /*
         // These is for navigation controller
        
         UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:toFromViewController]; 
         self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
         [[self window] setRootViewController:navController];
         [self.window makeKeyAndVisible];
        */
         
        // This is for TabBar controller
        
        self.tabBarController = [[RXCustomTabBar alloc] init];
        twitterView = [[twitterViewController alloc] initWithNibName:@"twitterViewController" bundle:nil];
        settingView = [[SettingInfoViewController alloc] initWithNibName:@"SettingInfoViewController" bundle:nil];
        fbView = [[FeedBackForm alloc] initWithNibName:@"FeedBackForm" bundle:nil];
        
               
        UINavigationController *toFromController = [[UINavigationController alloc] initWithRootViewController:toFromViewController];
         UINavigationController *tweetController = [[UINavigationController alloc] initWithRootViewController:twitterView];
         UINavigationController *settingController = [[UINavigationController alloc] initWithRootViewController:settingView];
         UINavigationController *fbController = [[UINavigationController alloc] initWithRootViewController:fbView];
        self.tabBarController.viewControllers = [NSArray arrayWithObjects:toFromController,tweetController,settingController,fbController, nil];
        
//        [self.tabBarController.tabBar setSelectedImageTintColor:[UIColor redColor]];
//        [self.tabBarController.tabBar setBackgroundImage:[UIImage imageNamed:@"img_tabbar.png"]];
        [[nc_AppDelegate sharedInstance] updateTime];
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [[self window] setRootViewController:self.tabBarController];
        [self.window makeKeyAndVisible];
        
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->didFinishLaunchingWithOptions #2", @"", exception);
    }
    return YES;
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
    if (!currentLocation) {
        NSArray* matchingLocations = [locations locationsWithFormattedAddress:@"Current Location"];
        if ([matchingLocations count] == 0) { // if current location not in db
            currentLocation = [locations newEmptyLocation];
            [currentLocation setFormattedAddress:@"Current Location"];
            [currentLocation setFromFrequencyFloat:100.0];
            [toFromViewController reloadTables]; // DE30 fix (1 of 2)
            [locations setIsLocationServiceEnable:TRUE];
        }
        else {
            currentLocation = [matchingLocations objectAtIndex:0];
            [locations setIsLocationServiceEnable:TRUE];
        }
        [toFromViewController setCurrentLocation:currentLocation];
        [toFromViewController setIsCurrentLocationMode:TRUE];
#if FLURRY_ENABLED
        [Flurry logEvent:FLURRY_CURRENT_LOCATION_AVAILABLE];
#endif
    }
    
    [currentLocation setLatFloat:[newLocation coordinate].latitude];
    [currentLocation setLngFloat:[newLocation coordinate].longitude];
    
    //TODO error handling if location services not available
    //TODO error handling if current location is in the database, but not populated
    //TODO error handling for very old cached current location data
    //TODO adjust frequency if needed
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
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
        
    saveContext([self managedObjectContext]);
    [locationManager stopUpdatingLocation];
    
    //Reload ToFromViewController
    if(self.isToFromView){
        self.toLoc = toFromViewController.toLocation;
        self.fromLoc = toFromViewController.fromLocation;
        [toFromViewController setEditMode:NO_EDIT]; 
        toFromViewController.toTableVC.txtField.text = NULL_STRING;
        toFromViewController.fromTableVC.txtField.text = NULL_STRING;
        [toFromViewController.toTableVC toFromTyping:toFromViewController.toTableVC.txtField forEvent:nil];
        [toFromViewController.toTableVC textSubmitted:toFromViewController.toTableVC.txtField forEvent:nil];
        [toFromViewController.fromTableVC toFromTyping:toFromViewController.fromTableVC.txtField forEvent:nil];
        [toFromViewController.fromTableVC textSubmitted:toFromViewController.fromTableVC.txtField forEvent:nil];
    }
    
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
    [toFromViewController.timerGettingRealDataByItinerary invalidate];
    toFromViewController.timerGettingRealDataByItinerary = nil;
    isFromBackground = YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    
    // Check the date and if it is not today's date we will make request.
    NSDate *todayDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    NSString *strTodayDate = [dateFormatter stringFromDate:todayDate];
    NSDate *currentDate = [[NSUserDefaults standardUserDefaults] objectForKey:CURRENT_DATE];
    if(![strTodayDate isEqual:currentDate]){
        [[nc_AppDelegate sharedInstance] updateTime];
        [[NSUserDefaults standardUserDefaults] setObject:strTodayDate forKey:CURRENT_DATE];
        [[NSUserDefaults standardUserDefaults] synchronize];
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
    if(isFromBackground){
            toFromViewController.timerGettingRealDataByItinerary =   [NSTimer scheduledTimerWithTimeInterval:TIMER_STANDARD_REQUEST_DELAY target:toFromViewController selector:@selector(getRealTimeDataForItinerary) userInfo:nil repeats: YES];

    }
    if(!isSettingSavedSuccessfully){
        [self saveSetting];
    }
//    sleep(2);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    [self isNetworkConnectionLive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    saveContext([self managedObjectContext]);
}


#pragma mark - Directions request URL handler from iOS6

// Directions request URL handler from iOS6
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    if ([MKDirectionsRequest isDirectionsRequestURL:url]) {
        MKDirectionsRequest* directionsInfo = [[MKDirectionsRequest alloc] initWithContentsOfURL:url];
        
        // Create & set the source location
        Location* sourceLoc;
        if ([[directionsInfo source] isCurrentLocation]) {
            sourceLoc = currentLocation;
        } else {
            MKPlacemark* sourcePlacemark = [[directionsInfo source] placemark];
            sourceLoc = [locations newEmptyLocation];
            sourceLoc.formattedAddress = [NSString stringWithFormat:@"%@, %@", 
                                          sourcePlacemark.thoroughfare, sourcePlacemark.locality];
            sourceLoc.latFloat = sourcePlacemark.location.coordinate.latitude;
            sourceLoc.lngFloat = sourcePlacemark.location.coordinate.longitude;
        }
        [toFromViewController updateToFromLocation:self isFrom:true location:sourceLoc];
        
        // Create & set the destination location
        Location* destinationLoc;
        if ([[directionsInfo destination] isCurrentLocation]) {
            destinationLoc = currentLocation;
        } else {
            MKPlacemark* destinationPlacemark = [[directionsInfo destination] placemark];
            destinationLoc = [locations newEmptyLocation];
            destinationLoc.formattedAddress = [NSString stringWithFormat:@"%@, %@", 
                                               destinationPlacemark.thoroughfare, destinationPlacemark.locality];
            destinationLoc.latFloat = destinationPlacemark.location.coordinate.latitude;
            destinationLoc.lngFloat = destinationPlacemark.location.coordinate.longitude;
        }
        [toFromViewController updateToFromLocation:self isFrom:false location:destinationLoc];
        
        // Request route
        [toFromViewController getRouteFromMapKitURLRequest];
        return YES;
    }
    return NO;
    
    // TODO Do a consolidateLocations versus existing locations
    // TODO Make robust use of Apple geocoding
    // TODO Make sure this works even if Current Location is turned off for Nimbler
    // TODO Adjust the GeoJSON to cover a smaller Nimbler Caltrain footprint
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
        if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
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
            NIMLOG_ERR1(@"Unresolved error %@, %@", error, [error userInfo]);
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
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        [[RKClient sharedClient]  get:@"metadata" delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->suppertedRegion", @"", exception);    }
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response 
{  
    isFromBackground = NO;
    @try {
        if ([request isGET]) {
            NIMLOG_OBJECT1(@"nc_AppDelegate response from Get: %@", [response bodyAsString]);
            
            NSError *error = nil;
            if (error == nil)
            {
                RKJSONParserJSONKit* rkParser = [RKJSONParserJSONKit new];
                NSDictionary *tempResponseDictionary = [rkParser objectFromString:[response bodyAsString] error:nil];
                if([tempResponseDictionary objectForKey:GTFS_UPDATE_TIME] != nil ){
                    NIMLOG_EVENT1(@"Loaded TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY");
                    if(lastGTFSLoadDateByAgency != tempResponseDictionary){
                        lastGTFSLoadDateByAgency = tempResponseDictionary;
                        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                        [keyObjectStore setObject:lastGTFSLoadDateByAgency forKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
                        [[nc_AppDelegate sharedInstance] performSelector:@selector(serviceByWeekday) withObject:nil afterDelay:0.5];
                    }
                }
                else if([tempResponseDictionary objectForKey:GTFS_SERVICE_BY_WEEKDAY] != nil){
                    NIMLOG_EVENT1(@"Loaded TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY");
                    serviceByWeekdayByAgency = tempResponseDictionary;
                    KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                    [keyObjectStore setObject:serviceByWeekdayByAgency forKey:TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY ];
                    [[nc_AppDelegate sharedInstance] performSelector:@selector(calendarByDate) withObject:nil afterDelay:0.5];
                }
                else if([tempResponseDictionary objectForKey:GTFS_SERVICE_EXCEPTIONS_DATES] != nil){
                    NIMLOG_EVENT1(@"Loaded TR_CALENDAR_BY_DATE_BY_AGENCY");
                    calendarByDateByAgency = tempResponseDictionary;
                    KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                    [keyObjectStore setObject:calendarByDateByAgency forKey:TR_CALENDAR_BY_DATE_BY_AGENCY];
                }
                else if(isSettingRequest){
                    NSDictionary  *dictTemp = [rkParser objectFromString:[response bodyAsString] error:nil];
                    NIMLOG_EVENT1(@"Setting Request RKResponse: %@",[response bodyAsString]);
                    NSNumber *respCode = [(NSDictionary*)dictTemp objectForKey:CODE];
                    if ([respCode intValue]== RESPONSE_SUCCESSFULL) { 
                        self.isSettingSavedSuccessfully = YES;
                    }
                    else{
                        self.isSettingSavedSuccessfully = NO;
                    }
                    isSettingRequest = NO;
                }
                else if (isTwitterLivaData) {
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
                } else if(isRegionSupport){
                    NIMLOG_EVENT1(@"Loaded SupportedRegion response");
                    NSDictionary  *regionParser = [rkParser objectFromString:[response bodyAsString] error:nil];
                    SupportedRegion *region = [[SupportedRegion alloc] init];
                    isRegionSupport = FALSE;
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
                        } else if ([key isEqualToString:@"lowerLeftLongitude"]){
                            [region setLowerLeftLongitude:[regionParser objectForKey:key] ];
                        } else if ([key isEqualToString:@"lowerLeftLatitude"]){
                            [region setLowerLeftLatitude:[regionParser objectForKey:key] ];
                        } 
                    }                
                    [toFromViewController setSupportedRegion:region];
                    [self getTwiiterLiveData];
                    if (timerTweeterGetData == nil) {
                        timerTweeterGetData =   [NSTimer scheduledTimerWithTimeInterval:TWEET_COUNT_POLLING_INTERVAL target:self selector:@selector(getTwiiterLiveData) userInfo:nil repeats: YES];
                    }
                }
                else if(isUpdateTime){
                     NSDictionary  *dictUpdateTime = [rkParser objectFromString:[response bodyAsString] error:nil];
                    NIMLOG_EVENT1(@"isUpdateTime update %@", dictUpdateTime); 
                    isUpdateTime = NO;
                }
                else if(isServiceByWeekday){
                    NIMLOG_OBJECT1(@"isServiceByWeekday response: %@",[response bodyAsString]);
                    NSDictionary  *dictServiceByweekday = [rkParser objectFromString:[response bodyAsString] error:nil];
                    NIMLOG_EVENT1(@"isServiceByWeekday update %@", dictServiceByweekday); 
                    isServiceByWeekday = NO;
                }
                else if(isCalendarByDate){
                    NSDictionary  *dictCalendarByDate = [rkParser objectFromString:[response bodyAsString] error:nil];
                    NIMLOG_EVENT1(@"isCalendarByDate update %@", dictCalendarByDate); 
                    isCalendarByDate = NO;
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
    NIMLOG_PERF1(@"Registering for push notifications...");    
    [[UIApplication sharedApplication] 
     registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert | 
      UIRemoteNotificationTypeBadge | 
      UIRemoteNotificationTypeSound)];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    @try {
        NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: NULL_STRING] stringByReplacingOccurrencesOfString: @">" withString: NULL_STRING] stringByReplacingOccurrencesOfString: @" " withString: @""];
        NIMLOG_OBJECT1(@"deviceTokenString: %@",token);
        [UIApplication sharedApplication].applicationIconBadgeNumber = BADGE_COUNT_ZERO;
        [prefs setObject:token forKey:DEVICE_TOKEN];  
        [prefs synchronize];
        [self upadateDefaultUserValue];
#if FLURRY_ENABLED
        NSDictionary *flurryParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                      FLURRY_NOTIFICATION_TOKEN, token, nil];
        [Flurry logEvent: FLURRY_PUSH_AVAILABLE withParameters:flurryParams];
#endif
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
        NSString  *token = @"26d906c5c273446d5f40d2c173ddd3f6869b2666b1c7afd5173d69b6629def70";
        [prefs setObject:token forKey:DEVICE_TOKEN];
        [self upadateDefaultUserValue];
        //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler Push Alert" message:@"your device couldn't connect with apple. Please reinstall application" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        //    [alert show];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->didFailToRegisterForRemoteNotificationWithError", @"", exception);
    }
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo 
{
    @try {
        for (id key in userInfo) {
            NIMLOG_EVENT1(@"didReceiveRemoteNotification key: %@, value: %@", key, [userInfo objectForKey:key]);
        }        
        NSString *isUrgent = [userInfo valueForKey:@"isUrgent"];
        NSString *message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
        NSString *sound = [[userInfo valueForKey:@"aps"] valueForKey:@"sound"];
        NIMLOG_EVENT1(@"Remote Notification Sound: %@",sound);
        NSString *badge = [[userInfo valueForKey:@"aps"] valueForKey:@"badge"];
        prefs = [NSUserDefaults standardUserDefaults];  
        [prefs setObject:badge forKey:TWEET_COUNT];
        
        if ([isUrgent isEqualToString:@"true"]) {
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
                if([[NSUserDefaults standardUserDefaults] integerForKey:ENABLE_URGENTNOTIFICATION_SOUND] == 1 || [[NSUserDefaults standardUserDefaults] integerForKey:ENABLE_URGENTNOTIFICATION_SOUND] == 0){
                    AudioServicesPlaySystemSound(1015);  
                }
            }
            UIAlertView *dataAlert = [[UIAlertView alloc] initWithTitle:@"Nimbler Caltrain"
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
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        isUpdateTime = YES;
        NSString *request = [UPDATE_TIME_URL appendQueryParams:nil];
        NIMLOG_TWITTER1(@"updateTime req: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->updateTime", @"", exception);
    }
}

-(void)serviceByWeekday{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        isServiceByWeekday = YES;
        NSString *serviceByWeekdayReq = [SERVICE_BY_WEEKDAY_URL appendQueryParams:nil];
        NIMLOG_EVENT1(@"Service By Weekday req: %@", serviceByWeekdayReq);
        [[RKClient sharedClient]  get:serviceByWeekdayReq delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->serviceByWeekday", @"", exception);    }
}

-(void)calendarByDate{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        isCalendarByDate = YES;
        NSString *request = [CALENDAR_BY_DATE_URL appendQueryParams:nil];
        NIMLOG_EVENT1(@"Calendar By Date req: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->calendarByDate", @"", exception);
    }
}

#pragma mark Twitter Live count request
-(void)getTwiiterLiveData{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
//        NSString *udid = [UIDevice currentDevice].uniqueIdentifier;            
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID], nil];    
        isTwitterLivaData = TRUE;
        NSString *request = [@"advisories/count" appendQueryParams:params];
        NIMLOG_EVENT1(@"twitter count req: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->getTwiiterLiveData", @"", exception);    }
}

- (void)saveSetting{
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString *token = [userDefault objectForKey:DEVICE_TOKEN];
    NSString *pushEnable = [prefs objectForKey:PREFS_IS_PUSH_ENABLE];
    int pushHour;
    if([pushEnable intValue] == 0){
        pushHour = -1;
    }
    else{
        pushHour = [userDefault integerForKey:PREFS_PUSH_NOTIFICATION_THRESHOLD];
    }
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    [RKClient setSharedClient:client];
    NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                            DEVICE_ID, [userDefault objectForKey:DEVICE_CFUUID],
                            ALERT_COUNT,[NSNumber numberWithInt:pushHour],
                            DEVICE_TOKEN, token,
                            MAXIMUM_WALK_DISTANCE,[NSNumber numberWithFloat:[userDefault floatForKey:PREFS_MAX_WALK_DISTANCE]],ENABLE_URGENTNOTIFICATION_SOUND,[NSNumber numberWithInt: [userDefault integerForKey:ENABLE_URGENTNOTIFICATION_SOUND]],ENABLE_STANDARDNOTIFICATION_SOUND,[NSNumber numberWithInt: [userDefault integerForKey:ENABLE_STANDARDNOTIFICATION_SOUND]],
                            nil];
    NSString *request = [UPDATE_SETTING_REQ appendQueryParams:params];
    NIMLOG_EVENT1(@"Save setting Req = %@", request);
    isSettingRequest = YES;
    [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = NO;
    [[RKClient sharedClient]  get:request delegate:self];

}

#pragma mark update userSettings from server 
-(void)upadateDefaultUserValue{
    @try {
        UserPreferance* userPrefs = [UserPreferance userPreferance]; // get singleton
        // set in TPServer
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];    
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
                                @"alertCount", [userPrefs triggerAtHour],
                                DEVICE_TOKEN, [prefs objectForKey:DEVICE_TOKEN],
                                @"maxDistance", [userPrefs walkDistance],ENABLE_URGENTNOTIFICATION_SOUND,[NSNumber numberWithInt:URGENT_NOTIFICATION_DEFAULT_VALUE],ENABLE_STANDARDNOTIFICATION_SOUND,[NSNumber numberWithInt:STANDARD_NOTIFICATION_DEFAULT_VALUE],
                                nil];
        NIMLOG_EVENT1(@"params=%@",params);
        NSString *request = [UPDATE_SETTING_REQ appendQueryParams:params];
        [[RKClient sharedClient]  get:request delegate:self]; 
        
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->upadateDefaultUserValue", @"", exception);
    }
}

// update badge
-(void)updateBadge:(int)count
{
    int tweetConut =count;
    [twitterCount removeFromSuperview];
    twitterCount = [[CustomBadge alloc] init];
    twitterCount = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d",tweetConut]];
    [twitterCount setFrame:CGRectMake(130,430, twitterCount.frame.size.width, twitterCount.frame.size.height)];        
    if (tweetConut == 0) {
        [twitterCount setHidden:YES];
    } else {
        [self.window addSubview:twitterCount];
        [twitterCount setHidden:NO];
    }
}

-(void)isNetworkConnectionLive
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
      
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
      [reachability startNotifier];

    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    
    if(remoteHostStatus == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:ALERT_NETWORK delegate:self cancelButtonTitle:BTN_EXIT otherButtonTitles:BTN_CANCEL, nil];
        [alert show];
    } 
}
// Partial Implementation Of Clearing PlanCache
// Get The All PlanRequestChunk and delete them when max walk distance change.
- (void)clearCache{ 
    NSError *error;
    NSManagedObjectContext * context = [self managedObjectContext];
    NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:[NSEntityDescription entityForName:@"PlanRequestChunk" inManagedObjectContext:context]];
    NSArray * result = [context executeFetchRequest:fetch error:nil];
    for (id basket in result){
        [context deleteObject:basket];
    }
    [context save:&error];
    if(error){
        NIMLOG_ERR1(@"Error While Clearing Cache:%@",error);
    }
}
@end