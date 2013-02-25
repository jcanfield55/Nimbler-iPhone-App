//
//  RouteExcludeSettings.m
//  Nimbler SF
//
//  Created by John Canfield on 2/19/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//
// This class models the settings a user makes on the Route Options page to select which modes / agencies / routes they
// want to see or not see on their Route Options

#import "RouteExcludeSettings.h"
#import "Leg.h"
#import "RouteExcludeSetting.h"
#import "UtilityFunctions.h"

#define BY_AGENCY @"By Agency"
#define BY_RAIL_BUS  @"By Rail/Bus"
#define SETTING_STRING_INCLUDE @"Include"
#define SETTING_STRING_EXCLUDE @"Exclude"

@interface RouteExcludeSettings() {
    NSDictionary *agencyIDHandlingDictionaryInternal;
}

-(NSDictionary *)agencyIDHandlingDictionary;
-(NSMutableDictionary *)excludeDictionary;

@end


@implementation RouteExcludeSettings

@dynamic excludeDictionaryInternal;
@dynamic isCurrentUserSetting;
@dynamic usedByRequestChunks;

static RouteExcludeSettings *latestUserSettingsStatic=nil; // latest User Settings
static NSManagedObjectContext *managedObjectContext=nil; // For storing and creating new objects

// Sets the ManagedObjectContext where RouteExcludeSettings are stored
+(void)setManagedObjectContext:(NSManagedObjectContext *)moc
{
    managedObjectContext = moc;
}

// Used for automated tests to clear out any old static latestUserSettings variable
+(void)clearLatestUserSettings
{
    latestUserSettingsStatic = nil;
}

// Returns the RouteExcludeSettings that are the latest from the user.
// Fetches from CoreData if needed
+ (RouteExcludeSettings *)latestUserSettings
{
    if (!managedObjectContext) {
        logError(@"RouteExcludeSettings -> latestUserSettings", @"managedObjectContext = nil");
        return nil;
    }
    if(!latestUserSettingsStatic){
        NSManagedObjectModel *managedObjectModel = [[managedObjectContext persistentStoreCoordinator] managedObjectModel];
        NSFetchRequest *request = [managedObjectModel fetchRequestTemplateForName:@"LatestRouteExcludeSettings"];
        NSError *error;
        NSArray *arraySettings = [managedObjectContext executeFetchRequest:request error:&error];
        if (arraySettings && [arraySettings count]==1) { // Found it
            latestUserSettingsStatic = [arraySettings objectAtIndex:0];
        }
        else if ([arraySettings count] > 1) {
            logError(@"RouteExcludeSettings -> latestUserSettings",
                     [NSString stringWithFormat:@"Unexpectedly latestUserSettings generating %d results",
                      [arraySettings count]]);
        }
        else {  // no stored latest, so create a new one
            latestUserSettingsStatic = [NSEntityDescription insertNewObjectForEntityForName:@"RouteExcludeSettings"
                                                             inManagedObjectContext:managedObjectContext];
            [latestUserSettingsStatic setIsCurrentUserSetting:[NSNumber numberWithBool:true]];
        }
    }
    return latestUserSettingsStatic;
}

// Returns a new RouteExcludeSettings object which is a copy of the current object's excludeDictionary
// The new RouteExcludeSetting has isCurrentUserSetting==false (it is the archive 
// The usedByRequestChunks are copied over to the new object, and are cleared in self
// This is used to create an archive copy of self, while keeping self as the latestUserSettings which can be modified
-(RouteExcludeSettings *)copyOfCurrentSettings
{
    RouteExcludeSettings* returnCopy = [NSEntityDescription insertNewObjectForEntityForName:@"RouteExcludeSettings"
                                                         inManagedObjectContext:managedObjectContext];
    [returnCopy setExcludeDictionaryInternal:[NSMutableDictionary dictionaryWithDictionary:[self excludeDictionaryInternal]]];
    [returnCopy setIsCurrentUserSetting:[NSNumber numberWithBool:false]];
    
    // Transfer over the PlanRequestChunks to the new copy
    for (PlanRequestChunk* reqChunk in [NSSet setWithSet:[self usedByRequestChunks]]) {
        [reqChunk setRouteExcludeSettings:returnCopy];
    }
    
    return returnCopy;
}

