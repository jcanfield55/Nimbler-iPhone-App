//
//  PreloadedStop.m
//  Nimbler Caltrain
//
//  Created by macmini on 15/02/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "PreloadedStop.h"
#import "StationListElement.h"


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

@end
