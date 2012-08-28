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