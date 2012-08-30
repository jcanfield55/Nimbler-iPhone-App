//
//  Network_CommutingTests.h
//  Network CommutingTests
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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

@interface Network_CommutingTests : SenTestCase
{
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectModel *managedObjectModel;
    
    Location *loc1;
    Location *loc2;
    Location *loc3;
    
    Locations *locations;
    PlanStore *planStore;
    
    Plan *plan1;
    Plan *plan2;
    Plan *plan3;
    Plan *plan4;
    Plan *plan5;
    Plan *plan6;
    Plan *plan7;
    Plan *plan8;

    Itinerary *itin10;
    Itinerary *itin11;
    Itinerary *itin20;
    Itinerary *itin30;
    Itinerary *itin31;
    Itinerary *itin32;
    Itinerary *itin40;
    Itinerary *itin41;
    Itinerary *itin50;
    Itinerary *itin51;
    Itinerary *itin52;
    Itinerary *itin60;
    Itinerary *itin61;
    Itinerary *itin62;
    Itinerary *itin70;
    Itinerary *itin71;
    Itinerary *itin72;
    Itinerary *itin80;

    NSDate* date60req;
}
@end
