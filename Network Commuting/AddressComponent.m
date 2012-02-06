//
//  AddressComponent.m
//  Network Commuting
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "AddressComponent.h"

@implementation AddressComponent

@synthesize longName;
@synthesize shortName;
@synthesize types;

+ (RKObjectMapping *)objectMappingForApi:(APIType)gt
{
    RKObjectMapping* addrCompMapping = [RKObjectMapping mappingForClass:[AddressComponent class]];
    
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

- (id)initWithLongName:(NSString *)lName shortName:(NSString *)sName types:(NSArray *)t
{
    self = [super init];
    if (self) {
        [self setLongName:lName];
        [self setShortName:sName];
        [self setTypes:t];
    } 
    return self;
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{AddressComponent:  longName: %@;  shortName: %@;  types: %@}",
                      longName, shortName, types];
    return desc;
}

@end
