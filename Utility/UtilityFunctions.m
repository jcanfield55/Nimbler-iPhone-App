//
//  UtilityFunctions.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "UtilityFunctions.h"
#import "Logging.h"
#import "nc_AppDelegate.h"
#if FLURRY_ENABLED
#include "Flurry.h"
#endif


static NSDateFormatter *utilitiesTimeFormatter;  // Static variable for short time formatter for use by utility
static NSDateFormatter *timeFormatterForTimeString;  // used for dateForTimeString utility @"MM/dd/yyyy HH:mm:ss"
static NSDateFormatter *timeFormatterOnly;  // time formatter for HH:mm:ss
static NSDateFormatter *dayOfWeekFormatter;  // date formatter to return day of week @"e"
static NSDate *zeroTimeOnly;    // "Zero time, i.e. timeOnly for 00:00:00"
static NSCalendar *currentCalendar;   // [NSCalendar currentCalendar]
static NSDictionary *agencyShortNameMapping;  // used for returnShortAgencyName
static NSDictionary *agencyFeedIdFromAgencyNameDictionary;  // used by agencyFeedIdFromAgencyName
static NSDictionary *agencyNameFromAgencyFeedIdDictionary;  // used by agencyNameFromAgencyFeedId

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
            [managedObjectContext rollback];  // Revert to previous state so hopefully we can keep going
            [NSException raise:@"saveContext failed, rolling back" format:@"Reason: %@", error];
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
    NSString* origFormattedString = [utilitiesShortTimeFormatter() stringFromDate:date];
    if (!origFormattedString) {   // DE-208 attempted fix
        logError(@"Utilities --> superShortTimeStringForDate",
                 [NSString stringWithFormat:@"date = %@, utilitiesShortTimeFormatter = %@, origFormattedString = %@",
                  date, utilitiesShortTimeFormatter(), origFormattedString]);
        return @"";
    }
    NSMutableString* timeString = [NSMutableString stringWithString:origFormattedString];
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
//
NSDate *timeOnlyFromDate(NSDate *date) {
    if (!zeroTimeOnly) {
        if (!currentCalendar) {
            currentCalendar = [NSCalendar currentCalendar];
        }
        NSDateComponents* zeroTimeComponents = [[NSDateComponents alloc] init];
        zeroTimeOnly = [currentCalendar dateFromComponents:zeroTimeComponents];
    }
    
    NSDate* dateOnly = dateOnlyFromDate(date);
    NSTimeInterval timeOnlyInterval = [date timeIntervalSinceDate:dateOnly];
    return [zeroTimeOnly dateByAddingTimeInterval:timeOnlyInterval];

}

//
// Returns a NSString containing just the time of the date parameter in the format HH:mm:ss
//
NSString *timeStringFromDate(NSDate *date) {
    if (!timeFormatterOnly) {
        timeFormatterOnly = [[NSDateFormatter alloc] init];
        [timeFormatterOnly setDateFormat:@"HH:mm:ss"];
    }
    return [timeFormatterOnly stringFromDate:date];
}

//
// Assumes that the receiver is a timeString of format HH:mm:ss
// Returns a new timeString of the same format but with a value from adding interval (in seconds)
// Note: this will go past 24 hours (i.e. 25:30 represents 1:30am the next day).
//
NSString *timeStringByAddingInterval(NSString *timeString, NSTimeInterval interval) {
    NSArray *arrayTimeComponents = [timeString componentsSeparatedByString:@":"];
    int hours=0, minutes=0, seconds=0;
    for (int i=0; i<[arrayTimeComponents count]; i++) {
        int value = [[arrayTimeComponents objectAtIndex:i] intValue];
        if (i == 0) {
            hours = value;
        } else if (i==1) {
            minutes = [[arrayTimeComponents objectAtIndex:1] intValue];
        } else if (i==2) {
            seconds = [[arrayTimeComponents objectAtIndex:2] intValue];
        }
    }
    int intervalInt = interval;  // cast to an int
    int hoursInterval = intervalInt / (60*60);
    intervalInt = intervalInt - hoursInterval * (60*60);  // remaining minutes
    int minutesInterval = intervalInt / 60;
    int secondsInterval = intervalInt - minutesInterval * 60;  // remaining seconds
    
    hours = hours + hoursInterval;
    minutes = minutes + minutesInterval;
    seconds = seconds + secondsInterval;
    if (seconds >= 60) {
        minutes++;
        seconds = seconds - 60;
    }
    if (minutes >= 60) {
        hours++;
        minutes = minutes - 60;
    }
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}

