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

@interface nc_AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate> {
    Location* currentLocation;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;

@property (readonly, strong, nonatomic) Locations *locations;
@property (readonly, strong, nonatomic) ToFromViewController *toFromViewController;
@property (readonly, strong, nonatomic) CLLocationManager* locationManager;

// Properties for Core Data
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;

@end
