//
//  RouteExcludeSetting.m
//  Nimbler SF
//
//  Created by John Canfield on 2/19/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

// Helper class for RouteExcludeSettings.  Contains a single key / value setting pair
#import "RouteExcludeSetting.h"
#import "UtilityFunctions.h"

@implementation RouteExcludeSetting

@synthesize key;
@synthesize setting;
@synthesize agencyId;
@synthesize agencyName;
@synthesize mode;
@synthesize bannedAgencyString;
@synthesize bannedAgencyByModeString;

// Override to update bannedAgencyString or bannedAgencyByModeString based on the new setting
-(void)setSetting:(IncludeExcludeSetting)setting0
{
    setting = setting0;
    NSString* handling = [[RouteExcludeSettings agencyButtonHandlingDictionary] objectForKey:returnShortAgencyName(agencyName)];
    if (handling) {
        if (setting == SETTING_EXCLUDE_ROUTE) {
            if ([handling isEqualToString:EXCLUSION_BY_AGENCY]) {
                bannedAgencyString = agencyId;
            } else {
                bannedAgencyByModeString = [NSString stringWithFormat:@"%@::%@",
                                            agencyId,
                                            returnRouteTypeFromLegMode(mode)];
            }
        }
    }
}
@end
