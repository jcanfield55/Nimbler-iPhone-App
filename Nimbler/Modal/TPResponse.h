//
//  TPResponse.h
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/21/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "enums.h"

@interface TPResponse : NSManagedObject

+ (RKManagedObjectMapping *)objectMappingforTPResponse:(APIType)apiType;
@end
