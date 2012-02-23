//
//  DateFormatterMSFrom1970.m
//  Network Commuting
//
//  Created by John Canfield on 2/21/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "DateFormatterMSFrom1970.h"

@implementation DateFormatterMSFrom1970

+ (DateFormatterMSFrom1970 *)dateFormatter {
    return [[DateFormatterMSFrom1970 alloc] init];
}


- (NSDate *)dateFromString:(NSString *)string {
    double milliseconds = [string doubleValue];
    if (milliseconds == 0.0) {
        return nil;   // return nil if not formatted for getting a number
    }
    return [NSDate dateWithTimeIntervalSince1970:(milliseconds/1000.0)];
}


- (NSString *)stringFromDate:(NSDate *)date {
    if (!date) {
        return nil;
    }
    long long milliseconds = ([date timeIntervalSince1970])*1000.0;
    return [NSString stringWithFormat:@"%qi", milliseconds];
}

@end
