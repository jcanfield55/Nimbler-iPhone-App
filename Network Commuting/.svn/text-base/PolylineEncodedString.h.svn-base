//
//  PolylineEncodedString.h
//  Nimbler
//
//  Created by John Canfield on 3/31/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h> 
#import <CoreLocation/CoreLocation.h>

@interface PolylineEncodedString : NSObject

@property(strong,nonatomic) NSString* encodedString;
@property(strong,nonatomic,readonly) MKPolyline* polyline;
@property(nonatomic,readonly) CLLocationCoordinate2D startCoord;
@property(nonatomic,readonly) CLLocationCoordinate2D endCoord;

- (id)initWithEncodedString:(NSString *)encStr;
@end
