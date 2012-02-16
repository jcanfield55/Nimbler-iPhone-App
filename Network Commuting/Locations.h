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

    NSArray *sortedMatchingFromLocations; // All from locations that somehow match the typedFromString
    int matchingFromRowCount;  // Count of from locations (including frequency=0) that match the typedFromString
    NSArray *sortedMatchingToLocations;
    int matchingToRowCount;
    NSArray *sortedFromLocations;  // All locations sorted by from frequency
    NSArray *sortedToLocations;    // All locations sorted by to frequency
    int fromRowCount;  // Row count excluding frequency=0 locations
    int toRowCount;    // Row count excluding frequency=0 locations
    NSFetchRequest *locationsFetchRequest;
}

@property (strong, nonatomic) NSString *typedFromString;  // Typed string in the from field 
@property (strong, nonatomic) NSString *typedToString;    // Typed string in the to field
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) BOOL areLocationsChanged;  // True if there have been locations added or changed
@property (nonatomic) BOOL areMatchingLocationsChanged; // True if matching location arrays has been updated (in which case view controller should refresh arrays)

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc;
- (Location *)locationWithRawAddress:(NSString *)rawAddress;
- (NSArray *)locationsWithFormattedAddress:(NSString *)formattedAddress; // Array of matching locations
- (Location *)newEmptyLocation;
- (int)numberOfLocations:(BOOL)isFrom;
- (Location *)locationAtIndex:(int)index isFrom:(BOOL)isFrom;

- (Location *)consolidateWithMatchingLocations:(Location *)loc0;

// Internal methods
- (void) updateInternalCache;

@end
