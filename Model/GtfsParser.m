//
//  GtfsParser.m
//  Nimbler Caltrain
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "GtfsParser.h"
#import "GtfsAgency.h"
#import "UtilityFunctions.h"
#import "GtfsCalendarDates.h"
#import "GtfsStopTimes.h"
#import "GtfsParsingStatus.h"
#import "UtilityFunctions.h"
#import "nc_AppDelegate.h"
#import "GtfsRoutes.h"
#import "GtfsTempItinerary.h"
#import "RealTimeManager.h"

@interface GtfsParser ()
{
    NSString* lastTripsDataRequestString;
    int backgroundThreadsOutstanding;  // Count of # of background threads outstanding for parsing
}

@end

@implementation GtfsParser

@synthesize managedObjectContext;
@synthesize rkTpClient;
@synthesize strAgenciesURL;
@synthesize strCalendarDatesURL;
@synthesize strCalendarURL;
@synthesize strRoutesURL;
@synthesize strStopsURL;
@synthesize strTripsURL;
@synthesize strStopTimesURL;
@synthesize loadedInitialData;
@synthesize dictServerCallSoFar;
@synthesize tripsDictionary;
@synthesize stopsDictionary;
// @synthesize backgroundMOC;
@synthesize isParticularTripRequest;
@synthesize temporaryLeg;
@synthesize temporaryItinerary;
@synthesize legsArray;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkTpClient:(RKClient *)rkClient
{
    self = [super init];
    if (self) {
        self.managedObjectContext = moc;
        self.rkTpClient = rkClient;
        dictServerCallSoFar = [[NSMutableDictionary alloc] init];
        
        // John: managedObjectContext is supposed to be created in the thread using it per: http://developer.apple.com/library/mac/#documentation/cocoa/conceptual/CoreData/Articles/cdConcurrency.html
        // NSPersistentStoreCoordinator *psc = [self.managedObjectContext persistentStoreCoordinator];
        // backgroundMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        // [backgroundMOC setUndoManager:nil];  // turn off undo for higher performance
        // [backgroundMOC setPersistentStoreCoordinator:psc];
        // [backgroundMOC setMergePolicy:NSOverwriteMergePolicy];
        // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:backgroundMOC];
    }
    return self;
}

