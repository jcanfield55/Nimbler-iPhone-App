//
//  nc_AppDelegate.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "nc_AppDelegate.h"
#import "UtilityFunctions.h"
#import "TestFlightSDK1/TestFlight.h"
#import "ToFromViewController.h"
#import "TwitterSearch.h"
#import "twitterViewController.h"

#define TESTING 1  // If 1, then testFlightApp will collect device UIDs, if 0, it will not
#define DEVELOPMENT 1  // If 1, then do not include testFlightApp at all (don't need crash report while developing)

BOOL isTwitterLivaData = FALSE; 

static nc_AppDelegate *appDelegate;

@implementation nc_AppDelegate

@synthesize locations;
@synthesize locationManager;
@synthesize toFromViewController;
@synthesize feedbackView;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize window = _window;
@synthesize timerTweeterGetData;
@synthesize propertyInfo;
@synthesize prefs;

+(nc_AppDelegate *)sharedInstance
{
    if(appDelegate == nil){
        appDelegate = (nc_AppDelegate *)[[UIApplication sharedApplication] delegate];
        
    }
    return appDelegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [[UIApplication sharedApplication] 
     registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert | 
      UIRemoteNotificationTypeBadge | 
      UIRemoteNotificationTypeSound)];
    
    // Configure the RestKit RKClient object for Geocoding and trip planning
    RKObjectManager* rkGeoMgr = [RKObjectManager objectManagerWithBaseURL:GEO_RESPONSE_URL];
    // Trimet base URL is http://rtp.trimet.org/opentripplanner-api-webapp/ws/
    
    RKObjectManager *rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:TRIP_GENERATE_URL];
    
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
        toFromViewController = [[ToFromViewController alloc] initWithNibName:nil bundle:nil];
        [toFromViewController setRkGeoMgr:rkGeoMgr];    // Pass the geocoding RK object
        [toFromViewController setRkPlanMgr:rkPlanMgr];    // Pass the planning RK object
        
        
        // Turn on location manager
        locationManager = [[CLLocationManager alloc] init];
        [locationManager setDelegate:self];
        [locationManager startUpdatingLocation];
        
        // Initialize the Locations class and store "Current Location" into the database if not there already
        locations = [[Locations alloc] initWithManagedObjectContext:[self managedObjectContext] rkGeoMgr:rkGeoMgr];
        [toFromViewController setLocations:locations];
        
        // Pre-load stations location files
        NSDecimalNumber* version = [NSDecimalNumber decimalNumberWithString:PRELOAD_VERSION_NUMBER];
        [locations preLoadIfNeededFromFile:PRELOAD_LOCATION_FILE latestVersionNumber:version];
        
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"UserPreferance"] == nil) {
            propertyInfo = [NSEntityDescription
                            insertNewObjectForEntityForName:@"UserPreferance" 
                            inManagedObjectContext:self.managedObjectContext];
            
            NSNumber *walkDistance = [NSNumber numberWithFloat:0.8];
            [toFromViewController setMaxiWalkDistance:walkDistance];
            
            [propertyInfo setValue:[NSNumber numberWithBool:YES] forKey:@"pushEnable"];
            [propertyInfo setValue:[NSNumber numberWithInt:3]    forKey:@"triggerAtHour"];
            [propertyInfo setValue:[NSNumber numberWithFloat:0.75] forKey:@"walkDistance"];
            
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            }
        }
    }@catch (NSException *exception) {
        NSLog(@"Exception: ----------------- %@", exception);
    } 
    
    // Call TestFlightApp SDK
#if !DEVELOPMENT
#ifdef TESTING
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
    [TestFlight takeOff:@"48a90a98948864a11c80bd2ecd7a7e5c_ODU5MzMyMDEyLTA1LTA3IDE5OjE3OjUwLjMxMDUyMg"];
