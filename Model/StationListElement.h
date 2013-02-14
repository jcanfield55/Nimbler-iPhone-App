//
//  StationListElement.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 2/13/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//
// Implementation for US216 station lists (like SFMuni station list)
// One stationListElement for each member of a list
// The stationList will link to either a GtfsStop, a Location, or a containsList (sub-list)

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsStop, Location, StationListElement;

@interface StationListElement : NSManagedObject

@property (nonatomic, retain) NSString *memberOfList; // Required:  Name of the list this element is part of
@property (nonatomic, retain) NSNumber * sequenceNumber; // Where in the sequence this element appears within its parent list
// Only one of the three properties below should be filled in -- the rest should be null
@property (nonatomic, retain) NSString *containsList; // if this element contains another list, name of that list
@property (nonatomic, retain) GtfsStop *gtfsStopMember; // if this element contains a GtfsStop...
@property (nonatomic, retain) Location *locationMember; // if this element contains a Location

@end
