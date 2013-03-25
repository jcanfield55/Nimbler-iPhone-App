//
//  MutableBoolean.m
//  Nimbler SF
//
//  Created by John Canfield on 3/24/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "MutableBoolean.h"

@implementation MutableBoolean

@synthesize boolValue;

-(id)initWithBool:(BOOL)value
{
    self = [super init];
    if (self) {
        boolValue = value;
    }
    return self;
}
@end
