//
//  UtilityFunctions.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h> 
#import <CoreLocation/CoreLocation.h>

NSString *pathInDocumentDirectory(NSString *fileName);

void saveContext(NSManagedObjectContext *managedObjectContext);

// Handy debugging function for sending the character-by-character unicode of a string to NSLog
void stringToUnicodeNSLog(NSString *string);

// Converts from milliseconds to a string formatted as "X days, Y hours, Z minutes"
NSString *durationString(double milliseconds);

// Converts from meters to a string in either miles or feed
NSString *distanceStringInMilesFeet(double meters);

NSDateFormatter *utilitiesShortTimeFormatter(void);
NSString *superShortTimeStringForDate(NSDate *date);

// Returns a NSDate object containing just the time of the date parameter.
// Uses [NSCalendar currentCalendar] and the hours and minutes components to compute
NSDate *timeOnlyFromDate(NSDate *date);

// Returns a NSDate object containing just the date part of the date parameter (not the time)
// Uses [NSCalendar currentCalendar] and the month, day, and year components to compute
NSDate *dateOnlyFromDate(NSDate *date);

// Retrieves the day of week from the date (Sunday = 1, Saturday = 7)
NSInteger dayOfWeekFromDate(NSDate *date);

// Returns a date where the date components are taken from dateOnly, and the time components are
// taken from timeOnly
NSDate *addDateOnlyWithTimeOnly(NSDate *dateOnly, NSDate *timeOnly);

// Returns a date where the date components are taken from dateOnly, and this is added to time
// timeOnly is assumed to have originated from a timeOnly value, but may have a value that passes midnight
// (for example [itinerary startTimeOnly] value)
NSDate *addDateOnlyWithTime(NSDate *date, NSDate *timeOnly);

//
// Returns a string that is a truncated version of string that fits within
// width using font
//
NSString *stringByTruncatingToWidth(NSString *string, CGFloat width, UIFont *font);

//
// Logs event to Flurry (and any other logging)
// Can accept up to 4 parameter names and value pairs.  If  the parameter name is nil, that parameter is not included in the log
// If the parameter value is nil, then the string @"nil" is written in the log instead
//
void logEvent(NSString *eventName, NSString *param1name, NSString *param1value, NSString *param2name, NSString* param2value,
              NSString *param3name, NSString *param3value, NSString *param4name, NSString *param4value);

// Logs exception using NIMLOG_ERR1 and if Flurry activated, logs to Flurry as well
void logException(NSString *errorName, NSString *errorMessage, NSException *e);

// Logs errors using NIMLOG_ERR1 and if Flurry activated, logs to Flurry as well
void logError(NSString *errorName, NSString *errorMessage);

// Handles and logs uncaught exceptions
void uncaughtExceptionHandler(NSException *exception);
float calculateLevenshteinDistance(NSString *originalString,NSString *comparisonString);
NSInteger smallestOf3(NSInteger a,NSInteger b,NSInteger c);
NSInteger smallestOf2(NSInteger a,NSInteger b);

//Calculate Distance Between Two Location
CLLocationDistance distanceBetweenTwoLocation(CLLocation *toLocation,CLLocation *fromLocation);