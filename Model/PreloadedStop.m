//
//  PreloadedStop.m
//  Nimbler Caltrain
//
//  Created by macmini on 15/02/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "PreloadedStop.h"
#import "StationListElement.h"
#import "nc_AppDelegate.h"


@implementation PreloadedStop

@dynamic formattedAddress;
@dynamic lat;
@dynamic lon;
@dynamic stopId;
@dynamic stationListElement;

+ (RKManagedObjectMapping *)objectMappingforStop:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[PreloadedStop class]];
    
    mapping.setDefaultValueForMissingAttributes = TRUE;
    
    // Make the mappings
    if (apiType==STATION_PARSER) {
        // TODO  Do all the mapping
        [mapping mapKeyPath:@"formatted_address"  toAttribute:@"formattedAddress"];
        [mapping mapKeyPath:@"stopId"  toAttribute:@"stopId"];
        [mapping mapKeyPath:@"lat"  toAttribute:@"lat"];
        [mapping mapKeyPath:@"lon" toAttribute:@"lon"];
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

-(BOOL) isMatchingTypedString:(NSString *)str{
    NSString *address = [[self formattedAddress] lowercaseString];
    NSString *strAdress = [[nc_AppDelegate sharedInstance].locations rawAddressWithOutAgencyName:address SearchStringArray:SEARCH_STRINGS_ARRAY ReplaceStringArray:REPLACE_STRINGS_ARRAY];
    NSArray *arrComponents = [strAdress componentsSeparatedByString:@" "];
    for(int i=0;i<[arrComponents count];i++){
        NSString *token = [arrComponents objectAtIndex:i];
        if([token hasPrefix:str])
            return true;
    }
    return false;
}
@end
