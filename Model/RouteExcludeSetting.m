//
//  RouteExcludeSetting.m
//  Nimbler SF
//
//  Created by John Canfield on 2/19/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//
// This class models the settings a user makes on the Route Options page to select which modes / agencies / routes they
// want to see or not see on their Route Options

#import "RouteExcludeSetting.h"
#import "KeyObjectStore.h"
#import "Leg.h"
#import "RouteExcludeSetting.h"
#import "UtilityFunctions.h"

#define BY_AGENCY @"By Agency"
#define BY_RAIL_BUS  @"By Rail/Bus"
#define SETTING_STRING_INCLUDE @"Include"
#define SETTING_STRING_EXCLUDE @"Exclude"

@interface RouteExcludeSetting() {
    NSMutableDictionary *excludeDictionaryInternal;
    NSDictionary *agencyIDHandlingDictionaryInternal;
}

-(NSDictionary *)agencyIDHandlingDictionary;
-(NSMutableDictionary *)excludeDictionary;

@end


@implementation RouteExcludeSetting

@synthesize key;
@synthesize setting;

static RouteExcludeSetting *routeExcludeSetting;

+ (RouteExcludeSetting *)routeExcludeSetting{
    if(!routeExcludeSetting){
        routeExcludeSetting = [[RouteExcludeSetting alloc] init];
    }
    return routeExcludeSetting;
}

// Initiatializes (if needed) and returns dictionary mapping agencyIDs to how we will handle
// BY_AGENCY means we will show just one include/exclude button for that agency
// BY_RAIL_BUS means we will show up to two buttons for that agency, one for rail and one for bus service
-(NSDictionary *)agencyIDHandlingDictionary{
        if (!agencyIDHandlingDictionaryInternal) {
               agencyIDHandlingDictionaryInternal = [NSDictionary dictionaryWithKeysAndObjects:CALTRAIN_BUTTON, BY_AGENCY,BART_BUTTON, BY_AGENCY,// AIRBART, BY_AGENCY,
                                                     MUNI_BUTTON, BY_RAIL_BUS,
                                                    ACTRANSIT_BUTTON, BY_AGENCY,
                                                   // VTA, BY_RAIL_BUS,
                                                   // FERRIES, BY_AGENCY,
                                                  // MENLO_MIDDAY, BY_AGENCY,
                                                nil];
        // TODO -- make sure that these constants match the agency strings returned from the leg Agency_ID field
        }
        return agencyIDHandlingDictionaryInternal;
}


// Returns the main dictionary storing include / exclude settings
-(NSMutableDictionary *)excludeDictionary
{
        if (!excludeDictionaryInternal) {
               excludeDictionaryInternal = [[KeyObjectStore keyObjectStore] objectForKey:EXCLUDE_SETTINGS_DICTIONARY];
                if (!excludeDictionaryInternal) {
                        excludeDictionaryInternal = [[NSMutableDictionary alloc] initWithCapacity:20];
                    [excludeDictionaryInternal setObject:SETTING_STRING_EXCLUDE forKey:BIKE_MODE];
                }
               [[KeyObjectStore keyObjectStore] setObject:[self excludeDictionary] forKey:EXCLUDE_SETTINGS_DICTIONARY];
        }
       return excludeDictionaryInternal;
}

// Returns setting for a particular key.  If key is not in dictionary, returns INCLUDE
-(IncludeExcludeSetting)settingForKey:(NSString *)key {
        NSString* settingString = [[self excludeDictionary] objectForKey:key];
    NSLog(@"%@",key);
    NSLog(@"%@",settingString);
        if (settingString && [settingString isEqualToString:SETTING_STRING_EXCLUDE]) {
               return SETTING_EXCLUDE_ROUTE;
        } else {
                return SETTING_INCLUDE_ROUTE;  // if setting not in dictionary, default to "Include"
        }
}


// Changes setting associated with a key
-(void)changeSettingTo:(IncludeExcludeSetting)value forKey:(NSString *)key
{
       if (key) {
           NSString* setting = ((value == SETTING_EXCLUDE_ROUTE) ? SETTING_STRING_EXCLUDE : SETTING_STRING_INCLUDE);
           [[self excludeDictionary] setObject:setting forKey:key];
           // Store in database
           [[KeyObjectStore keyObjectStore] setObject:[self excludeDictionary] forKey:EXCLUDE_SETTINGS_DICTIONARY];
       }
}


