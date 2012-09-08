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
@property (nonatomic) BOOL isLocationServiceEnable;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkGeoMgr:(RKObjectManager *)rkG;
- (BOOL)preLoadIfNeededFromFile:(NSString *)filename latestVersionNumber:(NSDecimalNumber *)version;  // Preloads locations (like Caltrain stations) from a file

// Returns a sorted array of all locations whose memberOfList field starts with listNamePrefix.  
// Array is sorted in alphabetical order by the memberOfList field (i.e. by everything after the prefix)
// If no matches, returns an empty array
- (NSArray *)locationsMembersOfList:(NSString *)listNamePrefix;

- (Location *)locationWithRawAddress:(NSString *)rawAddress;
- (NSArray *)locationsWithFormattedAddress:(NSString *)formattedAddress; // Array of matching locations
- (Location *)newEmptyLocation;
- (int)numberOfLocations:(BOOL)isFrom;
- (Location *)locationAtIndex:(int)index isFrom:(BOOL)isFrom;

// Takes loc0 (typically a newly geocoded location) and see if there are any equivalent locations
// already in the Location store.  If so, then consolidate the two locations so there is only one left.
// If keepThisLocation is true, keeps loc0 and deletes the duplicate in the database, otherwise keeps
// the one in the database and deletes loc0.  
// To consolidate, combines the rawAddress strings and adds the to&from frequencies.    
// Returns a location -- either the original loc0 if there is no matching location, or 
// the consolidated matching location if there is one.
- (Location *)consolidateWithMatchingLocations:(Location *)loc0 keepThisLocation:(BOOL)keepThisLocation;

- (void)removeLocation:(Location *)loc0;  // Remove location from Core Data
- (void)updateSelectedLocation:(Location *)sL isFrom:(BOOL)isFrom;


@end
