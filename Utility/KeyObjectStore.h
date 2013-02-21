//
//  KeyObjectStore.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/21/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
// Singleton wrapper class for managing the store of KeyObjectPairs in Core Data
// General Purpose CoreData storage for objects that meet NSCoding protocol
//
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KeyObjectPair.h"

@interface KeyObjectStore : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;


+ (void)setUpWithManagedObjectContext:(NSManagedObjectContext *)moc;
+ (KeyObjectStore *)keyObjectStore; // returns the singleton value
- (void)setObject:(id)obj forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
- (void)removeKeyObjectForKey:(NSString *)key;
- (void)saveToPermanentStore;   // Saves to Core Data permanent storage using ManagedObjectContext from initialization

@end
