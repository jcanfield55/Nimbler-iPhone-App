//
//  AddressComponent.h
//  Network Commuting
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "enums.h"

@interface AddressComponent : NSObject

@property (nonatomic, copy) NSString * longName;
@property (nonatomic, copy) NSString * shortName;
@property (nonatomic, copy) NSArray * types;

+ (RKObjectMapping *)objectMappingForApi:(APIType)gt;
- (id)initWithLongName:(NSString *)lName shortName:(NSString *)sName types:(NSArray *)t;

@end
