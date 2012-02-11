//
//  RawAddress.m
//  Network Commuting
//
//  Created by John Canfield on 2/9/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RawAddress.h"
#import "Location.h"


@implementation RawAddress 

@dynamic rawAddressString;
@dynamic location;

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:@"{%@}", rawAddressString];
    return desc;
}

@end
