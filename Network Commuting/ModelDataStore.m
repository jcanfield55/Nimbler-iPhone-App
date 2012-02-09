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

static ModelDataStore *defaultStore = nil;

@implementation ModelDataStore

@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;

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

- (Location *)newEmptyLocation 
{
    Location *l = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
    return l;
}

// Adds a new location object to the Locations table
- (BOOL)addLocation:(Location *)loc 
{
    // TODO add ability to add a location
    return YES;
}

// Returns first location that has an exact match for formattedAddress
- (Location *)locationWithFormattedAddress:(NSString *)formattedAddress
{
    NSFetchRequest *request = [managedObjectModel fetchRequestFromTemplateWithName:@"LocationByFormattedAddress" substitutionVariables:[NSDictionary dictionaryWithObject:formattedAddress forKey:@"ADDRESS2"]];

    
/*  Alternate code not using the FetchRequestTemplate  
 NSExpression *lhs = [NSExpression expressionForKeyPath:@"formattedAddress"];
    NSExpression *rhs = [NSExpression expressionForConstantValue:formattedAddress];
    NSPredicate *predicate = [NSComparisonPredicate
                                         predicateWithLeftExpression:lhs
                                         rightExpression:rhs
                                         modifier:NSDirectPredicateModifier
                                         type:NSEqualToPredicateOperatorType
                                         options:0];
    NSEntityDescription *e = [[managedObjectModel entitiesByName] objectForKey:@"Location"];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:e];
    [request setPredicate:predicate];
*/    
    
    NSLog(@"Fetch predicate: %@", [request predicate]);
    NSError *error; 
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error]; 
    if (!result) { 
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]]; 
    }
    if ([result count]>=1) {            // if there is a match
        return [result objectAtIndex:0];  // Return the first object
    }
    else {
        return nil;   // return nil if no matching Location
    }
}

// Finds locations in Locations table that have the same Formatted Address string at Loc0
- (Location *)findEquivalentLocationTo:(Location *)loc0
{
    return [self locationWithFormattedAddress:[loc0 formattedAddress]];  
}
@end
