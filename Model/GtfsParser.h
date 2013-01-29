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
@property (nonatomic, strong) RKClient *rkTpClient;
@property (strong, nonatomic) NSString *strAgenciesURL;
@property (strong, nonatomic) NSString *strCalendarDatesURL;
@property (strong, nonatomic) NSString *strCalendarURL;
@property (strong, nonatomic) NSString *strRoutesURL;
@property (strong, nonatomic) NSString *strStopsURL;
@property (strong, nonatomic) NSString *strTripsURL;
@property (strong, nonatomic) NSString *strStopTimesURL;
@property (strong, nonatomic) Plan *tempPlan;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkTpClient:(RKClient *)rkClient;

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
- (void) parseAndStroreGtfsTripsData:(NSDictionary *)dictFileData RequestUrl:(NSString *)strRequestUrl;

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
- (void)generateStopTimesRequestStringUsingTripIds:(NSArray *)tripIds agencyIds:(NSArray *)agencyIds;

// Generate The Trips Request Comma Separated string like agencyID_ROUTEID
- (void)generateGtfsTripsRequestStringUsingPlan:(Plan *) plan;

// This method get the serviceId based on tripId.
// Then get the calendar data for particular serviceID.
// the check for the request date comes after service start date and comes befor enddate.
// then check service is enabled on request day if yes then return yes otherwise return no.
- (BOOL) isServiceEnableForStopTimes:(GtfsStopTimes *)stopTimes RequestDate:(NSDate *)requestDate;

// first get stoptimes from StopTimes Table based on stopId
// Then make a pair of StopTimes if both stoptimes have same tripId then check for the stopSequence and the departure time is greater than request trip time and also check if service is enabled for that stopTimes if yes the add both stopTimes as To/From StopTimes pair.
- (NSMutableArray *)getStopTimes:(NSString *)strToStopID strFromStopID:(NSString *)strFromStopID startDate:(NSDate *)startDate;

// Generate legs and itinerary from realtime data if available otherwise generate legs and itinerary from schedule data.
- (Plan *)generateLegsAndItineraryFromPatternsOfPlan:(Plan *)plan parameters:(PlanRequestParameters *)parameters Context:(NSManagedObjectContext *)context;

- (NSDate *)timeAndDateFromString:(NSString *)strTime;
- (NSArray *) findNearestStopTimeFromStopTimeArray:(NSArray *)arrStopTimes Itinerary:(Itinerary *)itinerary;

// Remove The legs from where conflict found in itinerary.
// Then generate new legs from Gtfs StopTimes and old legs data.
- (void) generateNewItineraryByRemovingConflictLegs:(Itinerary *)itinerary:(Leg *)conflictLeg:(NSManagedObjectContext *)context;

// Find the maximum prediction count from patterns.
- (int) findMaximumPredictionCount:(NSMutableDictionary *)predictions;

// Find the nearest realtime from multiple realtimes. 
- (NSDictionary *) findNearestRealTimeFromPredictions:(NSMutableArray *)predictions Time:(NSDate *)time;

// TODO:- Need to add flag that determine flag is generated from realtime data or scheduled data.
// generate new leg from prediction data.
- (void) generateLegFromPrediction:(NSDictionary *)prediction newItinerary:(Itinerary *)newItinerary Leg:(Leg *)leg Context:(NSManagedObjectContext *)context;

@end

