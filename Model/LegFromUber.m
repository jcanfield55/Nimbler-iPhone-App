//
//  LegFromUber.m
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import "LegFromUber.h"

@implementation LegFromUber

@synthesize uberProductID;
@synthesize uberDisplayName;
@synthesize uberPriceEstimate;
@synthesize uberLowEstimate;
@synthesize uberHighEstimate;
@synthesize uberSurgeMultiplier;
@synthesize uberTimeEstimateSeconds;

-(int)uberTimeEstimateMinutes
{
    int minutes = ceil(uberTimeEstimateSeconds.floatValue / 60.0);
    return minutes;
}


@end
