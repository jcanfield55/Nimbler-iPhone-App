//
//  AddressComponent.m
//  Network Commuting
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "AddressComponent.h"

@implementation AddressComponent

@dynamic longName;
@dynamic shortName;
@dynamic types;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)gt
{
    RKManagedObjectMapping* addrCompMapping = [RKManagedObjectMapping mappingForClass:[AddressComponent class]];
    
    if (gt==GOOGLE_GEOCODER) {
        [addrCompMapping mapKeyPath:@"long_name" toAttribute:@"longName"];
        [addrCompMapping mapKeyPath:@"short_name" toAttribute:@"shortName"];
        [addrCompMapping mapKeyPath:@"types" toAttribute:@"types"];
    }
    else {
        // Unknown geocoder type, throw an exception
    }
    
    return addrCompMapping;
}

// TODO -- get a new way to do description
/*
- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{AddressComponent:  longName: %@;  shortName: %@;  types: %@}",
                      longName, shortName, types];
    return desc;
}
 */

@end
