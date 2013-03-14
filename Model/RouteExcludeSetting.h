//
//  RouteExcludeSetting.h
//  Nimbler SF
//
//  Created by John Canfield on 2/19/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

// Helper class for RouteExcludeSettings.  Contains a single key / value setting pair

#import <Foundation/Foundation.h>
#import "RouteExcludeSettings.h"

@interface RouteExcludeSetting : NSObject

@property(nonatomic, strong) NSString* key;
@property(nonatomic) IncludeExcludeSetting setting;
@property(nonatomic, strong) NSString* mode;   // mode of the leg that goes with this key (used to create
@property(nonatomic, strong) NSString* agencyId;  // AgencyId that goes with this key (from leg.AgencyId)
@property(nonatomic, strong) NSString* agencyName; // AgencyName (from leg.AgencyName)

// If setting==SETTING_EXCLUDE_ROUTE, and key is an agency (i.e. not Bike) then one of the following two properties will be set
// bannedAgencyString is set if the exclude bans the whole agency
// bannedAgencyByModeString is set if the exclude bans particular modes for the agency
// These updates are done in the setSetting method override
@property(nonatomic, strong) NSString* bannedAgencyString;
@property(nonatomic, strong) NSString* bannedAgencyByModeString;

@end
