
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
@synthesize realTimeURL;


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
    if([plan haveOnlyUnScheduledSorteditineraries]){
        [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.activityIndicator stopAnimating];
        return;
    }
//    for(int i=0;i<[[plan itineraries] count];i++){
//        Itinerary *itinerary = [[[plan itineraries] allObjects] objectAtIndex:i];
//        for(int j=0;j<[[itinerary sortedLegs] count];j++){
//            Leg *leg = [[itinerary sortedLegs] objectAtIndex:j];
//            NIMLOG_PERF2(@"fromStopId->%@, toStopId->%@, routeId->%@, mode->%@",leg.from.stopId,leg.to.stopId,leg.routeShortName,leg.mode);
//        }
//    }
    
//    for(int i=0;i<[[plan uniqueItineraries] count];i++){
//        Itinerary *itinerary = [[plan uniqueItineraries]  objectAtIndex:i];
//        for(int j=0;j<[[itinerary sortedLegs] count];j++){
//            Leg *leg = [[itinerary sortedLegs] objectAtIndex:j];
//            NIMLOG_PERF2(@"fromStopId->%@, toStopId->%@, routeId->%@, mode->%@",leg.from.stopId,leg.to.stopId,leg.routeShortName,leg.mode);
//        }
//    }
    
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
                        NSDictionary *dicToStopId = [NSDictionary dictionaryWithObjectsAndKeys:leg.to.stopAgencyId,@"agencyId",leg.to.stopId,@"id", nil];
                        NSDictionary *dicTo = [NSDictionary dictionaryWithObjectsAndKeys:dicToStopId,@"stopId", nil];
                        NSDictionary *dicFromStopId = [NSDictionary dictionaryWithObjectsAndKeys:leg.from.stopAgencyId,@"agencyId",leg.from.stopId,@"id", nil];
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
                        NSString *headSign;
                        if(leg.headSign){
                            headSign = leg.headSign;
                        }
                        else{
                            headSign = @"";
                        }
                        NSDictionary *dicLegData = [NSDictionary dictionaryWithObjectsAndKeys:tripId,@"tripId",strRouteLongName,@"routeLongName",strRouteShortName,@"routeShortName",[NSNumber numberWithDouble:startDate],@"startTime",[NSNumber numberWithDouble:endDate],@"endTime",leg.routeId,@"routeId",dicTo,@"to",dicFrom,@"from",leg.mode,@"mode",leg.agencyId,@"agencyId",leg.agencyName,@"agencyName",leg.route,@"route",headSign,@"headsign",leg.legId,@"id", nil];
//                        NIMLOG_PERF2(@"fromStopId->%@, toStopId->%@, fromStopName->%@, toStopName->%@, legId->%@, routeId->%@, tripId->%@,",leg.from.stopId,leg.to.stopId,leg.from.name,leg.to.name,leg.legId,leg.routeId,leg.tripId);
//                        NIMLOG_PERF2(@"-----------------------------------------");
                        [arrLegs addObject:dicLegData];
                    }
                }  
            }
        }
        if([arrLegs count] > 0){
            NSString *strRequestString = [arrLegs JSONString];
            RKParams *requestParameter = [RKParams params];
            [requestParameter setValue:strRequestString forParam:LEGS];
            [requestParameter setValue:[[nc_AppDelegate sharedInstance] deviceTokenString]  forParam:DEVICE_TOKEN];
            [requestParameter setValue:[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId] forParam:APPLICATION_TYPE];
            [requestParameter setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"] forParam:APPLICATION_VERSION];
            realTimeURL = LIVE_FEEDS_BY_LEGS;
            [self.rkTpClient post:LIVE_FEEDS_BY_LEGS params:requestParameter delegate:self];
            NIMLOG_PERF2(@"Realtime Data Request Sent At-->%f",[[NSDate date] timeIntervalSince1970]);
        } 
     }
}

