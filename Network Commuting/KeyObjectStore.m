//
//  KeyObjectStore.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/21/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
// Wrapper class for managing the store of KeyObjectPairs in Core Data
// General Purpose CoreData storage for objects that meet NSCoding protocol
//
#import "KeyObjectStore.h"

@interface KeyObjectStore()

// Internal methods
- (KeyObjectPair *)keyObjectPairForKey:(NSString *)key;
@end

@implementation KeyObjectStore

@synthesize managedObjectContext;
@synthesize managedObjectModel;

static KeyObjectStore* keyObjectStoreSingleton;

// Required to call before using class
+ (void)setUpWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    if (!keyObjectStoreSingleton) {
        keyObjectStoreSingleton = [[KeyObjectStore alloc] init];
    }
    [keyObjectStoreSingleton setManagedObjectContext:moc];
    [keyObjectStoreSingleton setManagedObjectModel:[[moc persistentStoreCoordinator] managedObjectModel]];
}

// returns the singleton value.  Note must call setUpWithManagedObjectContext first
+ (KeyObjectStore *)keyObjectStore
{
    if (!keyObjectStoreSingleton) {
        keyObjectStoreSingleton = [[KeyObjectStore alloc] init];
    }
    return keyObjectStoreSingleton;
}

- (void)setObject:(id)obj forKey:(NSString *)key
{
    KeyObjectPair* pair = [self keyObjectPairForKey:key];
    if (pair) { // If there already is a pair
        [pair setObject:obj];  // update the object to the new value
    }
    else { // else create a new object and set the key & object
        pair = [NSEntityDescription insertNewObjectForEntityForName:@"KeyObjectPair" inManagedObjectContext:managedObjectContext];
        [pair setKey:key];
        [pair setObject:obj];
    }
}

- (id)objectForKey:(NSString *)key {
    return [[self keyObjectPairForKey:key] object];
}

- (KeyObjectPair *)keyObjectPairForKey:(NSString *)key
{
    if (!key || [key length] == 0) {
        return nil;
    }
    NSFetchRequest *request = [managedObjectModel fetchRequestFromTemplateWithName:@"KeyObjectPairForKey" substitutionVariables:[NSDictionary dictionaryWithObject:key forKey:@"KEY"]];
    
    NSError *error;
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error];
    if (!result) {
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]];
    }
    if ([result count] == 0) {
        return nil;   // No matches
    } else if ([result count] == 1) {
        return [result objectAtIndex:0];
    } else {
        NSLog(@"KeyObjectStore: unexpected multiple objects found for Key = '%@'", key);
        return [result objectAtIndex:0];   // Return just the first one
    }
}

// Remove KeyObjectPair with key from Core Data
- (void)removeKeyObjectForKey:(NSString *)key
{
    KeyObjectPair* pair = [self keyObjectPairForKey:key];
    if (pair) {  // if there is a match, delete it
        [managedObjectContext deleteObject:pair];
    }
}

@end