//
// Returns a NSDate object containing just the date part of the date parameter (not the time)
//
NSDate *dateOnlyFromDate(NSDate *date) {
    if (!currentCalendar) {
        currentCalendar = [NSCalendar currentCalendar];
    }
    NSUInteger timeComponents = NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit;
    
    // Get the key times (independent of date)
    NSDate *returnDateOnly = [currentCalendar dateFromComponents:[currentCalendar components:timeComponents
                                                                                    fromDate:date]];
    return returnDateOnly;
}

//
// Retrieves the day of week from the date (Sunday = 1, Saturday = 7)
//
NSInteger dayOfWeekFromDate(NSDate *date) {
    if (!dayOfWeekFormatter) {
        dayOfWeekFormatter = [[NSDateFormatter alloc] init];
        [dayOfWeekFormatter setDateFormat:@"e"];
    }
    NSString* dayOfWeekStr = [dayOfWeekFormatter stringFromDate:date]; // returns a number format
    return [dayOfWeekStr intValue];
}

//
// Returns a date where the date components are taken from date, and the time components are
// taken from time
//
NSDate *addDateOnlyWithTimeOnly(NSDate *date, NSDate *time) {
    if (!currentCalendar) {
        currentCalendar = [NSCalendar currentCalendar];
    }
    NSUInteger dateComponentNames = NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit;
    NSUInteger timeComponentNames = NSHourCalendarUnit | NSMinuteCalendarUnit;

    // Get the components of date and time
    NSDateComponents* dateComponents = [currentCalendar components:dateComponentNames fromDate:date];
    NSDateComponents* timeComponents = [currentCalendar components:timeComponentNames fromDate:time];
    
    // Transfer time components over
    [dateComponents setHour:[timeComponents hour]];
    [dateComponents setMinute:[timeComponents minute]];
    
    return [currentCalendar dateFromComponents:dateComponents];
}

//
// Returns a date where the date components are taken from dateOnly, and this is added to time
// timeOnly is assumed to have originated from a timeOnly value, but may have a value that passes midnight
// (for example [itinerary startTimeOnly] value)
// This function is part of the DE161 fix
//
NSDate *addDateOnlyWithTime(NSDate *date, NSDate *timeOnly) {
    // Get the zeroTime, which is the time corresponding to all zeros in the NSDateComponents
    if (!zeroTimeOnly) {
        if (!currentCalendar) {
            currentCalendar = [NSCalendar currentCalendar];
        }
        NSDateComponents* zeroTimeComponents = [[NSDateComponents alloc] init];
        zeroTimeOnly = [currentCalendar dateFromComponents:zeroTimeComponents];
    }
    // Get the time interval from timeOnly from zeroTime
    NSTimeInterval timeOnlyInterval = [timeOnly timeIntervalSinceDate:zeroTimeOnly];
    
    // Return dateOnly plus the timeOnlyInterval
    return [dateOnlyFromDate(date) dateByAddingTimeInterval:timeOnlyInterval];
}

