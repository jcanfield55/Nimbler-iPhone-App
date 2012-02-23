//
//  Plan.m
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Plan.h"
#import "DateFormatterMSFrom1970.h"

@implementation Plan

@synthesize date;
@synthesize from;
@synthesize to;

+ (RKObjectMapping *)objectMappingforPlanner:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[Plan class]];

    RKObjectMapping* planPlaceMapping = [PlanPlace objectMappingForApi:apiType];

    // Make the mappings
    if (apiType==OTP_PLANNER) {
        // TODO  Do all the mapping
        // TODO take the below comment out when I have confirmed another way to do date formatting in milliseconds
        /* DateFormatterMSFrom1970 *dateFormatter = [DateFormatterMSFrom1970 dateFormatter]; // sets date formatter to parse milliseconds from 1970 date format
         [mapping setPreferredDateFormatter:dateFormatter]; */
        [mapping mapKeyPath:@"date" toAttribute:@"date"];
        [mapping mapKeyPath:@"from" toRelationship:@"from" withMapping:planPlaceMapping];
        [mapping mapKeyPath:@"to" toRelationship:@"to" withMapping:planPlaceMapping];

    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

// Detects whether date returned by REST API is >1,000 years in the future.  If so, the value is likely being returned in milliseconds from 1970, rather than seconds from 1970, in which we correct the date by dividing by the timeSince1970 value by 1,000
// Comment out for now, since it is not being used
/*
- (BOOL)validateDate:(__autoreleasing id *)ioValue error:(NSError *__autoreleasing *)outError
{
    if ([*ioValue isKindOfClass:[NSDate class]]) {
        NSDate* ioDate = *ioValue;
        NSDate* farFutureDate = [NSDate dateWithTimeIntervalSinceNow:(60.0*60*24*365*1000)]; // 1,000 years in future
        if ([ioDate laterDate:farFutureDate]==ioDate) {   // if date is >1,000 years in future, divide time since 1970 by 1000
            NSDate* newDate = [NSDate dateWithTimeIntervalSince1970:([ioDate timeIntervalSince1970] / 1000.0)];
            NSLog(@"[self date] = %@", [self date]);
            NSLog(@"New Date = %@", newDate);
            *ioValue = newDate;
            NSLog(@"New ioValue = %@", *ioValue);
            NSLog(@"[self date] = %@", [self date]);
        }
        return YES;
    }
    return NO;
} */

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{Plan Object: date: %@;  from: %@;  to: %@}",date, from, to];
    return desc;
}

@end
