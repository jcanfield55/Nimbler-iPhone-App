//
//  UberQueueEntry.m
//  Nimbler SF
//
//  Created by John Canfield on 9/1/14.
//  Copyright (c) 2014 Nimbler World, Inc. All rights reserved.
//

#import "UberQueueEntry.h"

@implementation UberQueueEntry

@synthesize planRequestParamArray;
@synthesize createTime;
@synthesize parameterKey;
@synthesize itineraryArray;
@synthesize receivedPrices;
@synthesize receivedTimes;

// Initialize and set the createTime
- (id)init
{
    self = [super init];
    if (self) {
        createTime = [NSDate date];
        itineraryArray = [NSMutableArray arrayWithCapacity:6];
        planRequestParamArray = [NSMutableArray arrayWithCapacity:6];
        receivedTimes = false;
        receivedPrices = false;
    }
    return self;
}

// Returns a unique parameterKey string based on params dictionary.
+ (NSString *)parameterKeyWithParams:(NSDictionary *)params;
{
    NSString *parameterKey = [NSString stringWithFormat:@"(%@,%@) to (%@,%@)",
                              [params objectForKey:UBER_START_LATITUDE],
                              [params objectForKey:UBER_START_LONGITUDE],
                              [params objectForKey:UBER_END_LATITUDE],
                              [params objectForKey:UBER_END_LONGITUDE]];
    return parameterKey;
}

-(void)addPlanRequestParametersObject:(PlanRequestParameters *)planReqParObject
{
    [planRequestParamArray addObject:planReqParObject];
}

@end