/*
- (void) logRealtimeData:(NSDictionary *)dictionary{
    NSArray *array = [dictionary objectForKey:@"legLiveFeeds"];
    for(int i=0;i<[array count];i++){
        NSDictionary *dict = [array objectAtIndex:i];
        NIMLOG_PERF2(@"legId->%@",[[dict objectForKey:@"leg"] objectForKey:@"id"]);
        NSArray *arrayLegs = [dict objectForKey:@"lstPredictions"];
        for(int j=0;j<[arrayLegs count];j++){
            NSDictionary *responseDict = [arrayLegs objectAtIndex:j];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[responseDict objectForKey:@"epochTime"] doubleValue]/1000];
            NIMLOG_PERF2(@"realTime->%@, scheduleTime->%@, scheduleTripId->%@, realTripId->%@,",date,[responseDict objectForKey:@"scheduleTime"],[responseDict objectForKey:@"scheduleTripId"],[responseDict objectForKey:@"tripId"]);
        }
    NIMLOG_PERF2(@"---------------------------------------------------------");
    }
}
 */

#pragma mark RKResponse Delegate method
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
    @try {
        NSString *resourcePath = [request resourcePath];
        if([resourcePath isEqualToString:realTimeURL]){
            // DE 175 Fixed
            BOOL isRouteOptionView = [nc_AppDelegate sharedInstance].isRouteOptionView;
            BOOL isRouteDetailView = [nc_AppDelegate sharedInstance].isRouteDetailView;
            if(isRouteOptionView || isRouteDetailView){
                [nc_AppDelegate sharedInstance].isNeedToLoadRealData = YES;
                RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                loadedRealTimeData = true;
                id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.activityIndicator stopAnimating];
                [routeOptionsVC setIsReloadRealData:false];
                [self setLiveFeed:res];
            }
        }
        else{
            RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
            id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
            [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC.legMapVC addVehicleTomapView:[res objectForKey:@"legLiveFeeds"]];
        }
    }  @catch (NSException *exception) {
        logException(@"RealTimeManager->didLoadResponse", @"load response for real time request", exception);
    }
}

