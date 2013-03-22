//
//  LegMapViewController.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 3/23/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h> 
#import "Itinerary.h"
#import "Leg.h"

@interface LegMapViewController : UIViewController <RKRequestDelegate, MKMapViewDelegate>

@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) Itinerary *itinerary;
@property(nonatomic) int itineraryNumber;

- (id)initWithMapView:(MKMapView *)m0;  // Preferred initializer
- (void)setMapViewRegion;  
- (void)refreshLegOverlay:(int)number;
- (void) addIntermediateStationsToMapView:(NSArray *)sortedLegs;
- (void) addIntermediateStops:(NSArray *)stopTimes Leg:(Leg *)leg;
@end