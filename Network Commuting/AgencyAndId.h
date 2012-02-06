//
//  AgencyAndId.h
//  Network Commuting
//
//  Created by John Canfield on 1/29/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/Restkit.h>
#import "enums.h"

@interface AgencyAndId : NSObject

@property(nonatomic,strong) NSString *agency;
@property(nonatomic,strong) NSString *id;

+ (RKObjectMapping *)objectMappingForApi:(APIType)tpt;


@end
