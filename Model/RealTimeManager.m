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
@synthesize loadedRealTimeData;

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
    NSDate *tripDateOnly = dateOnlyFromDate(originalTripDate);
    NSDate *currentDate = [NSDate date];
    NSDate *currentDateOnly = dateOnlyFromDate(currentDate);
    NSDate *currentDatePlus90Miuntes = [currentDate dateByAddingTimeInterval:CURRENT_DATE_PLUS_INTERVAL];
    // TODO:- Comment This if statement to run automated test case
    // if([tripDateOnly isEqualToDate:currentDateOnly] && [originalTripDate compare:currentDatePlus90Miuntes] == NSOrderedAscending){
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
    // }
}

#pragma mark RKResponse Delegate method
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
    
    @try {
        // DE 175 Fixed
        [nc_AppDelegate sharedInstance].isNeedToLoadRealData = YES;
        RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
        loadedRealTimeData = true;
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
        for(int i=0;i<[[plan itineraries] count];i++){
            Itinerary *iti = [[[plan itineraries] allObjects]  objectAtIndex:i];
            iti.itinArrivalFlag = nil;
            iti.hideItinerary = false;
            if(iti.isRealTimeItinerary){
                for(int j=0;j<[[iti sortedLegs] count];j++){
                    Leg *leg = [[iti sortedLegs] objectAtIndex:j];
                    leg.predictions = nil;
                    leg.arrivalFlag = nil;
                    leg.timeDiffInMins = nil;
                }
                [plan deleteItinerary:iti];
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
                [self setRealTimePredictionsFromLiveFeeds1:legLiveFees];
                // TODO:- Comment Four lines to run automated test case 
                // [[nc_AppDelegate sharedInstance].gtfsParser generateItinerariesFromRealTime:plan TripDate:originalTripDate Context:nil];
                // [plan prepareSortedItinerariesWithMatchesForDate:originalTripDate departOrArrive:DEPART];
                // [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC reloadData:plan];
                // [routeDetailVC ReloadLegWithNewData];
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
    NSMutableArray *arrItineraries = [[NSMutableArray alloc] init];
    for(int i=0;i<[arrItinerary count];i++){
        Itinerary *itinerary = [arrItinerary objectAtIndex:i];
        if(!itinerary.hideItinerary)
            [arrItineraries addObject:itinerary];
            
    }
    [plan setSortedItineraries:arrItineraries];
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

- (void) setRealTimePredictionsFromLiveFeeds1:(NSArray *)liveFeeds{
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
