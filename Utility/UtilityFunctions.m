//
//  UtilityFunctions.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "UtilityFunctions.h"
#import "Constants.h"   // contains Flurry variables
#import "Logging.h"
#if FLURRY_ENABLED
#include "Flurry.h"
#endif


static NSDateFormatter *utilitiesTimeFormatter;  // Static variable for short time formatter for use by utility


// This function will construct the full path for a file with name *filename
// in the Documents Directory
NSString *pathInDocumentDirectory(NSString *fileName)
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    // Get the one and only document directory from the list
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:fileName];
}


void saveContext(NSManagedObjectContext *managedObjectContext)
{
    NSError *error = nil;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NIMLOG_ERR1(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

// Handy debugging function for sending the character-by-character unicode of a string to NSLog
void stringToUnicodeNSLog(NSString *string)
{
    for (int i=0; i<[string length]; i++) {
        unichar c = [string characterAtIndex:i];
        NSLog(@"Character = %C, %d", c, c);
    }
}

// Converts from milliseconds to a string formatted as "X days, Y hours, Z minutes"
NSString *durationString(double milliseconds)
{
    NSString *returnString;
    double minutes = milliseconds / (1000.0 * 60.0);
    if (minutes < 1.0) {
        returnString = @"less than 1 minute";
    }
    else if (minutes <1.5) {
        returnString = @"1 minute";
    }
    else if (minutes < 60.0) {
        returnString = [NSString stringWithFormat:@"%d minutes", (int) round(minutes)];
    }
    else {  // hours
        NSString *daysString = @"";
        NSString *hoursString;
        int hours = (int) floor(minutes/60);
        minutes = minutes - hours * 60;  // redo minutes to remaining minutes after hours taken out
        if (hours == 1) {
            hoursString = @"1 hr";
        }
        else if (hours < 24) {
            hoursString = [NSString stringWithFormat:@"%d hrs", hours];
        }
        else { // days
            int days = (int) floor((float) hours / 24.0);
            hours = hours - (days * 24);  // redo hours to remianing hours after days taken out
            if (days == 1) {
                daysString = @"1 day";
            }
            else {
                daysString = [NSString stringWithFormat:@"%d days", days];
            }
            if (hours > 1) {
                hoursString = [NSString stringWithFormat:@"%@, %d hrs", daysString, hours];
            }
            else if (hours == 1) {
                hoursString = [NSString stringWithFormat:@"%@, %d hr", daysString, hours];
            }
            else {
                hoursString = daysString;
            }
        }
        // Now add minutes (abbreviated) after hours, if needed
        if (minutes < 1.0) {
            returnString = hoursString;
        } else { // Minutes plus hours
            NSString* minutesString;
            if (minutes <1.5) {
                minutesString = @"1 min";
            }
            else {
                minutesString = [NSString stringWithFormat:@"%d min", (int) round(minutes)];
            }
            returnString = [NSString stringWithFormat:@"%@, %@", hoursString, minutesString];
        }
    }
    return returnString;
}

// Returns a NSDateFormatter set for short time format
NSDateFormatter *utilitiesShortTimeFormatter(void) {
    if (!utilitiesTimeFormatter) {
        utilitiesTimeFormatter = [[NSDateFormatter alloc] init];
        [utilitiesTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return utilitiesTimeFormatter;
}

// 
NSString *superShortTimeStringForDate(NSDate *date) {
    NSMutableString* timeString = [NSMutableString stringWithString:
                                   [utilitiesShortTimeFormatter() stringFromDate:date]];
    // Remove the space before AM/PM
    [timeString replaceOccurrencesOfString:@" " 
                                withString:@"" 
                                   options:0 
                                     range:NSMakeRange(0, [timeString length])];
    // Convert to lowercase
    NSString* returnString = [timeString lowercaseString];
    return returnString;
}


// Converts from meters to a string in either miles or feet
NSString *distanceStringInMilesFeet(double meters) {
    NSString *returnString;
    double feet = meters * 3.2808398950131235;  // from http://www.calculateme.com/Length/Meters/ToFeet.htm
    double miles = feet / 5280.0;
    if (miles < 0.1) {  // convey in feet
        if (feet < 1.0) {
            returnString = @"less than 1 foot";
        }
        else if (feet < 1.5) {
            returnString = @"1 foot";
        }
        else {
            returnString = [NSString stringWithFormat:@"%d feet", (int) round(feet)];
        }
    }
    else { // convey in miles
        returnString = [NSString stringWithFormat:@"%.1f miles", miles];
    }
    return returnString;
}

//
// Returns a NSDate object containing just the time of the date parameter.
// Uses [NSCalendar currentCalendar] and the hours and minutes components to compute
//
NSDate *timeOnlyFromDate(NSDate *date) {
    // Set up what we need to look at date components
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSUInteger timeComponents = NSHourCalendarUnit | NSMinuteCalendarUnit;
    
    // Get the key times (independent of date)
    NSDate *returnTime = [calendar dateFromComponents:[calendar components:timeComponents
                                                                   fromDate:date]];
    return returnTime;
}

//
// Returns a NSDate object containing just the date part of the date parameter (not the time)
// Uses [NSCalendar currentCalendar] and the month, day, and year components to compute
//
NSDate *dateOnlyFromDate(NSDate *date) {
    // Set up what we need to look at date components
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSUInteger timeComponents = NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit;
    
    // Get the key times (independent of date)
    NSDate *returnTime = [calendar dateFromComponents:[calendar components:timeComponents
                                                                  fromDate:date]];
    return returnTime;
}

//
// Retrieves the day of week from the date (Sunday = 1, Saturday = 7)
//
NSInteger dayOfWeekFromDate(NSDate *date) {
    // Set up what we need to look at date components
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSUInteger timeComponents = NSWeekdayCalendarUnit;
    
    // Get the key times (independent of date)
    NSInteger returnedWeekday = [[calendar components:timeComponents fromDate:date] weekday];
    return returnedWeekday;
}

//
// Returns a date where the date components are taken from date, and the time components are
// taken from time
//
NSDate *addDateOnlyWithTimeOnly(NSDate *date, NSDate *time) {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSUInteger dateComponentNames = NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit;
    NSUInteger timeComponentNames = NSHourCalendarUnit | NSMinuteCalendarUnit;

    // Get the components of date and time
    NSDateComponents* dateComponents = [calendar components:dateComponentNames fromDate:date];
    NSDateComponents* timeComponents = [calendar components:timeComponentNames fromDate:time];
    
    // Transfer time components over
    [dateComponents setHour:[timeComponents hour]];
    [dateComponents setMinute:[timeComponents minute]];
    
    return [calendar dateFromComponents:dateComponents];
}

//
// Returns a date where the date components are taken from dateOnly, and this is added to time
// timeOnly is assumed to have originated from a timeOnly value, but may have a value that passes midnight
// (for example [itinerary startTimeOnly] value)
// This function is part of the DE161 fix
//
NSDate *addDateOnlyWithTime(NSDate *date, NSDate *timeOnly) {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSUInteger dateComponentNames = NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit;
    
    // Get the components of date 
    NSDateComponents* dateComponents = [calendar components:dateComponentNames fromDate:date];
    
    // Get the zeroTime, which is the time corresponding to all zeros in the NSDateComponents
    NSDateComponents* zeroTimeComponents = [[NSDateComponents alloc] init];
    NSDate* zeroTime = [calendar dateFromComponents:zeroTimeComponents];
    // Get the time interval from timeOnly from zeroTime
    NSTimeInterval timeOnlyInterval = [timeOnly timeIntervalSinceDate:zeroTime];
    
    // Return dateOnly plus the timeOnlyInterval
    return [[calendar dateFromComponents:dateComponents] dateByAddingTimeInterval:timeOnlyInterval];
}

//
// Returns a string that is a truncated version of string that fits within
// width using font
// Based on implementation from http://mobiledevelopertips.com/cocoa/truncate-an-nsstring-and-append-an-ellipsis-respecting-the-font-size.html
// If width is 0 or font == nil, returns entire string
//
#define ellipsis @"…"

NSString *stringByTruncatingToWidth(NSString *string, CGFloat width, UIFont *font)
{
    if (width == 0.0 || font==nil) {
        return string;
    }
    // Create copy that will be the returned result
    NSMutableString *truncatedString = [NSMutableString stringWithString:string];
    
    // Make sure string is longer than requested width
    if ([string sizeWithFont:font].width > width)
    {
        // Accommodate for ellipsis we'll tack on the end
        width -= [ellipsis sizeWithFont:font].width;
        
        // Get range for last character in string
        NSRange range = {truncatedString.length - 1, 1};
        
        // Loop, deleting characters until string fits within width
        while ([truncatedString sizeWithFont:font].width > width)
        {
            // Delete character at end
            [truncatedString deleteCharactersInRange:range];
            
            // Move back another character
            range.location--;
        }
        
        // Append ellipsis
        [truncatedString replaceCharactersInRange:range withString:ellipsis];
    }
    
    return truncatedString;
}

//
// Logs event to Flurry (and any other logging)
// Can accept up to 4 parameter names and value pairs.  If  the parameter name is nil, that parameter is not included in the log
// If the parameter value is nil, then the string @"null" is written in the log instead
//
void logEvent(NSString *eventName, NSString *param1name, NSString *param1value, NSString *param2name, NSString* param2value,
              NSString *param3name, NSString *param3value, NSString *param4name, NSString *param4value)
{
#if FLURRY_ENABLED
    if (eventName && [eventName length]>0) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:4];
        
        if (param1name && [param1name length]>0) {
            if (!param1value) {
                param1value = @"null";
            }
            [dictionary setObject:param1value forKey:param1name];
        }
        if (param2name && [param2name length]>0) {
            if (!param2value) {
                param2value = @"null";
            }
            [dictionary setObject:param2value forKey:param2name];
        }
        if (param3name && [param3name length]>0) {
            if (!param3value) {
                param3value = @"null";
            }
            [dictionary setObject:param3value forKey:param3name];
        }
        if (param4name && [param4name length]>0) {
            if (!param4value) {
                param4value = @"null";
            }
            [dictionary setObject:param4value forKey:param4name];
        }
        
        if ([dictionary count]>0) {
            [Flurry logEvent:eventName withParameters:dictionary];
        } else {
            [Flurry logEvent:eventName];
        }
    }

#endif
}

// Logs exception using NIMLOG_ERR1 and if Flurry activated, logs to Flurry as well 
void logException(NSString *errorName, NSString *errorMessage, NSException *e)
{
    NIMLOG_ERR1(@"\n----------> Exception in: %@, \n  Nimbler Message: %@, \n  Exception: %@", errorName, errorMessage, e);
#if FLURRY_ENABLED
    [Flurry logError:errorName message:errorMessage exception:e];
#endif
}

// Logs non-exception errror using NIMLOG_ERR1 and if Flurry activated, logs to Flurry as well
void logError(NSString *errorName, NSString *errorMessage)
{
    NIMLOG_ERR1(@"\n----------> Error in: %@, \n  Nimbler Message: %@", errorName, errorMessage);
#if FLURRY_ENABLED
    [Flurry logError:errorName message:errorMessage exception:nil];
#endif
}

// Handles and logs uncaught exceptions
void uncaughtExceptionHandler(NSException *exception)
{
    logException(@"Uncaught exception handler", @"", exception);
}
