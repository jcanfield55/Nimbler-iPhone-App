//
//  UtilityFunctions.m
//  Network Commuting
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "UtilityFunctions.h"


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
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
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
            hoursString = @"1 hour";
        }
        else if (hours < 24) {
            hoursString = [NSString stringWithFormat:@"%d hours", hours];
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
                hoursString = [NSString stringWithFormat:@"%@, %d hours", daysString, hours];
            }
            else if (hours == 1) {
                hoursString = [NSString stringWithFormat:@"%@, %d hour", daysString, hours];
            }
            else {
                hoursString = daysString;
            }
        }
        NSString *minutesString = durationString(minutes * 60.0 * 1000.0);
        if ([minutesString isEqualToString:@"less than 1 minute"]) {
            returnString = hoursString;  
        }
        else {
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


// Converts from meters to a string in either miles or feed
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
// Returns an NSDate object containing just the date (month, day, year) of the date parameter, but not the time
// Uses [NSCalendar currentCalendar] and the hours and minutes components to compute
//