- (void) parseAndStoreGtfsAgencyData:(NSDictionary *)dictFileData{
//    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:moc];
//    backgroundThreadsOutstanding++;
//    [moc setPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator]];
//    [moc setMergePolicy:NSOverwriteMergePolicy];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFetchRequest * fetchAgencies = [[NSFetchRequest alloc] init];
        [fetchAgencies setEntity:[NSEntityDescription entityForName:@"GtfsAgency" inManagedObjectContext:managedObjectContext]];
        NSArray * arrayAgencies = [managedObjectContext executeFetchRequest:fetchAgencies error:nil];
        for (id agency in arrayAgencies){
            [managedObjectContext deleteObject:agency];
        }
        
        NSMutableArray *arrayAgencyID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayAgencyName = [[NSMutableArray alloc] init];
        NSMutableArray *arrayAgencyURL = [[NSMutableArray alloc] init];
        
        NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
        for(int k=1;k<=8;k++){
            NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_agency",k]];
            for(int i=1;i<[arrayComponentsAgency count];i++){
                NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
                NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                [arrayAgencyID addObject:getItemAtIndexFromArray(0, arraySubComponents)];
                [arrayAgencyName addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                [arrayAgencyURL addObject:getItemAtIndexFromArray(2,arraySubComponents)];
            }
        }
        for(int i=0;i<[arrayAgencyID count];i++){
            GtfsAgency* agency = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsAgency" inManagedObjectContext:managedObjectContext];
            agency.agencyID = [arrayAgencyID objectAtIndex:i];
            agency.agencyName = [arrayAgencyName objectAtIndex:i];
            agency.agencyURL = [arrayAgencyURL objectAtIndex:i];
        }
        saveContext(managedObjectContext);
//        dispatch_async(dispatch_get_main_queue(), ^{
//        });
//    });
}

- (void) parseAndStoreGtfsCalendarDatesData:(NSDictionary *)dictFileData{
//    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:moc];
//    backgroundThreadsOutstanding++;
//    [moc setPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator]];
//    [moc setMergePolicy:NSOverwriteMergePolicy];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFetchRequest * fetchCalendarDates = [[NSFetchRequest alloc] init];
        [fetchCalendarDates setEntity:[NSEntityDescription entityForName:@"GtfsCalendarDates" inManagedObjectContext:managedObjectContext]];
        NSArray * arrayPlanCalendarDates = [managedObjectContext executeFetchRequest:fetchCalendarDates error:nil];
        for (id calendarDates in arrayPlanCalendarDates){
            [managedObjectContext deleteObject:calendarDates];
        }
        
        NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayDate = [[NSMutableArray alloc] init];
        NSMutableArray *arrayExceptionType = [[NSMutableArray alloc] init];
        
        NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
        for(int k=1;k<=8;k++){
            NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_calendar_dates",k]];
            for(int i=1;i<[arrayComponentsAgency count];i++){
                NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
                if(strSubComponents && strSubComponents.length > 0){
                    NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                    [arrayServiceID addObject:getItemAtIndexFromArray(0, arraySubComponents)];
                    [arrayDate addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                    [arrayExceptionType addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                }
            }
        }
        NSDateFormatter *formtter = [[NSDateFormatter alloc] init];
        [formtter setDateFormat:@"yyyyMMdd"];
        NSFetchRequest * fetchCalendar = [[NSFetchRequest alloc] init];
        [fetchCalendar setEntity:[NSEntityDescription entityForName:@"GtfsCalendar" inManagedObjectContext:managedObjectContext]];
        NSArray * arrayCalendar = [managedObjectContext executeFetchRequest:fetchCalendar error:nil];
        NSMutableDictionary *dictCalendar = [[NSMutableDictionary alloc] init];
        for(int i=0;i<[arrayCalendar count];i++){
            GtfsCalendar *calendar = [arrayCalendar objectAtIndex:i];
            [dictCalendar setObject:calendar forKey:calendar.serviceID];
        }
        for(int i=0;i<[arrayServiceID count];i++){
            GtfsCalendarDates* calendarDates = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsCalendarDates" inManagedObjectContext:managedObjectContext];
            calendarDates.serviceID = [arrayServiceID objectAtIndex:i];
            calendarDates.calendar = [dictCalendar objectForKey:calendarDates.serviceID];
            NSString *strDate = [arrayDate objectAtIndex:i];
            NSDate *dates;
            if(strDate.length > 0){
                dates = [formtter dateFromString:[arrayDate objectAtIndex:i]];
                calendarDates.date = dates;
            }
            calendarDates.exceptionType = [arrayExceptionType objectAtIndex:i];
        }
        saveContext(managedObjectContext);
//        dispatch_async(dispatch_get_main_queue(), ^{
//        });
//    });
}

- (void) parseAndStoreGtfsCalendarData:(NSDictionary *)dictFileData{
    
//    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:moc];
//    backgroundThreadsOutstanding++;
//    [moc setPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator]];
//    [moc setMergePolicy:NSOverwriteMergePolicy];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFetchRequest * fetchCalendar = [[NSFetchRequest alloc] init];
        [fetchCalendar setEntity:[NSEntityDescription entityForName:@"GtfsCalendar" inManagedObjectContext:managedObjectContext]];
        NSArray * arrayCalendar = [managedObjectContext executeFetchRequest:fetchCalendar error:nil];
        for (id calendar in arrayCalendar){
            [managedObjectContext deleteObject:calendar];
        }
        
        NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayMonday = [[NSMutableArray alloc] init];
        NSMutableArray *arrayTuesday = [[NSMutableArray alloc] init];
        NSMutableArray *arrayWednesday = [[NSMutableArray alloc] init];
        NSMutableArray *arrayThursday = [[NSMutableArray alloc] init];
        NSMutableArray *arrayFriday = [[NSMutableArray alloc] init];
        NSMutableArray *arraySaturday = [[NSMutableArray alloc] init];
        NSMutableArray *arraySunday = [[NSMutableArray alloc] init];
        NSMutableArray *arrayStartDate = [[NSMutableArray alloc] init];
        NSMutableArray *arrayEndDate = [[NSMutableArray alloc] init];
        
        NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
        for(int k=1;k<=8;k++){
            NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_calendar",k]];
            for(int i=1;i<[arrayComponentsAgency count];i++){
                NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
                if(strSubComponents && strSubComponents.length > 0){
                    NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                    [arrayServiceID addObject:getItemAtIndexFromArray(0, arraySubComponents)];
                    [arrayMonday addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                    [arrayTuesday addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                    [arrayWednesday addObject:getItemAtIndexFromArray(3, arraySubComponents)];
                    [arrayThursday addObject:getItemAtIndexFromArray(4,arraySubComponents)];
                    [arrayFriday addObject:getItemAtIndexFromArray(5,arraySubComponents)];
                    [arraySaturday addObject:getItemAtIndexFromArray(6, arraySubComponents)];
                    [arraySunday addObject:getItemAtIndexFromArray(7,arraySubComponents)];
                    [arrayStartDate addObject:getItemAtIndexFromArray(8,arraySubComponents)];
                    [arrayEndDate addObject:getItemAtIndexFromArray(9,arraySubComponents)];
                }
            }
        }
        NSDateFormatter *formtter = [[NSDateFormatter alloc] init];
        [formtter setDateFormat:@"yyyyMMdd"];
        for(int i=0;i<[arrayServiceID count];i++){
            GtfsCalendar* calendar = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsCalendar" inManagedObjectContext:managedObjectContext];
            calendar.serviceID = [arrayServiceID objectAtIndex:i];
            int dMonday = [[arrayMonday objectAtIndex:i] intValue];
            int dTuesday = [[arrayTuesday objectAtIndex:i] intValue];
            int dWednesday = [[arrayWednesday objectAtIndex:i] intValue];
            int dThursday = [[arrayThursday objectAtIndex:i] intValue];
            int dFriday = [[arrayFriday objectAtIndex:i] intValue];
            int dSaturday = [[arraySaturday objectAtIndex:i] intValue];
            int dSunday = [[arraySunday objectAtIndex:i] intValue];
            calendar.monday = [NSNumber numberWithInt:dMonday];
            calendar.tuesday = [NSNumber numberWithInt:dTuesday];
            calendar.wednesday = [NSNumber numberWithInt:dWednesday];
            calendar.thursday = [NSNumber numberWithInt:dThursday];
            calendar.friday = [NSNumber numberWithInt:dFriday];
            calendar.saturday = [NSNumber numberWithInt:dSaturday];
            calendar.sunday = [NSNumber numberWithInt:dSunday];
            NSString *strStartDate = [arrayStartDate objectAtIndex:i];
            NSString *strEndDate = [arrayEndDate objectAtIndex:i];
            if(strStartDate.length > 0){
                NSDate *startDate = [formtter dateFromString:strStartDate];
                calendar.startDate = startDate;
            }
            if(strEndDate.length > 0){
                NSDate *endDate = [formtter dateFromString:strEndDate];
                calendar.endDate = endDate;
            }
        }
        saveContext(managedObjectContext);
//        dispatch_async(dispatch_get_main_queue(), ^{
//        });
//    });
}

- (void) parseAndStoreGtfsRoutesData:(NSDictionary *)dictFileData{
    
//    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:moc];
//    backgroundThreadsOutstanding++;
//    [moc setPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator]];
//    [moc setMergePolicy:NSOverwriteMergePolicy];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFetchRequest * fetchRoutes = [[NSFetchRequest alloc] init];
        [fetchRoutes setEntity:[NSEntityDescription entityForName:@"GtfsRoutes" inManagedObjectContext:managedObjectContext]];
        NSArray * arrayRoutes = [managedObjectContext executeFetchRequest:fetchRoutes error:nil];
        for (id routes in arrayRoutes){
            [managedObjectContext deleteObject:routes];
        }
    
        NSMutableArray *routeIDsWithodBus = [[NSMutableArray alloc] init];
        NSMutableArray *agencyIDsWithodBus = [[NSMutableArray alloc] init];
    
        NSMutableArray *arrayRouteID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayRouteShortName = [[NSMutableArray alloc] init];
        NSMutableArray *arrayRouteLongName = [[NSMutableArray alloc] init];
        NSMutableArray *arrayRouteDesc = [[NSMutableArray alloc] init];
        NSMutableArray *arrayRouteType = [[NSMutableArray alloc] init];
        NSMutableArray *arrayRouteURL = [[NSMutableArray alloc] init];
        NSMutableArray *arrayRouteColor = [[NSMutableArray alloc] init];
        NSMutableArray *arrayRouteTextColor = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyId = [[NSMutableArray alloc] init];
    
        NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
        for(int k=1;k<=8;k++){
            NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_routes",k]];
            for(int i=1;i<[arrayComponentsAgency count];i++){
                NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
                if(strSubComponents && strSubComponents.length > 0){
                    NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                    [arrayAgencyId addObject:[NSString stringWithFormat:@"%d",k]];
                    [arrayRouteID addObject:getItemAtIndexFromArray(0,arraySubComponents)];
                    [arrayRouteShortName addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                    [arrayRouteLongName addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                    [arrayRouteDesc addObject:getItemAtIndexFromArray(3,arraySubComponents)];
                    [arrayRouteType addObject:getItemAtIndexFromArray(4,arraySubComponents)];
                    [arrayRouteURL addObject:getItemAtIndexFromArray(5,arraySubComponents)];
                    [arrayRouteColor addObject:getItemAtIndexFromArray(6,arraySubComponents)];
                    [arrayRouteTextColor addObject:getItemAtIndexFromArray(7,arraySubComponents)];
                }
                
            }
        }
        for(int i=0;i<[arrayRouteID count];i++){
            GtfsRoutes* routes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsRoutes" inManagedObjectContext:managedObjectContext];
            routes.routeID = [arrayRouteID objectAtIndex:i];
            routes.routeShortName = [arrayRouteShortName objectAtIndex:i];
            routes.routeLongname = [arrayRouteLongName objectAtIndex:i];
            routes.routeDesc = [arrayRouteDesc objectAtIndex:i];
            routes.routeType = [arrayRouteType objectAtIndex:i];
            routes.routeURL = [arrayRouteURL objectAtIndex:i];
            routes.routeColor = [arrayRouteColor objectAtIndex:i];
            routes.routeTextColor = [arrayRouteTextColor objectAtIndex:i];
            if(![routes.routeType isEqualToString:@"3"]){
                [routeIDsWithodBus addObject:[arrayRouteID objectAtIndex:i]];
                [agencyIDsWithodBus addObject:[arrayAgencyId objectAtIndex:i]];
            }
        }
        saveContext(managedObjectContext);
//        dispatch_async(dispatch_get_main_queue(), ^{
//        });
//    });
    
#if GENERATING_SEED_DATABASE
    [self generateTripsRequestForSeedDB:routeIDsWithodBus agencyIds:agencyIDsWithodBus];
#endif
}

- (void) parseAndStoreGtfsStopsData:(NSDictionary *)dictFileData{
//    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:moc];
//    backgroundThreadsOutstanding++;
//    [moc setPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator]];
//    [moc setMergePolicy:NSOverwriteMergePolicy];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFetchRequest * fetchStops = [[NSFetchRequest alloc] init];
        [fetchStops setEntity:[NSEntityDescription entityForName:@"GtfsStop" inManagedObjectContext:managedObjectContext]];
        NSArray * arrayStops = [managedObjectContext executeFetchRequest:fetchStops error:nil];
        for (id stops in arrayStops){
            [managedObjectContext deleteObject:stops];
        }
        
        NSMutableArray *arrayStopID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayStopName = [[NSMutableArray alloc] init];
        NSMutableArray *arrayStopDesc = [[NSMutableArray alloc] init];
        NSMutableArray *arrayStopLat = [[NSMutableArray alloc] init];
        NSMutableArray *arrayStopLong = [[NSMutableArray alloc] init];
        NSMutableArray *arrayZoneID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayStopURL = [[NSMutableArray alloc] init];
        
        NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
        for(int k=1;k<=8;k++){
            NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_stops",k]];
            for(int i=1;i<[arrayComponentsAgency count];i++){
                NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
                if(strSubComponents && strSubComponents.length > 0){
                    NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                    [arrayStopID addObject:getItemAtIndexFromArray(0,arraySubComponents)];
                    [arrayStopName addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                    [arrayStopDesc addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                    [arrayStopLat addObject:getItemAtIndexFromArray(3,arraySubComponents)];
                    [arrayStopLong addObject:getItemAtIndexFromArray(4,arraySubComponents)];
                    [arrayZoneID addObject:getItemAtIndexFromArray(5,arraySubComponents)];
                    [arrayStopURL addObject:getItemAtIndexFromArray(6,arraySubComponents)];
                }
            }
        }
        for(int i=0;i<[arrayStopID count];i++){
            GtfsStop* routes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsStop" inManagedObjectContext:managedObjectContext];
            routes.stopID = [arrayStopID objectAtIndex:i];
            routes.stopName = [arrayStopName objectAtIndex:i];
            routes.stopDesc = [arrayStopDesc objectAtIndex:i];
            double stopLat = [[arrayStopLat objectAtIndex:i] doubleValue];
            double stopLong = [[arrayStopLong objectAtIndex:i] doubleValue];
            routes.stopLat = [NSNumber numberWithDouble:stopLat];
            routes.stopLon = [NSNumber numberWithDouble:stopLong];
            routes.zoneID = [arrayZoneID objectAtIndex:i];
            routes.stopURL = [arrayStopURL objectAtIndex:i];
        }
        saveContext(managedObjectContext);
//        dispatch_async(dispatch_get_main_queue(), ^{
//        });
//    });
}

- (void) parseAndStoreGtfsTripsData:(NSDictionary *)dictFileData RequestUrl:(NSString *)strRequestUrl{
//    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:moc];
//    backgroundThreadsOutstanding++;
//    [moc setPersistentStoreCoordinator:[self.managedObjectContext persistentStoreCoordinator]];
//    [moc setMergePolicy:NSOverwriteMergePolicy];
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSArray *arrayComponents = [strRequestUrl componentsSeparatedByString:@"?"];
//        NSString *tempString = [arrayComponents objectAtIndex:1];
//        NSArray *arraySubComponents = [tempString componentsSeparatedByString:@"="];
//        NSString *tempStringSubComponents = [arraySubComponents objectAtIndex:1];
//        NSArray *arrayAgencyIds = [tempStringSubComponents componentsSeparatedByString:@"%2C"];
        NSMutableArray *arrayTripID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayRouteID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayTripHeadSign = [[NSMutableArray alloc] init];
        NSMutableArray *arrayDirectionID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayBlockID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayShapeID = [[NSMutableArray alloc] init];
        NSMutableArray *arrayAgencyID = [[NSMutableArray alloc] init];
        
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] initWithDictionary:dictComponents];
    [tempDictionary removeObjectForKey:@"headers"];
    dictComponents = tempDictionary;
    NSArray *arrayAgencyIds = [dictComponents allKeys];
    for(int k=0;k<[arrayAgencyIds count];k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[arrayAgencyIds objectAtIndex:k]];
        for(int i=0;i<[arrayComponentsAgency count];i++){
            NSString *strAgencyIds = [arrayAgencyIds objectAtIndex:k];
            NSArray *arrayAgencyIdsComponents = [strAgencyIds componentsSeparatedByString:@"_"];
            [arrayAgencyID addObject:getItemAtIndexFromArray(0,arrayAgencyIdsComponents)];
                NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
                if(strSubComponents && strSubComponents.length > 0){
                    NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                    [arrayTripID addObject:getItemAtIndexFromArray(0,arraySubComponents)];
                    [arrayRouteID addObject:getItemAtIndexFromArray(1,arraySubComponents)];
                    [arrayServiceID addObject:getItemAtIndexFromArray(2,arraySubComponents)];
                    [arrayTripHeadSign addObject:getItemAtIndexFromArray(3,arraySubComponents)];
                    [arrayDirectionID addObject:getItemAtIndexFromArray(4,arraySubComponents)];
                    [arrayBlockID addObject:getItemAtIndexFromArray(5,arraySubComponents)];
                    [arrayShapeID addObject:getItemAtIndexFromArray(6,arraySubComponents)];
                }
            }
        }
        NSFetchRequest * fetchRoutes = [[NSFetchRequest alloc] init];
        [fetchRoutes setEntity:[NSEntityDescription entityForName:@"GtfsRoutes" inManagedObjectContext:managedObjectContext]];
        NSArray * arrayRoutes = [managedObjectContext executeFetchRequest:fetchRoutes error:nil];
        NSMutableDictionary *dictRoutes = [[NSMutableDictionary alloc] init];
        for(int i=0;i<[arrayRoutes count];i++){
            GtfsRoutes *routes = [arrayRoutes objectAtIndex:i];
            [dictRoutes setObject:routes forKey:routes.routeID];
        }
        
        NSFetchRequest * fetchCalendar = [[NSFetchRequest alloc] init];
        [fetchCalendar setEntity:[NSEntityDescription entityForName:@"GtfsCalendar" inManagedObjectContext:managedObjectContext]];
        NSArray * arrayCalendar = [managedObjectContext executeFetchRequest:fetchCalendar error:nil];
        NSMutableDictionary *dictCalendar = [[NSMutableDictionary alloc] init];
        for(int i=0;i<[arrayCalendar count];i++){
            GtfsCalendar *calendar = [arrayCalendar objectAtIndex:i];
            [dictCalendar setObject:calendar forKey:calendar.serviceID];
        }
        for(int i=0;i<[arrayTripID count];i++){
            GtfsTrips* trips = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsTrips" inManagedObjectContext:managedObjectContext];
            trips.tripID = [arrayTripID objectAtIndex:i];
            trips.routeID = [arrayRouteID objectAtIndex:i];
            trips.route = [dictRoutes objectForKey:trips.routeID];
            trips.serviceID = [arrayServiceID objectAtIndex:i];
            trips.calendar = [dictCalendar objectForKey:trips.serviceID];
            
            trips.tripHeadSign = [arrayTripHeadSign objectAtIndex:i];
            trips.directionID = [arrayDirectionID objectAtIndex:i];
            trips.blockID = [arrayBlockID objectAtIndex:i];
            trips.shapeID = [arrayShapeID objectAtIndex:i];
            if (!trips.calendar) {
                logError(@"gtfsParser->parseAndStoreGtfsTripsData",
                         [NSString stringWithFormat:@"trips.calendar==nil for tripID = %@, trips.serviceID = %@",trips.tripID, trips.serviceID]);
            }
        }
        saveContext(managedObjectContext);
    [self generateStopTimesRequestStringUsingTripIds:arrayTripID agencyIds:arrayAgencyID];
}

- (void)contextChanged:(NSNotification*)notification
{
    if ([notification object] == [self managedObjectContext]) return;
    
    if (![NSThread isMainThread]) {
        // John note: Changed waitUntilDone: to NO in attempt to avoid deadlocks when main thread is waiting
        // to be able to save context itself.  
        [self performSelectorOnMainThread:@selector(contextChanged:) withObject:notification waitUntilDone:NO];
        return;
    }
    [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
    // TODO:  uncomment below code once we can distinguish between interim and final parseStopTimes notification
    // [[[nc_AppDelegate sharedInstance] planStore] updatePlansWithNewGtfsDataIfNeeded];  // see if any plans need the data just updated
    // backgroundThreadsOutstanding--;
    // if (backgroundThreadsOutstanding <= 0) {  // only remove observer if there are no more background requests outstanding
    //     [[NSNotificationCenter defaultCenter] removeObserver:self];
    // }
}

- (void) parseStopTimesDataForSingleTripData:(NSDictionary *)dictFileData{
        @try {
            NSMutableArray *stopTimes = [[NSMutableArray alloc] init];
            NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
            NSArray *arrayAgency_TripIds = [dictComponents allKeys];
            for(int k=0;k<[arrayAgency_TripIds count];k++){
                if ([[arrayAgency_TripIds objectAtIndex:k] isEqualToString:@"headers"]) {
                    continue;    // skip headers rows
                }
                NSArray *arrayComponentsAgency = [dictComponents objectForKey:[arrayAgency_TripIds objectAtIndex:k]];
                NSString *strAgency_TripIds = [arrayAgency_TripIds objectAtIndex:k];
                NSArray *arrayAgencyIdsComponents = [strAgency_TripIds componentsSeparatedByString:@"_"];
                for(int i=0;i<[arrayComponentsAgency count];i++){
                    NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
                    if(strSubComponents && strSubComponents.length > 0){
                        GtfsStopTimes* stopTime = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsStopTimes" inManagedObjectContext:managedObjectContext];
                        NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                        
                        NSString* tripID = getItemAtIndexFromArray(0,arraySubComponents);
                        stopTime.tripID = tripID;
                        stopTime.arrivalTime = getItemAtIndexFromArray(1,arraySubComponents);
                        stopTime.departureTime = getItemAtIndexFromArray(2,arraySubComponents);
                        NSString* stopID = getItemAtIndexFromArray(3,arraySubComponents);
                        stopTime.stopID = stopID;
                        stopTime.stopSequence = getItemAtIndexFromArray(4,arraySubComponents);
                        stopTime.pickUpType = getItemAtIndexFromArray(5,arraySubComponents);
                        stopTime.dropOffType = getItemAtIndexFromArray(6,arraySubComponents);
                        stopTime.shapeDistTravelled = getItemAtIndexFromArray(7,arraySubComponents);
                        
                        stopTime.departureTimeInterval = [NSNumber numberWithInt:timeIntervalFromTimeString(getItemAtIndexFromArray(2,arraySubComponents))] ;
                        stopTime.arrivalTimeInterval = [NSNumber numberWithInt:timeIntervalFromTimeString(getItemAtIndexFromArray(1, arraySubComponents))];
                        
                        NSString* agencyID = getItemAtIndexFromArray(0,arrayAgencyIdsComponents);
                        stopTime.agencyID = agencyID;
                        [stopTimes addObject:stopTime];
                    }
                }
            }
            NSSortDescriptor *sortD = [[NSSortDescriptor alloc]
                                       
                                       initWithKey:@"stopSequence" ascending:YES selector:@selector(localizedStandardCompare:)];
            NSArray *arrayStopTimes = [stopTimes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]];
            NSMutableArray *intermediateStops = [[NSMutableArray alloc] init];
            
            int startIndex = 0;
            int endIndex = 0;
            NIMLOG_PERF2(@"fromStopId=%@",temporaryLeg.from.stopId);
            NIMLOG_PERF2(@"toStopId=%@",temporaryLeg.to.stopId);
            GtfsStopTimes *matchingStopTime;
            for(int i=0;i<[arrayStopTimes count];i++){
                GtfsStopTimes *stopTimes = [arrayStopTimes objectAtIndex:i];
                if([stopTimes.stopID isEqualToString:temporaryLeg.from.stopId]){
                    startIndex = i + 1;
                    matchingStopTime = [arrayStopTimes objectAtIndex:i];
                    break;
                }
            }
            for(int i=0;i<[arrayStopTimes count];i++){
                GtfsStopTimes *stopTimes = [arrayStopTimes objectAtIndex:i];
                if([stopTimes.stopID isEqualToString:temporaryLeg.to.stopId]){
                    endIndex = i;
                    break;
                }
            }
            for(int i = startIndex; i<endIndex ;i++){
                GtfsStopTimes *stopTimes = [arrayStopTimes objectAtIndex:i];
                [intermediateStops addObject:stopTimes];
            }
            [[nc_AppDelegate sharedInstance].toFromViewController.routeOptionsVC.routeDetailsVC intermediateStopTimesReceived:intermediateStops Leg:temporaryLeg];
        }
        @catch (NSException *exception) {
            logException(@"GtfsParser->parseStopTimesDataForSingleTripData", @"exception in background task", exception);
        }
}

- (void) parseAndStoreGtfsStopTimesData:(NSDictionary *)dictFileData RequestUrl:(NSString *)strResourcePath{
    backgroundThreadsOutstanding++;
    __block double totalTime = 0.0;
    __block int totalrecords = 0;
    __block int saveContextCount = 0;
    // http://www.raywenderlich.com/4295/multithreading-and-grand-central-dispatch-on-ios-for-beginners-tutorial
    dispatch_queue_t backgroundQueue;
    backgroundQueue = dispatch_queue_create("com.nimbler.backgroundQueue", NULL);
    NSPersistentStoreCoordinator *psc = [self.managedObjectContext persistentStoreCoordinator];
    dispatch_async(backgroundQueue, ^(void) {
        @try {
            NSManagedObjectContext* backgroundMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [backgroundMOC setUndoManager:nil];  // turn off undo for higher performance
            [backgroundMOC setPersistentStoreCoordinator:psc];
            [backgroundMOC setMergePolicy:NSOverwriteMergePolicy];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:backgroundMOC];
            NSMutableDictionary *routeIdAndAgencyIdDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
            
            NIMLOG_PERF2(@"parse stop times start");
            
            NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
            NSArray *arrayAgency_TripIds = [dictComponents allKeys];
            
            NIMLOG_PERF2(@"Parse stop times main loop");
            
            int insertedRowCount = 0;
            
            for(int k=0;k<[arrayAgency_TripIds count];k++){
                if ([[arrayAgency_TripIds objectAtIndex:k] isEqualToString:@"headers"]) {
                    continue;    // skip headers rows
                }
                NSArray *arrayComponentsAgency = [dictComponents objectForKey:[arrayAgency_TripIds objectAtIndex:k]];
                NSString *strAgency_TripIds = [arrayAgency_TripIds objectAtIndex:k];
                NSArray *arrayAgencyIdsComponents = [strAgency_TripIds componentsSeparatedByString:@"_"];
                for(int i=0;i<[arrayComponentsAgency count];i++){
                    NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
                    if(strSubComponents && strSubComponents.length > 0){
                        insertedRowCount++;
                        totalrecords ++;
                        GtfsStopTimes* stopTime = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsStopTimes" inManagedObjectContext:backgroundMOC];
                        NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
                        
                        NSString* tripID = getItemAtIndexFromArray(0,arraySubComponents);
                        stopTime.tripID = tripID;
                        stopTime.arrivalTime = getItemAtIndexFromArray(1,arraySubComponents);
                        stopTime.departureTime = getItemAtIndexFromArray(2,arraySubComponents);
                        NSString* stopID = getItemAtIndexFromArray(3,arraySubComponents);
                        stopTime.stopID = stopID;
                        stopTime.stopSequence = getItemAtIndexFromArray(4,arraySubComponents);
                        stopTime.pickUpType = getItemAtIndexFromArray(5,arraySubComponents);
                        stopTime.dropOffType = getItemAtIndexFromArray(6,arraySubComponents);
                        stopTime.shapeDistTravelled = getItemAtIndexFromArray(7,arraySubComponents);
                        
                         stopTime.departureTimeInterval = [NSNumber numberWithInt:timeIntervalFromTimeString(getItemAtIndexFromArray(2,arraySubComponents))] ;
                         stopTime.arrivalTimeInterval = [NSNumber numberWithInt:timeIntervalFromTimeString(getItemAtIndexFromArray(1, arraySubComponents))];
                        
                        NSString* agencyID = getItemAtIndexFromArray(0,arrayAgencyIdsComponents);
                        stopTime.agencyID = agencyID;
                        //GtfsTrips* trip = [dictTrips objectForKey:tripID];
                        //stopTime.trips = trip;
                        //stopTime.stop = [dictStops objectForKey:stopID];
                        if (i==0) {  // only do once for a particular tripID
                            GtfsTrips *trip = [self fetchTripsFromTripId:tripID context:backgroundMOC];
                            if (trip.routeID) {
                                [routeIdAndAgencyIdDictionary setObject:agencyID forKey:trip.routeID];
                            } else {
                                NIMLOG_ERR1(@"GtfsParser->parseAndStoreGtfsStopTimesData: Nil routeID for stopTime.tripId: %@", stopTime.tripID);
                                [backgroundMOC deleteObject:stopTime];
                            }
                        }
                    }
                }  // end StopTimes loop
                
                if (insertedRowCount >= DB_ROWS_BEFORE_SAVING_TO_PSC) {
                    // Save context and create a new moc
                    NIMLOG_PERF2(@"Saving context after %d rows inserted", insertedRowCount);
                    NSDate *date1 = [NSDate date];
                    insertedRowCount = 0;
                    saveContextCount = saveContextCount + 1;
                    saveContext(backgroundMOC);
                    NSDate *date2 = [NSDate date];
                    double diff = [date2 timeIntervalSinceDate:date1];
                    totalTime = totalTime + diff;
                    NIMLOG_PERF2(@"Done saving context at=%f",diff);
                    
                    // Release and re-assign new backgroundMOC
                    [[NSNotificationCenter defaultCenter] removeObserver:self];
                    backgroundMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                    [backgroundMOC setUndoManager:nil];  // turn off undo for higher performance
                    [backgroundMOC setPersistentStoreCoordinator:psc];
                    [backgroundMOC setMergePolicy:NSOverwriteMergePolicy];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:backgroundMOC];
                }
            } // end TripId loop

            // Update gtfsParsingStatus for each routeId / AgencyId combination
            NSArray* keys = [routeIdAndAgencyIdDictionary allKeys];
            for (NSString* routeId in keys) {
                NSString* agencyName = agencyNameFromAgencyFeedId([routeIdAndAgencyIdDictionary objectForKey:routeId]);
                [self setGtfsDataAvailableForAgencyName:agencyName routeId:routeId context:backgroundMOC];
            }
            NIMLOG_PERF2(@"totalRecords=%d",totalrecords);
            NIMLOG_PERF2(@"totalTime=%f",totalTime);
            NIMLOG_PERF2(@"averageTime=%f",totalTime/saveContextCount);
            NIMLOG_PERF2(@"parse stop times saving context");
            saveContext(backgroundMOC);
            
            //NSDictionary *lastRealtimeResponse = [RealTimeManager realTimeManager].lastRealtimeResponse;
            //[[RealTimeManager realTimeManager] setLiveFeed:lastRealtimeResponse];
        }
        @catch (NSException *exception) {
            logException(@"GtfsParser->parseAndStoreGtfsStopTimesData", @"exception in background task", exception);
        }
        NIMLOG_PERF2(@"Parse stop times done");
    });
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//        });
//    });
}

#pragma mark  GTFS Requests

// Request The Server For Agency Data.
-(void)requestAgencyDataFromServer{
    int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_AGENCY_COUNTER] intValue];
    [dictServerCallSoFar setObject:[NSNumber numberWithInt:serverCallSoFar + 1] forKey:GTFS_AGENCY_COUNTER];
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"agency",ENTITY,@"1,2,3,4,5,6,7,8",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strAgenciesURL = request;
        NIMLOG_OBJECT1(@"Get Agencies: %@", request);
        [self.rkTpClient get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getAgencies", @"", exception);
    }
}

// Request The Server For Calendar Dates.
-(void)requestCalendarDatesDataFromServer{
    int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_CALENDAR_DATES_COUNTER] intValue];
    serverCallSoFar = serverCallSoFar + 1;
    [dictServerCallSoFar setObject:[NSNumber numberWithInt:serverCallSoFar] forKey:GTFS_CALENDAR_DATES_COUNTER];
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"calendar_dates",ENTITY,@"1,2,3,4,5,6,7,8",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strCalendarDatesURL = request;
        NIMLOG_OBJECT1(@"Get Calendar Dates: %@", request);
        [self.rkTpClient  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getCalendarDates", @"", exception);
    }
}

