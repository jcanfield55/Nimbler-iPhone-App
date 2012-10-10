//
//  AddressComponent.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import <CoreData/CoreData.h>
#import "enums.h"

@interface AddressComponent : NSManagedObject {
    NSString * longName;
    NSString * shortName;
    NSArray * types;
}

@property (nonatomic, strong) NSString * longName;
@property (nonatomic, strong) NSString * shortName;
@property (nonatomic, strong) NSArray * types;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)gt;

@end
