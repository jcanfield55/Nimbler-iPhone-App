//
//  Locations.h
//  Network Commuting
//
//  Created by John Canfield on 2/10/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
// This object is a wrapper for access and manipulating the set of Location managed objects
// in the application

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "Location.h"
@class ModelDataStore;

@interface Locations : NSObject

@property (nonatomic, unsafe_unretained) ModelDataStore *modelDataStore;
@property (nonatomic, strong) RKObjectManager *rkObjectManager;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

- (id)initWithRKObjectManager:(RKObjectManager *)rko modelDataStore:(ModelDataStore *)mds;
- (Location *)locationWithRawAddress:(NSString *)rawAddress;
- (Location *)locationWithFormattedAddress:(NSString *)formattedAddress;
- (Location *)newEmptyLocation;
- (Location *)findEquivalentLocationTo:(Location *)loc0;
- (Location *)consolidateWithMatchingLocations:(Location *)loc0;

@end