// Request The Server For Calendar Data.
-(void)requestCalendarDatafromServer{
    int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_CALENDAR_COUNTER] intValue];
    serverCallSoFar = serverCallSoFar + 1;
    [dictServerCallSoFar setObject:[NSNumber numberWithInt:serverCallSoFar] forKey:GTFS_CALENDAR_COUNTER];
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"calendar",ENTITY,@"1,2,3,4,5,6,7,8",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strCalendarURL = request;
        NIMLOG_OBJECT1(@"Get Calendar: %@", request);
        [self.rkTpClient  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getCalendarData", @"", exception);
    }
}

// Request The Server For Routes Data.
-(void)requestRoutesDatafromServer{
    int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_ROUTES_COUNTER] intValue];
    serverCallSoFar = serverCallSoFar + 1;
    [dictServerCallSoFar setObject:[NSNumber numberWithInt:serverCallSoFar] forKey:GTFS_ROUTES_COUNTER];
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"routes",ENTITY,@"1,2,3,4,5,6,7,8",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strRoutesURL = request;
        NIMLOG_OBJECT1(@"Get Routes: %@", request);
        [self.rkTpClient get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getRoutesData", @"", exception);
    }
}

// Request The Server For Stops Data.
-(void)requestStopsDataFromServer{
    int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_STOPS_COUNTER] intValue];
    serverCallSoFar = serverCallSoFar + 1;
    [dictServerCallSoFar setObject:[NSNumber numberWithInt:serverCallSoFar] forKey:GTFS_STOPS_COUNTER];
    @try {
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"stops",ENTITY,@"1,2,3,4,5,6,7,8",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strStopsURL = request;
        NIMLOG_OBJECT1(@"Get Stops: %@", request);
        [self.rkTpClient  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getStopsData", @"", exception);
    }
}

- (void) requestTripsDataForCreatingSeedDB:(NSMutableString *)strRequestString{
    int nLength = [strRequestString length];
    if(nLength > 0){
        [strRequestString deleteCharactersInRange:NSMakeRange(nLength-1, 1)];
    }
    @try {
        int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_TRIPS_COUNTER] intValue];
        serverCallSoFar = serverCallSoFar + 1;
        [dictServerCallSoFar setObject:[NSNumber numberWithInt:serverCallSoFar] forKey:GTFS_TRIPS_COUNTER];
        strTripsURL = GTFS_TRIPS;
        RKParams *requestParameter = [RKParams params];
        [requestParameter setValue:strRequestString forParam:AGENCY_ID_AND_ROUTE_ID];
        [self.rkTpClient post:GTFS_TRIPS params:requestParameter delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getGtfsStopTimes", @"", exception);
    }
}

// Request The Server For Trips Data.
-(void)requestTripsDatafromServer:(NSString *)strRequestString{
    @try {
        int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_TRIPS_COUNTER] intValue];
        serverCallSoFar = serverCallSoFar + 1;
        [dictServerCallSoFar setObject:[NSNumber numberWithInt:serverCallSoFar] forKey:GTFS_TRIPS_COUNTER];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:strRequestString,AGENCY_ID_AND_ROUTE_ID, nil];
        NSString *request = [GTFS_TRIPS appendQueryParams:dictParameters];
        strTripsURL = request;
        NIMLOG_OBJECT1(@"get Trips Data: %@", request);
        [self.rkTpClient  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getTripsData", @"", exception);
    }
}