#endif
    
    // Create an instance of a UINavigationController and put toFromViewController as the first view
    @try {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:toFromViewController]; 
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [[self window] setRootViewController:navController];
        
        [self.window makeKeyAndVisible];
    }
    @catch (NSException *exception) {
        NSLog(@"load exception: %@", exception);
    }
    return YES;
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
    timerTweeterGetData = nil;
    [timerTweeterGetData invalidate];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    [toFromViewController updateTripDate];
    [locationManager startUpdatingLocation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    saveContext([self managedObjectContext]);
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
        NSLog(@"exception at managedObjectContext delegate: %@", exception);
    }
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
        NSLog(@"exception at managedObjectModel delegate: %@", exception);
    }
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
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }    
        
        return __persistentStoreCoordinator;
    }
    @catch (NSException *exception) {
        NSLog(@"exception at persistentStoreCoordinator: %@", exception);
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
        RKClient *client = [RKClient clientWithBaseURL:TRIP_GENERATE_URL];
        [RKClient setSharedClient:client];
        [[RKClient sharedClient]  get:@"metadata" delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at requesting live supported data: %@", exception);
    }
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response 
{  
    @try {
        if ([request isGET]) {  
            NSLog(@"Got a response back from our GET! %@", [response bodyAsString]);      
            
            NSError *error = nil;
            if (error == nil)
            {
                RKJSONParserJSONKit* rkParser = [RKJSONParserJSONKit new];
                if (isTwitterLivaData) {
                    isTwitterLivaData = false;
                    NSLog(@"Responce %@", [response bodyAsString]);
                    NSDictionary  *tweeterCountParser = [rkParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [(NSDictionary*)tweeterCountParser objectForKey:@"errCode"];
                    //                NSString *allNew = [(NSDictionary*)tweeterCountParser objectForKey:@"allNew"];
                    if ([respCode intValue]== RESPONSE_SUCCESSFULL) {                   
                        NSLog(@"count: %@",[(NSDictionary*)tweeterCountParser objectForKey:TWEET_COUNT]);
                        NSString *tweeterCount = [(NSDictionary*)tweeterCountParser objectForKey:TWEET_COUNT];
                        prefs = [NSUserDefaults standardUserDefaults];  
                        [prefs setObject:tweeterCount forKey:TWEET_COUNT];
                        [prefs synchronize];
                        // Upadte automatic badge with Live tweeterCount 
                        [toFromViewController viewWillAppear:TRUE];
                        
                    }
                } else {                
                    NSDictionary  *regionParser = [rkParser objectFromString:[response bodyAsString] error:nil];                
                    SupportedRegion *region = [SupportedRegion alloc] ;
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
                    timerTweeterGetData =   [NSTimer scheduledTimerWithTimeInterval:TWEET_COUNT_POLLING_INTERVAL target:self selector:@selector(getTwiiterLiveData) userInfo:nil repeats: YES];
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at catching TPServer Response: %@", exception);
    }
}


#pragma mark Nimbler push notification

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    NSLog(@"Registering for push notifications...");    
    [[UIApplication sharedApplication] 
     registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert | 
      UIRemoteNotificationTypeBadge | 
      UIRemoteNotificationTypeSound)];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    @try {
        NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: NULL_STRING] stringByReplacingOccurrencesOfString: @">" withString: NULL_STRING] stringByReplacingOccurrencesOfString: @" " withString: @""];
        NSLog(@"deviceTokenString: %@",token);
        [UIApplication sharedApplication].applicationIconBadgeNumber = BADGE_COUNT_ZERO;
        prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:token forKey:DEVICE_TOKEN];  
        [prefs synchronize];
        [self upadateDefaultUserValue];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at registering push notification with apple: %@", exception);
    }
}


- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err { 
    @try {
        NSString *str = [NSString stringWithFormat: @"Error: %@", err];
        NSLog(@"didFail To Register For RemoteNotifications With Error: %@",str);     
        prefs = [NSUserDefaults standardUserDefaults];
        NSString  *token = @"26d906c5c273446d5f40d2c173ddd3f6869b2666b1c7afd5173d69b6629def70";
        [prefs setObject:token forKey:DEVICE_TOKEN];
        [self upadateDefaultUserValue];
        //    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler Push Alert" message:@"your device couldn't connect with apple. Please reinstall application" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        //    [alert show];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at fail to registration push notification: %@", exception);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo 
{        
    @try {
        for (id key in userInfo) {
            NSLog(@"key: %@, value: %@", key, [userInfo objectForKey:key]);
        }        
        NSString *isUrgent = [userInfo valueForKey:@"isUrgent"];
        NSString *message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
        NSString *badge = [[userInfo valueForKey:@"aps"] valueForKey:@"badge"];
        prefs = [NSUserDefaults standardUserDefaults];  
        [prefs setObject:badge forKey:TWEET_COUNT];
        if ([isUrgent isEqualToString:@"true"]) {
            UIAlertView *dataAlert = [[UIAlertView alloc] initWithTitle:@"Nimbler Caltrain"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil,nil];
            
            [dataAlert show];
            [UIApplication sharedApplication].applicationIconBadgeNumber = BADGE_COUNT_ZERO;
        } 
        else {
            [toFromViewController redirectInTwitterAtPushnotification]; 
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at push receive: %@", exception);
    }
}

-(void)alertView: (UIAlertView *)UIAlertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *btnName = [UIAlertView buttonTitleAtIndex:buttonIndex];
    if ([btnName isEqualToString:@"OK"]) {
        [toFromViewController redirectInTwitterAtPushnotification];
        NSLog(@"receive urgent message");
    }
}

#pragma mark Twitter Live count request
-(void)getTwiiterLiveData
{
    @try {
        NSLog(@"RealTimeTweets:");
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSString *udid = [UIDevice currentDevice].uniqueIdentifier;            
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                @"deviceid", udid, 
                                nil];    
        isTwitterLivaData = TRUE;
        NSString *twitCountReq = [@"advisories/count" appendQueryParams:params];
        [[RKClient sharedClient]  get:twitCountReq delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at getTwiiterLive count: %@", exception);
    }
}

#pragma mark update userSettings from server 
-(void)upadateDefaultUserValue
{
    @try {
        if ([[NSUserDefaults standardUserDefaults] valueForKey:@"UserPreferance"] == nil) {
           
            // set in TPServer
            RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
            [RKClient setSharedClient:client];
            NSString *udid = [UIDevice currentDevice].uniqueIdentifier;            
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                    @"deviceid", udid,
                                    @"alertCount", @"3",
                                    DEVICE_TOKEN, [prefs objectForKey:DEVICE_TOKEN],
                                    @"maxDistance", @"0.75",
                                    nil];    
            NSString *twitCountReq = [@"users/preferences/update" appendQueryParams:params];
            [[RKClient sharedClient]  get:twitCountReq delegate:self]; 
            
            [[NSUserDefaults standardUserDefaults] setValue:@"set" forKey:@"UserPreferance"];
            [[NSUserDefaults standardUserDefaults] synchronize];

        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception when update userSettings at appLuanch: %@",exception);
    }
}

@end