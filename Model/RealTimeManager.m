//
//  RealTimeManager.m
//  Nimbler Caltrain
//
//  Created by macmini on 24/01/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "RealTimeManager.h"
#import "nc_AppDelegate.h"
#import "UtilityFunctions.h"

@implementation RealTimeManager
@synthesize plan;
@synthesize routeOptionsVC;
@synthesize routeDetailVC;
@synthesize liveData;

static RealTimeManager* realTimeManager;

+(RealTimeManager *)realTimeManager{
    if(!realTimeManager){
       realTimeManager = [[RealTimeManager alloc] init]; 
    }
    return realTimeManager;
}

// Request RealTime data from server with legs attributes.
- (void) requestRealTimeDataFromServerUsingPlan:(Plan *)currentPlan{
    plan = currentPlan;
    NSMutableArray *arrLegs = [[NSMutableArray alloc] init];
    for(int i=0;i<[[plan uniqueItineraries] count];i++){
        Itinerary *itinerary = [[plan uniqueItineraries] objectAtIndex:i];
        for(int j=0;j<[[itinerary sortedLegs] count];j++){
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:j];
            if([leg isScheduled]){
                NSDictionary *dicToStopId = [NSDictionary dictionaryWithObjectsAndKeys:leg.agencyId,@"agencyId",leg.to.stopId,@"id", nil];
                NSDictionary *dicTo = [NSDictionary dictionaryWithObjectsAndKeys:dicToStopId,@"stopId", nil];
                NSDictionary *dicFromStopId = [NSDictionary dictionaryWithObjectsAndKeys:leg.agencyId,@"agencyId",leg.from.stopId,@"id", nil];
                NSDictionary *dicFrom = [NSDictionary dictionaryWithObjectsAndKeys:dicFromStopId,@"stopId", nil];
                NSString *strRouteShortName = leg.routeShortName;
                double startDate = 0;
                double endDate = 0;
                if(!strRouteShortName){
                    strRouteShortName = @"";
                }
                if(leg.startTime){
                    double startTimeInterval = [leg.startTime timeIntervalSince1970];
                    startDate = startTimeInterval*1000;
                }
                if(leg.endTime){
                    double endTimeInterval = [leg.endTime timeIntervalSince1970];
                    endDate = endTimeInterval*1000;
                }
                NSDictionary *dicLegData = [NSDictionary dictionaryWithObjectsAndKeys:leg.tripId,@"tripId",leg.routeLongName,@"routeLongName",strRouteShortName,@"routeShortName",[NSNumber numberWithDouble:startDate],@"startTime",[NSNumber numberWithDouble:endDate],@"endTime",leg.routeId,@"routeId",dicTo,@"to",dicFrom,@"from",leg.mode,@"mode",leg.agencyId,@"agencyId",leg.agencyName,@"agencyName",leg.route,@"route",leg.headSign,@"headsign",leg.legId,@"id", nil];
                [arrLegs addObject:dicLegData];
            }
        }
    }
    NSString *str = [arrLegs JSONString];
    RKParams *requestParameter = [RKParams params];
    [requestParameter setValue:str forParam:LEGS];
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    [RKClient setSharedClient:client];
    [[RKClient sharedClient] post:LIVE_FEEDS_BY_LEGS params:requestParameter delegate:self];
}

#pragma mark RKResponse Delegate method
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
    
    @try {
        // DE 175 Fixed
        [nc_AppDelegate sharedInstance].isNeedToLoadRealData = YES;
        RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
        id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
        [routeOptionsVC setIsReloadRealData:false];
        [self setLiveFeed:res];
    }  @catch (NSException *exception) {
        logException(@"RealTimeManager->didLoadResponse", @"load response for real time request", exception);
    }
}

// Parse the Realtime response and set realtime data to leg.
-(void)setLiveFeed:(id)liveFees
{
    @try {
        liveData = liveFees;
        NSNumber *respCode = [(NSDictionary *)liveData objectForKey:@"errCode"];
        if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
            //It means there are live feeds in response
            NSArray * legLiveFees = [liveData  objectForKey:@"legLiveFeeds"];
            if ([legLiveFees count] > 0) {
                [self setRealTimePredictionsFromLiveFeeds:legLiveFees];
            }
            routeOptionsVC.isReloadRealData = true;
            [routeOptionsVC.mainTable reloadData];
            [routeDetailVC ReloadLegWithNewData];
        }
        else {
            //thereare no live feeds available.
            routeOptionsVC.isReloadRealData = FALSE;
            NIMLOG_PERF1(@"thereare no live feeds available for current route");
        }
    }
    @catch (NSException *exception) {
        logException(@"RealTimeManager->liveFees", @"", exception);
    }
}

// Set realtime predictions to leg of unique itinerary.
- (void) setRealTimePredictionsFromLiveFeeds:(NSArray *)liveFeeds{
    for(int i=0;i<[[plan uniqueItineraries] count];i++){
        Itinerary *itinerary = [[plan uniqueItineraries] objectAtIndex:i];
        for(int j=0;j<[[itinerary sortedLegs] count];j++){
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:j];
            for (int j=0; j<[liveFeeds count]; j++) {
                 id key = [liveFeeds objectAtIndex:j];
                 NSString *legId = [[key objectForKey:@"leg"] objectForKey:@"id"];
                if([leg.legId isEqualToString:legId]){
                    NSArray *predictionList = [key objectForKey:@"lstPredictions"];
                    [leg setPredictions:predictionList];
                }
            }
        }
    }
}

@end
