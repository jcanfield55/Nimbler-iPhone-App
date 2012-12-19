//
//  Schedule.h
//  Nimbler Caltrain
//
//  Created by macmini on 18/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Schedule : NSManagedObject

@property (nonatomic, retain) id fromLocation;
@property (nonatomic, retain) id toLocation;
@property (nonatomic, retain) id legs;

@end
