//
//  StationListElement.m
//  Nimbler Caltrain
//
//  Created by conf on 2/15/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "StationListElement.h"
#import "GtfsStop.h"
#import "Location.h"
#import "LocationFromGoogle.h"
#import "PreloadedStop.h"



@implementation StationListElement

@dynamic memberOfListId;
@dynamic sequenceNumber;
@dynamic containsList;
@dynamic containsListId;
@dynamic agency;
@dynamic stop;
@dynamic location;

+ (RKManagedObjectMapping *)objectMappingforStation:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[StationListElement class]];
    RKManagedObjectMapping* locationMapping = [LocationFromGoogle objectMappingForApi:GOOGLE_GEOCODER];
    // RKManagedObjectMapping* stopMapping = [PreloadedStop objectMappingforStop:apiType];
    mapping.setDefaultValueForMissingAttributes = TRUE;
    locationMapping.setDefaultValueForMissingAttributes = TRUE;
    //stopMapping.setDefaultValueForMissingAttributes = TRUE;
        
    // Make the mappings
    if (apiType==STATION_PARSER) {
        // TODO  Do all the mapping
        [mapping mapKeyPath:@"memberOfListId" toAttribute:@"memberOfListId"];
        [mapping mapKeyPath:@"sequenceNumber"  toAttribute:@"sequenceNumber"];
        [mapping mapKeyPath:@"containsList"  toAttribute:@"containsList"];
        [mapping mapKeyPath:@"containsListId" toAttribute:@"containsListId"];
        [mapping mapKeyPath:@"agency" toAttribute:@"agency"];
        [mapping mapKeyPath:@"locationMember" toRelationship:@"location" withMapping:locationMapping];
         //[mapping mapKeyPath:@"gtfsStopMember" toRelationship:@"stop" withMapping:stopMapping];
        
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

@end
