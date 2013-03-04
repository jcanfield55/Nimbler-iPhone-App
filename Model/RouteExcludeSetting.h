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

// If setting==SETTING_EXCLUDE_ROUTE, and key is an agency (i.e. not Bike) then one of the following two properties will be set
// bannedAgencyString is set if the exclude bans the whole agency
// bannedAgencyByModeString is set if the exclude bans particular modes for the agency
@property(nonatomic, strong) NSString* bannedAgencyString;
@property(nonatomic, strong) NSString* bannedAgencyByModeString;

@end
