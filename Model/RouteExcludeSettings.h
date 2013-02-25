//
//  RouteExcludeSettings.h
//  Nimbler SF
//
//  Created by John Canfield on 2/19/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//
// This class models the settings a user makes on the Route Options page to select which modes / agencies / routes they
// want to see or not see on their Route Options

#import <CoreData/CoreData.h>
#import "Plan.h"
#import "Itinerary.h"

typedef enum {
    SETTING_EXCLUDE_ROUTE, // Exclude routes of a type in the route options
    SETTING_INCLUDE_ROUTE  // Include routes of a type in the route options
} IncludeExcludeSetting;

@interface RouteExcludeSettings : NSManagedObject

@property(nonatomic, strong) NSNumber *isCurrentUserSetting; // Boolean.  True if this is the latest setting from the user
@property(nonatomic, strong) NSMutableDictionary *excludeDictionaryInternal; // For internal use.  Stored in Core Data
@property(nonatomic, strong) NSSet *usedByRequestChunks; // All OTP request chunks that used this setting to generate their itineraries

// Sets the ManagedObjectContext where RouteExcludeSettings are stored
+(void)setManagedObjectContext:(NSManagedObjectContext *)moc;

// Returns the RouteExcludeSettings that are the latest from the user.
+ (RouteExcludeSettings *)latestUserSettings;

// Changes setting associated with a key.
// If self's usedByRequestChunks is not empty, then create an archive copy that those requestChunks can still point to
// before modifying self.  The modified self will have no 
-(void)changeSettingTo:(IncludeExcludeSetting)value forKey:(NSString *)key;


// Returns the keys and values for the routes that are available in the plan relevant to the originalTripDate
// in parameters.
// Returned array containing RouteExcludeSettings objects
// Array is ordered in the sequence options should be presented to user
-(NSArray *)excludeSettingsForPlan:(Plan *)plan withParameters:(PlanRequestParameters *)parameters;

// Returns true if itin should be included based on the RouteExclude settings
-(BOOL)isItineraryIncluded:(Itinerary *)itin;

// Remove the duplicate settings
- (NSArray *) returnUniqueRouteExcludeSettings:(NSArray *)array;

-(IncludeExcludeSetting)settingForKey:(NSString *)key;

// Returns true if the receiver and settings0 have equivalent setting values
// Note: does not compare isCurrentUserSetting
-(BOOL)isEquivalentTo:(RouteExcludeSettings *)settings0;

// Used for automated tests to clear out any old static latestUserSettings variable
+(void)clearLatestUserSettings;

@end