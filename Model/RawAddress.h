//
//  RawAddress.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/13/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface RawAddress : NSManagedObject

@property (nonatomic, copy) NSString * rawAddressString;
@property (nonatomic, retain) Location *location;

@end
