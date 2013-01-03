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
- (BOOL) isServiceEnableForDay:(NSString *)strTripID:(NSDate *)requestDate;

// first get stoptimes from StopTimes Table based on stopId
// Then make a pair of StopTimes if both stoptimes have same tripId then check for the stopSequence and the departure time is greater than request trip time and also check if service is enabled for that stopTimes if yes the add both stopTimes as To/From StopTimes pair.
- (NSArray *)getStopTimes:(NSString *)strToStopID strFromStopID:(NSString *)strFromStopID parameters:(PlanRequestParameters *)parameters;

// Get Stored Patterns fron Database
// Get The StopId From Stop Table and then get stoptimes according to stopID from StopTimes Table.
- (void)generateLegsFromPatterns:(Plan *)plan parameters:(PlanRequestParameters *)parameters;


// TODO:- Need to calculate new leg attributes and itinerary attributes.

// This method generate leg & itinerary from StopTimes data and Pattern and save it to database table.
// First find the minimum stopTimes count from arrCaltrainStopTimes,arrBartStopTimes,arrMuniStopTimes,arrAcTransitStopTimes
// Then start with iterating using this minimum number.
// Then we will get leg from itinerary if and check for mode if it walk the we will directly assign old leg and edit dome attributes like startTime,endTime etc.
// If mode is not walk the we will check agencyName  if the leg is first non walk leg then we will create new leg with some attributes from GtfsStopTimes.
// If Leg is Not First non walk leg the we will check departure time with previous non walk leg departure if current leg departure time is greater then we will create leg with some attributes.and add departure time to previous leg Departure time.

- (void) generateItineraryFromPatternAndStopTimes:(Itinerary *)itinerary arrCaltrainStopTimes:(NSArray *)arrCaltrainStopTimes arrBartStopTimes:(NSArray *)arrBartStopTimes arrMuniStopTimes:(NSArray *)arrMuniStopTimes arrAcTransitStopTimes:(NSArray *)arrAcTransitStopTimes plan:(Plan *)plan;
@end

