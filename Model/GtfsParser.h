//
//  GtfsParser.h
//  Nimbler Caltrain
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import <Restkit/RKJSONParserJSONKit.h>
#import "Plan.h"
#import "Leg.h"
#import "Schedule.h"
#import "PlanRequestParameters.h"
#import "GtfsCalendar.h"

@interface GtfsParser : NSObject<RKRequestDelegate>{
    NSManagedObjectContext *managedObjectContext;
}
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSString *strAgenciesURL;
@property (strong, nonatomic) NSString *strCalendarDatesURL;
@property (strong, nonatomic) NSString *strCalendarURL;
@property (strong, nonatomic) NSString *strRoutesURL;
@property (strong, nonatomic) NSString *strStopsURL;
@property (strong, nonatomic) NSString *strTripsURL;
@property (strong, nonatomic) NSString *strStopTimesURL;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc;
- (void) parseAgencyDataAndStroreToDataBase:(NSDictionary *)dictFileData;
- (void) parseCalendarDatesDataAndStroreToDataBase:(NSDictionary *)dictFileData;
- (void) parseCalendarDataAndStroreToDataBase:(NSDictionary *)dictFileData;
- (void) parseRoutesDataAndStroreToDataBase:(NSDictionary *)dictFileData;
- (void) parseStopsDataAndStroreToDataBase:(NSDictionary *)dictFileData;
- (void) parseTripsDataAndStroreToDataBase:(NSDictionary *)dictFileData;
- (void) parseStopTimesAndStroreToDataBase:(NSDictionary *)dictFileData:(NSString *)strResourcePath;
- (NSArray *)findNearestStation:(CLLocation *)toLocation;
-(void)getAgencyDatas;
-(void)getCalendarDates;
-(void)getCalendarData;
-(void)getRoutesData;
-(void)getStopsData;
-(void)getTripsData;
- (void) getGtfsStopTimes:(NSMutableString *)strRequestString;

// Generate The StopTimes Request Comma Separated string like agencyID_tripID
- (void)generateStopTimesRequestString:(Plan *)plan;

// Get The stopID form GtfsStop Table from To&From Location.
- (NSString *) getTheStopIDAccrodingToStation:(NSNumber *)lat:(NSNumber *)lng;

// get serviceID based on tripId.
- (NSString *) getServiceIdFromTripID:(NSString *)strTripID;

// Get Calendar Data from GtfsCalendar based on serviceID
- (GtfsCalendar *)getCalendarDataFromDatabase:(NSString *)strServiceID;

// This method get the serviceId based on tripId.
// Then get the calendar data for particular serviceID.
// the check for the request date comes after service start date and comes befor enddate.
// then check service is enabled on request day if yes then return yes otherwise return no.
- (BOOL) isServiceEnableForDay:(NSString *)strTripID:(NSDate *)requestDate;

// first get stoptimes from StopTimes Table based on stopId
// Then make a pair of StopTimes if both stoptimes have same tripId then check for the stopSequence and the departure time is greater than request trip time and also check if service is enabled for that stopTimes if yes the add both stopTimes as To/From StopTimes pair.
- (NSArray *)getStopTimes:(NSString *)strToStopID:(NSString *)strFromStopID:(PlanRequestParameters *)parameters;


// TODO:- Need to sort the stopTimes array according to departureTime. Then take first stopTimes from leg and call initWithToStopTime method to set from&toStopTime and save leg.

// Get Stored Patterns fron Database
// Get The StopId From Stop Table and then get stoptimes according to stopID from StopTimes Table.
- (void)generateLegsFromPatterns:(Plan *)plan:(PlanRequestParameters *)parameters;
@end
