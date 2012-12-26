//
//  Schedule.h
//  Nimbler Caltrain
//
//  Created by macmini on 25/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Schedule : NSManagedObject

// legs is array of array contaion dictionary of legs with agencyID,agencyName,route,routeShortNam,routeLongName,mode,startTime,endTime,polyLineEncodedString,distance,duration,toLat,toLng,fromLat,fromLng
@property (nonatomic, retain) id legs;
@property (nonatomic, retain) NSString * toFormattedAddress; // Formatted Address Of ToLocation
@property (nonatomic, retain) NSString * fromFormattedAddress; // Formatted Address of FromLocation
@property (nonatomic, retain) NSNumber * toLat; // Latitude Of ToLocation
@property (nonatomic, retain) NSNumber * fromLat; // Latitude Of FromLocation
@property (nonatomic, retain) NSNumber * toLng; // Longitude of ToLocation
@property (nonatomic, retain) NSNumber * fromLng; // Longitude Of FromLocation

@end