// Request The Server For StopTimes Data.
- (void) requestStopTimesDataFromServer:(NSMutableString *)strRequestString{
    int nLength = [strRequestString length];
    if(nLength > 0){
        [strRequestString deleteCharactersInRange:NSMakeRange(nLength-1, 1)];
    }
    @try {
        RKParams *requestParameter = [RKParams params];
        [requestParameter setValue:strRequestString forParam:AGENCY_IDS];
        NIMLOG_PERF2(@"StopTimes Request Sent");
        [self.rkTpClient post:GTFS_STOP_TIMES params:requestParameter delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getGtfsStopTimes", @"", exception);
    }
}

- (void) removeAllTripsAndStopTimesData{
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsTrips" inManagedObjectContext:managedObjectContext]];
    NSArray * arrayTrips = [managedObjectContext executeFetchRequest:fetchTrips error:nil];
    for (id trip in arrayTrips){
        [managedObjectContext deleteObject:trip];
    }
    
    NSFetchRequest * fetchStopTimes = [[NSFetchRequest alloc] init];
    [fetchStopTimes setEntity:[NSEntityDescription entityForName:@"GtfsStopTimes" inManagedObjectContext:managedObjectContext]];
    NSArray * arrayStopTimes = [managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
    for (id stopTimes in arrayStopTimes){
        [managedObjectContext deleteObject:stopTimes];
    }
}
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
    NSString *strRequestURL = request.resourcePath;
    @try {
        if ([request isGET]) {
            NSError *error = nil;
            if (error == nil)
            {
                if ([strRequestURL isEqualToString:strAgenciesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsAgencyData:res];
                        [self requestCalendarDatafromServer];
                        [dictServerCallSoFar setObject:[NSNumber numberWithInt:0] forKey:GTFS_AGENCY_COUNTER];
                    }
                    else{
                        int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_AGENCY_COUNTER] intValue];
                        if(serverCallSoFar < 3)
                            [self requestAgencyDataFromServer];
                        else
                            logError(@"No results Back from Server for GtfsAgency request", [res objectForKey:@"msg"]);
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarDatesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsCalendarDatesData:res];
                        [self requestRoutesDatafromServer];
                        [dictServerCallSoFar setObject:[NSNumber numberWithInt:0] forKey:GTFS_CALENDAR_DATES_COUNTER];
                    }
                    else{
                        int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_CALENDAR_DATES_COUNTER] intValue];
                        if(serverCallSoFar < 3)
                            [self requestCalendarDatesDataFromServer];
                        else
                            logError(@"No results Back from Server for GtfsCalendarDates request",[res objectForKey:@"msg"]);
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarURL]) {
                    [nc_AppDelegate sharedInstance].receivedReply = true;
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsCalendarData:res];
                        [self requestCalendarDatesDataFromServer];
                        [dictServerCallSoFar setObject:[NSNumber numberWithInt:0] forKey:GTFS_CALENDAR_COUNTER];
                    }
                    else{
                        int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_CALENDAR_COUNTER] intValue];
                        if(serverCallSoFar < 3)
                            [self requestCalendarDatafromServer];
                        else
                            logError(@"No results Back from Server for GtfsCalendar request", [res objectForKey:@"msg"]);
                    }
                }
                else if ([strRequestURL isEqualToString:strRoutesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsRoutesData:res];
                        [self requestStopsDataFromServer];
                        [dictServerCallSoFar setObject:[NSNumber numberWithInt:0] forKey:GTFS_ROUTES_COUNTER];
                    }
                    else{
                        int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_ROUTES_COUNTER] intValue];
                        if(serverCallSoFar < 3)
                            [self requestRoutesDatafromServer];
                        else
                            logError(@"No results Back from Server for GtfsRoutes request", [res objectForKey:@"msg"]);
                    }
                }
                else if ([strRequestURL isEqualToString:strStopsURL]) {
                    [nc_AppDelegate sharedInstance].receivedReply = true;
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsStopsData:res];
                        loadedInitialData = true;  // mark that we are done with our initial data load
                        [dictServerCallSoFar setObject:[NSNumber numberWithInt:0] forKey:GTFS_STOPS_COUNTER];
                    }
                    else{
                        int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_STOPS_COUNTER] intValue];
                        if(serverCallSoFar < 3)
                            [self requestStopsDataFromServer];
                        else
                            logError(@"No results Back from Server for GtfsStops request", [res objectForKey:@"msg"]);
                    }
                }
                else if ([strRequestURL isEqualToString:strTripsURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseAndStoreGtfsTripsData:res RequestUrl:strRequestURL];
                        [dictServerCallSoFar setObject:[NSNumber numberWithInt:0] forKey:GTFS_TRIPS_COUNTER];
                    }
                    else{
                        int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_STOPS_COUNTER] intValue];
                        if(serverCallSoFar < 3)
                            [self requestTripsDatafromServer:lastTripsDataRequestString];
                        else
                            logError(@"No results Back from Server for GtfsTrips request", [res objectForKey:@"msg"]);
                    }
                }
            }
        }
        else{
            if ([strRequestURL isEqualToString:strTripsURL]) {
                RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                    [self parseAndStoreGtfsTripsData:res RequestUrl:strRequestURL];
                    [dictServerCallSoFar setObject:[NSNumber numberWithInt:0] forKey:GTFS_TRIPS_COUNTER];
                }
                else{
                    int serverCallSoFar = [[dictServerCallSoFar objectForKey:GTFS_STOPS_COUNTER] intValue];
                    if(serverCallSoFar < 3)
                        [self requestTripsDatafromServer:lastTripsDataRequestString];
                    else
                        logError(@"No results Back from Server for GtfsTrips request", [res objectForKey:@"msg"]);
                }
            }
            else if(isParticularTripRequest){
                RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                NSDictionary * res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                    [self parseStopTimesDataForSingleTripData:res];
                    isParticularTripRequest = false;
                    NSMutableArray *legArray = [[NSMutableArray alloc] initWithArray:legsArray];
                    if([legArray count] > 0){
                        [legArray removeObjectAtIndex:0];
                    }
                    legsArray = legArray;
                    if([legsArray count] > 0){
                        [self requestStopTimesDataForParticularTripFromServer:temporaryItinerary];
                    }
                }
            }
            else{
                [nc_AppDelegate sharedInstance].receivedReply = true;
                RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                NSDictionary * res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                    NIMLOG_PERF2(@"StopTimes Parsing Started");
                    [self parseAndStoreGtfsStopTimesData:res RequestUrl:strRequestURL];
                    NIMLOG_PERF2(@"StopTimes Parsing and saving Done");
                    lastTripsDataRequestString = nil;
                }
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->didLoadResponse", @"catching TPServer Response", exception);
    }
}

- (BOOL) isTripsAlreadyExistsForTripId:(NSString *)strTripId RouteId:(NSString *)routeId{
    NSFetchRequest *fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsTripsByTripIdAndRouteId" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strTripId,@"TRIPID",routeId,@"ROUTEID", nil]];
    NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
    if([arrayStopTimes count] > 0)
        return YES;
    return NO;
}

// Check StopTimes Table for particular tripID&agencyID data is exists or not.
// If Data For tripID&agencyID  Already Exists then we will not ask StopTimes Data for that tripID from Server otherwise we will ask for StopTimes Data.
- (BOOL) checkIfTripIDAndAgencyIDAlreadyExists:(NSString *)strTripID
                                      agencyID:(NSString *)agencyID
{
    NSFetchRequest *fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopTimesByAgencyID" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:strTripID,@"TRIPID",agencyID,@"AGENCYID", nil]];
    NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
    if([arrayStopTimes count] > 0){
        return YES;
    }
    else{
        return NO;
    }
}

// Makes a request to the server for any GTFS Trips and StopTimes data not already in the database
// If there is data needed, planStore will eventually be called back when the data is loaded for plan refresh
- (void)generateGtfsTripsRequestStringUsingPlan:(Plan *) plan
{
    [nc_AppDelegate sharedInstance].receivedReply = false;
    NSMutableString *strRequestString = [[NSMutableString alloc] init];
    BOOL isStatusChanged = false;
    for (Itinerary* iti in [plan itineraries]) {
        if (iti.isOTPItinerary) {  // only check for OTP itineraries
            NSArray *legArray = [iti sortedLegs];
            for(int j=0;j<[legArray count];j++){
                Leg *leg = [legArray objectAtIndex:j];
                if([leg isScheduled]) {
                    if (![self isGtfsDataAvailableForAgencyName:leg.agencyName routeId:leg.routeId] &&
                        ![self hasGtfsDownloadRequestBeenSubmittedForAgencyName:leg.agencyName routeId:leg.routeId]) {
                        // if the data has not yet been requested, make the request
                        [strRequestString appendFormat:@"%@_%@,",agencyFeedIdFromAgencyName(leg.agencyName),leg.routeId];
                        [self setGtfsRequestSubmittedForAgencyName:leg.agencyName
                                                           routeId:leg.routeId
                                                              plan:plan];
                        isStatusChanged = true;
                    } // if data is requested, not adding this plan also at this point
                }
            }
        }
    }
    if([strRequestString length] > 0){
        int nLength = [strRequestString length];
        [strRequestString deleteCharactersInRange:NSMakeRange(nLength-1, 1)]; // Trim last comma
        lastTripsDataRequestString = strRequestString;
        // NIMLOG_US202(@"Request GTFS data for: %@",strRequestString);
        // [self requestTripsDatafromServer:strRequestString];  
    }
    if (isStatusChanged) {
        saveContext(managedObjectContext);
    }
}
-(void)someMethodToWaitForResult
{
    while (!([nc_AppDelegate sharedInstance].receivedReply^[nc_AppDelegate sharedInstance].receivedError))
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.00001]];
}

- (void)generateTripsRequestForSeedDB:(NSArray *)routeIds agencyIds:(NSArray *)agencyIds{
    NSMutableString *strRequestString = [[NSMutableString alloc] init];
    for(int i=0;i<[routeIds count];i++){
        NSString *strRouteId = [routeIds objectAtIndex:i];
        NSString *strAgencyId = [agencyIds objectAtIndex:i];
        if([strRequestString rangeOfString:[NSString stringWithFormat:@"%@_%@,",strAgencyId,strRouteId]].location == NSNotFound){
            [strRequestString appendFormat:@"%@_%@,",strAgencyId,strRouteId];
            [self setGtfsRequestSubmittedForAgencyName:agencyNameFromAgencyFeedId(strAgencyId) routeId:strRouteId plan:nil];
        }
    }
    if([strRequestString length] > 0){
        [self requestTripsDataForCreatingSeedDB:strRequestString];
    }
}


// Generate The StopTimes Request Comma Separated string like agencyID_tripID
- (void)generateStopTimesRequestStringUsingTripIds:(NSArray *)tripIds agencyIds:(NSArray *)agencyIds{
//    NSArray *arrTripId;
//    NSArray *arrAgencyId;
//    int n1 = [tripIds count]/50;
//    int n2 = [tripIds count]%50;
//    int loopCount = 0;
//    for(int i=0;i<[tripIds count];i=i+50){
//        [nc_AppDelegate sharedInstance].receivedReply = false;
//        NSRange range;
//        if(loopCount < n1)
//            range = NSMakeRange (i, 50);
//        else
//            range = NSMakeRange(i,n2);
//        loopCount++;
//        arrTripId = [tripIds subarrayWithRange:range];
//        arrAgencyId = [agencyIds subarrayWithRange:range];
        NSMutableString *strRequestString = [[NSMutableString alloc] init];
        for(int i=0;i<[tripIds count];i++){
            NSString *strTripId = [tripIds objectAtIndex:i];
            NSString *strAgencyId = [agencyIds objectAtIndex:i];
            if([strRequestString rangeOfString:[NSString stringWithFormat:@"%@_%@,",strAgencyId,strTripId]].location == NSNotFound)
                [strRequestString appendFormat:@"%@_%@,",strAgencyId,strTripId];
        }
        if([strRequestString length] > 0){
                [self requestStopTimesDataFromServer:strRequestString];
        }
}

// Fetch stops from stopsDictionary if available otherwise fetch all stops from database and set it to stopsDictionary and then get stops from stopsDictionary.

- (GtfsStop *) fetchStopsFromStopId:(NSString *)stopId{
    GtfsStop *stopFromDictionary = [stopsDictionary objectForKey:stopId];
    if(stopFromDictionary)
        return stopFromDictionary;
    
    NSError *error = nil;
    NSFetchRequest *fetchStops = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStop" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:stopId,@"STOPID", nil]];
    NSArray* stops = [managedObjectContext executeFetchRequest:fetchStops error:&error];
    NSMutableDictionary *stopsMutableDictionary = [[NSMutableDictionary alloc] init];
    if([stops count] > 0){
        GtfsStop *stop = [stops objectAtIndex:0];
        [stopsMutableDictionary setObject:stop forKey:stop.stopID];
    }
    stopsDictionary = stopsMutableDictionary;
    return [stopsDictionary objectForKey:stopId];
}

// Fetch trips from tripsDictionary if available otherwise fetch all trips from database and set it to tripsDictionary and then get trips from tripsDictionary.