// Initiatializes (if needed) and returns dictionary mapping agencyIDs to how we will handle
// BY_AGENCY means we will show just one include/exclude button for that agency
// BY_RAIL_BUS means we will show up to two buttons for that agency, one for rail and one for bus service
-(NSDictionary *)agencyIDHandlingDictionary{
        if (!agencyIDHandlingDictionaryInternal) {
            agencyIDHandlingDictionaryInternal = [NSDictionary dictionaryWithKeysAndObjects:
                                                  CALTRAIN_BUTTON, BY_AGENCY,
                                                  BART_BUTTON, BY_AGENCY,
                                                  AIRBART_BUTTON, BY_AGENCY,
                                                  MUNI_BUTTON, BY_RAIL_BUS,
                                                  ACTRANSIT_BUTTON, BY_AGENCY,
                                                  VTA_BUTTON, BY_RAIL_BUS,
                                                  MENLO_MIDDAY_BUTTON, BY_AGENCY,
                                                  BLUE_GOLD_BUTTON, BY_AGENCY,
                                                  HARBOR_BAY_BUTTON, BY_AGENCY,
                                                  BAYLINK_BUTTON,BY_AGENCY,
                                                  GOLDEN_GATE_BUTTON, BY_AGENCY,
                                                  nil];
        }
        return agencyIDHandlingDictionaryInternal;
}


// Returns the main dictionary storing include / exclude settings
-(NSMutableDictionary *)excludeDictionary
{
    if (!self.excludeDictionaryInternal) {
        NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] initWithCapacity:20];
        [newDictionary setObject:SETTING_STRING_EXCLUDE forKey:BIKE_BUTTON];
        [self setExcludeDictionaryInternal:newDictionary];
    }
    return self.excludeDictionaryInternal;
}

// Returns setting for a particular key.  If key is not in dictionary, returns INCLUDE
-(IncludeExcludeSetting)settingForKey:(NSString *)key0 {
    NSString* settingString = [[self excludeDictionary] objectForKey:key0];
    if (settingString && [settingString isEqualToString:SETTING_STRING_EXCLUDE]) {
        return SETTING_EXCLUDE_ROUTE;
    } else {
        return SETTING_INCLUDE_ROUTE;  // if setting not in dictionary, default to "Include"
    }
}

// Returns true if the receiver and settings0 have equivalent setting values
// Note: does not compare isCurrentUserSetting
-(BOOL)isEquivalentTo:(RouteExcludeSettings *)settings0
{
    NSArray* selfKeys = [[self excludeDictionary] allKeys];
    for (NSString* key in selfKeys) {
        if ([self settingForKey:key] != [settings0 settingForKey:key]) {
            return false;
        }
    }
    NSArray* keys0 = [[settings0 excludeDictionary] allKeys];
    for (NSString* key in keys0) {
        if ([self settingForKey:key] != [settings0 settingForKey:key]) {
            return false;
        }
    }
    return true;
}

// Changes setting associated with a key
-(void)changeSettingTo:(IncludeExcludeSetting)value forKey:(NSString *)key0
{
    if (key0) {
        if ([[self usedByRequestChunks] count] > 0) {   // If some requestChunks were created with these settings
            [self copyOfCurrentSettings];  // Create a new archive copy of self
        }
        NSString* setting0 = ((value == SETTING_EXCLUDE_ROUTE) ? SETTING_STRING_EXCLUDE : SETTING_STRING_INCLUDE);
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:[self excludeDictionary]];
        [dictionary setObject:setting0 forKey:key0];
        [self setExcludeDictionaryInternal:dictionary];  // Set it again so that Core Data will update it...
        
        // See if there are any archived RouteExcludeSettings with the same settings
        // If so, merge the archive into the current...
        
        // Get all the objects in the database...
        NSFetchRequest * fetchSettings = [[NSFetchRequest alloc] init];
        [fetchSettings setEntity:[NSEntityDescription entityForName:@"RouteExcludeSettings" inManagedObjectContext:managedObjectContext]];
        NSArray* arraySettings = [managedObjectContext executeFetchRequest:fetchSettings error:nil];

        for (RouteExcludeSettings* archiveSetting in arraySettings) {
            if (archiveSetting != self &&
                [archiveSetting isEquivalentTo:self]) { // if this is an actual different object, but equivalent
                // Copy over the PlanRequestChunks pointing to that archived object to self
                for (PlanRequestChunk *reqChunk in [NSSet setWithSet:[archiveSetting usedByRequestChunks]]) {
                    [reqChunk setRouteExcludeSettings:self];
                }
                [managedObjectContext deleteObject:archiveSetting]; // Remove redundant archiveSetting
            }
        }
        
        // Store in database
        saveContext(managedObjectContext);
    }
}


