
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
#import "RouteExcludeSetting.h"

@implementation RealTimeManager
@synthesize rkTpClient;
@synthesize plan;
@synthesize routeOptionsVC;
@synthesize routeDetailVC;
@synthesize liveData;
@synthesize originalTripDate;
@synthesize loadedRealTimeData;
@synthesize requestParameters;


static RealTimeManager* realTimeManager;

+(RealTimeManager *)realTimeManager{
    if(!realTimeManager){
       realTimeManager = [[RealTimeManager alloc] init]; 
    }
    return realTimeManager;
}

// Request RealTime data from server with legs attributes.
- (void) requestRealTimeDataFromServerUsingPlan:(Plan *)currentPlan PlanRequestParameters:(PlanRequestParameters *)planrequestParameters{
    plan = currentPlan;
    requestParameters = planrequestParameters;
    originalTripDate = planrequestParameters.originalTripDate;
    NSDate *currentDate = dateOnlyFromDate([NSDate date]);
    NSDate *tripDate = dateOnlyFromDate(originalTripDate);
    // TODO:- Comment This if statement to run automated test case
     if([tripDate compare:currentDate] != NSOrderedAscending){
        NSMutableArray *arrLegs = [[NSMutableArray alloc] init];
        for(int i=0;i<[[plan uniqueItineraries] count];i++){
            Itinerary *itinerary = [[plan uniqueItineraries] objectAtIndex:i];
            if(!itinerary.isRealTimeItinerary){
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
                        NSString *tripId;
                        if(leg.tripId){
                            tripId = leg.tripId;
                        }
                        else{
                            tripId = @"";
                        }
                        NSDictionary *dicLegData = [NSDictionary dictionaryWithObjectsAndKeys:leg.tripId,@"tripId",strRouteLongName,@"routeLongName",strRouteShortName,@"routeShortName",[NSNumber numberWithDouble:startDate],@"startTime",[NSNumber numberWithDouble:endDate],@"endTime",leg.routeId,@"routeId",dicTo,@"to",dicFrom,@"from",leg.mode,@"mode",leg.agencyId,@"agencyId",leg.agencyName,@"agencyName",leg.route,@"route",leg.headSign,@"headsign",leg.legId,@"id", nil];
                        [arrLegs addObject:dicLegData];
                    }
                }  
            }
        }
        if([arrLegs count] > 0){
            NSString *strRequestString = [arrLegs JSONString];
            RKParams *requestParameter = [RKParams params];
            [requestParameter setValue:strRequestString forParam:LEGS];
            [requestParameter setValue:[[NSUserDefaults standardUserDefaults] objectForKey:DEVICE_TOKEN] forParam:DEVICE_TOKEN];
            [self.rkTpClient post:LIVE_FEEDS_BY_LEGS params:requestParameter delegate:self];
        } 
     }
}

#pragma mark RKResponse Delegate method
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
    @try {
        // DE 175 Fixed
        [nc_AppDelegate sharedInstance].isNeedToLoadRealData = YES;
        RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
        loadedRealTimeData = true;
        id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
        NIMLOG_PERF2(@"Realtime Response=%@",res);
        [routeOptionsVC setIsReloadRealData:false];
        [self setLiveFeed:res];
    }  @catch (NSException *exception) {
        logException(@"RealTimeManager->didLoadResponse", @"load response for real time request", exception);
    }
}

