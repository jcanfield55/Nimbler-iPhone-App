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


#define TESTING 1  // If 1, then testFlightApp will collect device UIDs, if 0, it will not
#define DEVELOPMENT 1  // If 1, then do not include testFlightApp at all (don't need crash report while developing)

BOOL isTwitterLivaData = FALSE; 

@implementation nc_AppDelegate

@synthesize locations;
@synthesize locationManager;
@synthesize toFromViewController;
@synthesize feedbackView;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize window = _window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
   [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
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
        
        
        [self bayArea];
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
        [locations preLoadIfNeededFromFile:@"caltrain-station.json"];
        
        
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
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:toFromViewController]; 
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [[self window] setRootViewController:navController];

    [self.window makeKeyAndVisible];
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

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Network_Commuting" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
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

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

-(void)bayArea
{    

    RKClient *client = [RKClient clientWithBaseURL:@"http://23.23.210.156:8080/opentripplanner-api-webapp/ws/"];
    [RKClient setSharedClient:client];
    [[RKClient sharedClient]  get:@"metadata" delegate:self];
  
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    
    if ([request isGET]) {  
        NSLog(@"Got aresponse back from our GET! %@", [response bodyAsString]);      
                   
            NSError *error = nil;
            if (error == nil)
            {
                RKJSONParserJSONKit* rkParser = [RKJSONParserJSONKit new];
                if (isTwitterLivaData) {
//                    id  res = [rkParser objectFromString:[response bodyAsString] error:nil];
                    

                } else {
                    
                    NSDictionary  *regionParser = [rkParser objectFromString:[response bodyAsString] error:nil];                
                    SupportedRegion *region = [SupportedRegion alloc] ;
                    for (id key in regionParser) {
                        if ([key isEqualToString:@"upperRightLatitude"]) {
                            [region setUpperRightLatitude:[regionParser objectForKey:key] ];
                        } else if ([key isEqualToString:@"upperRightLongitude"]){
                            [region setUpperRightLongitude:[regionParser objectForKey:key] ];
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
                }
            }
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
    
    NSString *str = [NSString stringWithFormat:@"Device Token=%@",deviceToken];
    NSLog(@" %@",str); 
    
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];
    NSLog(@"DeviceTokenStr: %@",token);
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:token forKey:@"deviceToken"];
    
}


- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err { 
    NSString *str = [NSString stringWithFormat: @"Error: %@", err];
    NSLog(@" %@",str);        
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {    
    for (id key in userInfo) {
        
        NSLog(@"key: %@, value: %@", key, [userInfo objectForKey:key]);
        NSString *message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
        UIAlertView *dataAlert = [[UIAlertView alloc] initWithTitle:@"Nimbler Caltrain"
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Show Twits"
                                                  otherButtonTitles:@"No",nil];
        
        [dataAlert show];      
    }        
}


-(void)alertView: (UIAlertView *)UIAlertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *btnName = [UIAlertView buttonTitleAtIndex:buttonIndex];
    
    if ([btnName isEqualToString:@"No"]) {
        
    } else if ([btnName isEqualToString:@"Show Twits"]) {
        @try {
            TwitterSearch *twitter_search = [[TwitterSearch alloc] init];
            [[self.window.rootViewController navigationController] pushViewController:twitter_search animated:YES];
            [twitter_search loadRequest:CALTRAIN_TWITTER_URL];
        }
        @catch (NSException *exception) {
            NSLog(@" twitter page execution error: %@", exception);
        }
    } 
}

-(void)getTwiiterLiveData
{
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    [RKClient setSharedClient:client];
    isTwitterLivaData = TRUE;
    [[RKClient sharedClient]  get:@"advisories/all" delegate:self];
    
}

@end
