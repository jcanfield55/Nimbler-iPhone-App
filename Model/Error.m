//
//  Error.m
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/3/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Error.h"

@implementation Error

@dynamic id;
@dynamic missing;
@dynamic msg;
@dynamic noPath;


+ (RKManagedObjectMapping *)objectMappingforError:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[Error class]];
        // Make the mappings
    if (apiType==ERROR_PLANNER) {
        // TODO  Do all the mapping       
        [mapping mapKeyPath:@"id" toAttribute:@"id"];
        [mapping mapKeyPath:@"missing" toAttribute:@"missing" ];        
        [mapping mapKeyPath:@"msg" toAttribute:@"msg" ];
        [mapping mapKeyPath:@"noPath" toAttribute:@"noPath"];
    
    } else {
        // TODO Unknown Another type, throw an exception
    }
    return mapping;
}

- (NSString *)ncDescriptions
{
    NSString* desc = [NSString stringWithFormat:
                             @"{Error Object: ID: %@,  Missing: %@,  Msg: %@ ", [self id], [self missing ], [self msg] ];
   
    return desc;
}


@end