// Replace the RouteDetailView itinerary with matching realtime itinerary.
- (void) updateItineraryIfAlreadyInRouteDetailView{
    Itinerary *detailViewitinerary = [nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC.itinerary;
    if(!detailViewitinerary)
        return;
    
    for(int i=0;i<[[plan sortedItineraries] count];i++){
        Itinerary *itinerary = [[plan sortedItineraries] objectAtIndex:i];
        if(itinerary.isRealTimeItinerary && [itinerary.tripIdhexString isEqualToString:detailViewitinerary.tripIdhexString]){
            [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC newItineraryAvailable:itinerary status:ITINERARY_STATUS_OK];
            [plan deleteItinerary:detailViewitinerary];
            [plan prepareSortedItinerariesWithMatchesForDate:originalTripDate
                                              departOrArrive:DEPART
                                        routeExcludeSettings:[RouteExcludeSettings latestUserSettings]
                                     generateGtfsItineraries:NO
                                       removeNonOptimalItins:YES];
            return;
        }
    }
    [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC newItineraryAvailable:nil status:ITINERARY_STATUS_CONFLICT];
}
// Parse the Realtime response and set realtime data to leg.
-(void)setLiveFeed:(id)liveFees
{
    @try {
            for(int i=0;i<[[plan itineraries] count];i++){
                Itinerary *iti = [[[plan itineraries] allObjects]  objectAtIndex:i];
                Itinerary *detailViewitinerary = [nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC.itinerary;
                if(iti != detailViewitinerary){
                    if(iti.isRealTimeItinerary){
                        if([iti.startTime compare:[NSDate date]] == NSOrderedDescending)
                        [plan deleteItinerary:iti];
                    }
                }
            }
            for(int i=0;i<[[plan requestChunks] count];i++){
                PlanRequestChunk *reqChunks = [[[plan requestChunks] allObjects] objectAtIndex:i];
                if(reqChunks.type == [NSNumber numberWithInt:2]){
                    [[nc_AppDelegate sharedInstance].managedObjectContext deleteObject:reqChunks];
                }
            }
            saveContext([nc_AppDelegate sharedInstance].managedObjectContext);
        liveData = liveFees;
        NSNumber *respCode = [(NSDictionary *)liveData objectForKey:@"errCode"];
        if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
            //It means there are live feeds in response
            NSArray * legLiveFees = [liveData  objectForKey:@"legLiveFeeds"];
            if ([legLiveFees count] > 0) {
                [self setRealTimePredictionsFromLiveFeeds:legLiveFees];
                // TODO:- Comment Four lines to run automated test case
                [[nc_AppDelegate sharedInstance].gtfsParser generateItinerariesFromRealTime:plan TripDate:originalTripDate Context:nil];
                [self hideItineraryIfNeeded:[[plan itineraries] allObjects]];
                 [plan prepareSortedItinerariesWithMatchesForDate:originalTripDate
                                                   departOrArrive:requestParameters.departOrArrive
                                             routeExcludeSettings:[RouteExcludeSettings latestUserSettings]
                                          generateGtfsItineraries:NO
                                            removeNonOptimalItins:YES];
                Itinerary *detailViewitinerary = [nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC.itinerary;
                if(detailViewitinerary.isRealTimeItinerary){
                    [self updateItineraryIfAlreadyInRouteDetailView];
                }
                 [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC reloadData:plan];
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

- (void) hideItineraryIfNeeded:(NSArray *)arrItinerary{
    for(int i=0;i<[arrItinerary count];i++){
        Itinerary *itinerary1 = [arrItinerary objectAtIndex:i];
        if(!itinerary1.isRealTimeItinerary)
            continue;
        for(int j=0;j<[arrItinerary count];j++){
            Itinerary *itinerary2 = [arrItinerary objectAtIndex:j];
            if(itinerary2.isRealTimeItinerary || ![itinerary1 isEquivalentModesAndStopsAs:itinerary2])
                continue;
            NSDate *realStartTime = addDateOnlyWithTime(dateOnlyFromDate([NSDate date]), [itinerary1 startTimeOfFirstLeg]);
            NSDate *scheduledStartTime = addDateOnlyWithTime(dateOnlyFromDate([NSDate date]),[itinerary2 startTimeOfFirstLeg]);
            double realTimeInterval = timeIntervalFromDate(realStartTime);
            double scheduledTimeInterval = timeIntervalFromDate(scheduledStartTime);
            if([realStartTime compare:scheduledStartTime] == NSOrderedDescending || realTimeInterval == scheduledTimeInterval){
                itinerary2.hideItinerary = true;
            }
        }
    }
}

// return leg with matching legid
- (Leg *) returnLegWithSameLegId:(NSString *)strLegId{
    for(int i=0;i<[[plan uniqueItineraries] count];i++){
        Itinerary *iti = [[plan uniqueItineraries] objectAtIndex:i];
        for(int j=0;j<[[iti sortedLegs] count];j++){
            Leg *leg = [[iti sortedLegs] objectAtIndex:j];
            if([leg.legId isEqualToString:strLegId])
                return leg;
        }
    }
    return nil;
}

// return pattern with matching legId
- (Itinerary *) returnPatternWithSameLegId:(NSString *)strLegId{
    for(int i=0;i<[[plan uniqueItineraries] count];i++){
        Itinerary *iti = [[plan uniqueItineraries] objectAtIndex:i];
        for(int j=0;j<[[iti sortedLegs] count];j++){
            Leg *leg = [[iti sortedLegs] objectAtIndex:j];
            if([leg.legId isEqualToString:strLegId])
                return iti;
        }
    }
    return nil;
}

// return maximum epoch time.
// i.e if predictions of 4,8,10 then return epoch time for 10.

- (NSDate *) dateWithRealtimeBoundry:(NSArray *)predictions{
    NSDictionary *nearestRealTime = [predictions objectAtIndex:0];
    for(int i=0;i<[predictions count];i++){
        NSDictionary *dictPrediction = [predictions objectAtIndex:i];
        NSDate *predtctionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[dictPrediction objectForKey:@"epochTime"] doubleValue]/1000.0)]);
        NSDate *nearestPredictionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[nearestRealTime objectForKey:@"epochTime"] doubleValue]/1000.0)]);
        if ([predtctionTime compare:nearestPredictionTime] == NSOrderedDescending) {
            nearestRealTime = dictPrediction;
        }
    }
    NSDate *nearestPredictionTime = [NSDate dateWithTimeIntervalSince1970:([[nearestRealTime objectForKey:@"epochTime"] doubleValue]/1000.0)];
    return nearestPredictionTime;
}

