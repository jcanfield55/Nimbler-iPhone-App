//
//  RawAddress.h
//  Network Commuting
//
//  Created by John Canfield on 2/13/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface RawAddress : NSManagedObject

@property (nonatomic, retain) NSString * rawAddressString;
@property (nonatomic, retain) Location *location;

@end
