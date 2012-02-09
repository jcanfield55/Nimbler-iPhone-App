//
//  ModelDataStore.h
//  Network Commuting
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Location.h"

@interface ModelDataStore : NSObject

// Properties for Core Data
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (ModelDataStore *)defaultStore;
- (BOOL)saveChanges;

- (BOOL)addLocation:(Location *)loc;
- (Location *)locationWithFormattedAddress:(NSString *)formattedAddress;
- (Location *)newEmptyLocation;
- (Location *)findEquivalentLocationTo:(Location *)loc0;
@end
