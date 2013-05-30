//
//  Stations.m
//  Nimbler Caltrain
//
//  Created by conf on 2/15/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "Stations.h"
#import "UtilityFunctions.h"
#import "Location.h"
#import "LocationFromGoogle.h"
#import "StationListElement.h"
#import "nc_AppDelegate.h"
#import "PreloadedStop.h"

@implementation Stations
@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize rkStationMgr;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkPlanMgr:(RKObjectManager *)rkP
{
    self = [super init];
    if (self) {
        managedObjectContext = moc;
        managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
        rkStationMgr = rkP;
    }
    
    return self;
}

- (BOOL)preLoadIfNeededFromFile:(NSString *)filename latestVersionNumber:(NSDecimalNumber *)newVersion testAddress:(NSString *)testAddress {
        [[rkStationMgr mappingProvider] setMapping:[StationListElement objectMappingforStation:STATION_PARSER] forKeyPath:@"results"];
        [[NSUserDefaults standardUserDefaults] setFloat:[newVersion floatValue] forKey:filename];
        [[NSUserDefaults standardUserDefaults] synchronize];
        @try {
            // Check there version number against the the PRELOAD_TEST_ADDRESS to see if we need to open the file
            NSStringEncoding encoding;
            NSError* error = nil;
            NSString* preloadPath = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
            NSString *jsonText = [NSString stringWithContentsOfFile:preloadPath usedEncoding:&encoding error:&error];
            if (jsonText && !error) {
                
                id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
                id parsedData = [parser objectFromString:jsonText error:&error];
                if (parsedData == nil && error) {
                    logError(@"Locations->preLoadIfNeededFromFile", [NSString stringWithFormat:@"Parsing error: %@", error]);
                }
                RKObjectMappingProvider* mappingProvider = rkStationMgr.mappingProvider;
                
                RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
                RKObjectMappingResult* result = [mapper performMapping];
                if (result) {
                    // NSArray* resultArray = [result asCollection];
                }
            }
        }
        @catch (NSException *exception) {
            logException(@"Stations->preLoadIfNeededFromFile", @"", exception);
        }
    return YES;
}

- (NSArray *) fetchStationListByMemberOfListId:(NSString *)memberOfListId{
    NSFetchRequest *fetchStationListElement = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"StationListByMemberId" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:memberOfListId,@"MEMBEROFLISTID", nil]];
    NSArray * arrayStationListElement = [self.managedObjectContext executeFetchRequest:fetchStationListElement error:nil];
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"sequenceNumber" ascending:YES];
    return [arrayStationListElement sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]];
}

- (NSArray *) fetchStationListByContainsListId:(NSString *)containsListId{
    NSFetchRequest *fetchStationListElement = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"StationListByContainsId" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:containsListId,@"CONTAINSLISTID", nil]];
    NSArray * arrayStationListElement = [self.managedObjectContext executeFetchRequest:fetchStationListElement error:nil];
    return arrayStationListElement;
}

- (int) returnElementType:(StationListElement *)stationListElement{
    if(stationListElement.containsList)
        return CONTAINS_LIST_TYPE;
    else if(stationListElement.location)
        return LOCATION_TYPE;
    else
        return PRELOADSTOP_TYPE;
}

- (Location *) createNewLocationObjectFromGtfsStop:(PreloadedStop *)stop :(StationListElement *)stationListElement{
    LocationFromGoogle *newLoc = [[nc_AppDelegate sharedInstance].locations newEmptyLocationFromGoogle];
    newLoc.lat = stop.lat;
    newLoc.lng = stop.lon;
    newLoc.formattedAddress = stop.formattedAddress;
    // Setting the following addressComponent makes the formattedAddress substring searchable
    [newLoc addAddressComponentWithLongName:stop.formattedAddress
                                  shortName:nil
                                      types:[NSArray arrayWithObject:@"intersection"]
                                    context:managedObjectContext];
    return newLoc;
}

- (void) generateNewTempLocationForAllStationString{
    NSArray *arrListElement = [self fetchStationListByContainsListId:ALL_STATION];
    if([arrListElement count] > 0){
        StationListElement *stationListElement = [arrListElement objectAtIndex:0];
        Location *newLoc = [[nc_AppDelegate sharedInstance].locations newEmptyLocation];
        newLoc.fromFrequency = [NSNumber numberWithFloat:25.0];
        newLoc.toFrequency = [NSNumber numberWithFloat:25.0];
        newLoc.locationType = TOFROM_LIST_TYPE;
        newLoc.formattedAddress = stationListElement.containsList;
    }
}

- (void) removeStationListElementByAgency:(NSString *)agencyName{
        NSFetchRequest *fetchStationListElement = [[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName:@"StationListElementByAgency" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:agencyName,@"AGENCY", nil]];
        NSArray * arrayListElements = [managedObjectContext executeFetchRequest:fetchStationListElement error:nil];
        for (StationListElement *listElement in arrayListElements){
            if(listElement.location)
                [managedObjectContext deleteObject:listElement.location];
            if(listElement.stop)
                [managedObjectContext deleteObject:listElement.stop];
            [managedObjectContext deleteObject:listElement];
        }
}

@end