- (GtfsTrips *) fetchTripsFromTripId:(NSString *)tripId context:(NSManagedObjectContext *)context
{
    GtfsTrips *tripFromDictionary = [tripsDictionary objectForKey:tripId];
    if(tripFromDictionary)
        return tripFromDictionary;

    NSError *error = nil;
     NSFetchRequest *fetchTrips = [[[context persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsTrips" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:tripId,@"TRIPID", nil]];
    NSArray* trips = [context executeFetchRequest:fetchTrips error:&error];
    NSMutableDictionary *tripsMutableDictionary = [[NSMutableDictionary alloc] init];
    if([trips count] > 0){
        GtfsTrips *trip = [trips objectAtIndex:0];
        [tripsMutableDictionary setObject:trip forKey:trip.tripID];
    }
    tripsDictionary = tripsMutableDictionary;
    return [tripsDictionary objectForKey:tripId];
}

// This method get the serviceId based on tripId.
// Then get the calendar data for particular serviceID.
// the check for the request date comes after service start date and comes befor enddate.
// then check service is enabled on request day if yes then return yes otherwise return no.
- (BOOL) isServiceEnableForStopTimes:(GtfsStopTimes *)stopTimes RequestDate:(NSDate *)requestDate{
    @try {
        GtfsTrips *trips = [self fetchTripsFromTripId:stopTimes.tripID context:managedObjectContext];
        GtfsCalendar *calendar = trips.calendar;
        NSArray *arrServiceDays = [NSArray arrayWithObjects:calendar.sunday,calendar.monday,calendar.tuesday,calendar.wednesday,calendar.thursday,calendar.friday,calendar.saturday,nil];
        NSInteger dayOfWeek = dayOfWeekFromDate(requestDate)-1;
        NSDate* dateOnly = dateOnlyFromDate(requestDate);
        NSDateFormatter *dateFormatters = [[NSDateFormatter alloc] init];
        [dateFormatters setDateFormat:@"yyyyMMdd"];
        NSString *strStartDate = [dateFormatters stringFromDate:dateOnlyFromDate(calendar.startDate)];
        NSString *strEndDate =[dateFormatters stringFromDate:dateOnlyFromDate(calendar.endDate)] ;
        NSString* strDateOnly = [dateFormatters stringFromDate:dateOnly];
        
        if (strStartDate && strEndDate && [strDateOnly compare:strStartDate] == NSOrderedDescending && [strDateOnly compare:strEndDate] == NSOrderedAscending) {
            if([[arrServiceDays objectAtIndex:dayOfWeek] intValue] == 1){
                return YES;
            }
            return NO;
        }
        return NO;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->isServiceEnableForTripID", @"", exception);
    }
}

// first get stoptimes from StopTimes Table based on stopId
// Then make a pair of StopTimes if both stoptimes have same tripId then check for the stopSequence and the departure time is greater than request trip time and also check if service is enabled for that stopTimes if yes the add both stopTimes as To/From StopTimes pair.
// Returned array is in time order (by first pair departureTime)

- (NSMutableArray *)getStopTimes:(NSString *)strToStopID
                   strFromStopID:(NSString *)strFromStopID
                       startDate:(NSDate *)startDate
                    timeInterval:(NSTimeInterval)timeInterval
                          TripId:(NSString *)tripId
{
    @try {
        NSString *tripTime = timeStringFromDate(startDate);
        if(!tripTime || tripTime.length==0 || !strToStopID || strToStopID.length==0 || !strFromStopID ||
           strFromStopID.length==0 || !tripId || tripId.length == 0) {
            logError(@"GtfsParser-->getStopTimes null/empty strings",
                     [NSString stringWithFormat:@"tripTime: '%@', strToStopId '%@', strFromStopID '%@', tripId '%@'",
                      tripTime,strToStopID, strFromStopID, tripId]);
            return nil;
        }
        NSString *cutOffTime = timeStringByAddingInterval(tripTime, timeInterval);
        NSDictionary* fetchVars =[NSDictionary dictionaryWithObjectsAndKeys:
                                  strToStopID,@"STOPID1",
                                  strFromStopID,@"STOPID2",
                                  tripId,@"TRIPID",
                                  tripTime,@"TRIPTIME",
                                  cutOffTime,@"CUTOFFTIME",nil];
        NSFetchRequest *fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopTimesByStopID" substitutionVariables:fetchVars];
        NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
        NSMutableArray *arrMutableStopTimes = [[NSMutableArray alloc] init];
        NSMutableDictionary *dictStopTimes = [[NSMutableDictionary alloc] init];
        for(int i=0;i<[arrayStopTimes count];i++){
            GtfsStopTimes *stopTimes = [arrayStopTimes objectAtIndex:i];
            NSArray *arrStopTimesPair = [dictStopTimes objectForKey:stopTimes.tripID];
            if(arrStopTimesPair){
                NSMutableArray *arrStopTimes = [[NSMutableArray alloc] initWithArray:arrStopTimesPair];
                [arrStopTimes addObject:stopTimes];
                arrStopTimesPair = arrStopTimes;
                [dictStopTimes setObject:arrStopTimesPair forKey:stopTimes.tripID];
            }
            else{
                NSArray *arrStopTimes = [NSArray arrayWithObject:stopTimes];
                [dictStopTimes setObject:arrStopTimes forKey:stopTimes.tripID];
            }
        }
        
        NSArray *keys = [dictStopTimes allKeys];
        
        for(int j= 0;j<[keys count];j++){
            NSArray *arrStopTimes = [dictStopTimes objectForKey:[keys objectAtIndex:j]];
            if([arrStopTimes count] < 2 || [arrStopTimes count] > 2){
                // NIMLOG_US202(@"Exceptional StopTimes:%@",arrStopTimes);
                [dictStopTimes removeObjectForKey:[keys objectAtIndex:j]];
            }
            else{
                GtfsStopTimes *stopTimes1 = [arrStopTimes objectAtIndex:0];
                GtfsStopTimes *stopTimes2 = [arrStopTimes objectAtIndex:1];
                if(![stopTimes1.stopID isEqualToString: strFromStopID]){
                    stopTimes1 = [arrStopTimes objectAtIndex:1];
                    stopTimes2 = [arrStopTimes objectAtIndex:0];
                }

                if(stopTimes1 && stopTimes2){
                        if([stopTimes2.stopSequence intValue] > [stopTimes1.stopSequence intValue] && [self isServiceEnableForStopTimes:stopTimes1 RequestDate:startDate]){
                            NSArray *arrayTemp = [NSArray arrayWithObjects:stopTimes1,stopTimes2, nil];
                            [arrMutableStopTimes addObject:arrayTemp];
                        }
                    }
               }
            }
        
        // Sort the array by order of ascending first departureTime
        [arrMutableStopTimes sortUsingComparator:^(id obj1, id obj2) {
            NSString* obj1Time = [[obj1 objectAtIndex:0] departureTime];
            NSString* obj2Time = [[obj2 objectAtIndex:0] departureTime];
            return [obj1Time compare:obj2Time];
        }];

        return arrMutableStopTimes;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getStopTimes", @"", exception);
    }
}

// first check find stoptimes with the departure time greater than start time or end time.
// find stoptimes with minimum departure time from stoptimes array.
- (NSArray *)returnStopTimesWithNearestStartTimeOrEndTime:(NSDate *)time ArrStopTimes:(NSArray *)arrStopTimes{
    @try {
        NSDate *timeOnly = timeOnlyFromDate(time);
        NSMutableArray *arrStopTime = [[NSMutableArray alloc] init];
        for (int i=0;i< [arrStopTimes count];i++) {
            NSArray *stopTimePair = [arrStopTimes objectAtIndex:i];
                GtfsStopTimes *fromStopTime = [stopTimePair objectAtIndex:0];
            NSDate *fromDate = dateFromTimeString(fromStopTime.departureTime);
            NSDate *fromTime = timeOnlyFromDate(fromDate);
            if([fromTime compare:timeOnly] == NSOrderedDescending || [fromTime isEqualToDate:timeOnly]){
                    [arrStopTime addObject:stopTimePair];
            }
        }
        NSArray * arrSelectedStopTime;
        if([arrStopTime count] > 0){
           arrSelectedStopTime = [arrStopTime objectAtIndex:0]; 
        }
        for(int i=0;i<[arrStopTime count];i++){
            NSArray *stopTimePair = [arrStopTime objectAtIndex:i];
            GtfsStopTimes *selectedFromStopTime = [arrSelectedStopTime objectAtIndex:0];
            GtfsStopTimes *fromStopTime = [stopTimePair objectAtIndex:0];
            NSDate *fromDate = dateFromTimeString(fromStopTime.departureTime);
            NSDate *selectedFromDate = dateFromTimeString(selectedFromStopTime.departureTime);
            if([selectedFromDate compare:fromDate]== NSOrderedDescending){
                arrSelectedStopTime = [arrStopTime objectAtIndex:i];
            }
        }
        return arrSelectedStopTime;
        
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->returnStopTimesWithNearestStartTimeOrEndTime", @"", exception);
    }
}

- (NSDictionary *)returnMaximumRealTime:(NSArray *)predictions{
    NSDictionary * dictSelectedRealTime;
    if([predictions count] > 0){
        dictSelectedRealTime = [predictions objectAtIndex:0];
    }
    for(int i=0;i<[predictions count];i++){
        NSDictionary *dictRealTime = [predictions objectAtIndex:i];
        NSDate * realTime = [NSDate dateWithTimeIntervalSince1970:[[dictRealTime objectForKey:@"epochTime"] doubleValue]/1000];
        NSDate * selectedRealTime = [NSDate dateWithTimeIntervalSince1970:[[dictSelectedRealTime objectForKey:@"epochTime"] doubleValue]/1000];
        if([realTime compare:selectedRealTime] == NSOrderedDescending){
            dictSelectedRealTime = dictRealTime;
        }
    }
    return dictSelectedRealTime;
}

- (NSDictionary *)returnNearestRealtime:(NSDate *)time ArrRealTimes:(NSArray *)arrRealTimes{
    @try {
        if(!arrRealTimes || [arrRealTimes count] == 0)
            return nil;
        NSMutableArray *arrRealtime = [[NSMutableArray alloc] init];
        NSDate *timeOnly = time;
        for (int i=0;i< [arrRealTimes count];i++) {
            NSDictionary *dictRealTime = [arrRealTimes objectAtIndex:i];
            NSDate * realTime = [NSDate dateWithTimeIntervalSince1970:[[dictRealTime objectForKey:@"epochTime"] doubleValue]/1000];
            if([realTime compare:timeOnly] == NSOrderedDescending || [realTime isEqualToDate:timeOnly]){
                [arrRealtime addObject:dictRealTime];
            }
        }
        NSDictionary * dictSelectedRealTime;
        if([arrRealtime count] > 0){
            dictSelectedRealTime = [arrRealtime objectAtIndex:0];
        }
        for(int i=0;i<[arrRealtime count];i++){
            NSDictionary *dictRealTime = [arrRealtime objectAtIndex:i];
            NSDate * realTime = [NSDate dateWithTimeIntervalSince1970:[[dictRealTime objectForKey:@"epochTime"] doubleValue]/1000];
            NSDate * selectedRealTime = [NSDate dateWithTimeIntervalSince1970:[[dictSelectedRealTime objectForKey:@"epochTime"] doubleValue]/1000];
            if([selectedRealTime compare:realTime] == NSOrderedDescending){
                dictSelectedRealTime = dictRealTime;
            }
        }
        return dictSelectedRealTime;
        
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->returnNearestRealtime", @"", exception);
    }
}

// return nearest stoptimes form stoptimes array based on itinerary start time or itinerary end time.
- (NSArray *) findNearestStopTimeFromStopTimeArray:(NSArray *)arrStopTimes Itinerary:(Itinerary *)itinerary{
    if(itinerary.endTime){
       return  [self returnStopTimesWithNearestStartTimeOrEndTime:itinerary.endTime ArrStopTimes:arrStopTimes];
    }
       return  [self returnStopTimesWithNearestStartTimeOrEndTime:itinerary.startTime ArrStopTimes:arrStopTimes];
}

// This method create unscheduled newleg based on the pattern leg.
// Timing-wise, will add to the itinerary so that the newleg's endTime matches parameter endTime
// This is good for adding a unscheduled leg to the beginning of an itinerary, before the first scheduled leg
//- (Leg *) addUnScheduledLegToStartOfItinerary:(Itinerary *)itinerary
//                                      WalkLeg:(Leg *)leg
//                                      endTime:(NSDate *)endTime
//                                      Context:(NSManagedObjectContext *)context{
//    Leg* newleg;
//    @try {
//        newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
//        newleg.itinerary = itinerary;
//        itinerary.sortedLegs = nil;
//        newleg.endTime = endTime;
//        newleg.startTime = [newleg.endTime dateByAddingTimeInterval:(-[leg.duration floatValue]/1000)];
//        [newleg setNewlegAttributes:leg];
//    }
//    @catch (NSException *exception) {
//        logException(@"GtfsParser->addUnScheduledLegToItinerary", @"", exception);
//    }
//    return newleg;
//}

// This method creates unscheduled newleg based on the pattern leg.  Timing-wise, will add to the end of the itinerary.
// Returns newleg
- (Leg *) addUnScheduledLegToItinerary:(Itinerary *)itinerary WalkLeg:(Leg *)leg Context:(NSManagedObjectContext *)context Index:(int)index{
    Leg* newleg;
    @try {
        newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
        newleg.itinerary = itinerary;
        itinerary.sortedLegs = nil;
        if(index == 0){
           newleg.startTime = itinerary.startTime;
           newleg.endTime = itinerary.startTime;
        }
        else{
           newleg.startTime = itinerary.endTime;
           newleg.endTime = [newleg.startTime dateByAddingTimeInterval:([leg.duration floatValue]/1000)];
        }
        [newleg setNewlegAttributes:leg];
        itinerary.endTime = newleg.endTime;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->addUnScheduledLegToItinerary", @"", exception);
    }
    return newleg;
}

// This method create scheduled newleg from gtfs data based on pattern from leg
// First find the nearest stoptimes then create transit leg from stoptimes data.
// Then removes the selected arrayStopTime from the arrStopTimes
// Returns newleg
- (Leg *) addScheduledLegToItinerary:(Itinerary *)itinerary
                         TransitLeg:(Leg *)leg
                           StopTime:(NSMutableArray *)arrStopTimes
                           TripDate:(NSDate *)tripDate
                            Context:(NSManagedObjectContext *)context {
    @try {
        NSArray *arrayStopTime = [self findNearestStopTimeFromStopTimeArray:arrStopTimes Itinerary:itinerary];
        if(!arrayStopTime)
            return nil;
        GtfsStopTimes *fromStopTime = [arrayStopTime objectAtIndex:0];
        GtfsStopTimes *toStopTime = [arrayStopTime objectAtIndex:1];
        Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
        newleg.itinerary = itinerary;
        if(fromStopTime.departureTime){
            newleg.startTime = addDateOnlyWithTime(dateOnlyFromDate(tripDate),
                                                   dateFromTimeString(fromStopTime.departureTime));
            newleg.endTime = addDateOnlyWithTime(dateOnlyFromDate(tripDate),
                                                 dateFromTimeString(toStopTime.departureTime));
        }
        [newleg setNewlegAttributes:leg];
        newleg.tripId = fromStopTime.tripID;
        GtfsTrips *trips = [self fetchTripsFromTripId:fromStopTime.tripID context:managedObjectContext];
        newleg.headSign = trips.tripHeadSign;
        newleg.duration = [NSNumber numberWithDouble:[newleg.startTime timeIntervalSinceDate:newleg.endTime] * 1000];
        itinerary.endTime = newleg.endTime;
        [arrStopTimes removeObject:arrayStopTime];
        return newleg;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->addScheduledLegToItinerary", @"", exception);
    }
}

// Generates Gtfs itineraries in plan based on the pattern of itinerary
// tripDate is the original tripDate.  fromTimeOnly and toTimeOnly is the range of start-times that should be generated
// Generated itineraries will be associated with Plan and will be optimal for that pattern
// Returns request chunk with new itineraries, or nil if no new itineraries created
- (PlanRequestChunk *)generateItineraryFromItineraryPattern:(Itinerary *)itinerary
                                      tripDate:(NSDate *)tripDate
                                  fromTimeOnly:(NSDate *)fromTimeOnly
                                    toTimeOnly:(NSDate *)toTimeOnly
                                          Plan:(Plan *)plan
                                       Context:(NSManagedObjectContext *)context{
    NIMLOG_US202(@"Generating Gtfs itineraries from: %@ to: %@", fromTimeOnly, toTimeOnly);
    int legCount = [[itinerary sortedLegs] count];
    PlanRequestChunk* reqChunk = nil;
    
    if ([itinerary haveOnlyUnScheduledLeg]) {
        return nil;  // no new itineraries to generate
    }
    // Get array of arrStopTimes, indexed by leg #.  Unscheduled legs have leg inserted
    NSMutableArray* arrStopTimesArray = [[NSMutableArray alloc] initWithCapacity:legCount];
    for (int j=0; j<legCount; j++) {
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:j];
        if (![leg isScheduled]) {
            [arrStopTimesArray addObject:leg];
        } else {
            NSTimeInterval timeInterval = [toTimeOnly timeIntervalSinceDate:fromTimeOnly] + // time from fromTimeOnly to toTimeOnly
            ([[leg endTime] timeIntervalSinceDate:[itinerary startTime]]*2.0);    // + plenty enough extra time to reach this leg from startTime
            NSArray* arrStopTimes = [self getStopTimes:leg.to.stopId
                                         strFromStopID:leg.from.stopId
                                             startDate:addDateOnlyWithTime(tripDate, fromTimeOnly)
                                          timeInterval:timeInterval
                                                TripId:@"XYZ-Do-Not-Exclude-Any-TripIDs"];
            [arrStopTimesArray addObject:arrStopTimes];
        }
    }
    NIMLOG_PERF2(@"Finished fetching arrStopTimesArray");
    
    // Now build out an array of GtfsTempItinerary objects
    NSMutableArray* tempItinArray = [[NSMutableArray alloc] initWithCapacity:20]; // Array of GtfsTempItinerary
    GtfsTempItinerary* tempItinerary = [[GtfsTempItinerary alloc] initWithMinTransferTime:MIN_TRANSFER_TIME];
    [tempItinerary buildItinerariesFromArrStopTimesArray:arrStopTimesArray
                                                 putInto:tempItinArray
                                      startingatLegIndex:0]; // recursively builds out all the itineraries
    
    NIMLOG_PERF2(@"Finished building tempItineraries");
    // Build out itineraries from the tempItineraries
    for (GtfsTempItinerary* tempItinerary in tempItinArray) {
        Itinerary* newItinerary = [tempItinerary makeItineraryObjectInPlan:plan
                                                          patternItinerary:itinerary
                                                      managedObjectContext:context
                                                                  tripDate:tripDate];
        
        if ([newItinerary.startTimeOnly compare:fromTimeOnly] != NSOrderedAscending &&
            [newItinerary.startTimeOnly compare:toTimeOnly] != NSOrderedDescending) {
            // if newItinerary is within the requested time range...
            
            // Add these itineraries to the request chunk
            if (!reqChunk) {
                reqChunk = [NSEntityDescription insertNewObjectForEntityForName:@"PlanRequestChunk"
                                                         inManagedObjectContext:context];
                reqChunk.plan = plan;
                reqChunk.type =[NSNumber numberWithInt:GTFS_ITINERARY];
                reqChunk.gtfsItineraryPattern = itinerary;
                reqChunk.earliestRequestedDepartTimeDate = addDateOnlyWithTime(tripDate, fromTimeOnly); // assumes Depart
                reqChunk.latestEndOfRequestRangeTimeDate = addDateOnlyWithTime(tripDate, toTimeOnly);
            }
            if (newItinerary) {
                [reqChunk addItinerariesObject:newItinerary];
            }
        } else {  // if newItinerary is not within the desired time range, delete it
            [context deleteObject:newItinerary];
        }
    }
    saveContext(context);
    NIMLOG_US202(@"Finished generating Gtfs itineraries");
    return reqChunk;
}

// generate new leg from prediction data.
- (Leg *) generateLegFromPrediction:(NSDictionary *)prediction newItinerary:(Itinerary *)newItinerary Leg:(Leg *)leg Context:(NSManagedObjectContext *)context ISExtraPrediction:(BOOL)isExtraPrediction{
    NSDate *predtctionTime = [NSDate dateWithTimeIntervalSince1970:([[prediction objectForKey:@"epochTime"] doubleValue]/1000.0)];
    NSDate *scheduleTime = timeOnlyFromDate(dateFromTimeString([prediction objectForKey:@"scheduleTime"]));
    Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
    newleg.itinerary = newItinerary;
    newleg.startTime = predtctionTime;
    newleg.endTime = [newleg.startTime dateByAddingTimeInterval:([leg.duration floatValue]/1000)];
    [newleg setNewlegAttributes:leg];
    if(isExtraPrediction)
        newItinerary.startTime = newleg.startTime;
    newItinerary.endTime = newleg.endTime;
    newleg.isRealTimeLeg = true;
    newItinerary.isRealTimeItinerary = true;
    NSDate *predictionOnly = timeOnlyFromDate(predtctionTime);
    int timeDiff = [predictionOnly timeIntervalSinceDate:scheduleTime]/60;
    if([prediction objectForKey:@"tripId"]){
        newleg.realTripId = [prediction objectForKey:@"tripId"];
    }
    else{
        newleg.realTripId = [prediction objectForKey:@"scheduleTripId"];
    }
    newleg.timeDiff = timeDiff;
    int arrivalFlag;
    if(timeDiff >= -2 && timeDiff <= 2)
        arrivalFlag = ON_TIME;
    else if(timeDiff < -2)
        arrivalFlag = EARLY;
    else
        arrivalFlag = DELAYED;
    
    newleg.arrivalFlag = [NSString stringWithFormat:@"%d",arrivalFlag];
    NSDateFormatter *dateFormatters = [[NSDateFormatter alloc] init];
    [dateFormatters setDateFormat:@"yyyyMMdd"];
    NSString *strStartDate = [dateFormatters stringFromDate:dateOnlyFromDate([NSDate date])];
    newleg.arrivalTime = strStartDate;
    return newleg;
}

- (void) adjustItineraryAndLegsTimes:(Itinerary *)itinerary Context:(NSManagedObjectContext *)context{
    itinerary.sortedLegs = nil;
        if([[itinerary sortedLegs] count] > 0){
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:0];
            if(![leg isScheduled]){
                Leg *nextLeg = [leg getLegAtOffsetFromListOfLegs:[itinerary sortedLegs] offset:1];
                Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
                newleg.itinerary = itinerary;
                newleg.endTime = nextLeg.startTime;
                [newleg setNewlegAttributes:leg];
                newleg.startTime = [newleg.endTime dateByAddingTimeInterval:(-[newleg.duration intValue])/1000];
                itinerary.startTime = newleg.startTime;
                [itinerary removeLegsObject:leg];
            }
            
            Leg *lastLeg = [[itinerary sortedLegs] lastObject];
            if(![lastLeg isScheduled]){
                Leg *previousLeg = [lastLeg getLegAtOffsetFromListOfLegs:[itinerary sortedLegs] offset:-1];
                Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
                newleg.itinerary = itinerary;
                newleg.startTime = previousLeg.endTime;
                newleg.endTime = [newleg.startTime dateByAddingTimeInterval:([lastLeg.duration intValue])/1000];
                [newleg setNewlegAttributes:lastLeg];
                itinerary.endTime = newleg.endTime;
                [itinerary removeLegsObject:lastLeg];
            }
        }
    itinerary.sortedLegs = nil;
}

// Generate new leg with all parameters from old leg
- (void) generateNewLegFromOldLeg:(Leg *)leg Context:(NSManagedObjectContext *)context Itinerary:(Itinerary *)itinerary{
    Leg* newleg = [NSEntityDescription insertNewObjectForEntityForName:@"Leg" inManagedObjectContext:context];
    newleg.itinerary = itinerary;
    newleg.startTime = leg.startTime;
    newleg.endTime = leg.endTime;
    [newleg setNewlegAttributes:leg];
    newleg.tripId = leg.tripId;
    newleg.headSign = leg.headSign;
    itinerary.endTime = newleg.endTime;
}

- (Leg *)returnNearestLeg:(NSArray *)arrLegs{
    @try {
        Leg * selectedLeg;
        if([arrLegs count] > 0){
            selectedLeg = [arrLegs objectAtIndex:0];
        }
        for(int i=0;i<[arrLegs count];i++){
            Leg *leg = [arrLegs objectAtIndex:i];
            NSDate *selectedStartTime = selectedLeg.startTime;
            NSDate *startTime = leg.startTime;
            if([selectedStartTime compare:startTime] == NSOrderedDescending){
                selectedLeg = leg;
            }
        }
        return selectedLeg;
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->returnNearestLeg", @"", exception);
    }
}

- (void) hideItineraryIfNeeded:(NSArray *)itineraries Leg:(Leg *)leg Index:(int)index Predictions:(NSArray *)predictions{
    for(int i=0;i<[itineraries count];i++){
        Itinerary *itinerary = [itineraries objectAtIndex:i];
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:index];
        NSDate *startTimeOnly = timeOnlyFromDate(leg.startTime);
        NSDictionary *prediction = [self returnMaximumRealTime:predictions];
        NSDate *realTimeBoundry = timeOnlyFromDate([NSDate dateWithTimeIntervalSince1970:([[prediction objectForKey:@"epochTime"] doubleValue]/1000.0)]);
        if([startTimeOnly compare:realTimeBoundry] == NSOrderedAscending || [startTimeOnly isEqualToDate:realTimeBoundry]){
            if(![itinerary isRealTimeItinerary])
                itinerary.hideItinerary = true;
        }
    }
}

