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

@interface Locations : NSObject 

@property (strong, nonatomic) NSString *typedFromString;  // Typed string in the from field 
@property (strong, nonatomic) NSString *typedToString;    // Typed string in the to field
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property(strong, nonatomic) RKObjectManager* rkGeoMgr;  
@property (strong, nonatomic) Location* selectedFromLocation; // This location gets sorted to the top of the from list
@property (strong, nonatomic) Location* selectedToLocation; // This location gets sorted to the top of the to list
@property (nonatomic) BOOL areLocationsChanged;  // True if there have been locations added or changed
@property (nonatomic) BOOL areMatchingLocationsChanged; // True if matching location arrays has been updated (in which case view controller should refresh arrays)

@property (strong, nonatomic) NSString *rawAddressTo;
@property (strong, nonatomic) NSString *rawAddressFrom;
@property (strong, nonatomic) NSString *geoRespTo;
@property (strong, nonatomic) NSString *geoRespFrom;
@property (strong, nonatomic) NSString *geoRespTimeTo;
@property (strong, nonatomic) NSString *geoRespTimeFrom;
@property (nonatomic) BOOL isFromGeo;
@property (nonatomic) BOOL isToGeo;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkGeoMgr:(RKObjectManager *)rkG;
- (void)preLoadIfNeededFromFile:(NSString *)filename;  // Preloads locations (like Caltrain stations) from a file
- (Location *)locationWithRawAddress:(NSString *)rawAddress;
- (NSArray *)locationsWithFormattedAddress:(NSString *)formattedAddress; // Array of matching locations
- (Location *)newEmptyLocation;
- (int)numberOfLocations:(BOOL)isFrom;
- (Location *)locationAtIndex:(int)index isFrom:(BOOL)isFrom;
- (Location *)consolidateWithMatchingLocations:(Location *)loc0;
- (void)removeLocation:(Location *)loc0;  // Remove location from Core Data
- (void)updateSelectedLocation:(Location *)sL isFrom:(BOOL)isFrom;


@end
