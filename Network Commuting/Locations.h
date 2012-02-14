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

@interface Locations : NSObject {
    NSArray *sortedFromLocations;
    NSArray *sortedToLocations;
    int fromRowCount;
    int toRowCount;
    NSFetchRequest *locationsFetchRequest;
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) BOOL areLocationsChanged;  // True if there have been locations added or changed

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc;
- (Location *)locationWithRawAddress:(NSString *)rawAddress;
- (NSArray *)locationsWithFormattedAddress:(NSString *)formattedAddress; // Array of matching locations
- (Location *)newEmptyLocation;
- (int)numberOfLocations:(bool)isFrom;
- (Location *)locationAtIndex:(int)index isFrom:(BOOL)isFrom;

- (Location *)consolidateWithMatchingLocations:(Location *)loc0;

// Internal methods
- (void) updateInternalCache;

@end