- (void) setArrivalFlagFromRealTimeAndGtfsStopTimes:(Leg *)leg Prediction:(NSDictionary *)prediction Context:(NSManagedObjectContext *)context{
        NSFetchRequest *fetchParseStatus = [[[context persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"StopTimesByTripIdAndStopId" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:leg.realTripId,@"TRIPID",leg.from.stopId,@"STOPID", nil]];
        NSError *error;
        NSArray *result = [context executeFetchRequest:fetchParseStatus error:&error];
    int timeDiff;
    if([result count] == 0){
        timeDiff = ON_TIME;
    }
    else{
        GtfsStopTimes *stopTimes = [result objectAtIndex:0];
        NSDate *departureDate = dateFromTimeString(stopTimes.departureTime);
        
        NSDate *realTimeDate = [NSDate dateWithTimeIntervalSince1970:([[prediction objectForKey:@"epochTime"] doubleValue]/1000.0)];
        double millisecondsSchedule = ([timeOnlyFromDate(departureDate) timeIntervalSince1970])*1000.0;
        double millisecondsRealTime = ([timeOnlyFromDate(realTimeDate) timeIntervalSince1970])*1000.0;
        double timeDiffInMilliSeconds = millisecondsRealTime - millisecondsSchedule;
        timeDiff = timeDiffInMilliSeconds/(60*1000);
    }
    leg.timeDiff = timeDiff;
    int arrivalFlag;
    if(timeDiff >= -2 && timeDiff <= 2)
        arrivalFlag = ON_TIME;
    else if(timeDiff < -2)
        arrivalFlag = EARLY;
    else
        arrivalFlag = DELAYED;
    leg.arrivalFlag = [NSString stringWithFormat:@"%d",arrivalFlag];
    NSDateFormatter *dateFormatters = [[NSDateFormatter alloc] init];
    [dateFormatters setDateFormat:@"yyyyMMdd"];
    NSString *strStartDate = [dateFormatters stringFromDate:dateOnlyFromDate(leg.startTime)];
    leg.arrivalTime = strStartDate;
    
}

- (void) setArrivalTimeFlagForLegsAndItinerary:(Leg *)leg Prediction:(NSDictionary *)prediction Context:(NSManagedObjectContext *)context{
    NSDate *realTimeDate = [NSDate dateWithTimeIntervalSince1970:([[prediction objectForKey:@"epochTime"] doubleValue]/1000.0)];
    NSDate *lowerLimit = timeOnlyFromDate([realTimeDate dateByAddingTimeInterval:REALTIME_LOWER_LIMIT]);
    NSDate *upperLimit = timeOnlyFromDate([realTimeDate dateByAddingTimeInterval:REALTIME_UPPER_LIMIT]);
    
    double lowerInterval = timeIntervalFromDate(lowerLimit);
    double upperInterval = timeIntervalFromDate(upperLimit);
    
    NSFetchRequest *fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"StopTimesByFromStopIdAndDepartureTime" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:leg.from.stopId,@"FROMSTOPID",leg.to.stopId,@"TOSTOPID",[NSNumber numberWithDouble:lowerInterval],@"LOWERLIMIT",[NSNumber numberWithDouble:upperInterval],@"UPPERLIMIT", nil]];
    NSArray *arrayStopTimes = [managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
    arrayStopTimes = [self getStopTimesBasedOnStopIdAndnearestTime:arrayStopTimes FromStopId:leg.from.stopId];
    
    if([arrayStopTimes count] == 0)
        return;
    NSArray *stopTime = [arrayStopTimes objectAtIndex:0];
    if([stopTime count] == 0)
        return;
    GtfsStopTimes *stopTimes = [stopTime objectAtIndex:0];
    NSDate *departureDate = dateFromTimeString(stopTimes.departureTime);
    
    double millisecondsSchedule = ([timeOnlyFromDate(departureDate) timeIntervalSince1970])*1000.0;
    double millisecondsRealTime = ([timeOnlyFromDate(realTimeDate) timeIntervalSince1970])*1000.0;
    double timeDiffInMilliSeconds = millisecondsRealTime - millisecondsSchedule;
    int timeDiff = timeDiffInMilliSeconds/(60*1000);
    
    leg.timeDiff = timeDiff;
    int arrivalFlag;
    if(timeDiff >= -2 && timeDiff <= 2)
        arrivalFlag = ON_TIME;
    else if(timeDiff < -2)
        arrivalFlag = EARLY;
    else
        arrivalFlag = DELAYED;
    leg.arrivalFlag = [NSString stringWithFormat:@"%d",arrivalFlag];
    NSDateFormatter *dateFormatters = [[NSDateFormatter alloc] init];
    [dateFormatters setDateFormat:@"yyyyMMdd"];
    NSString *strStartDate = [dateFormatters stringFromDate:dateOnlyFromDate(leg.startTime)];
    leg.arrivalTime = strStartDate;
    
}

