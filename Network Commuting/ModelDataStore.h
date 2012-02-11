//
//  ModelDataStore.h
//  Network Commuting
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
@class Locations;

@interface ModelDataStore : NSObject

// Properties for Core Data
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) Locations *locations; // Class managing collection of Locations objects

+ (ModelDataStore *)defaultStore;
- (BOOL)saveChanges;

@end
