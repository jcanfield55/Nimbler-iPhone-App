//
//  RouteMapViewController.m
//  Nimbler Caltrain
//
//  Created by Carl on 10/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RouteMapViewController.h"
#import "Leg.h"


@interface RouteMapViewController ()

@end

@implementation RouteMapViewController

@synthesize mapView, plan;
//@synthesize mapPoints;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // init the mapview
    mapView.mapType = MKMapTypeStandard;
    mapView.scrollEnabled = YES;
    mapView.zoomEnabled = YES;
  
  // TEST: center map to the Bay Area
  CLLocationCoordinate2D mapCoords;
  mapCoords.latitude = 37.774929;
  mapCoords.longitude = -122.270803;
  MKCoordinateSpan mapSpan;
  mapSpan.latitudeDelta = 0.01;
  mapSpan.longitudeDelta = 0.01;

  
  //mapPoints = [[NSMutableArray alloc] initWithCapacity:[[plan sortedItineraries] count]];
  
  BOOL zoomFlag = FALSE;
  
  // loop thru the plan itineraries and create map annotations
  if (plan != nil) {
    // [plan sortedItineraries]
    int i=0;
    for (Itinerary *itin in [plan sortedItineraries]) {
      i++;
      NSLog(@"itin: %d", i);
      int j=0;
      for (Leg *leg in [itin sortedLegs]) {
        j++;
        NSLog(@"  leg: %d", j);
        if ([leg isBus] || [leg isTrain]){
          NSLog(@"  Leg is a bus or train.");
          NSLog(@"    from: %f  to: %f", leg.from.latFloat, leg.from.lngFloat);

          // create annotation and add to map
          CLLocationCoordinate2D legCoords;
          legCoords.latitude = leg.from.latFloat;
          legCoords.longitude = leg.from.lngFloat;
          if (!zoomFlag) {
            mapCoords = legCoords;
            zoomFlag = TRUE;
          }
          AddressAnnotation *anno = [[AddressAnnotation alloc] initWithCoordinate:legCoords];
          //[mapPoints addObject:anno];
          anno.title = @"foo";
          anno.subtitle = @"bar";
          
          [mapView addAnnotation:anno];

          break;
        }
      }
      
    }
    
  } // end if

  // zoom map
  mapView.region = MKCoordinateRegionMake(mapCoords, mapSpan);

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
