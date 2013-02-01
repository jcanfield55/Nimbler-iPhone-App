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
#import "PlanRequestParameters.h"

@implementation RealTimeManager
@synthesize rkTpClient;
@synthesize plan;
@synthesize routeOptionsVC;
@synthesize routeDetailVC;
@synthesize liveData;
@synthesize originalTripDate;

static RealTimeManager* realTimeManager;

+(RealTimeManager *)realTimeManager{
    if(!realTimeManager){
       realTimeManager = [[RealTimeManager alloc] init]; 
    }
    return realTimeManager;
}

// Request RealTime data from server with legs attributes.
- (void) requestRealTimeDataFromServerUsingPlan:(Plan *)currentPlan tripDate:(NSDate *)tripDate{
    plan = currentPlan;
    originalTripDate = tripDate;
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
                NSString *strRouteLongName = leg.routeLongName;
                double startDate = 0;
                double endDate = 0;
                if(!strRouteShortName){
                    strRouteShortName = @"";
                }
                if(!strRouteLongName){
                    strRouteLongName = @"";
                }
                if(leg.startTime){
                    double startTimeInterval = [leg.startTime timeIntervalSince1970];
                    startDate = startTimeInterval*1000;
                }
                if(leg.endTime){
                    double endTimeInterval = [leg.endTime timeIntervalSince1970];
                    endDate = endTimeInterval*1000;
                }
                NSDictionary *dicLegData = [NSDictionary dictionaryWithObjectsAndKeys:leg.tripId,@"tripId",strRouteLongName,@"routeLongName",strRouteShortName,@"routeShortName",[NSNumber numberWithDouble:startDate],@"startTime",[NSNumber numberWithDouble:endDate],@"endTime",leg.routeId,@"routeId",dicTo,@"to",dicFrom,@"from",leg.mode,@"mode",leg.agencyId,@"agencyId",leg.agencyName,@"agencyName",leg.route,@"route",leg.headSign,@"headsign",leg.legId,@"id", nil];
                [arrLegs addObject:dicLegData];
            }
        }
    }
    NSString *str = [arrLegs JSONString];
    RKParams *requestParameter = [RKParams params];
    [requestParameter setValue:str forParam:LEGS];
    [self.rkTpClient post:LIVE_FEEDS_BY_LEGS params:requestParameter delegate:self];
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
        for(int i=0;i<[[plan sortedItineraries] count];i++){
            Itinerary *iti = [[plan sortedItineraries]  objectAtIndex:i];
            if(iti.isRealTimeItinerary){
                [plan deleteItinerary:iti];
            }
            for(int j=0;j<[[iti sortedLegs] count];j++){
                Leg *leg = [[iti sortedLegs] objectAtIndex:j];
                leg.predictions = nil;
            }
        }
        liveData = liveFees;
        NSNumber *respCode = [(NSDictionary *)liveData objectForKey:@"errCode"];
        if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
            //It means there are live feeds in response
            NSArray * legLiveFees = [liveData  objectForKey:@"legLiveFeeds"];
            if ([legLiveFees count] > 0) {
                [self setRealTimePredictionsFromLiveFeeds:legLiveFees];
                plan = [[nc_AppDelegate sharedInstance].gtfsParser generateLegsAndItineraryFromPatternsOfPlan:plan tripDate:originalTripDate Context:nil];
                plan.sortedItineraries = nil;
                //plan.uniqueItineraryPatterns = [NSSet setWithArray:[plan uniqueItineraries]];
                for(int i=0;i<[[plan sortedItineraries] count];i++){
                    Itinerary *iti = [[plan sortedItineraries] objectAtIndex:i];
                    iti.sortedLegs = nil;
                }

                [[nc_AppDelegate sharedInstance].planStore.routeOptionsVC reloadData:plan];
                [routeDetailVC ReloadLegWithNewData];
            }
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

- (NSArray *) hideItineraryIfNeeded:(NSArray *)arrItinerary{
    NSMutableArray *arrItineraries = [[NSMutableArray alloc] init];
    for(int i=0;i<[arrItinerary count];i++){
        Itinerary *itinerary = [arrItinerary objectAtIndex:i];
        if(!itinerary.hideItinerary)
            [arrItineraries addObject:itinerary];
            
    }
    return arrItineraries;
}

