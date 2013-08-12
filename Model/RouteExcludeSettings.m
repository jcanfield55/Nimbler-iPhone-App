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
#import "LocalConstants.h"
#import "nc_AppDelegate.h"

#define SETTING_STRING_INCLUDE @"Include"
#define SETTING_STRING_EXCLUDE @"Exclude"

@interface RouteExcludeSettings() {

}

-(NSMutableDictionary *)excludeDictionary;

@end


@implementation RouteExcludeSettings

@dynamic excludeDictionaryInternal;
@dynamic isCurrentUserSetting;
@dynamic usedByRequestChunks;

static RouteExcludeSettings *latestUserSettingsStatic=nil; // latest User Settings
static NSManagedObjectContext *routeExcludeMOC=nil; // For storing and creating new objects
static NSDictionary *agencyButtonHandlingDictionaryInternal;

// Sets the routeExcludeMOC where RouteExcludeSettings are stored
+(void)setManagedObjectContext:(NSManagedObjectContext *)moc
{
    if (routeExcludeMOC != moc) {
        routeExcludeMOC = moc;
        latestUserSettingsStatic = nil;  // clear out latestUserSettings if we have a new managed object context
    }
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
    if (!routeExcludeMOC) {
        logError(@"RouteExcludeSettings -> latestUserSettings", @"routeExcludeMOC = nil");
        return nil;
    }
    if(!latestUserSettingsStatic){
        NSManagedObjectModel *managedObjectModel = [[routeExcludeMOC persistentStoreCoordinator] managedObjectModel];
        NSFetchRequest *request = [managedObjectModel fetchRequestTemplateForName:@"LatestRouteExcludeSettings"];
        NSError *error;
        NSArray *arraySettings = [routeExcludeMOC executeFetchRequest:request error:&error];
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
                                                             inManagedObjectContext:routeExcludeMOC];
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
                                                         inManagedObjectContext:routeExcludeMOC];
    [returnCopy setExcludeDictionaryInternal:[NSMutableDictionary dictionaryWithDictionary:[self excludeDictionaryInternal]]];
    [returnCopy setIsCurrentUserSetting:[NSNumber numberWithBool:false]];
    
    // Transfer over the PlanRequestChunks to the new copy
    for (PlanRequestChunk* reqChunk in [NSSet setWithSet:[self usedByRequestChunks]]) {
        [reqChunk setRouteExcludeSettings:returnCopy];
    }
    
    return returnCopy;
}

// Initiatializes (if needed) and returns dictionary mapping agency button names to how we will handle
// EXCLUSION_BY_AGENCY means we will show just one include/exclude button for that agency
// EXCLUSION_BY_RAIL_BUS means we will show up to two buttons for that agency, one for rail and one for bus service
+(NSDictionary *)agencyButtonHandlingDictionary {
        if (!agencyButtonHandlingDictionaryInternal) {
            agencyButtonHandlingDictionaryInternal = [Agencies agencies].excludeButtonHandlingByAgencyDictionary;
        }
        return agencyButtonHandlingDictionaryInternal;
}


