//
//  RealTimeServerStubTest.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 1/26/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Locations.h"
#import "Location.h"
#import "AddressComponent.h"
#import "UtilityFunctions.h"
#import "KeyObjectStore.h"
#import "KeyObjectPair.h"
#import "TransitCalendar.h"
#import "PlanRequestChunk.h"
#import "Plan.h"
#import "PlanStore.h"
#import "Itinerary.h"
#import "Leg.h"
#import "GtfsParser.h"
#import "nc_AppDelegate.h"

@interface RealTimeServerStubTest : SenTestCase<RKRequestDelegate>
{
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectModel *managedObjectModel;
    
    RKManagedObjectStore *rkMOS;
    RKObjectManager *rkPlanMgr;
    
    RKClient *rkTpClient;
    
    GtfsParser *gtfsParser;
    
    NSDateFormatter* dateFormatter;
    NSDateFormatter* timeFormatter;
    Location *loc1;
    Location *loc2;
    Location *loc3;
    
    Locations *locations;
    PlanStore *planStore;

    
    Plan *plan10;
    Plan *plan11;
    Plan *plan12;
    
    Itinerary *itin101;
    Itinerary *itin102;
    Itinerary *itin103;
    
    Itinerary *itin111;
    Itinerary *itin112;
    Itinerary *itin113;
    
    Itinerary *itin120;
    
    Leg *leg1011;
    Leg *leg1012;
    Leg *leg1013;
    Leg *leg1021;
    Leg *leg1031;
    Leg *leg1032;
    
    Leg *leg1111;
    Leg *leg1112;
    Leg *leg1113;
    Leg *leg1121;
    Leg *leg1131;
    Leg *leg1132;
    
    Leg *leg1201;
    Leg *leg1202;
    Leg *leg1203;
    Leg *leg1204;
    Leg *leg1205;
}

@end
