//
//  TransitCalendar.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/21/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
// This class stores transit calendars for various agencies and does matching on whether a cached transit
// request would have the same schedule as a new request

#import "TransitCalendar.h"
#import "UtilityFunctions.h"
#import "KeyObjectStore.h"
#import "Constants.h"

@interface TransitCalendar()

// Stub functions.  Should be replaced by calls to the server
- (NSDictionary *)getLastGTFSLoadDateByAgencyStub;
- (NSDictionary *)getCalendarDatesDictionaryStub;
- (NSArray *)getServiceByWeekdayArrayStub;

@end


@implementation TransitCalendar

@synthesize lastGTFSLoadDateByAgency;
@synthesize calendarDatesDictionary;
@synthesize serviceByWeekdayArray;

// Accessor override to populate this dictionary if not already there
- (NSDictionary *)lastGTFSLoadDateByAgency
{
    if (!lastGTFSLoadDateByAgency) {
        // See if it is the KeyObjectStore
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        lastGTFSLoadDateByAgency = [keyObjectStore objectForKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
        if (!lastGTFSLoadDateByAgency) {
            // use stub function to get values -- change this once have server call
            lastGTFSLoadDateByAgency = [self getLastGTFSLoadDateByAgencyStub];
            [keyObjectStore setObject:lastGTFSLoadDateByAgency forKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
        }
    }
    return lastGTFSLoadDateByAgency;
}


- (NSDictionary *)calendarDatesDictionary
{
    if (!calendarDatesDictionary) {
        // See if it is the KeyObjectStore
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        calendarDatesDictionary = [keyObjectStore objectForKey:TR_CALENDAR_DATES_DICTIONARY];
        if (!calendarDatesDictionary) {
            // use stub function to get values -- change this once have server call
            calendarDatesDictionary = [self getCalendarDatesDictionaryStub];
            [keyObjectStore setObject:calendarDatesDictionary forKey:TR_CALENDAR_DATES_DICTIONARY];
        }
    }
    return calendarDatesDictionary;
}

- (NSArray *)serviceByWeekdayArray
{
    if (!serviceByWeekdayArray) {
        // See if it is the KeyObjectStore
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        serviceByWeekdayArray = [keyObjectStore objectForKey:TR_CALENDAR_SERVICE_BY_WEEKDAY_ARRAY];
        if (!serviceByWeekdayArray) {
            // use stub function to get values -- change this once have server call
            serviceByWeekdayArray = [self getServiceByWeekdayArrayStub];
            [keyObjectStore setObject:serviceByWeekdayArray forKey:TR_CALENDAR_SERVICE_BY_WEEKDAY_ARRAY];
        }
    }
    return serviceByWeekdayArray;
}


//
// Returns true if the provided date comes after the last GTFS update for given agencyId
//
- (BOOL)isCurrentVsGtfsFileFor:(NSDate *)date agencyId:(NSString *)agencyId
{
    NSDate* gtfsLoadDate = [lastGTFSLoadDateByAgency objectForKey:agencyId];
    if ([date compare:gtfsLoadDate] == NSOrderedDescending) {
        // If dates come after the gtfsLoadDate, then return true
        return true;
    } else {
        return false;
    }
    
}


//
// Returns true if the two dates have equivalent service schedule based on:
//   - day of the week and calendar.txt GTFS file for the given agencyId
//   - any exceptions in calendar_dates.txt GTFS file for the given agencyId
// Otherwise returns false
//
- (BOOL)isEquivalentServiceDayFor:(NSDate *)date1 And:(NSDate *)date2 agencyId:(NSString *)agencyId
{

    NSInteger dayOfWeek1 = dayOfWeekFromDate(date1);
    NSInteger dayOfWeek2 = dayOfWeekFromDate(date2);
    
    NSString* date1String; // TODO get this string
    NSString* date2String; // TODO get this string
        
    // Compare the weekday codes
    NSString* date1Services = [serviceByWeekdayArray objectAtIndex:dayOfWeek1];
    NSString* date2Services = [serviceByWeekdayArray objectAtIndex:dayOfWeek2];
    
    // Look for exceptions in the calendarDates Dictionary and refine as needed
    NSString* date1ServiceExemption = [calendarDatesDictionary objectForKey:date1String];
    if (date1ServiceExemption) {
        date1Services = date1ServiceExemption;
    }
    NSString* date2ServiceExemption = [calendarDatesDictionary objectForKey:date2String];
    if (date2ServiceExemption) {
        date2Services = date2ServiceExemption;
    }
    
    if ([date1Services isEqualToString:date2Services]) {
        return true; // if the services match, return true
    } else {
        return false;
    }
}


@end