// Newly Created methods


//- (Leg *) returnLegWithSameLegId:(NSString *)strLegId{
//    for(int i=0;i<[[plan uniqueItineraries] count];i++){
//        Itinerary *iti = [[plan uniqueItineraries] objectAtIndex:i];
//        for(int j=0;j<[[iti sortedLegs] count];j++){
//            Leg *leg = [[iti sortedLegs] objectAtIndex:j];
//            if([leg.legId isEqualToString:strLegId])
//                return leg;
//        }
//    }
//    return nil;
//}

//- (NSDate *) dateWithRealtimeBoundry:(NSArray *)predictions{
//    NSDictionary *nearestRealTime = [predictions objectAtIndex:0];
//    for(int i=0;i<[predictions count];i++){
//        NSDictionary *dictPrediction = [predictions objectAtIndex:i];
//        NSDate *predtctionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[dictPrediction objectForKey:@"epochTime"] doubleValue]/1000.0)]);
//        NSDate *nearestPredictionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[nearestRealTime objectForKey:@"epochTime"] doubleValue]/1000.0)]);
//        if ([predtctionTime compare:nearestPredictionTime] == NSOrderedDescending) {
//            nearestRealTime = dictPrediction;
//        }
//    }
//    NSDate *nearestPredictionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[nearestRealTime objectForKey:@"epochTime"] doubleValue]/1000.0)]);
//    return nearestPredictionTime;
//}

//- (double) findnearestEpochTime:(NSArray *)predictions{
//    NSDictionary *nearestRealTime = [predictions objectAtIndex:0];
//    for(int i=0;i<[predictions count];i++){
//        NSDictionary *dictPrediction = [predictions objectAtIndex:i];
//        NSDate *predtctionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[dictPrediction objectForKey:@"epochTime"] doubleValue]/1000.0)]);
//        NSDate *nearestPredictionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[nearestRealTime objectForKey:@"epochTime"] doubleValue]/1000.0)]);
//        if ([nearestPredictionTime compare:predtctionTime] == NSOrderedDescending) {
//            nearestRealTime = dictPrediction;
//        }
//    }
//    return [[nearestRealTime objectForKey:@"epochTime"] doubleValue];
//}

//- (void) updateRealtimeForLegsAndItineraries:(NSArray *)liveFeeds{
//    for (int j=0; j<[liveFeeds count]; j++) {
//        id key = [liveFeeds objectAtIndex:j];
//        NSString *legId = [[key objectForKey:@"leg"] objectForKey:@"id"];
//        NSArray *predictionList = [key objectForKey:@"lstPredictions"];
//        Leg *uniqueLeg = [self returnLegWithSameLegId:legId];
//        for(int i=0;i<[[plan sortedItineraries] count];i++){
//            Itinerary *itinerary = [[plan sortedItineraries] objectAtIndex:i];
//            for(int k=0;k<[[itinerary sortedLegs] count];k++){
//                Leg *leg = [[itinerary sortedLegs] objectAtIndex:k];
//                if(uniqueLeg.to == leg.to && uniqueLeg.from == leg.from && [uniqueLeg.routeId isEqualToString:leg.routeId]){
//                    NSDate *realTimeBoundry = [self dateWithRealtimeBoundry:predictionList];
//                    if(realTimeBoundry){
//                        double epochTime = [self findnearestEpochTime:predictionList];
//                        [leg setRealTimeParametersUsingEpochTime:epochTime];
//                        Leg *conflictLeg = [itinerary conflictLegFromItinerary];
//                        if(conflictLeg){
//                           Leg *adjustedLeg =  [itinerary adjustLegsIfRequired];
//                           if(adjustedLeg)
//                               [[nc_AppDelegate sharedInstance].gtfsParser generateNewItineraryByRemovingConflictLegs:itinerary :adjustedLeg :nil];
//                        }
//                    }
//                    else{
//                        continue;
//                    }
//                }
//            }
//        }
//    }
//}
@end
