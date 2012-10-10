//
//  TPResponse.m
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/21/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "TPResponse.h"

@implementation TPResponse

+ (RKManagedObjectMapping *)objectMappingforTPResponse:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[TPResponse class]];
    if (apiType==OTP_PLANNER) {
        // TODO  Do all the mapping       
        [mapping mapKeyPath:@"status" toAttribute:@"status"];
    } else {
        // TODO Unknown Another type, throw an exception
    }
    return mapping;
}

@end
