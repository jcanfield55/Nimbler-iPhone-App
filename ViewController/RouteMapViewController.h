//
//  RouteMapViewController.h
//  Nimbler Caltrain
//
//  Created by Carl on 10/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Plan.h"
#import "enums.h"
#import "AddressAnnotation.h"


@interface RouteMapViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) Plan *plan;
//@property (nonatomic, strong) NSMutableArray *mapPoints;  // list of AddressAnnotations

@end
