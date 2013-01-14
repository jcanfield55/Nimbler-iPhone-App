//
//  TestGeneratePlan.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 1/13/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "Locations.h"


@interface TestGeneratePlan : SenTestCase<RKRequestDelegate>
{
    Locations *locations;
    
    NSManagedObjectContext *managedObjectContext;
    NSManagedObjectModel *managedObjectModel;
    
    NSDateFormatter* dateFormatter;
}

@end
