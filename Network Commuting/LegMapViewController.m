//
//  LegMapViewController.m
//  Network Commuting
//
//  Created by John Canfield on 3/23/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LegMapViewController.h"
#import "UtilityFunctions.h"

@interface LegMapViewController()
// Utility routine for setting the region on the MapView based on the itineraryNumber
- (void)setMapViewRegion;
- (void)setDirectionsText;
@end

@implementation LegMapViewController

@synthesize itinerary;
@synthesize itineraryNumber;
@synthesize mapView;
@synthesize directionsView;
@synthesize directionsTitle;
@synthesize directionsDetails;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"Nimbler"];
        
        // create the container to hold forward and back buttons
        /*
         UIView* container = [[UIView alloc] init];
        UIButton* backBBI = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [backBBI setTitle:@"Bak" forState:UIControlStateNormal];
        [backBBI addTarget:self action:@selector(navigateBack:) forControlEvents:UIControlEventTouchDown];
        // [container addSubview:backBBI];
        
        UIButton* forwardBBI = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [forwardBBI setTitle:@"For" forState:UIControlStateNormal];
        [forwardBBI addTarget:self action:@selector(navigateForward:) forControlEvents:UIControlEventTouchDown];
        // [container addSubview:forwardBBI];
        
        UILabel* label = [[UILabel alloc] init];
        [label setText:@"Howdy!"];
        [container addSubview:label];
        // Now add the container as the right BarButtonItem

        UIBarButtonItem* bbi = [[UIBarButtonItem alloc] initWithCustomView:container];
         */
        
        // TODO make this work with iOS 4.0, and get better formatting
        UIBarButtonItem* forwardBBI = [[UIBarButtonItem alloc] initWithTitle:@"For" style:UIBarButtonItemStylePlain target:self action:@selector(navigateForward:)];
        UIBarButtonItem* bakBBI = [[UIBarButtonItem alloc] initWithTitle:@"Bak" style:UIBarButtonItemStylePlain target:self action:@selector(navigateBack:)];
        NSArray* bbiArray = [NSArray arrayWithObjects:forwardBBI, bakBBI, nil];
        [[self navigationItem] setRightBarButtonItems:bbiArray];
    }
    return self;
}

- (void)setItinerary:(Itinerary *)itin itineraryNumber:(int)num;
{
    itinerary = itin;
    itineraryNumber = num;
    
    // Add start and endpoint annotation
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    startPoint = [[MKPointAnnotation alloc] init];
    [startPoint setCoordinate:CLLocationCoordinate2DMake([[itinerary from] latFloat], [[itinerary from] lngFloat])];
    [mapView addAnnotation:startPoint];
    endPoint = [[MKPointAnnotation alloc] init];
    [endPoint setCoordinate:CLLocationCoordinate2DMake([[itinerary to] latFloat], [[itinerary to] lngFloat])];    
    [mapView addAnnotation:endPoint];
    
    // Add the overlays for paths to the mapView
    NSArray *sortedLegs = [itinerary sortedLegs];
    polyLineArray = [NSMutableArray array];
    for (int i=0; i < [sortedLegs count]; i++) {
        Leg* l = [sortedLegs objectAtIndex:i];
        MKPolyline *polyLine = polylineWithEncodedString([l legGeometryPoints]);
        [mapView addOverlay:polyLine];
        [polyLineArray addObject:polyLine];
    }
    
    [self setMapViewRegion];   // update the mapView region to correspond to the numItinerary item
    [self setDirectionsText];  // update the directions text accordingly
}

- (void)setMapViewRegion {
    if (itineraryNumber == 0) {  // if the startpoint set region in a 200m x 200m box around it
        [mapView setRegion:MKCoordinateRegionMakeWithDistance([startPoint coordinate],200, 200)]; 
    }
    else if (itineraryNumber == [[itinerary sortedLegs] count] + 1) {
        [mapView setRegion:MKCoordinateRegionMakeWithDistance([endPoint coordinate],200, 200)]; 
    }
    else { 
        // if inineraryNumber is pointing to a leg, then set the bound around the polyline
        [mapView setVisibleMapRect:[[polyLineArray objectAtIndex:(itineraryNumber-1)] boundingMapRect]];
    }
}

- (void)setDirectionsText 
{
    NSString* titleText;
    NSString* subTitle;
    if (itineraryNumber == 0) { // if first row, put in start point
        titleText = [NSString stringWithFormat:@"Start at %@", [[itinerary from] name]];
    }
    else if (itineraryNumber == [[itinerary sortedLegs] count] + 1) { // if last row, put in end point
        titleText = [NSString stringWithFormat:@"End at %@", [[itinerary to] name]];
    }
    else {  // otherwise, it is one of the legs
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:(itineraryNumber-1)];
        titleText = [leg directionsTitleText];
        subTitle = [leg directionsDetailText];
    }
    [directionsTitle setText:titleText];
    [directionsDetails setText:subTitle];
}

// Callback for when user presses the navigate back button on the right navbar
- (IBAction)navigateBack:(id)sender {
    // Go back to the previous step
    if (itineraryNumber > 0) {
        itineraryNumber--;
    }
    [self setMapViewRegion];  // redefine the bounding box
    [self setDirectionsText];
}

// Callback for when user presses the navigate forward button on the right navbar
- (IBAction)navigateForward:(id)sender {
    NSArray *sortedLegs = [itinerary sortedLegs];
    // Go forward to the next step
    if (itineraryNumber <= [sortedLegs count]) {
        itineraryNumber++;
    }
    [self setMapViewRegion];  // redefine the bounding box
    [self setDirectionsText];
}



// Callback for providing any annotation views
- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MKPinAnnotationView class]])
    {
        // Try to dequeue an existing pin view first.
        MKPinAnnotationView* pinView = (MKPinAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"MyPinAnnotationView"];
        
        if (!pinView)
        {
            // If an existing pin view was not available, create one.
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                       reuseIdentifier:@"MyPinAnnotation"];
            pinView.animatesDrop = NO;
            pinView.canShowCallout = NO;
        }
        else
            pinView.annotation = annotation;
        
        if (annotation == startPoint) {
            pinView.pinColor = MKPinAnnotationColorGreen;
        } 
        else {
            pinView.pinColor = MKPinAnnotationColorRed;
        }
        
        return pinView;
    }
    return nil;
}

// Callback for providing the overlay view
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *aView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
        aView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        aView.lineWidth = 3;
        return aView;
    }
    return nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
