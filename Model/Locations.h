//
//  Locations.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/10/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
// This object is a wrapper for access and manipulating the set of Location managed objects
// in the application

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "Location.h"
#import "LocationFromIOS.h"
#import "LocationFromGoogle.h"
#import "GeocodeRequestParameters.h"
#import "LocationFromLocalSearch.h"

// Callback protocol used for objects calling geocoder methods
@protocol LocationsGeocodeResultsDelegate

@required
/**
 * Returns an array of locations from the geocoder (could be empty) and a status code.
 * Also supplies the parameters used for the original request
 */
-(void)newGeocodeResults:(NSArray *)locationArray withStatus:(GeocodeRequestStatus)status parameters:(GeocodeRequestParameters *)parameters;

@end


@interface Locations : NSObject <RKObjectLoaderDelegate,CLLocationManagerDelegate>

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
@property (strong, nonatomic) NSString *geoRespTimeTo;
@property (strong, nonatomic) NSString *geoRespTimeFrom;
@property (nonatomic) BOOL isFromGeo;
@property (nonatomic) BOOL isToGeo;
@property (nonatomic) BOOL isLocationServiceEnable;
@property (nonatomic) BOOL isLocationSelected;

@property (nonatomic , strong) Location *tempSelectedFromLocation;
@property (nonatomic , strong) Location *tempSelectedToLocation;
@property (nonatomic , strong) NSArray *sortedMatchingFromLocations;
@property (nonatomic , strong) NSArray *sortedMatchingToLocations;
@property (nonatomic) int matchingFromRowCount;
@property (nonatomic) int matchingToRowCount;
@property (nonatomic, strong)  NSArray *searchableFromLocations;
@property (nonatomic, strong)  NSArray *searchableToLocations;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkGeoMgr:(RKObjectManager *)rkG;

// Preloads locations (like Caltrain stations) from a file.  testAddress is a formatted address of a station name that it can test whether the stored version is up-to-date
- (BOOL)preLoadIfNeededFromFile:(NSString *)filename latestVersionNumber:(NSDecimalNumber *)newVersion testAddress:(NSString *)testAddress;

// Returns a sorted array of all locations whose memberOfList field starts with listNamePrefix.  
// Array is sorted in alphabetical order by the memberOfList field (i.e. by everything after the prefix)
// If no matches, returns an empty array
- (NSArray *)locationsMembersOfList:(NSString *)listNamePrefix;

- (Location *)locationWithRawAddress:(NSString *)rawAddress;
- (NSArray *)locationsWithFormattedAddress:(NSString *)formattedAddress; // Array of matching locations
- (NSArray *)locationsWithLocationName:(NSString *)locationName;
- (Location *)newEmptyLocation;
- (LocationFromGoogle *)newEmptyLocationFromGoogle;
- (LocationFromIOS *)newLocationFromIOSWithPlacemark:(CLPlacemark *)placemark error:(NSError *)error; // set error==nil if status is OK
//Add selected Local Search Result to Location and remove from LocationFromLocalSearch
-(LocationFromIOS *)selectedLocationOfLocalSearchWithLocation:(LocationFromLocalSearch *)localSearchLocation IsFrom:(BOOL)isFrom error:(NSError *)error;
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

// Geocoding functions

// Requests a forward geocode with the supplied rawAddress, apiType, supportedRegion and isFrom in the parameters
// Calls the newGeocodeResults of the delegate object with the results and status. 
- (void)forwardGeocodeWithParameters:(GeocodeRequestParameters *)parameters callBack:(id <LocationsGeocodeResultsDelegate>)delegate;

// Requests a reverse geocode using the lat, lng, and apiType specified in parameters
// Calls the newGeocodeResults of the delegate object with the results and status.  
- (void)reverseGeocodeWithParameters:(GeocodeRequestParameters *)parameters callBack:(id <LocationsGeocodeResultsDelegate>)delegate;

// Station Search From Json Files.
- (NSString *)rawAddressWithOutAgencyName:(NSArray *)searchStringsArray
                      replaceStringsArray:(NSArray *)replaceStringsArray
                                  address:(NSString *)address;

//- (NSArray *)searchedStationsFromRawAddress:(NSString *)address
//                         searchStringsArray:(NSArray *)searchStringsArray
//                        replaceStringsArray:(NSArray *)replaceStringsArray
//                     agencyNameNotToInclude:(NSString *)agencyNameNotToInclude;

- (NSString *) rawAddressWithOutAgencyName:(NSString *)address SearchStringArray:(NSArray *)searchStringArray;

// Returns an array of Location objects that are created based on matches to PreloadStations
// A pre-load station matches when each typed token has a substring match with the preloadStation name
- (NSArray *) preloadStationLocationsMatchingTypedAddress:(NSString *)string;

// Local Search
- (void)setTypedFromStringForLocalSearch:(NSString *)typedFromStr0;
- (void)setTypedToStringForLocalSearch:(NSString *)typedToStr0;

- (LocationFromLocalSearch *)newLocationFromIOSWithPlacemark:(CLPlacemark *)placemark error:(NSError *)error IsLocalSearchResult:(BOOL) isLocalSearchResult locationName:(NSString *)locationName;

// Check in database for exact lat lng match
- (NSArray *) locationsWithLat:(double)lat Lng:(double)lng;

// fetch matching location from searchableFromLocations or searchableToLocations array using matching lat lng.
- (NSArray *) locationsWithLat:(double)lat Lng:(double)lng FromArray:(NSArray *)array;

// Fetch Searchable from and to locations from DB if required.
- (void) fetchSearchableLocations;
@end
