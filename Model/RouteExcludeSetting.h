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

@end
