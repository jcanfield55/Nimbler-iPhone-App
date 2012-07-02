//
//  UserPreferance.h
//  Nimbler
//
//  Created by JaY Kumbhani on 7/2/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface UserPreferance : NSManagedObject

@property (nonatomic, retain) NSNumber * pushEnable;
@property (nonatomic, retain) NSNumber * triggerAtHour;
@property (nonatomic, retain) NSNumber * walkDistance;

@end
