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
#import "UserPreferance.h"

@interface RealTimeServerStubTest : SenTestCase<RKRequestDelegate,LocationsGeocodeResultsDelegate>
{
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectModel *managedObjectModel;
    
    RKManagedObjectStore *rkMOS;
    RKObjectManager *rkPlanMgr;
    RKObjectManager *rkGeoMgr;
    
    RKClient *rkTpClient;
    
    GtfsParser *gtfsParser;
    
    NSDateFormatter* dateFormatter;
    
    Locations *locations;
    PlanStore *planStore;

    Location *fromLocation;
    Location *toLocation;
    
    UserPreferance *userPreferance;
    ToFromViewController *toFromViewController;
}

@end
