//
//  Agencies.m
//  Nimbler SF
//
//  Created by macmini on 23/04/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "Agencies.h"
#import "UtilityFunctions.h"
#import "KeyObjectStore.h"
#import "nc_AppDelegate.h"

@implementation Agencies

@synthesize agenciesDictionary;
@synthesize rkTpClient;
@synthesize excludeButtonHandlingByAgencyDictionary;
@synthesize agencyButtonNameByAgencyDictionary;
@synthesize agencyShortNameByAgencyIdDictionary;
@synthesize agencyFeedIdFromAgencyNameDictionary;
@synthesize agencyNameFromAgencyFeedIdDictionary;
@synthesize advisoriesChoices;

static Agencies * agenciesSingleton;

// returns the singleton value.
+ (Agencies *)agencies
{
    if (!agenciesSingleton) {
        agenciesSingleton = [[Agencies alloc] init];
    }
    return agenciesSingleton;
}

// Call server for updated agencies data.
- (void)updateAgenciesFromServer{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],APPLICATION_TYPE, nil];
    NSString *request = [APP_AGENCIES appendQueryParams:params];
    [rkTpClient get:request delegate:self];
}

// Accessor override to populate this dictionary if not already there
- (NSDictionary *)agenciesDictionary
{
    if (!agenciesDictionary) {
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        agenciesDictionary = [keyObjectStore objectForKey:AGENCIES_DICTIONARY];
    }
    return agenciesDictionary;
}

- (NSDictionary *)excludeButtonHandlingByAgencyDictionary{
    if (!excludeButtonHandlingByAgencyDictionary) {
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        excludeButtonHandlingByAgencyDictionary = [keyObjectStore objectForKey:EXCLUDE_BUTTON_HANDLING_BY_AGENCY_DICTIONARY];
    }
    return excludeButtonHandlingByAgencyDictionary;
}

- (NSDictionary *)agencyButtonNameByAgencyDictionary{
    if (!agencyButtonNameByAgencyDictionary) {
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        agencyButtonNameByAgencyDictionary = [keyObjectStore objectForKey:AGENCY_BUTTON_NAME_BY_AGENCY_DICTIONARY];
    }
    return agencyButtonNameByAgencyDictionary;
}

- (NSDictionary *)agencyShortNameByAgencyIdDictionary{
    if (!agencyShortNameByAgencyIdDictionary) {
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        agencyShortNameByAgencyIdDictionary = [keyObjectStore objectForKey:AGENCY_SHORT_NAME_BY_AGENCY_ID_DICTIONARY];
    }
    return agencyShortNameByAgencyIdDictionary;
}

- (NSDictionary *)agencyFeedIdFromAgencyNameDictionary{
    if (!agencyFeedIdFromAgencyNameDictionary) {
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        agencyFeedIdFromAgencyNameDictionary = [keyObjectStore objectForKey:AGENCY_FEED_ID_FROM_AGENCY_NAME_DICTIONARY];
    }
    return agencyFeedIdFromAgencyNameDictionary;
}

- (NSDictionary *)agencyNameFromAgencyFeedIdDictionary{
    if (!agencyNameFromAgencyFeedIdDictionary) {
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        agencyNameFromAgencyFeedIdDictionary = [keyObjectStore objectForKey:AGENCY_NAME_FROM_AGENCY_FEED_ID_DICTIONARY];
    }
    return agencyNameFromAgencyFeedIdDictionary;
}

