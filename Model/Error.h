//
//  Error.h
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/3/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <RestKit/Restkit.h>
#import "Location.h"
#import "enums.h"

@interface Error : NSManagedObject

@property(nonatomic,strong) NSString *noPath;
@property(nonatomic,strong) NSString *id;
@property(nonatomic,strong) NSString *missing;
@property(nonatomic,strong) NSString *msg;

+ (RKManagedObjectMapping *)objectMappingforError:(APIType)tpt;
- (NSString *)ncDescriptions;
@end