// return dictionary with minimum time.
// i.e if predictions of 4,8,10 then return dictionary with prediction 4.
- (NSDictionary *) findnearestEpochTime:(NSMutableArray *)predictions Time:(NSDate *)time{
    NSMutableArray *arrPredictions = [[NSMutableArray alloc] initWithArray:predictions];
    for (int i=0;i<[arrPredictions count];i++) {
        NSDate *requestTime = timeOnlyFromDate([time dateByAddingTimeInterval:REALTIME_LOWER_LIMIT]);
               NSDictionary *dictPrediction = [arrPredictions objectAtIndex:i];
                NSDate *predtctionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[dictPrediction objectForKey:@"epochTime"] doubleValue]/1000.0)]);
                   if ([requestTime compare:predtctionTime] == NSOrderedDescending) {
                          [arrPredictions removeObject:dictPrediction];
                        i = i - 1;
                     }
        }
         if([arrPredictions count] == 0){
                return nil;
         }
    
    NSDictionary *nearestRealTime = [arrPredictions objectAtIndex:0];
    for(int i=0;i<[arrPredictions count];i++){
        NSDictionary *dictPrediction = [arrPredictions objectAtIndex:i];
        NSDate *predtctionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[dictPrediction objectForKey:@"epochTime"] doubleValue]/1000.0)]);
        NSDate *nearestPredictionTime = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[nearestRealTime objectForKey:@"epochTime"] doubleValue]/1000.0)]);
        if ([nearestPredictionTime compare:predtctionTime] == NSOrderedDescending) {
            nearestRealTime = dictPrediction;
        }
    }
    return nearestRealTime;
}

- (void) setRealTimePredictionsFromLiveFeeds:(NSArray *)liveFeeds{
    for (int j=0; j<[liveFeeds count]; j++) {
        id key = [liveFeeds objectAtIndex:j];
        NSString *legId = [[key objectForKey:@"leg"] objectForKey:@"id"];
        NSArray *predictionList = [key objectForKey:@"lstPredictions"];
        Leg *uniqueLeg = [self returnLegWithSameLegId:legId];
        for(int i=0;i<[[plan uniqueItineraries] count];i++){
            Itinerary *itinerary = [[plan uniqueItineraries] objectAtIndex:i];
            for(int k=0;k<[[itinerary sortedLegs] count];k++){
                Leg *leg = [[itinerary sortedLegs] objectAtIndex:k];
                if([leg.legId isEqualToString:uniqueLeg.legId]){
                    leg.predictions = predictionList;
                }
            }
        }
    }
}
@end