//
// Return date with time from time string like (10:45:00).
// Also handles times like 24:30 (by adding a day) for overnight trips per the GTFS standard
// This function should be used with addDateOnlyWithTime() function
//
NSDate *dateFromTimeString(NSString *strTime) {
    @try {
        NSString *newStrTime;
        NSArray *arrayTimeComponents = [strTime componentsSeparatedByString:@":"];
        int hours=0, minutes=0, seconds=0, days=0;
        for (int i=0; i<[arrayTimeComponents count]; i++) {
            int value = [[arrayTimeComponents objectAtIndex:i] intValue];
            if (i == 0) {
                hours = value;
            } else if (i==1) {
                minutes = [[arrayTimeComponents objectAtIndex:1] intValue];
            } else if (i==2) {
                seconds = [[arrayTimeComponents objectAtIndex:2] intValue];
            }
        }
        if(hours > 23){
            days = hours / 24;
            hours = hours % 24;
        }
        newStrTime = [NSString stringWithFormat:@"%d/%d/%d %d:%d:%d", 1, (days+1), 1, hours,minutes,seconds];
        
        if (!timeFormatterForTimeString) {
            timeFormatterForTimeString = [[NSDateFormatter alloc] init];
            timeFormatterForTimeString.dateFormat = @"MM/dd/yyyy HH:mm:ss";
        }
        NSDate *returnDate = [timeFormatterForTimeString dateFromString:newStrTime];
        return returnDate;
    }
    @catch (NSException *exception) {
        logException(@"UtilityFunctions->timeAndDateFromString", @"", exception);
    }
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
    if (!string) {
        return @"";
    }
    // Create copy that will be the returned result
    NSMutableString *truncatedString = [NSMutableString stringWithString:string];
    
    // Make sure string is longer than requested width
    if ([string sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width > width)
    {
        // Accommodate for ellipsis we'll tack on the end
        width -= [ellipsis sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width;
        
        // Get range for last character in string
        NSRange range = {truncatedString.length - 1, 1};
        
        // Loop, deleting characters until string fits within width
        while ([truncatedString sizeWithAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName]].width > width)
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
#if IS_KICKFOLIO
        [dictionary setObject:@"1" forKey:FLURRY_IS_KICKFOLIO];
#endif
#if FLURRY_ENABLED
        if ([dictionary count]>0) {
            [Flurry logEvent:eventName withParameters:dictionary];
        } else {
            [Flurry logEvent:eventName];
        }
#else
        // Log onto console if Flurry not enabled.
        
        NSMutableString* log = [NSMutableString stringWithFormat:@"Flurry event: %@", eventName];
        NSEnumerator* enumerator = [dictionary keyEnumerator];
        NSString* param;
        int i=1;
        while (param = [enumerator nextObject]) {  // enumerate thru all the type strings in the dictionary
            NSString* value = [dictionary objectForKey:param];
            [log appendFormat:@"\n  Param%d: %@, Value%d: %@",i, param, i, value];
            i++;
        }
        
        NIMLOG_FLURRY(@"%@", log);
#endif
    }

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

// Levenshtein Algorithm To calculate The Distance between Two String
// https://gist.github.com/1593632

float calculateLevenshteinDistance(NSString *originalString,NSString *comparisonString)
{
    // Normalize strings
    [originalString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [comparisonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    originalString = [originalString lowercaseString];
    comparisonString = [comparisonString lowercaseString];
    NSInteger k, i, j, cost, * d, distance;
    
    NSInteger n = [originalString length];
    NSInteger m = [comparisonString length];
    
    if( n++ != 0 && m++ != 0 ) {
        
        d = malloc( sizeof(NSInteger) * m * n );
        
        // Step 2
        for( k = 0; k < n; k++)
            d[k] = k;
        
        for( k = 0; k < m; k++)
            d[ k * n ] = k;
        
        // Step 3 and 4
        for( i = 1; i < n; i++ )
            for( j = 1; j < m; j++ ) {
                
                // Step 5
                if( [originalString characterAtIndex: i-1] ==
                   [comparisonString characterAtIndex: j-1] )
                    cost = 0;
                else
                    cost = 1;
                
                // Step 6
                d[ j * n + i ] = smallestOf3(d [ (j - 1) * n + i ] + 1,d[ j * n + i - 1 ] + 1,d[ (j - 1) * n + i - 1 ] + cost);
                if( i>1 && j>1 && [originalString characterAtIndex: i-1] ==
                   [comparisonString characterAtIndex: j-2] &&
                   [originalString characterAtIndex: i-2] ==
                   [comparisonString characterAtIndex: j-1] )
                {
                    d[ j * n + i] = smallestOf2(d[ j * n + i ],d[ (j - 2) * n + i - 2 ] + cost);
                }
            }
        
        distance = d[ n * m - 1 ];
        
        free( d );
        
        return distance;
    }
    return 0.0;
}

NSInteger smallestOf3(NSInteger a,NSInteger b,NSInteger c)
{
    NSInteger min = a;
    if ( b < min )
        min = b;
    
    if( c < min )
        min = c;
    
    return min;
}

NSInteger smallestOf2(NSInteger a,NSInteger b)
{
    NSInteger min=a;
    if (b < min)
        min=b;
    
    return min;
}

//Calculate Distance Between Two Location
CLLocationDistance distanceBetweenTwoLocation(CLLocation *toLocation,CLLocation *fromLocation){
    CLLocationDistance distance = [toLocation distanceFromLocation:fromLocation];
    return distance;
}

// Get AgencyId from Agencyname
NSString *agencyFeedIdFromAgencyName(NSString *agencyName){
    if (!agencyFeedIdFromAgencyNameDictionary) {
        agencyFeedIdFromAgencyNameDictionary = [Agencies agencies].agencyFeedIdFromAgencyNameDictionary;
    }
    return [agencyFeedIdFromAgencyNameDictionary objectForKey:agencyName];
}

// Get AgencyName from AgencyId
NSString *agencyNameFromAgencyFeedId(NSString *agencyId){
    if (!agencyNameFromAgencyFeedIdDictionary) {
        agencyNameFromAgencyFeedIdDictionary = [Agencies agencies].agencyNameFromAgencyFeedIdDictionary;
    }
    return [agencyNameFromAgencyFeedIdDictionary objectForKey:agencyId];
}

NSString *getItemAtIndexFromArray(int index,NSArray *arrayComponents){
    if([arrayComponents count] > index){
        return  [arrayComponents objectAtIndex:index];
    }
    return @"";
}
int timeIntervalFromDate(NSDate * date){
    if (!currentCalendar) {
        currentCalendar = [NSCalendar currentCalendar];
    }
    NSDateComponents *componentsDepartureTime = [currentCalendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    int hourDepartureTime = [componentsDepartureTime hour];
    int minuteDepartureTime = [componentsDepartureTime minute];
    int intervalDepartureTime = (hourDepartureTime)*60*60 + minuteDepartureTime*60;
    return intervalDepartureTime;
}

NSString *generateRandomString(int length){
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    for (int i = 0; i< length ; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    return randomString;
}

// return the image from document directory or from server
// First check if image exist at document directory folder if yes then take image from document directory otherwise request server for image and save image to document directory and next time use image from document directory.
UIImage *getAgencyIcon(NSString * imageName){
    UIImage *agencyImage;
    NSString *documentFolderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *strImagePath = [NSString stringWithFormat:@"%@/%@",documentFolderPath,imageName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath: strImagePath]){
        agencyImage = [UIImage imageWithData:[NSData dataWithContentsOfFile:strImagePath]];
    }
    else{
        agencyImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@",TRIP_PROCESS_URL,LIVE_FEEDS_IMAGE_DOWNLOAD_URL,imageName]]]];
        NSData *imageData = UIImagePNGRepresentation(agencyImage);
        [imageData writeToFile:strImagePath atomically:YES];
    }
    return agencyImage;
}

NSString *returnShortAgencyName(NSString *agencyName){
    ;
    if (!agencyShortNameMapping) {
        agencyShortNameMapping = [Agencies agencies].agencyButtonNameByAgencyDictionary;
    }
    if (!agencyName) {
        return nil;
    }
    NSString* returnString = [agencyShortNameMapping objectForKey:agencyName];
    if (returnString) {
        return returnString;
    } else {
        return agencyName;
    }
}

NSString *returnRouteTypeFromLegMode(NSString *legMode){
    legMode = [legMode lowercaseString];
    if([legMode isEqualToString:@"tram"])
        return @"0";
    else if([legMode isEqualToString:@"subway"])
        return @"1";
    else if([legMode isEqualToString:@"rail"])
        return @"2";
    else if([legMode isEqualToString:@"bus"])
        return @"3";
    else if([legMode isEqualToString:@"ferry"])
        return @"4";
    else if([legMode isEqualToString:@"cable car"])
        return @"5";
    else if([legMode isEqualToString:@"gondola"])
        return @"6";
    else if([legMode isEqualToString:@"funicular"])
        return @"7";
    else
        return nil;
}

int timeIntervalFromTimeString(NSString *strTime) {
    NSArray *arrayTimeComponents = [strTime componentsSeparatedByString:@":"];
    int hours=0, minutes=0, seconds=0;
    for (int i=0; i<[arrayTimeComponents count]; i++) {
        int value = [[arrayTimeComponents objectAtIndex:i] intValue];
        if (i == 0) {
            hours = value;
        } else if (i==1) {
            minutes = [[arrayTimeComponents objectAtIndex:1] intValue];
        } else if (i==2) {
            seconds = [[arrayTimeComponents objectAtIndex:2] intValue];
        }
    }
    if(hours > 23){
        hours = hours % 24;
    }
    int interval = (hours*60*60) + (minutes*60) + seconds;
    return interval;
}

// http://stackoverflow.com/questions/6466178/how-to-convert-an-nsdata-to-a-zip-file-with-objective-c/6466832#6466832

// Compress the NSData
NSData* compressData(NSData* uncompressedData) {
    if ([uncompressedData length] == 0) return uncompressedData;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[uncompressedData bytes];
    strm.avail_in = (unsigned int)[uncompressedData length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (unsigned int)([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    return [NSData dataWithData:compressed];
}

// UnCompress the NSData
NSData* uncompressGZip(NSData* compressedData) {
    if ([compressedData length] == 0) return compressedData;
    
    NSUInteger full_length = [compressedData length];
    NSUInteger half_length = [compressedData length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[compressedData bytes];
    strm.avail_in = (unsigned int)[compressedData length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    
    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length]) {
            [decompressed increaseLengthBy: half_length];
        }
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (unsigned int)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) {
            done = YES;
        } else if (status != Z_OK) {
            break;
        }
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done) {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    } else {
        return nil;
    }
}

NSString *returnBikeButtonTitle(void){
    if([[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId] isEqualToString:WMATA_APP_TYPE]){
        return MY_BIKE;
    }
    else{
        return BIKE_BUTTON;
    }
}

NSString *containsListFromFormattedAddress(NSString *formattedAddress){
    if([formattedAddress isEqualToString:@"SF-Muni Station List"]){
        return @"muni_st_list";
    }
    else if([formattedAddress isEqualToString:@"Caltrain Station List"]){
       return @"caltrain_st_list";
    }
    else if([formattedAddress isEqualToString:@"Trimet Station List"]){
       return @"trimet_st_list";
    }
    else{
        return @"bart_st_list";
    }
}
UIImage *returnNavigationBarBackgroundImage(void){
    UIImage *navBarBackgroundImage;
    if([[[UIDevice currentDevice] systemVersion] intValue] >= 7){
        navBarBackgroundImage = [UIImage imageNamed:@"navBar.png"];
    }
    else{
       navBarBackgroundImage = [UIImage imageNamed:@"navBarNormal.png"];
    }
    return navBarBackgroundImage;
}

// Takes a NSObject, object, of unknown type and returns a NSNumber if possible.
// If object is a NSNumber, returns that.
// If object is a NSString, converts string to a number if possible using a doubleValue.
// NSString objects with non-numberic values will return a NSNumber with value = 0
// If object is nil or any other type, returns nil.
NSNumber *NSNumberFromNSObject(NSObject *object)
{
    if (object == nil) {
        return nil;
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)object;
    }
    else if ([object isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *) object;
        NSNumber *number = [NSNumber numberWithDouble:[string doubleValue]];
        return number;
    }
    return nil;  // return nil if not a NSNumber or NSString
}

// Takes a NSObject, object, of unknown type and returns an NSString if possible.
// If object is nil or any other type, returns nil.
NSString *NSStringFromNSObject(NSObject *object)
{
    if (object == nil) {
        return nil;
    }
    else if ([object isKindOfClass:[NSString class]]) {
        return (NSString *)object;
    }
    return nil;  // return nil if not an NSString
}