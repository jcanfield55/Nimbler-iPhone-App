//
//  DateFormatterMSFrom1970.h
//  Network Commuting
//
//  Created by John Canfield on 2/21/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateFormatterMSFrom1970 : NSDateFormatter {
    NSRegularExpression *dotNetExpression;
}

/**
 Instantiates an DateFormatterMSFrom1970 object with the timezone set to UTC 
 (Greenwich Mean Time).
 */
+ (DateFormatterMSFrom1970 *)dateFormatter;

/**
 Returns an NSDate object from pure milliseconds from 1970 respresentation, as seen in Open Trip Planner
 Examples format is:  1112715000000
 Where 1112715000000 is the number of milliseconds since January 1, 1970 00:00 GMT/UTC, and 

 */
- (NSDate *)dateFromString:(NSString *)string;

// Does the converse mapping
- (NSString *)stringFromDate:(NSDate *)date;

@end
