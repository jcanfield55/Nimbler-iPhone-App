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
#import "Plan.h"
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
}
@end
