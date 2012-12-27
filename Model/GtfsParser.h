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

// Generate Patterns From Plan.
- (void)generatePatternsFromPlan:(Plan *)plan:(Location *)fromLocation:(Location *)toLocation;

// Get Patterns According to To&From Location.
- (NSArray *)getSchedule:(Location *)toLocation:(Location *)fromLocation;

// Get The stopID form GtfsStop Table from To&From Location.
- (NSString *) getTheStopIDAccrodingToStation:(NSString *)lat:(NSString *)lng;

// To Get Stored Patterns
// Then Get The stopID From To&From Location.
// Then We get The StopTimes According To TO&From stopID.
- (void)getStoredPatterns:(PlanRequestParameters *)parameters;
@end