// Returns the keys and values for the routes that are available in the plan relevant to the originalTripDate
// in parameters.
// Returned array containing routeExcludeSettings objects
// Array is ordered in the sequence options should be presented to user
-(NSArray *)excludeSettingsForPlan:(Plan *)plan withParameters:(PlanRequestParameters *)parameters {
    
    // Get the itineraries that are relevant to this particular tripDate but with no exclusions
    NSArray* relevantItineraries = [plan returnSortedItinerariesWithMatchesForDate:parameters.originalTripDate
                                                                    departOrArrive:parameters.departOrArrive
                                                               RouteExcludeSettings:nil
                                                                          callBack:nil
                                                          planMaxItinerariesToShow:PLAN_MAX_ITINERARIES_TO_SHOW
                                                  planBufferSecondsBeforeItinerary:PLAN_BUFFER_SECONDS_BEFORE_ITINERARY
                                                       planMaxTimeForResultsToShow:PLAN_MAX_TIME_FOR_RESULTS_TO_SHOW];
    NSMutableArray* returnArray = [[NSMutableArray alloc] initWithCapacity:10];
    for (Itinerary* itin in relevantItineraries) {
        for (Leg* leg in [itin legs]) {
            RouteExcludeSetting* routeExclSetting = [[RouteExcludeSetting alloc] init];
            if (leg.isScheduled && returnShortAgencyName(leg.agencyName)) {      
                NSString* handling = [[self agencyIDHandlingDictionary] objectForKey:returnShortAgencyName(leg.agencyName)];
                if (handling) {
                    if ([handling isEqualToString:BY_AGENCY]) {
                        routeExclSetting.key = returnShortAgencyName(leg.agencyName);
                        
                    } else {  // BY_RAIL_BUS
                        NSString *railOrBus = (leg.isBus ? @"Bus" : @"Rail");
                        if ([leg.agencyName isEqualToString:SFMUNI_AGENCY_NAME]) {
                            railOrBus = (leg.isBus ? @"Bus" : @"Tram");
                        }
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
    routeExclSetting.key = BIKE_BUTTON;
    routeExclSetting.setting = [self settingForKey:BIKE_BUTTON];
    [returnArray addObject:routeExclSetting];
    return [self returnUniqueRouteExcludeSettings:returnArray];
}

// Returns true if itin should be included based on the RouteExclude settings
-(BOOL)isItineraryIncluded:(Itinerary *)itin
{
       for (Leg* leg in [itin legs]) {
           NSString* legKey = nil;
           if (leg.isWalk && [self settingForKey:BIKE_BUTTON]==SETTING_INCLUDE_ROUTE) {
               return false; // exclude all walk itineraries if we are in bike mode
           }
           else if (leg.isBike && [self settingForKey:BIKE_BUTTON]==SETTING_EXCLUDE_ROUTE) { // TODO double-check isBike method
               return false; // Exclude bike itinerary if BIKE_BUTTON excluded
           }
           else if (returnShortAgencyName(leg.agencyName)) {      
               NSString* handling = [[self agencyIDHandlingDictionary] objectForKey:returnShortAgencyName(leg.agencyName)];
               if (handling) {
                   if ([handling isEqualToString:BY_AGENCY]) {
                       legKey = returnShortAgencyName(leg.agencyName);
                   } else {  // BY_RAIL_BUS
                       NSString *railOrBus = (leg.isBus ? @"Bus" : @"Rail");
                       if ([leg.agencyName isEqualToString:SFMUNI_AGENCY_NAME]) {
                           railOrBus = (leg.isBus ? @"Bus" : @"Tram");
                       }
                       legKey = [NSString stringWithFormat:@"%@ %@", returnShortAgencyName(leg.agencyName), railOrBus];
                   }
                   if ([self settingForKey:legKey] == SETTING_EXCLUDE_ROUTE) {
                       return false;
                   }
               } // else agency not in handling dictionary, count as include
           }  // else no agency name, do not generate button
       }
    return true;
}

- (NSArray *) returnUniqueRouteExcludeSettings:(NSArray *)array{
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