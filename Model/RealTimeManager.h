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

+(RealTimeManager *)realTimeManager;

// Request RealTime data from server with legs attributes.
- (void) requestRealTimeDataFromServerUsingPlan:(Plan *)plan;

// Parse the Realtime response and set realtime data to leg.
-(void)setLiveFeed:(id)liveFees;

// Set realtime predictions to leg of unique itinerary.
- (void) setRealTimePredictionsFromLiveFeeds:(NSArray *)liveFeeds;
@end
