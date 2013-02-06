//
//  LegFromOTP.h
//  Nimbler Caltrain
//
//  Created by macmini on 30/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Leg.h"

@interface LegFromOTP : Leg
+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType;
@end
