//
//  Stations.h
//  Nimbler Caltrain
//
//  Created by conf on 2/15/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import <Restkit/RKJSONParserJSONKit.h>
#import "StationListElement.h"
#import "PreloadedStop.h"

@interface Stations : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) RKObjectManager *rkStationMgr;
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkPlanMgr:(RKObjectManager *)rkP;
- (BOOL)preLoadIfNeededFromFile:(NSString *)filename latestVersionNumber:(NSDecimalNumber *)newVersion testAddress:(NSString *)testAddress;
- (NSArray *) fetchStationListByMemberOfListId:(NSString *)memberOfListId;
- (NSArray *) fetchStationListByContainsListId:(NSString *)containsListId;
- (int) returnElementType:(StationListElement *)stationListElement;
- (Location *) createNewLocationObjectFromGtfsStop:(PreloadedStop *)stop :(StationListElement *)stationListElement;
- (Location *) generateNewTempLocationForAllStationString:(NSString *)containslistId;
- (void) removeStationListElementByAgency:(NSString *)agencyName;
@end
