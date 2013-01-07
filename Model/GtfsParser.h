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
#import "PlanRequestParameters.h"
#import "GtfsCalendar.h"
#import "GtfsRoutes.h"
#import "GtfsTrips.h"
#import "GtfsStop.h"

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

// Parse the Gtfs Agency Data and store to database.
- (void) parseAndStroreGtfsAgencyData:(NSDictionary *)dictFileData;

// Parse the Gtfs CalendarDates Data and store to database.
- (void) parseAndStoreGtfsCalendarDatesData:(NSDictionary *)dictFileData;

// Parse the Gtfs Calendar Data and store to database.
- (void) parseAndStoreGtfsCalendarData:(NSDictionary *)dictFileData;

// Parse the Gtfs Routes Data and store to database.
- (void) parseAndStoreGtfsRoutesData:(NSDictionary *)dictFileData;

// Parse the Gtfs Stops Data and store to database.
- (void) parseAndStoreGtfsStopsData:(NSDictionary *)dictFileData;

// Parse the Gtfs Trips Data and store to database.
- (void) parseAndStroreGtfsTripsData:(NSDictionary *)dictFileData;

// Parse the Gtfs StopTimes Data and store to database.
- (void) parseAndStoreGtfsStopTimesData:(NSDictionary *)dictFileData RequestUrl:(NSString *) strResourcePath;

-(void)requestAgencyDataFromServer;
-(void)requestCalendarDatesDataFromServer;
-(void)requestCalendarDatafromServer;
-(void)requestRoutesDatafromServer;
-(void)requestStopsDataFromServer;
-(void)requestTripsDatafromServer:(NSMutableString *)strRequestString;
- (void)requestStopTimesDataFromServer:(NSMutableString *)strRequestString;

// Generate The StopTimes Request Comma Separated string like agencyID_tripID
- (void)generateStopTimesRequestString:(Plan *)plan;

// Generate The Trips Request Comma Separated string like agencyID_ROUTEID
- (void)generateGtfsTripsRequestStringUsingPlan:(Plan *) plan;

// Get The stopID form GtfsStop Table from To&From Location.
- (NSString *) getTheStopIDAccrodingToStation:(NSNumber *)lat:(NSNumber *)lng;

// get serviceID based on tripId.
- (NSString *) getServiceIdFromTripID:(NSString *)strTripID;

// Get trips Data from GtfsTrips based on tripID
- (GtfsTrips *)getTripsDataFromDatabase:(NSString *)strTripID;

// Get stops Data from GtfsStop based on stopID
- (GtfsStop *)getStopsDataFromDatabase:(NSString *)strStopID;

// Get routes Data from GtfsRoutes based on routeID
- (GtfsRoutes *)getRoutesDataFromDatabase:(NSString *)strRouteID;

// Get Calendar Data from GtfsCalendar based on serviceID
- (GtfsCalendar *)getCalendarDataFromDatabase:(NSString *)strServiceID;

// This method get the serviceId based on tripId.
// Then get the calendar data for particular serviceID.
// the check for the request date comes after service start date and comes befor enddate.
// then check service is enabled on request day if yes then return yes otherwise return no.
- (BOOL) isServiceEnableForTripID:(NSString *)strTripID RequestDate:(NSDate *)requestDate;

// first get stoptimes from StopTimes Table based on stopId
// Then make a pair of StopTimes if both stoptimes have same tripId then check for the stopSequence and the departure time is greater than request trip time and also check if service is enabled for that stopTimes if yes the add both stopTimes as To/From StopTimes pair.
- (NSMutableArray *)getStopTimes:(NSString *)strToStopID strFromStopID:(NSString *)strFromStopID parameters:(PlanRequestParameters *)parameters;

// First get The unique itinerary pattern from plan.the loop through every itinerary pattern.
// For each legs of itinerary pattern check first if it is walk leg if yes the create new leg with some additional attributes.
// if leg is transit leg then first get the stoptimes from that leg and choose nearest stoptimes and remove it from mutable array.
// this lopp continue until we have stoptimes data.

- (void)generateLegsAndItineraryFromPatternsOfPlan:(Plan *)plan parameters:(PlanRequestParameters *)parameters;

- (NSDate *)timeAndDateFromString:(NSString *)strTime;
- (NSArray *) findNearestStopTimeFromStopTimeArray:(NSArray *)arrStopTimes Itinerary:(Itinerary *)itinerary;

@end