- (NSArray *) returnItinerariesFromPattern:(Itinerary *)pattern Plan:(Plan *)plan{
    NSMutableArray *itineraries = [[NSMutableArray alloc] init];
    for(int i=0;i<[[plan sortedItineraries] count];i++){
        Itinerary *tempItinerary = [[plan sortedItineraries] objectAtIndex:i];
        if([pattern isEquivalentModesAndStopsAndRouteAs:tempItinerary])
            [itineraries addObject:tempItinerary];
    }
    return  itineraries;
}

// Generate reattime itineraries from pattern and realtime data.
- (void) generateItinerariesFromRealTime:(Plan *)plan TripDate:(NSDate *)tripDate Context:(NSManagedObjectContext *)context{
    if(!context) {
        context = managedObjectContext;
    }

    NIMLOG_PERF2(@"Start generateItinerariesFromRealTime");
    NSMutableDictionary *dictPredictions = [[NSMutableDictionary alloc] init];
    for(int i=0;i<[[plan uniqueItineraries] count];i++){
        Itinerary *itinerary = [[plan uniqueItineraries] objectAtIndex:i];
        for(int j=0;j<[[itinerary sortedLegs] count];j++){
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:j];
            if(leg.predictions){
                NSMutableArray *arrPrediction = [[NSMutableArray alloc] initWithArray:leg.predictions];
                [dictPredictions setObject:arrPrediction forKey:leg.legId];
            }
        }
    }
    for(int i=0;i<[[plan uniqueItineraries] count];i++){
        Itinerary *itinerary = [[plan uniqueItineraries] objectAtIndex:i];
        [self generateItinerariesFromPrediction:plan Itinerary:itinerary Prediction:dictPredictions TripDate:tripDate Context:context];
    }
    NIMLOG_PERF2(@"Finish generateItinerariesFromRealTime");
}

-(BOOL) isFirstScheduledLeg:(Leg *)leg Itinerary:(Itinerary *)itinerary{
    Leg *tempLeg;
    for(int i=0;i<[[itinerary sortedLegs] count];i++){
        tempLeg = [[itinerary sortedLegs] objectAtIndex:i];
        if([tempLeg isScheduled]){
            break;
        }
    }
    if(tempLeg == leg)
        return true;
    return false;
}

// Add leg from itineraries to newitinerary if leg start time is greater  or equal to new itinerary endtime.
- (BOOL) addRestOfLegFromItineraries:(NSArray *)itineraries Leg:(Leg *)pattenLeg IndexOfLeg:(int)indexOfLeg NewItinerary:(Itinerary *)newItinerary Context:(NSManagedObjectContext *)context{
    for(int i=0;i<[itineraries count];i++){
        Itinerary *tempItinerary = [itineraries objectAtIndex:i];
        Leg *leg = [[tempItinerary sortedLegs] objectAtIndex:indexOfLeg];
        NSDate *legStartTime = addDateOnlyWithTimeOnly(dateOnlyFromDate([NSDate date]),timeOnlyFromDate(leg.startTime));
        NSDate *itiEndTime = addDateOnlyWithTimeOnly(dateOnlyFromDate([NSDate date]),timeOnlyFromDate(newItinerary.endTime));
        if([legStartTime compare:itiEndTime] == NSOrderedDescending || [legStartTime isEqualToDate:itiEndTime]){
            [self generateNewLegFromOldLeg:[[tempItinerary sortedLegs] objectAtIndex:indexOfLeg] Context:context Itinerary:newItinerary];
            return YES;
        }
    }
    return NO;
}

- (NSString *) generateTripIdHexString:(Itinerary *)itinerary{
    NSMutableString *strTripIdhexString = [[NSMutableString alloc] init];
    for(int i=0;i<[[itinerary sortedLegs] count];i++){
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:i];
        if([leg isScheduled]){
            if([leg isRealTimeLeg] && leg.realTripId)
                [strTripIdhexString appendString:[NSString stringWithFormat:@"%@-",leg.realTripId]];
            else
                [strTripIdhexString appendString:[NSString stringWithFormat:@"%@-",leg.tripId]];
        }
        else{
            [strTripIdhexString appendString:[NSString stringWithFormat:@"%@-",leg.legGeometryPoints]];
        }
    }
    return strTripIdhexString;
}
- (void)removeRealtimeBeforeTripDate:(NSDate *)time RealTimes:(NSMutableDictionary *)realtimes Leg:(Leg *)leg{
    NSMutableArray *arrRealTimes = [[NSMutableArray alloc]initWithArray:[realtimes objectForKey:leg.legId]];
        if(!arrRealTimes || [arrRealTimes count] == 0)
            return;
        NSDate *timeOnly = time;
        for (int i=0;i< [arrRealTimes count];i++) {
            NSDictionary *dictRealTime = [arrRealTimes objectAtIndex:i];
            NSDate * realTime = [NSDate dateWithTimeIntervalSince1970:[[dictRealTime objectForKey:@"epochTime"] doubleValue]/1000];
            if([realTime compare:timeOnly] == NSOrderedAscending){
                [arrRealTimes removeObjectAtIndex:i];
            }
        }
    [realtimes setObject:arrRealTimes forKey:leg.legId];
}
// Generate reattime itineraries from pattern and realtime data.
- (void) generateItinerariesFromPrediction:(Plan *)plan Itinerary:(Itinerary *)itinerary Prediction:(NSMutableDictionary *)dictPredictions TripDate:(NSDate *)tripDate Context:(NSManagedObjectContext *)context{
    PlanRequestChunk* reqChunk;
    for (int i=0; i<200; i++) {
        if(i==199){
            logError(@"GtfsParser-->generateItinerariesFromPrediction", @"Reached 199 iterations in generating itinerary");
            break;
        }
        Leg *selectedLeg;
        for(int k=0;k<[[itinerary sortedLegs] count];k++){
            selectedLeg = [[itinerary sortedLegs] objectAtIndex:k];
            if([selectedLeg isScheduled]){
                break;
            }
        }
        NSArray *predictions = [dictPredictions objectForKey:selectedLeg.legId];
        if(!predictions || [predictions count] == 0){
            break;
        }
        Itinerary* newItinerary = [NSEntityDescription insertNewObjectForEntityForName:@"Itinerary" inManagedObjectContext:context];
        newItinerary.plan = plan;
        newItinerary.startTime = tripDate;
        newItinerary.endTime = tripDate;
        
        for(int j=0;j<[[itinerary sortedLegs] count];j++){
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:j];
            if([leg isScheduled]){
                if([self isFirstScheduledLeg:leg Itinerary:itinerary]){
                   [self removeRealtimeBeforeTripDate:newItinerary.endTime RealTimes:dictPredictions Leg:leg]; 
                }
                NSMutableArray *arrPrediction = [dictPredictions objectForKey:leg.legId];
                    NSDictionary *dictPrediction = [self returnNearestRealtime:newItinerary.endTime ArrRealTimes:arrPrediction];
                    if(dictPrediction){
                       Leg *newleg = [self generateLegFromPrediction:dictPrediction newItinerary:newItinerary Leg:leg Context:context ISExtraPrediction:false];
                        if([self isFirstScheduledLeg:leg Itinerary:itinerary]){
                            newItinerary.startTime = newleg.startTime;
                            [arrPrediction removeObject:dictPrediction];
                            [dictPredictions setObject:arrPrediction forKey:leg.legId];
                        }
                    }
                    else{
//                        NSArray *itineraries = [self returnItinerariesFromPattern:itinerary Plan:plan];
//                        if(![self addRestOfLegFromItineraries:itineraries Leg:leg IndexOfLeg:j NewItinerary:newItinerary Context:context]){
                            NSString *strTOStopID = leg.to.stopId;
                            NSString *strFromStopID = leg.from.stopId;
                            NSMutableArray *arrStopTime = [self getStopTimes:strTOStopID
                                                               strFromStopID:strFromStopID
                                                                   startDate:newItinerary.endTime
                                                                timeInterval:GTFS_MAX_TIME_TO_PULL_SCHEDULES
                                                                      TripId:@"Include any tripId"];
                            if(!arrStopTime || [arrStopTime count] == 0){
                               [plan deleteItinerary:newItinerary];
                                break;
                            }
                            [self addScheduledLegToItinerary:newItinerary
                                                  TransitLeg:leg
                                                    StopTime:arrStopTime
                                                    TripDate:newItinerary.endTime
                                                     Context:context];
                        }
                    //}
            }
            else{
                [self addUnScheduledLegToItinerary:newItinerary WalkLeg:leg Context:context Index:j];
            }
        }
        if (![newItinerary isDeleted]) {
            [self adjustItineraryAndLegsTimes:newItinerary Context:context];
            [newItinerary setArrivalFlagFromLegsRealTime];
            [newItinerary initializeTimeOnlyVariablesWithRequestDate:tripDate];
            newItinerary.tripIdhexString = [self generateTripIdHexString:newItinerary];
            // Add these itineraries to the request chunk
            if (!reqChunk) {
                reqChunk = [NSEntityDescription insertNewObjectForEntityForName:@"PlanRequestChunk"
                                                         inManagedObjectContext:context];
                reqChunk.plan = plan;
                reqChunk.gtfsItineraryPattern = itinerary;
                reqChunk.type =[NSNumber numberWithInt:REALTIME_ITINERARY];
                reqChunk.earliestRequestedDepartTimeDate = tripDate; // assumes Depart
            }
            [reqChunk addItinerariesObject:newItinerary];
        }
    }
}

