//
//  RouteMapViewController.m
//  Nimbler Caltrain
//
//  Created by Carl on 10/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RouteMapViewController.h"
#import "Leg.h"
#import "UtilityFunctions.h"
#import "UIConstants.h"


@interface RouteMapViewController ()
{
    UIImage *dotImage;
}
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
            
            NSString* durationStr = durationString(1000.0 * [[itin endTimeOfLastLeg]
                                                             timeIntervalSinceDate:[itin startTimeOfFirstLeg]]);
            NSString *titleText = [NSString stringWithFormat:@"%@ - %@ (%@)",
                                   superShortTimeStringForDate([itin startTimeOfFirstLeg]),
                                   superShortTimeStringForDate([itin endTimeOfLastLeg]),
                                   durationStr];
            
            NSString *detailText = [itin itinerarySummaryStringForWidth:ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH
                                                                   Font:[UIFont systemFontOfSize:15]];
          anno.title = titleText;
          anno.subtitle = detailText;
          
          [mapView addAnnotation:anno];

          break;
        }
      }
      
    }
    
  } // end if

  // zoom map
  mapView.region = MKCoordinateRegionMake(mapCoords, mapSpan);

}


// Callback for providing any annotation views

/*
- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]){
        return nil;
    }
    
    
    MKAnnotationView* dotView = (MKAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"MyDotAnnotationView"];
    
    if (!dotView)
    {
        // If an existing pin view was not available, create one.
        dotView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                               reuseIdentifier:@"MyDotAnnotation"];
        dotView.canShowCallout = NO;
        if (!dotImage) {
            NSString* imageName = [[NSBundle mainBundle] pathForResource:@"img_redspike1" ofType:@"png"];
            dotImage = [UIImage imageWithContentsOfFile:imageName];
        }
        if (dotImage) {
            [dotView setImage:dotImage];
        }
    }
    else
        dotView.annotation = annotation;
    
    return dotView;
}
 */


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