// Returns the keys and values for the routes that are available in the plan
// Returned array containing RouteExcludeSetting objects
// Array is ordered in the sequence options should be presented to user
-(NSArray *)excludeSettingsForPlan:(Plan *)plan{
        NSMutableArray* returnArray = [[NSMutableArray alloc] initWithCapacity:10];
        for (Itinerary* itin in [plan itineraries]) {
                for (Leg* leg in [itin legs]) {
                    RouteExcludeSetting* routeExclSetting = [[RouteExcludeSetting alloc] init];
                        if (leg.isScheduled && returnShortAgencyName(leg.agencyName)) {       // TODO  should we compare agencyID or agencyName?
                                NSString* handling = [[self agencyIDHandlingDictionary] objectForKey:returnShortAgencyName(leg.agencyName)];
                                if (handling) {
                                       if ([handling isEqualToString:BY_AGENCY]) {
                                                routeExclSetting.key = returnShortAgencyName(leg.agencyName);
                        
                                            } else {  // BY_RAIL_BUS
                                                   NSString *railOrBus = (leg.isBus ? @"Bus" : @"Rail");
                                                   routeExclSetting.key = [NSString stringWithFormat:@"%@ %@", returnShortAgencyName(leg.agencyName), railOrBus];
                                                }
                                        routeExclSetting.setting = [self settingForKey:routeExclSetting.key];
                                    [returnArray addObject:routeExclSetting];
                                   } // else agency not in handling dictionary, do not generate button
                           }  // else no agency name, do not generate button
                   }
            }
    
       // Add bike button
       RouteExcludeSetting* routeExclSetting = [[RouteExcludeSetting alloc] init];
       routeExclSetting.key = BIKE_MODE;
       routeExclSetting.setting = [self settingForKey:BIKE_MODE];
       [returnArray addObject:routeExclSetting];
        return [self returnUniqueRouteExcludeSetting:returnArray];
    }

// Returns true if itin should be included based on the RouteExclude settings
-(BOOL)isItineraryIncluded:(Itinerary *)itin
{
       for (Leg* leg in [itin legs]) {
           NSString* key = nil;
           if (leg.isWalk && [self settingForKey:BIKE_MODE]==SETTING_INCLUDE_ROUTE) {
               return false; // exclude all walk itineraries if we are in bike mode
           }
           else if (leg.isBike && [self settingForKey:BIKE_MODE]==SETTING_EXCLUDE_ROUTE) { // TODO double-check isBike method
               return false; // Exclude bike itinerary if BIKE_MODE excluded
           }
           if (returnShortAgencyName(leg.agencyName)) {       // TODO  should we compare agencyID or agencyName?
               NSString* handling = [[self agencyIDHandlingDictionary] objectForKey:returnShortAgencyName(leg.agencyName)];
               if (handling) {
                   if ([handling isEqualToString:BY_AGENCY]) {
                       key = returnShortAgencyName(leg.agencyName);
                   } else {  // BY_RAIL_BUS
                       NSString *railOrBus = (leg.isBus ? @"Bus" : @"Rail");
                       key = [NSString stringWithFormat:@"%@ %@", returnShortAgencyName(leg.agencyName), railOrBus];
                   }
                   if ([self settingForKey:key] == SETTING_EXCLUDE_ROUTE) {
                       return false;
                   }
               } // else agency not in handling dictionary, count as include
           }  // else no agency name, do not generate button
       }
    return true;
}

- (NSArray *) returnUniqueRouteExcludeSetting:(NSArray *)array{
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:array];
    for(int i=0;i<[mutableArray count];i++){
        for(int j=i+1;j<[mutableArray count];j++){
            RouteExcludeSetting *setting1 = [mutableArray objectAtIndex:i];
            RouteExcludeSetting *setting2 = [mutableArray objectAtIndex:j];
            if([setting1.key isEqualToString:setting2.key]){
                [mutableArray removeObject:setting2];
                i = i-1;
                break;
            }
        }
    }
    return mutableArray;
}
@end