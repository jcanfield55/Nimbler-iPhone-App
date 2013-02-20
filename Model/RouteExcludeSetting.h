//
//  RouteExcludeSetting.h
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

@interface RouteExcludeSetting : NSObject

@property(nonatomic, strong) NSString* key;
@property(nonatomic) IncludeExcludeSetting setting;

+ (RouteExcludeSetting *)routeExcludeSetting;
// Changes setting associated with a key
-(void)changeSettingTo:(IncludeExcludeSetting)value forKey:(NSString *)key;

// Returns the keys and values for the routes that are available in the plan
// Returned array containing RouteExcludeSetting objects
// Array is ordered in the sequence options should be presented to user
-(NSArray *)excludeSettingsForPlan:(Plan *)plan;

// Returns true if itin should be included based on the RouteExclude settings
-(BOOL)isItineraryIncluded:(Itinerary *)itin;

// Remove the duplicate settings
- (NSArray *) returnUniqueRouteExcludeSetting:(NSArray *)array;
-(IncludeExcludeSetting)settingForKey:(NSString *)key;
@end