// Replace the RouteDetailView itinerary with matching realtime itinerary.
- (void) updateItineraryIfAlreadyInRouteDetailView{
    Itinerary *detailViewitinerary = [nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC.itinerary;
    int itineraryNumber = [nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC.itineraryNumber;
    if(!detailViewitinerary)
        return;
    
    for(int i=0;i<[[plan sortedItineraries] count];i++){
        Itinerary *itinerary = [[plan sortedItineraries] objectAtIndex:i];
        if(itinerary.isRealTimeItinerary && [itinerary.tripIdhexString isEqualToString:detailViewitinerary.tripIdhexString]){
            [nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC.count = [nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.remainingCount;
            [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC newItineraryAvailable:itinerary status:ITINERARY_STATUS_OK ItineraryNumber:itineraryNumber];
            [plan deleteItinerary:detailViewitinerary];
            [plan prepareSortedItinerariesWithMatchesForDate:originalTripDate
                                              departOrArrive:requestParameters.departOrArrive
                                        routeExcludeSettings:[RouteExcludeSettings latestUserSettings]
                                     generateGtfsItineraries:NO
                                       removeNonOptimalItins:YES];
            return;
        }
    }
    [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC newItineraryAvailable:nil status:ITINERARY_STATUS_CONFLICT ItineraryNumber:itineraryNumber];
}

- (void) removeRealtimeItinerary:(NSDate *)tripDate{
    NSInteger epochTripDate = [tripDate timeIntervalSince1970];
    for(Itinerary *itinerary in [plan itineraries]){
        if(itinerary && itinerary.isRealTimeItinerary){
            NSDate *itineraryEndTime = itinerary.endTimeOfLastLeg;
            NSInteger itineraryEpoch = [itineraryEndTime timeIntervalSince1970];
            if(epochTripDate > itineraryEpoch)
                [plan deleteItinerary:itinerary];
        }
    }
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
            for(PlanRequestChunk *reqChunks in [plan requestChunks]){
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
                NIMLOG_PERF2(@"Realtime Parsing and Processing Started At-->%f",[[NSDate date] timeIntervalSince1970]);
                [self setRealTimePredictionsFromLiveFeeds:legLiveFees];
                // TODO:- Comment Four lines to run automated test case
                NSDate *tripDate;
                if(requestParameters.departOrArrive == ARRIVE){
                    tripDate = [originalTripDate dateByAddingTimeInterval:-(1*60*60)];
                }
                else{
                    tripDate = originalTripDate;
                }
                [[nc_AppDelegate sharedInstance].gtfsParser generateItinerariesFromRealTime:plan TripDate:tripDate Context:nil];
                // Part of DE-292 Fix
                 [self removeRealtimeItinerary:tripDate]; 
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
                NIMLOG_PERF2(@"Realtime Parsing and Processing Finished At-->%f",[[NSDate date] timeIntervalSince1970]);
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

// Part of DE-292 Fix
- (void) hideItineraryIfNeeded:(NSArray *)arrItinerary{
    NSDate *currentDate = [NSDate date];
    NSInteger currentEpoch = [currentDate timeIntervalSince1970];
    for(int i=0;i<[arrItinerary count];i++){
        Itinerary *itinerary1 = [arrItinerary objectAtIndex:i];
        if(!itinerary1.isRealTimeItinerary)
            continue;
        for(int j=0;j<[arrItinerary count];j++){
            Itinerary *itinerary2 = [arrItinerary objectAtIndex:j];
            if(itinerary2.isRealTimeItinerary || ![itinerary1 isEquivalentModesAndStopsAs:itinerary2])
                continue;
            
            NSDate *realStartTime =  [itinerary1 maximumPredictionDate];
            NSInteger realEpoch = [realStartTime timeIntervalSince1970];
            NSInteger scheduledEpoch = [[itinerary2 startTimeOfFirstLeg] timeIntervalSince1970];
            if(realEpoch >= scheduledEpoch && scheduledEpoch > currentEpoch){
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

// Request the vehicle position data from server
- (void) requestVehiclePositionForRealTimeLeg:(NSArray *)sortedLegs{
    // Don't ask server for vehicle position in Washington DC application.
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
        return;
    }
    NSMutableArray *legArray = [[NSMutableArray alloc] init];
    for(int i=0;i<[sortedLegs count];i++){
        Leg *leg = [sortedLegs objectAtIndex:i];
        NSString *route = leg.route;
        if(!route)
            route = @"";
        
        NSString *routeShortName = leg.routeShortName;
        if(!routeShortName)
            routeShortName = @"";
        
        NSString *headSign = leg.headSign;
        if(!headSign)
            headSign = @"";
        
        if(leg.isRealTimeLeg && leg.vehicleId){
                NSDictionary *legData = [NSDictionary dictionaryWithObjectsAndKeys:leg.agencyId,@"agencyId",leg.legId,@"id",route,@"route",leg.vehicleId,@"vehicleId",leg.mode,@"mode",routeShortName,@"routeShortName",headSign,@"headsign",leg.agencyName,@"agencyName", nil];
                [legArray addObject:legData];
        }
    }
    if([legArray count] > 0){
        NSString *strRequestString = [legArray JSONString];
        RKParams *requestParameter = [RKParams params];
        [requestParameter setValue:strRequestString forParam:LEGS];
        [requestParameter setValue:[[nc_AppDelegate sharedInstance] deviceTokenString]  forParam:DEVICE_TOKEN];
        [requestParameter setValue:[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId] forParam:APPLICATION_TYPE];
        [requestParameter setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"] forParam:APPLICATION_VERSION];
        [self.rkTpClient post:LIVE_FEEDS_BY_VEHICLE_POSITION params:requestParameter delegate:self];
    }else{
        LegMapViewController *legMapVC = [nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC.legMapVC;
        [legMapVC removeMovingAnnotations];
    }
}

@end
