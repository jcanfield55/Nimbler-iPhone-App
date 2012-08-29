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
- (void)getAgencyCalendarDataStub;

@end

@implementation TransitCalendar

@synthesize lastGTFSLoadDateByAgency;
@synthesize calendarByDateByAgency;
@synthesize serviceByWeekdayByAgency;

static TransitCalendar * transitCalendarSingleton;


// returns the singleton value.  
+ (TransitCalendar *)transitCalendar
{
    if (!transitCalendarSingleton) {
        transitCalendarSingleton = [[TransitCalendar alloc] init];
    }
    return transitCalendarSingleton;
}



// Accessor override to populate this dictionary if not already there
- (NSDictionary *)lastGTFSLoadDateByAgency
{
    if (!lastGTFSLoadDateByAgency) {
        // See if it is the KeyObjectStore
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        lastGTFSLoadDateByAgency = [keyObjectStore objectForKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
        if (!lastGTFSLoadDateByAgency) {
            // use stub function to get values -- change this once have server call
            [self getAgencyCalendarDataStub];
            [keyObjectStore setObject:lastGTFSLoadDateByAgency forKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
        }
    }
    return lastGTFSLoadDateByAgency;
}


- (NSDictionary *)calendarByDateByAgency
{
    if (!calendarByDateByAgency) {
        // See if it is the KeyObjectStore
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        calendarByDateByAgency = [keyObjectStore objectForKey:TR_CALENDAR_BY_DATE_BY_AGENCY ];
        if (!calendarByDateByAgency) {
            // use stub function to get values -- change this once have server call
            [self getAgencyCalendarDataStub];
            [keyObjectStore setObject:calendarByDateByAgency forKey:TR_CALENDAR_BY_DATE_BY_AGENCY];
        }
    }
    return calendarByDateByAgency;
}

- (NSDictionary *)serviceByWeekdayByAgency
{
    if (!serviceByWeekdayByAgency) {
        // See if it is the KeyObjectStore
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        serviceByWeekdayByAgency = [keyObjectStore objectForKey:TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY];
        if (!serviceByWeekdayByAgency) {
            // use stub function to get values -- change this once have server call
            [self getAgencyCalendarDataStub];
            [keyObjectStore setObject:serviceByWeekdayByAgency forKey:TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY ];
        }
    }
    return serviceByWeekdayByAgency;
}


//
// Returns true if the provided date comes after the last GTFS update for given agencyId
//
- (BOOL)isCurrentVsGtfsFileFor:(NSDate *)date agencyId:(NSString *)agencyId
{
    NSDate* gtfsLoadDate = [[self lastGTFSLoadDateByAgency] objectForKey:agencyId];
    if (gtfsLoadDate && [date compare:gtfsLoadDate] == NSOrderedDescending) {
        // If dates come after the gtfsLoadDate, then return true
        return true;
    } else {
        return false;
    }
    
}

// Returns the agency-specific services string for the given date and agency
- (NSString *)serviceStringForDate:(NSDate *)date agencyId:(NSString *)agencyId
{
    NSInteger dayOfWeek = dayOfWeekFromDate(date)-1;
    NSDate* dateOnly = dateOnlyFromDate(date);
    
    // Get the weekday services code
    NSString* dateServices = [[[self serviceByWeekdayByAgency] objectForKey:agencyId] objectAtIndex:dayOfWeek];
    
    // Look for exceptions in the calendarDates Dictionary and refine as needed
    NSString* dateServiceExemption = [[[self calendarByDateByAgency] objectForKey:agencyId] objectForKey:dateOnly];
    if (dateServiceExemption) {
        dateServices = dateServiceExemption;
    }
    return dateServices;
}

//
// Returns true if the two dates have equivalent service schedule based on:
//   - day of the week and calendar.txt GTFS file for the given agencyId
//   - any exceptions in calendar_dates.txt GTFS file for the given agencyId
// Otherwise returns false
//
- (BOOL)isEquivalentServiceDayFor:(NSDate *)date1 And:(NSDate *)date2 agencyId:(NSString *)agencyId
{
    NSString* date1Services = [self serviceStringForDate:date1 agencyId:agencyId];
    NSString* date2Services = [self serviceStringForDate:date2 agencyId:agencyId];
    
    return (date1Services && date2Services && [date1Services isEqualToString:date2Services]);
}

// TODO - Handle walking legs appropriately (they do not have a transit agency or schedule)

//
// Stub for filling in the trip information
// TODO -- replace this stubs with logic to load periodically from server
//

- (void)getAgencyCalendarDataStub
{
    NSArray* agencyIDs = [NSArray arrayWithObjects:
                          @"VTA", @"SFMTA", @"BART", @"AirBART", @"AC Transit",
                          @"caltrain-ca-us", nil];
    NSMutableDictionary* lastGTFSLoadDateMutable = [[NSMutableDictionary alloc] initWithCapacity:[agencyIDs count]];
    NSMutableDictionary* serviceByWeekdayMutable = [[NSMutableDictionary alloc] initWithCapacity:[agencyIDs count]];
    NSMutableDictionary* calendarByDateMutable = [[NSMutableDictionary alloc] initWithCapacity:[agencyIDs count]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    NSDate* loadDate = [dateFormatter dateFromString:@"July 11, 2012"];  // Last Caltrain load time
    NSDate* laborDay = [dateFormatter dateFromString:@"September 3, 2012"];
    
    for (NSString* agencyID in agencyIDs) {
        [lastGTFSLoadDateMutable setObject:loadDate forKey:agencyID];
        
        // Indicate different services for weekdays, Saturdays and Sundays
        NSArray* serviceByWeekday = [NSArray arrayWithObjects:@"Sunday", @"Weekday",
                                     @"Weekday", @"Weekday", @"Weekday", @"Weekday", @"Saturday", nil];
        NSArray* ACTransitServiceByWeekday = [NSArray arrayWithObjects:@"Sunday", @"Monday",
                                              @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", nil];
        if ([agencyID isEqualToString:@"AC Transit"]) {
            [serviceByWeekdayMutable setObject:ACTransitServiceByWeekday forKey:agencyID];
        } else {
            [serviceByWeekdayMutable setObject:serviceByWeekday forKey:agencyID];
        }
        
        NSDictionary* calendarByDate = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"Sunday", laborDay, nil];  // Give Sunday schedule on Labor Day
        [calendarByDateMutable setObject:calendarByDate forKey:agencyID];
    }
    
    lastGTFSLoadDateByAgency = lastGTFSLoadDateMutable;
    serviceByWeekdayByAgency = serviceByWeekdayMutable;
    calendarByDateByAgency = calendarByDateMutable;
}



@end
