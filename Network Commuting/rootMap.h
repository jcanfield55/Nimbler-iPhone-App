//
//  LegMapViewController.h
//  Network Commuting
//
//   Created by Sitanshu Joshi on 5/3/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h> 
#import "Itinerary.h"
#import "Leg.h"


@interface rootMap : UIViewController {
    MKPointAnnotation* startPoint;  // annotation for startPoint of the itinerary
    MKPointAnnotation* endPoint;    // annotation for the endPoint of the itinerary
    NSMutableArray* polyLineArray;       // Array of polylines for each leg
    UIImage* dotImage;
}

@property(nonatomic, strong) IBOutlet MKMapView *mapView;
@property(nonatomic, strong) IBOutlet UIView *directionsView;
@property(nonatomic, strong, readonly) Itinerary *itinerary;
@property(nonatomic, readonly) int itineraryNumber;

- (void)setItinerarys:(Itinerary *)itin itineraryNumber:(int)num;
-(void)startTrip;

@end