//
// GtfsParsingStatusMethods
// 
-(BOOL)hasGtfsDownloadRequestBeenSubmittedForAgencyName:(NSString *)agencyName
                                            routeId:(NSString *)routeId
{
    GtfsParsingStatus* status = [self getParsingStatusObjectForAgencyName:agencyName
                                                              routeId:routeId
                                                              context:managedObjectContext];
    return [status hasGtfsDownloadRequestBeenSubmitted];
}

-(BOOL)isGtfsDataAvailableForAgencyName:(NSString *)agencyName
                            routeId:(NSString *)routeId
{
    GtfsParsingStatus* status = [self getParsingStatusObjectForAgencyName:agencyName
                                                              routeId:routeId
                                                              context:managedObjectContext];
    return [status isGtfsDataAvailable];
}

-(void)setGtfsRequestSubmittedForAgencyName:(NSString *)agencyName
                                    routeId:(NSString *)routeId
                                       plan:(Plan *)plan
{
    GtfsParsingStatus* status = [self getParsingStatusObjectForAgencyName:agencyName routeId:routeId context:managedObjectContext];
    if (!status) {
        status = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsParsingStatus" inManagedObjectContext:managedObjectContext];
        [status setAgencyFeedIdAndRoute:[NSString stringWithFormat:@"%@_%@,",agencyFeedIdFromAgencyName(agencyName),routeId]];
    }
    [status setGtfsRequestMadeFor:plan];
}

// For all the plans in requestingPlans, will call the plan's "prepareSortedItineraries" method
// once all the needed data is available
-(void)setGtfsDataAvailableForAgencyName:(NSString *)agencyName
                             routeId:(NSString *)routeId
                             context:(NSManagedObjectContext *) context;
{
    GtfsParsingStatus* status = [self getParsingStatusObjectForAgencyName:agencyName routeId:routeId context:context];
    if (!status) {
        status = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsParsingStatus" inManagedObjectContext:context];
        [status setAgencyFeedIdAndRoute:[NSString stringWithFormat:@"%@_%@,",agencyFeedIdFromAgencyName(agencyName),routeId]];
    }
    [status setGtfsDataAvailable];
}

-(GtfsParsingStatus *)getParsingStatusObjectForAgencyName:(NSString *)agencyName
                                              routeId:(NSString *)routeId
                                              context:(NSManagedObjectContext *)context;
{
    NSString* feedIdAndRouteStr = [NSString stringWithFormat:@"%@_%@,",agencyFeedIdFromAgencyName(agencyName),routeId];
    NSFetchRequest *fetchParseStatus = [[[context persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsParsingStatusByFeedIdAndRoute" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:feedIdAndRouteStr,@"FEEDANDROUTE", nil]];
    NSError *error;
    NSArray* result = [context executeFetchRequest:fetchParseStatus error:&error];
    if (!result) {
        logError(@"GtfsParser -> getParsingStatusObjectFor", [NSString stringWithFormat:@"Error fetching from Core Data: %@", error]);
        return nil;
    }
    if (result.count == 0) {
        return nil;  // No matches found result
    }
    if (result.count > 1) {
        logError(@"GtfsParser -> getParsingStatusObjectFor", [NSString stringWithFormat:@"Unexpectedly have %d matching ParsingStatusObjects", result.count]);
    }
    return [result objectAtIndex:0];  // Return first object
}

- (NSArray *) getStopTimesBasedOnStopIdAndnearestTime:(NSArray *)stopTime FromStopId:(NSString *)fromStopId{
    NSMutableArray *arrMutableStopTimes = [[NSMutableArray alloc] init];
    NSMutableDictionary *dictStopTimes = [[NSMutableDictionary alloc] init];
    for(int i=0;i<[stopTime count];i++){
        GtfsStopTimes *stopTimes = [stopTime objectAtIndex:i];
        NSArray *arrStopTimesPair = [dictStopTimes objectForKey:stopTimes.tripID];
        if(arrStopTimesPair){
            NSMutableArray *arrStopTimes = [[NSMutableArray alloc] initWithArray:arrStopTimesPair];
            [arrStopTimes addObject:stopTimes];
            arrStopTimesPair = arrStopTimes;
            [dictStopTimes setObject:arrStopTimesPair forKey:stopTimes.tripID];
        }
        else{
            NSArray *arrStopTimes = [NSArray arrayWithObject:stopTimes];
            [dictStopTimes setObject:arrStopTimes forKey:stopTimes.tripID];
        }
    }
    
    NSArray *keys = [dictStopTimes allKeys];
    
    for(int j= 0;j<[keys count];j++){
        NSArray *arrStopTimes = [dictStopTimes objectForKey:[keys objectAtIndex:j]];
        if([arrStopTimes count] < 2 || [arrStopTimes count] > 2){
            // NIMLOG_US202(@"Exceptional StopTimes:%@",arrStopTimes);
            [dictStopTimes removeObjectForKey:[keys objectAtIndex:j]];
        }
        else{
            GtfsStopTimes *stopTimes1 = [arrStopTimes objectAtIndex:0];
            GtfsStopTimes *stopTimes2 = [arrStopTimes objectAtIndex:1];
            if(![stopTimes1.stopID isEqualToString:fromStopId]){
                stopTimes1 = [arrStopTimes objectAtIndex:1];
                stopTimes2 = [arrStopTimes objectAtIndex:0];
            }
            
            if(stopTimes1 && stopTimes2){
                if([stopTimes2.stopSequence intValue] > [stopTimes1.stopSequence intValue]){
                    NSArray *arrayTemp = [NSArray arrayWithObjects:stopTimes1,stopTimes2, nil];
                    [arrMutableStopTimes addObject:arrayTemp];
                }
            }
        }
    }
    
    // Sort the array by order of ascending first departureTime
    [arrMutableStopTimes sortUsingComparator:^(id obj1, id obj2) {
        NSString* obj1Time = [[obj1 objectAtIndex:0] departureTime];
        NSString* obj2Time = [[obj2 objectAtIndex:0] departureTime];
        return [obj1Time compare:obj2Time];
    }];
    
    return arrMutableStopTimes;
}

//- (NSArray *) returnIntermediateStopForLeg:(Leg *)leg Itinerary:(Itinerary *)itinerary{
//    NSMutableArray *intermediateStops = [[NSMutableArray alloc] init];
//    NIMLOG_PERF2(@"Begin returnIntermediateStopForLeg: %@", leg.tripId);
//        NSString *tripId  = nil;
//        NSFetchRequest *fetchStopTimes;
//        NSArray * arrayStopTimes;
//        NIMLOG_PERF2(@"legStartTime=%@",leg.startTime);
//        NSDate *lowerLimit = [leg.startTime dateByAddingTimeInterval:REALTIME_LOWER_LIMIT];
//        NSDate *upperLimit = [leg.startTime dateByAddingTimeInterval:REALTIME_UPPER_LIMIT];
//    
//        double lowerInterval = timeIntervalFromDate(lowerLimit);
//        double upperInterval = timeIntervalFromDate(upperLimit);
//        if(upperInterval < lowerInterval)
//            upperInterval = upperInterval + lowerInterval;
//        
//        if(!leg.isRealTimeLeg){
//            tripId = leg.tripId;
//            fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopTimesByAgencyID" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:tripId,@"TRIPID",agencyFeedIdFromAgencyName(leg.agencyName),@"AGENCYID", nil]];
//            arrayStopTimes = [managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
//            NIMLOG_PERF2(@"Completed fetch of intermediate stop times");
//            NSSortDescriptor *sortD = [[NSSortDescriptor alloc]
//                                       
//                                       initWithKey:@"stopSequence" ascending:YES selector:@selector(localizedStandardCompare:)];
//            arrayStopTimes = [arrayStopTimes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]];
//        }
//        else{
//            if(leg.realTripId){
//                tripId = leg.realTripId;
//                fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopTimesByAgencyID" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:tripId,@"TRIPID",agencyFeedIdFromAgencyName(leg.agencyName),@"AGENCYID", nil]];
//                arrayStopTimes = [managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
//                NIMLOG_PERF2(@"Completed fetch of intermediate stop times");
//                NSSortDescriptor *sortD = [[NSSortDescriptor alloc]
//                                           
//                                           initWithKey:@"stopSequence" ascending:YES selector:@selector(localizedStandardCompare:)];
//                arrayStopTimes = [arrayStopTimes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]];
//                if([arrayStopTimes count] == 0){
//                    [self requestStopTimesDataForParticularTripFromServer:[NSString stringWithFormat:@"%@_%@",agencyFeedIdFromAgencyName(leg.agencyName),leg.realTripId] Leg:leg itinerary:itinerary];
//                }
//            }
//            else{
//                if (!leg.from.stopId || !leg.to.stopId) {
//                    return nil;
//                }
//                fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"StopTimesByFromStopIdAndDepartureTime" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:leg.from.stopId,@"FROMSTOPID",leg.to.stopId,@"TOSTOPID",[NSNumber numberWithDouble:lowerInterval],@"LOWERLIMIT",[NSNumber numberWithDouble:upperInterval],@"UPPERLIMIT", nil]];
//                arrayStopTimes = [managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
//                NIMLOG_PERF2(@"Completed fetch of intermediate stop times");
//                arrayStopTimes = [self getStopTimesBasedOnStopIdAndnearestTime:arrayStopTimes FromStopId:leg.from.stopId];
//                GtfsStopTimes *stoptimes;
//                if([arrayStopTimes count] > 0){
//                    NSArray *stoptime = [arrayStopTimes objectAtIndex:0];
//                    if([stoptime count] > 0)
//                        stoptimes = [stoptime objectAtIndex:0];
//                    else
//                        return nil;
//                    fetchStopTimes = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"GtfsStopTimesByAgencyID" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:stoptimes.tripID,@"TRIPID",stoptimes.agencyID,@"AGENCYID", nil]];
//                    arrayStopTimes = [managedObjectContext executeFetchRequest:fetchStopTimes error:nil];
//                    NSSortDescriptor *sortD = [[NSSortDescriptor alloc]
//                                               
//                                               initWithKey:@"stopSequence" ascending:YES selector:@selector(localizedStandardCompare:)];
//                    arrayStopTimes = [arrayStopTimes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]];
//                }
//            }
//        }
//        NIMLOG_PERF2(@"stoptimes arrive=%@",[NSDate date]);
//        int startIndex = 0;
//        int endIndex = 0;
//        for(int i=0;i<[arrayStopTimes count];i++){
//            GtfsStopTimes *stopTimes = [arrayStopTimes objectAtIndex:i];
//            if([stopTimes.stopID isEqualToString:leg.from.stopId]){
//                startIndex = i + 1;
//                break;
//            }
//        }
//        for(int i=0;i<[arrayStopTimes count];i++){
//            GtfsStopTimes *stopTimes = [arrayStopTimes objectAtIndex:i];
//            if([stopTimes.stopID isEqualToString:leg.to.stopId]){
//                endIndex = i;
//                break;
//            }
//        }
//        for(int i = startIndex; i<endIndex ;i++){
//            GtfsStopTimes *stopTimes = [arrayStopTimes objectAtIndex:i];
//            [intermediateStops addObject:stopTimes];
//        }
//    return intermediateStops;
//}

- (void) requestStopTimesDataForParticularTripFromServer:(Itinerary *)itinerary{
    @try {
        if([legsArray count] == 0){
            NSMutableArray *tempLegs = [[NSMutableArray alloc] initWithArray:[itinerary sortedLegs]];
            for(int i=0;i<[tempLegs count];i++){
                Leg *leg = [tempLegs objectAtIndex:i];
                if(![leg isScheduled]){
                    [tempLegs removeObject:leg];
                }
            }
           legsArray = tempLegs;
        }
        Leg *leg = [legsArray objectAtIndex:0];
        temporaryLeg = leg;
        NSString *tripId;
        if(leg.realTripId){
            tripId = leg.realTripId;
        }
        else{
            tripId = leg.tripId;
        }
        NSString *agencytripString = [NSString stringWithFormat:@"%@_%@",agencyFeedIdFromAgencyName(leg.agencyName),tripId];
        RKParams *requestParameter = [RKParams params];
        [requestParameter setValue:agencytripString forParam:AGENCY_IDS];
        isParticularTripRequest = true;
        [self.rkTpClient post:GTFS_STOP_TIMES params:requestParameter delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getGtfsStopTimes", @"", exception);
    }
}
@end

