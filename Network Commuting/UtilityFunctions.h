//
//  UtilityFunctions.h
//  Network Commuting
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h> 
#import <CoreLocation/CoreLocation.h>

NSString *pathInDocumentDirectory(NSString *fileName);

void saveContext(NSManagedObjectContext *managedObjectContext);

// Converts from milliseconds to a string formatted as "X days, Y hours, Z minutes"
NSString *durationString(double milliseconds);

// Converts from meters to a string in either miles or feed
NSString *distanceStringInMilesFeet(double meters);


