//
//  RealTimeManager.h
//  Nimbler Caltrain
//
//  Created by macmini on 24/01/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import <Restkit/RKJSONParserJSONKit.h>
#import "Plan.h"
#import "Leg.h"
#import "PlanRequestParameters.h"
#import <RestKit/JsonKit.h>
#import "RouteOptionsViewController.h"
#import "RouteDetailsViewController.h"

@interface RealTimeManager : NSObject<RKRequestDelegate>{
    Plan *plan;
}
@property (nonatomic, strong) RKClient* rkTpClient; // rkClient for calling server (must be set before using)
@property (nonatomic, strong) Plan *plan;
@property (unsafe_unretained, nonatomic) RouteOptionsViewController *routeOptionsVC;
@property (unsafe_unretained, nonatomic) RouteDetailsViewController *routeDetailVC;
@property(strong, nonatomic) id liveData;
@property (strong, nonatomic) NSDate *originalTripDate;
@property (nonatomic) BOOL loadedRealTimeData;
@property (nonatomic, strong) PlanRequestParameters *requestParameters;
@property (nonatomic, strong) NSString *realTimeURL;

+(RealTimeManager *)realTimeManager;

// Request RealTime data from server with legs attributes.
- (void) requestRealTimeDataFromServerUsingPlan:(Plan *)currentPlan PlanRequestParameters:(PlanRequestParameters *)planrequestParameters;

// Parse the Realtime response and set realtime data to leg.
-(void)setLiveFeed:(id)liveFees;

// return leg with matching legid
- (Leg *) returnLegWithSameLegId:(NSString *)strLegId;

// return pattern with matching legId
- (Itinerary *) returnPatternWithSameLegId:(NSString *)strLegId;

// return maximum epoch time.
// i.e if predictions of 4,8,10 then return epoch time for 10.
- (NSDate *) dateWithRealtimeBoundry:(NSArray *)predictions;

// return dictionary with minimum time.
// i.e if predictions of 4,8,10 then return dictionary with prediction 4.
- (NSDictionary *) findnearestEpochTime:(NSMutableArray *)predictions Time:(NSDate *)time;

// Set matching prediction to leg of itineraries.
// First get unique leg from pattern based on legid from prediction.
// Then check if leg from itinerary match with unique pattern if yes then check if leg start time is within (realtimeBoundry-5,realtimeBoundry+15) if yes then set nearest prediction to leg.
// if any remaining prediction from realtime response then generate new itinerary with this new realtime data.
- (void) setRealTimePredictionsFromLiveFeeds:(NSArray *)liveFeeds;

- (void) hideItineraryIfNeeded:(NSArray *)arrItinerary;

// Request the vehicle position data from server
- (void) requestVehiclePositionForRealTimeLeg:(NSArray *)sortedLegs;

@end
