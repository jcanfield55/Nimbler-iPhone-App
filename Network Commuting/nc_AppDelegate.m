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
#import "JSONKit.h"

#define TESTING 1  // If 1, then testFlightApp will collect device UIDs, if 0, it will not
#define DEVELOPMENT 1  // If 1, then do not include testFlightApp at all (don't need crash report)

@implementation nc_AppDelegate

@synthesize locations;
@synthesize locationManager;
@synthesize toFromViewController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize window = _window;
@synthesize rkbatarea;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
   
    // Configure the RestKit RKClient object for Geocoding and trip planning
    RKObjectManager* rk_geo_mgr = [RKObjectManager objectManagerWithBaseURL:@"http://maps.googleapis.com/maps/api/geocode/"];
    // Trimet base URL is http://rtp.trimet.org/opentripplanner-api-webapp/ws/
    //RKObjectManager* rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:@"http://ec2-107-21-80-36.compute-1.amazonaws.com:8080/opentripplanner-api-webapp/ws/"];
     RKObjectManager* rkPlanMgr = [RKObjectManager objectManagerWithBaseURL:@"http://ec2-204-236-191-166.us-west-1.compute.amazonaws.com:8080/opentripplanner-api-webapp/ws/"];
    
    rkbatarea = [RKObjectManager objectManagerWithBaseURL:@"http://ec2-107-21-80-36.compute-1.amazonaws.com:8080/opentripplanner-api-webapp/ws/metadata"];
    
        
    // Other URLs:
    // Trimet base URL is http://rtp.trimet.org/opentripplanner-api-webapp/ws/
    // NY City demo URL is http://demo.opentripplanner.org/opentripplanner-api-webapp/ws/
    
    // Add the CoreData managed object store
    RKManagedObjectStore *rkMOS;
    @try {
       rkMOS = [RKManagedObjectStore objectStoreWithStoreFilename:@"store.data"];
        [rk_geo_mgr setObjectStore:rkMOS];
        [rkPlanMgr setObjectStore:rkMOS];
        [rkbatarea setObjectStore:rkMOS];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception:");
    }
    
     [self bayArea];
    // Get the NSManagedObjectContext from restkit
    __managedObjectContext = [rkMOS managedObjectContext];
    
    // Create initial view controller 
    toFromViewController = [[ToFromViewController alloc] initWithNibName:nil bundle:nil];
    [toFromViewController setRkGeoMgr:rk_geo_mgr];    // Pass the geocoding RK object
    [toFromViewController setRkPlanMgr:rkPlanMgr];    // Pass the planning RK object
    [toFromViewController setRkBayArea:rkbatarea];    // pass the bayArea Rk objects
    
    // Turn on location manager
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [locationManager startUpdatingLocation];
    
    // Initialize the Locations class and store "Current Location" into the database if not there already
    locations = [[Locations alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [toFromViewController setLocations:locations];
     [toFromViewController setLocations:locations];
        
    // Call TestFlightApp SDK
#if !DEVELOPMENT
    [TestFlight takeOff:@"48a90a98948864a11c80bd2ecd7a7e5c_ODU5MzMyMDEyLTA1LTA3IDE5OjE3OjUwLjMxMDUyMg"];

#ifdef TESTING
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
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
            [currentLocation setFromFrequencyInt:100];
            [toFromViewController setCurrentLocation:currentLocation];
        }
        else {
            currentLocation = [matchingLocations objectAtIndex:0];
        }
    }

    [currentLocation setLatFloat:[newLocation coordinate].latitude];
    [currentLocation setLngFloat:[newLocation coordinate].longitude];
   
    //TODO error handling if location services not available
    //TODO error handling if current location is in the database, but not populated
    //TODO error handling for very old cached current location data
    //TODO adjust frequency if needed
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
    //http://ec2-107-21-80-36.compute-1.amazonaws.com:8080/opentripplanner-api-webapp/ws/metadata"
        
    NSString *urlString = [NSString stringWithFormat:@"http://ec2-204-236-191-166.us-west-1.compute.amazonaws.com:8080/opentripplanner-api-webapp/ws/metadata?output=xml"];   
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *locationString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil]; 
    NSLog(@"Full String: %@", locationString);
    
    locationString = [locationString stringByReplacingOccurrencesOfString:@"{\""
                                         withString:@""];
    locationString = [locationString stringByReplacingOccurrencesOfString:@"\":"
                                                               withString:@","];
    locationString = [locationString stringByReplacingOccurrencesOfString:@"\""
                                                               withString:@""];
    locationString = [locationString stringByReplacingOccurrencesOfString:@"}"
                                                               withString:@""];
    NSLog(@"klj %@", locationString);
       
    NSArray *srtreets = [locationString componentsSeparatedByString:@","];
    NSLog(@" kjgh %@", srtreets);
    
    
      
    for (int i =0;i<[srtreets count]; i++) {
       NSLog(@"%d : %@",i, [srtreets objectAtIndex:i]);
    }
     
    bayArea *b = [bayArea alloc] ;
    [b setLowerLeftLatitude:[srtreets objectAtIndex:1] ];
    [b setLowerLeftLongitude:[srtreets objectAtIndex:3]];
    [b setMaxLatitude:[srtreets objectAtIndex:5]];
    [b setMaxLongitude:[srtreets objectAtIndex:7]];
    [b setMinLatitude:[srtreets objectAtIndex:16]];
    [b setMinLongitude:[srtreets objectAtIndex:18]];
    [b setUpperRightLatitude:[srtreets objectAtIndex:20]];
    [b setUpperRightLatitude:[srtreets objectAtIndex:22]];
       
    NSLog(@"real %@", b);
    ToFromViewController *l = [[ToFromViewController alloc] initWithNibName:nil bundle:nil];
   
    [l setBayArea:b];
    // Tell NSXMLParser that this class is its delegate
   // [parser selfDelegate:self];
    
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    
}
@end