// Returns the main dictionary storing include / exclude settings
-(NSMutableDictionary *)excludeDictionary
{
    if (!self.excludeDictionaryInternal) {
        NSMutableDictionary* newDictionary = [[NSMutableDictionary alloc] initWithCapacity:20];
        if([[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId] isEqualToString:WMATA_APP_TYPE]){
            [newDictionary setObject:SETTING_STRING_EXCLUDE forKey:MY_BIKE];
            [newDictionary setObject:SETTING_STRING_INCLUDE forKey:BIKE_SHARE];
        }
        else{
            [newDictionary setObject:SETTING_STRING_EXCLUDE forKey:BIKE_BUTTON];
            [newDictionary setObject:SETTING_STRING_EXCLUDE forKey:BIKE_SHARE];
        }
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
// If settings0 == nil, returns true if self has default exclude settings
// Note: does not compare isCurrentUserSetting
-(BOOL)isEquivalentTo:(RouteExcludeSettings *)settings0
{
    if (!settings0) {
        return [self isDefaultSettings];
    }
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
        [fetchSettings setEntity:[NSEntityDescription entityForName:@"RouteExcludeSettings" inManagedObjectContext:routeExcludeMOC]];
        NSArray* arraySettings = [routeExcludeMOC executeFetchRequest:fetchSettings error:nil];
        
        for (RouteExcludeSettings* archiveSetting in arraySettings) {
            if (archiveSetting != self &&
                [archiveSetting isEquivalentTo:self]) { // if this is an actual different object, but equivalent
                // Copy over the PlanRequestChunks pointing to that archived object to self
                for (PlanRequestChunk *reqChunk in [NSSet setWithSet:[archiveSetting usedByRequestChunks]]) {
                    [reqChunk setRouteExcludeSettings:self];
                }
                [routeExcludeMOC deleteObject:archiveSetting]; // Remove redundant archiveSetting
            }
        }
        
        // Store in database
        saveContext(routeExcludeMOC);
    }
}


// Returns the keys and values for the routes that are available in the plan relevant to the originalTripDate
// in parameters.
// Returned array containing routeExcludeSettings objects
// Array is ordered in the sequence options should be presented to user
-(NSArray *)excludeSettingsForPlan:(Plan *)plan {
    
    // Get the itineraries that are relevant to this particular tripDate but with no exclusions
    NSArray* relevantItineraries = [[plan itineraries] allObjects];
    NSMutableArray* returnArray = [[NSMutableArray alloc] initWithCapacity:10];
    for (Itinerary* itin in relevantItineraries) {
        for (Leg* leg in [itin legs]) {
            if (leg.isScheduled && returnShortAgencyName(leg.agencyName)) {      
                NSString* handling = [[RouteExcludeSettings agencyButtonHandlingDictionary] objectForKey:returnShortAgencyName(leg.agencyName)];
                if (handling) {
                    RouteExcludeSetting* routeExclSetting = [[RouteExcludeSetting alloc] init];
                    routeExclSetting.agencyId = leg.agencyId;
                    routeExclSetting.agencyName = leg.agencyName;
                    routeExclSetting.mode = leg.mode;
                    if ([handling isEqualToString:EXCLUSION_BY_AGENCY]) {
                        routeExclSetting.key = returnShortAgencyName(leg.agencyName);
                    } else {  // EXCLUSION_BY_RAIL_BUS
                        NSString *railOrBus = (leg.isBus ? @"Bus" : @"Rail");
                        if ([leg.agencyName isEqualToString:SFMUNI_AGENCY_NAME]) {
                            railOrBus = (leg.isBus ? @"Bus" : @"Tram");
                        }
                        routeExclSetting.key = [NSString stringWithFormat:@"%@ %@", returnShortAgencyName(leg.agencyName), railOrBus];
                    }
                    routeExclSetting.setting = [self settingForKey:routeExclSetting.key]; // automatically updates agencyStrings
                    [returnArray addObject:routeExclSetting];
                } // else agency not in handling dictionary, do not generate button
            }  // else no agency name, do not generate button
        }
    }
    NSSortDescriptor *sortD = [[NSSortDescriptor alloc]
                               initWithKey:@"key" ascending:YES selector:@selector(localizedStandardCompare:)];
    [returnArray sortUsingDescriptors:[NSArray arrayWithObject:sortD]];
    
    if([[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId] isEqualToString:WMATA_APP_TYPE]){
        // Add bike button
        RouteExcludeSetting* routeExclSettingBike = [[RouteExcludeSetting alloc] init];
        routeExclSettingBike.key = MY_BIKE;
        routeExclSettingBike.setting = [self settingForKey:MY_BIKE];
        [returnArray addObject:routeExclSettingBike];
        
        // Add bike button
        RouteExcludeSetting* routeExclSettingBikeShare = [[RouteExcludeSetting alloc] init];
        routeExclSettingBikeShare.key = BIKE_SHARE;
        routeExclSettingBikeShare.setting = [self settingForKey:BIKE_SHARE];
        [returnArray addObject:routeExclSettingBikeShare];
    }
    else{
        // Add bike button
        RouteExcludeSetting* routeExclSetting = [[RouteExcludeSetting alloc] init];
        routeExclSetting.key = BIKE_BUTTON;
        routeExclSetting.setting = [self settingForKey:BIKE_BUTTON];
        [returnArray addObject:routeExclSetting];
    }
    return [self returnUniqueRouteExcludeSettings:returnArray];
}

// Returns an array of RouteExcludeSetting objects with everything default except has the specified bikeSetting
+(NSArray *)arrayWithNoExcludesExceptExcludeBike:(IncludeExcludeSetting)bikeSetting
{
    RouteExcludeSetting* routeExclSetting = [[RouteExcludeSetting alloc] init];
    if([[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId] isEqualToString:WMATA_APP_TYPE]){
        routeExclSetting.key = MY_BIKE;
    }
    else{
        routeExclSetting.key = BIKE_BUTTON;
    }
    routeExclSetting.setting = bikeSetting;
    NSArray* returnArray = [NSArray arrayWithObject:routeExclSetting];
    return returnArray;
}

// Generates the bannedAgencyString which can be passed to OTP for any agency-wide excludes
// settingArray is an array of RouteExcludeSetting objects returned by excludeSettingsForPlan method
-(NSString *)bannedAgencyStringForSettingArray:(NSArray *)settingArray
{
    if (!settingArray) {
        return nil;
    }
    NSMutableString *strAgencies = [[NSMutableString alloc] initWithCapacity:20];
    for (RouteExcludeSetting* exclSetting in settingArray) {
        if (exclSetting.bannedAgencyString && exclSetting.bannedAgencyString.length > 0) {
            if (strAgencies.length == 0) {
                [strAgencies appendString:exclSetting.bannedAgencyString];
            } else {  // insert a comma if this is not the first string
                [strAgencies appendFormat:@",%@", exclSetting.bannedAgencyString];
            }
        }
    }
    if (strAgencies.length == 0) {
        return nil;
    } else {
        return strAgencies;
    }
}

// Generates the bannedAgencyByModeString which can be passed to OTP for any agency-wide excludes
// settingArray is an array of RouteExcludeSetting objects returned by excludeSettingsForPlan method
-(NSString *)bannedAgencyByModeStringForSettingArray:(NSArray *)settingArray
{
    if (!settingArray) {
        return nil;
    }
    NSMutableString *strAgencies = [[NSMutableString alloc] initWithCapacity:20];
    for (RouteExcludeSetting* exclSetting in settingArray) {
        if (exclSetting.bannedAgencyByModeString && exclSetting.bannedAgencyByModeString.length > 0) {
            if (strAgencies.length == 0) {
                [strAgencies appendString:exclSetting.bannedAgencyByModeString];
            } else {  // insert a comma if this is not the first string
                [strAgencies appendFormat:@",%@", exclSetting.bannedAgencyByModeString];
            }
        }
    }
    if (strAgencies.length == 0) {
        return nil;
    } else {
        return strAgencies;
    }
}

// Creates a new RouteExcludeSettings using the values in settingArray.
// settingArray is created by excludeSettingsForPlan method
+(RouteExcludeSettings *)excludeSettingsWithSettingArray:(NSArray *)settingArray
{
    NSMutableDictionary* newExcludeDictionary = [NSMutableDictionary dictionaryWithCapacity:10];    
    for (RouteExcludeSetting* exclSetting in settingArray) {
        if (exclSetting.setting == SETTING_EXCLUDE_ROUTE) {
            [newExcludeDictionary setObject:SETTING_STRING_EXCLUDE forKey:exclSetting.key];
        }
    }
    // Create the new object
    RouteExcludeSettings* newSettings = [NSEntityDescription insertNewObjectForEntityForName:@"RouteExcludeSettings"
                                                                     inManagedObjectContext:routeExcludeMOC];
    [newSettings setIsCurrentUserSetting:[NSNumber numberWithBool:false]];
    [newSettings setExcludeDictionaryInternal:newExcludeDictionary];
    
    // Check that there are not already duplicates if so, consolidate
    NSFetchRequest * fetchSettings = [[NSFetchRequest alloc] init];
    [fetchSettings setEntity:[NSEntityDescription entityForName:@"RouteExcludeSettings" inManagedObjectContext:routeExcludeMOC]];
    NSArray* fetchedSettingsArray = [routeExcludeMOC executeFetchRequest:fetchSettings error:nil];
    
    for (RouteExcludeSettings* archiveSetting in fetchedSettingsArray) {
        if (archiveSetting != newSettings &&
            [archiveSetting isEquivalentTo:newSettings]) { // if this is an actual different object, but equivalent
            // Delete this new copy -- we don't need it -- and return archiveSetting
            [routeExcludeMOC deleteObject:newSettings]; // Remove redundant archiveSetting
            return archiveSetting;
        }
    }
    return newSettings;  // if no equivalent one already in the system, return newSettings
}

// Creates a string showing the values in the settingArray (can be used for logging)
+(NSString *)stringFromSettingArray:(NSArray *)settingArray
{
    NSMutableString* resultString = [NSMutableString stringWithCapacity:50];
    for (RouteExcludeSetting* setting in settingArray) {
        NSString *settingStr = (setting.setting == SETTING_INCLUDE_ROUTE ? @"Include" : @"Exclude");
        [resultString appendFormat:@"Key: %@, Value: %@\n", setting.key, settingStr];
    }
    return resultString;
}

                
// Returns true if self contains the default settings (the equivalent of a nil exclude)
// This means no excludes except for Bike mode exclude
-(BOOL)isDefaultSettings
{
    for (NSString* key in [[self excludeDictionary] allKeys]) {
        if ([key isEqualToString:returnBikeButtonTitle()]) { // bike button must be exclude
            if ([self settingForKey:key] == SETTING_INCLUDE_ROUTE) {
                return false;
            }
        } else { // not bike mode, must be include
            if ([self settingForKey:key] == SETTING_EXCLUDE_ROUTE) {
                return false;
            }
        }
    }
    return true;
}

// Fixed DE-313
// Returns true if itin contains walk and bike and also route exclude settings for bike is SETTING_INCLUDE_ROUTE otherwise return false.
- (BOOL) itineraryContainsWalkAndBike:(NSSet *)legs{
    
    BOOL bikeMode = [[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_BIKE_MODE] boolValue];
    BOOL bikeShare = [[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_SHARE_MODE] boolValue];
    BOOL walkMode = [[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_WALK_MODE] boolValue];
    BOOL transitMode = [[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_TRANSIT_MODE] boolValue];
    
    BOOL containWalk = false;
    BOOL containBike = false;
    BOOL needToIncludeLeg = true;
    BOOL rentedBike = false; 
    for(Leg *leg in legs){
        if(leg.isBike){
            containBike = true;
        }
        if(leg.isWalk){
            containWalk = true;
        }
        if(leg.rentedBike){
            rentedBike = true;
        }
        if (returnShortAgencyName(leg.agencyName)) {
            if(!transitMode)
                return false;
            NSString *legKey;
            NSString* handling = [[RouteExcludeSettings agencyButtonHandlingDictionary] objectForKey:returnShortAgencyName(leg.agencyName)];
            if (handling) {
                if ([handling isEqualToString:EXCLUSION_BY_AGENCY]) {
                    legKey = returnShortAgencyName(leg.agencyName);
                } else {  // EXCLUSION_BY_RAIL_BUS
                    NSString *railOrBus = (leg.isBus ? @"Bus" : @"Rail");
                    if ([leg.agencyName isEqualToString:SFMUNI_AGENCY_NAME]) {
                        railOrBus = (leg.isBus ? @"Bus" : @"Tram");
                    }
                    legKey = [NSString stringWithFormat:@"%@ %@", returnShortAgencyName(leg.agencyName), railOrBus];
                }
                if ([self settingForKey:legKey] == SETTING_EXCLUDE_ROUTE) {
                    needToIncludeLeg = false;
                }
            }
        }
    }
     if((bikeMode || bikeShare) && walkMode && containBike && containWalk && [self settingForKey:returnBikeButtonTitle()]==SETTING_INCLUDE_ROUTE && [self settingForKey:BIKE_SHARE]==SETTING_INCLUDE_ROUTE && needToIncludeLeg)
         return true;
    
     else if( (bikeMode || bikeShare) && walkMode && containBike && containWalk && [self settingForKey:returnBikeButtonTitle()]==SETTING_INCLUDE_ROUTE && [self settingForKey:BIKE_SHARE]==SETTING_EXCLUDE_ROUTE && !rentedBike && needToIncludeLeg)
         return true;
    
     else if((bikeMode || bikeShare) && walkMode && containBike && containWalk && [self settingForKey:returnBikeButtonTitle()]==SETTING_EXCLUDE_ROUTE && [self settingForKey:BIKE_SHARE]==SETTING_INCLUDE_ROUTE && rentedBike && needToIncludeLeg)
        return true;
    
    else
        return false;
}


// Returns true if itin should be included based on the RouteExclude settings
-(BOOL)isItineraryIncluded:(Itinerary *)itin {
   
    BOOL transitMode = [[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_TRANSIT_MODE] boolValue];
    BOOL walkMode = [[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_WALK_MODE] boolValue];
    
    if([self itineraryContainsWalkAndBike:[itin legs]]){
        return true;
    }
    for (Leg* leg in [itin legs]) {
        NSString* legKey = nil;
        if(leg.isWalk && !walkMode){
            return false; // Exclude walk itinerary if WALK Mode disable
        }
        else if (leg.isWalk && [self settingForKey:returnBikeButtonTitle()]==SETTING_INCLUDE_ROUTE) {
            return false; // exclude all walk itineraries if we are in bike mode
        }
        else if (leg.isBike && [self settingForKey:returnBikeButtonTitle()]==SETTING_EXCLUDE_ROUTE && [self settingForKey:BIKE_SHARE] == SETTING_EXCLUDE_ROUTE) { // TODO double-check isBike method
            return false; // Exclude bike itinerary if BIKE_BUTTON excluded
        }
        else if (leg.isBike && [self settingForKey:returnBikeButtonTitle()]==SETTING_INCLUDE_ROUTE && ([self settingForKey:BIKE_SHARE] == SETTING_EXCLUDE_ROUTE && leg.rentedBike)) { // TODO double-check isBike method
            return false; // Exclude bike itinerary if BIKE_BUTTON excluded
        }
        else if (leg.isBike && [self settingForKey:returnBikeButtonTitle()]==SETTING_EXCLUDE_ROUTE && ([self settingForKey:BIKE_SHARE] == SETTING_INCLUDE_ROUTE && !leg.rentedBike)) { // TODO double-check isBike method
            return false; // Exclude bike itinerary if BIKE_BUTTON excluded
        }
        else if (returnShortAgencyName(leg.agencyName)) {
            if(!transitMode){
                return false;
            }
            NSString* handling = [[RouteExcludeSettings agencyButtonHandlingDictionary] objectForKey:returnShortAgencyName(leg.agencyName)];
            if (handling) {
                if ([handling isEqualToString:EXCLUSION_BY_AGENCY]) {
                    legKey = returnShortAgencyName(leg.agencyName);
                } else { // EXCLUSION_BY_RAIL_BUS
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
        } // else no agency name, do not generate button
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