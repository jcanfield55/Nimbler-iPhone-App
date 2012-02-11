//
//  ModelDataStore.m
//  Network Commuting
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//


// ModelDataStore is a singleton for managing the CoreData for all the model tables (in particular Locations and Itineraries).  

#import "ModelDataStore.h"
#import "UtilityFunctions.h"
#import "Locations.h"

static ModelDataStore *defaultStore = nil;

@implementation ModelDataStore

@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize locations;

+ (ModelDataStore *)defaultStore
{
    if (!defaultStore) {
        // Create the singleton
        defaultStore = [[super allocWithZone:NULL] init];
    }
    return defaultStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self defaultStore];
}

- (id)init
{
    if (defaultStore) {
        return defaultStore;
    }
    
    self = [super init];
    if (self) {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        NSString *path = pathInDocumentDirectory(@"store.data");
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        
        NSError *error = nil;
        
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            [NSException raise:@"Data store open failed" format:@"Reason %@", [error localizedDescription]];
        }
        
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:psc];
        [managedObjectContext setUndoManager:nil];
    }
    return self;
}

- (BOOL)saveChanges
{
    NSError *err = nil;
    BOOL successful = [managedObjectContext save:&err];
    if (!successful) {
        NSLog(@"Error saving: %@", [err localizedDescription]);
    }
    return successful;
}

@end