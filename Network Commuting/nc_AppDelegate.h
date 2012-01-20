//
//  nc_AppDelegate.h
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/Restkit.h>

@interface nc_AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic, readonly) NSMutableDictionary *locations; // dictionary of all locations used, formattedAddress is the key

// Properties for Core Data
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
