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

// Initiatializes (if needed) and returns dictionary mapping agency button names to how we will handle
// BY_AGENCY means we will show just one include/exclude button for that agency
// BY_RAIL_BUS means we will show up to two buttons for that agency, one for rail and one for bus service
+(NSDictionary *)agencyButtonHandlingDictionary;

// Changes setting associated with a key.
// If self's usedByRequestChunks is not empty, then create an archive copy that those requestChunks can still point to
// before modifying self.  The modified self will have no 
-(void)changeSettingTo:(IncludeExcludeSetting)value forKey:(NSString *)key;

// Returns the keys and values for the routes that are available in the plan relevant to the originalTripDate
// in parameters.
// Returned array containing RouteExcludeSetting objects
// Array is ordered in the sequence options should be presented to user
-(NSArray *)excludeSettingsForPlan:(Plan *)plan;

// Returns an array of RouteExcludeSetting objects with everything default except has the specified bikeSetting
+(NSArray *)arrayWithNoExcludesExceptExcludeBike:(IncludeExcludeSetting)bikeSetting;

// Generates the bannedAgencyString which can be passed to OTP for any agency-wide excludes
// settingArray is an array of RouteExcludeSetting objects returned by excludeSettingsForPlan method
-(NSString *)bannedAgencyStringForSettingArray:(NSArray *)settingArray;

// Generates the bannedAgencyByModeString which can be passed to OTP for any agency-wide excludes
// settingArray is an array of RouteExcludeSetting objects returned by excludeSettingsForPlan method
-(NSString *)bannedAgencyByModeStringForSettingArray:(NSArray *)settingArray;

// Creates a new RouteExcludeSettings using the values in settingArray.
// settingArray is created by excludeSettingsForPlan method
+(RouteExcludeSettings *)excludeSettingsWithSettingArray:(NSArray *)settingArray;

// Creates a string showing the values in the settingArray (can be used for logging)
// settingArray is created by excludeSettingsForPlan method
+(NSString *)stringFromSettingArray:(NSArray *)settingArray;

// Returns true if self contains the default settings (the equivalent of a nil exclude)
// This means no excludes except for Bike mode exclude
-(BOOL)isDefaultSettings;

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