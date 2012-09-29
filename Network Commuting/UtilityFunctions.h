//
//  UtilityFunctions.h
//  Network Commuting
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h> 
#import <CoreLocation/CoreLocation.h>

NSString *pathInDocumentDirectory(NSString *fileName);

void saveContext(NSManagedObjectContext *managedObjectContext);

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

// Logs exception using NIMLOG_ERR1 and if Flurry activated, logs to Flurry as well
void logException(NSString *errorName, NSString *errorMessage, NSException *e);

// Logs errors using NIMLOG_ERR1 and if Flurry activated, logs to Flurry as well
void logError(NSString *errorName, NSString *errorMessage);

// Handles and logs uncaught exceptions
void uncaughtExceptionHandler(NSException *exception);