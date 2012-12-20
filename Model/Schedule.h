//
//  Schedule.h
//  RestKit
//
//  Created by macmini on 20/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Leg;

@interface Schedule : NSManagedObject

@property (nonatomic, retain) id fromLocation;
@property (nonatomic, retain) id legs;
@property (nonatomic, retain) id toLocation;
@end