- (void) addvaluesToDictionaryFromResponseData:(NSDictionary *)agencyDictionary{
    NSMutableDictionary *mutableexcludeButtonHandlingByAgencyDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *mutableagencyButtonNameByAgencyDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *mutableagencyShortNameByAgencyIdDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *mutableagencyFeedIdFromAgencyNameDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *mutableagencyNameFromAgencyFeedIdDictionary = [[NSMutableDictionary alloc] init];
    NSArray *agenciesArray = [agencyDictionary objectForKey:AGENCIES_DICTIONARY];
    for(int i=0;i<[agenciesArray count];i++){
        NSDictionary *dictAgencies = [agenciesArray objectAtIndex:i];
        NSString *feedId = [dictAgencies objectForKey:NIMBLER_AGENCY_ID];
        NSString *exclusionType = [dictAgencies objectForKey:EXCLUSION_TYPE];
        NSArray *subAgenciesArray = [dictAgencies objectForKey:AGENCIES_DICTIONARY];
        for(int j=0;j<[subAgenciesArray count];j++){
            NSDictionary *dictSubAgencies = [subAgenciesArray objectAtIndex:j];
            NSString *agencyId = [dictSubAgencies objectForKey:GTFS_AGENCY_ID];
            NSString *agencyName = [dictSubAgencies objectForKey:AGENCY_NAME];
            NSString *displayName = [dictSubAgencies objectForKey:DISPLAY_NAME];
            [mutableexcludeButtonHandlingByAgencyDictionary setObject:exclusionType forKey:displayName];
            [mutableagencyButtonNameByAgencyDictionary setObject:displayName forKey:agencyName];
            [mutableagencyShortNameByAgencyIdDictionary setObject:displayName forKey:agencyId];
            [mutableagencyFeedIdFromAgencyNameDictionary setObject:feedId forKey:agencyName];
            [mutableagencyNameFromAgencyFeedIdDictionary setObject:agencyName forKey:feedId];
        }
    }
    excludeButtonHandlingByAgencyDictionary =mutableexcludeButtonHandlingByAgencyDictionary;
    agencyButtonNameByAgencyDictionary = mutableagencyButtonNameByAgencyDictionary;
    agencyShortNameByAgencyIdDictionary = mutableagencyShortNameByAgencyIdDictionary;
    agencyFeedIdFromAgencyNameDictionary = mutableagencyFeedIdFromAgencyNameDictionary;
    agencyNameFromAgencyFeedIdDictionary = mutableagencyNameFromAgencyFeedIdDictionary;
    
    KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
    [keyObjectStore setObject:excludeButtonHandlingByAgencyDictionary forKey:EXCLUDE_BUTTON_HANDLING_BY_AGENCY_DICTIONARY];
    [keyObjectStore setObject:agencyButtonNameByAgencyDictionary forKey:AGENCY_BUTTON_NAME_BY_AGENCY_DICTIONARY];
    [keyObjectStore setObject:agencyShortNameByAgencyIdDictionary forKey:AGENCY_SHORT_NAME_BY_AGENCY_ID_DICTIONARY];
    [keyObjectStore setObject:agencyFeedIdFromAgencyNameDictionary forKey:AGENCY_FEED_ID_FROM_AGENCY_NAME_DICTIONARY];
    [keyObjectStore setObject:agencyNameFromAgencyFeedIdDictionary forKey:AGENCY_NAME_FROM_AGENCY_FEED_ID_DICTIONARY];
}
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response{
        RKJSONParserJSONKit* rkParser = [RKJSONParserJSONKit new];
        NSDictionary *tempResponseDictionary = [rkParser objectFromString:[response bodyAsString] error:nil];
        if([tempResponseDictionary objectForKey:AGENCIES_DICTIONARY] != nil ){
            [[NSUserDefaults standardUserDefaults] setObject:dateOnlyFromDate([NSDate date]) forKey:CURRENT_DATE_AGENCIES];
            [[NSUserDefaults standardUserDefaults] synchronize];
            KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
            agenciesDictionary = [keyObjectStore objectForKey:AGENCIES_DICTIONARY];
            if(!agenciesDictionary){
                agenciesDictionary = tempResponseDictionary;
                [self addvaluesToDictionaryFromResponseData:agenciesDictionary];
                KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                [keyObjectStore setObject:agenciesDictionary forKey:AGENCIES_DICTIONARY];
            }
            else if(![agenciesDictionary isEqualToDictionary: tempResponseDictionary]){
                agenciesDictionary = tempResponseDictionary;
                [self addvaluesToDictionaryFromResponseData:agenciesDictionary];
                KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                [keyObjectStore setObject:agenciesDictionary forKey:AGENCIES_DICTIONARY];
            }
        }
    saveContext([nc_AppDelegate sharedInstance].managedObjectContext);
}
@end
