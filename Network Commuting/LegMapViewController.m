//
//  LegMapViewController.m
//  Network Commuting
//
//  Created by John Canfield on 3/23/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LegMapViewController.h"

@interface LegMapViewController()
// Utility routine for setting the region on the MapView based on the itineraryNumber
- (void)setMapViewRegion;
- (void)setDirectionsText;
- (void)refreshLegOverlay:(int)number;
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

    NSArray *sortedLegs = [itinerary sortedLegs];

    // Take startpoint as the beginning of the first leg's polyline, 
    // and endpoint form the last leg's polyline
    startPoint = [[MKPointAnnotation alloc] init];
    [startPoint setCoordinate:[[[sortedLegs objectAtIndex:0] polylineEncodedString] startCoord]];
    [mapView addAnnotation:startPoint];
    endPoint = [[MKPointAnnotation alloc] init];
    [endPoint setCoordinate:[[[sortedLegs objectAtIndex:([sortedLegs count]-1)] polylineEncodedString] endCoord]];
    [mapView addAnnotation:endPoint];

    // Add the overlays and dot AnnotationViews for paths to the mapView
    polyLineArray = [NSMutableArray array];
    for (int i=0; i < [sortedLegs count]; i++) {
        Leg* l = [sortedLegs objectAtIndex:i];
        MKPolyline *polyLine = [[l polylineEncodedString] polyline];
        [polyLineArray addObject:polyLine];
        [mapView addOverlay:polyLine];
        
        MKPointAnnotation* dotPoint = [[MKPointAnnotation alloc] init];
        [dotPoint setCoordinate:[[l polylineEncodedString] endCoord]];
        [mapView addAnnotation:dotPoint];
    }
    NSLog(@"ViewWillAppear, polyLineArray count = %d",[polyLineArray count]);
    
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
        MKMapRect mpRect = [[polyLineArray objectAtIndex:(itineraryNumber-1)] boundingMapRect];
        MKCoordinateRegion mpRegion = MKCoordinateRegionForMapRect(mpRect);
        // Move the center down by 15% of span so that route is not obscured by directions text
        mpRegion.center.latitude = mpRegion.center.latitude + mpRegion.span.latitudeDelta*0.15;
        // zoom out the map by 10% (lat) and 20% (long)
        mpRegion.span.latitudeDelta = mpRegion.span.latitudeDelta * 1.2; 
        mpRegion.span.longitudeDelta = mpRegion.span.longitudeDelta * 1.1;
        // Create a 100m x 100m coord region around the center, and choose that if bigger
        MKCoordinateRegion minRegion = MKCoordinateRegionMakeWithDistance(mpRegion.center, 100.0, 100.0);
        if ((minRegion.span.latitudeDelta > mpRegion.span.latitudeDelta) &&
            (minRegion.span.longitudeDelta > mpRegion.span.longitudeDelta)) {
            mpRegion = minRegion;  // if minRegion is larger, replace mpRegion with it
        }
        
        [mapView setRegion:mpRegion];
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
    [self refreshLegOverlay:itineraryNumber+1];  // refreshes the previous itinerary number
    [self refreshLegOverlay:itineraryNumber];   // refreshes the new itinerary number
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
    [self refreshLegOverlay:itineraryNumber-1];  // refreshes the last itinerary number
    [self refreshLegOverlay:itineraryNumber];   // refreshes the new itinerary number
    [self setMapViewRegion];  // redefine the bounding box
    [self setDirectionsText];
}

// Removes and re-inserts the polyline overlay for the specified iNumber (could be itineraryNumber)
- (void)refreshLegOverlay:(int)iNumber
{
    int i = iNumber-1; 
    if (i>=0 && i<[polyLineArray count]) {  // only refresh if there is a corresponding polyline
        [mapView removeOverlay:[polyLineArray objectAtIndex:i]];
        [mapView addOverlay:[polyLineArray objectAtIndex:i]];
    }
}


// Callback for providing any annotation views
- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle point annotations
    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        // if startpoint or endpoint, then use MKPinAnnotationView
        if (annotation == startPoint || annotation == endPoint) {
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
        // Otherwise, use the dot view controller
        else {
            MKAnnotationView* dotView = (MKAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"MyDotAnnotationView"];
            
            if (!dotView)
            {
                // If an existing pin view was not available, create one.
                dotView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:@"MyDotAnnotation"];
                dotView.canShowCallout = NO;
                if (!dotImage) {
                    // TODO add @2X image for retina screens
                    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"Blue_dot_7px" ofType:@"gif"];
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
    }
    return nil;
}

// Callback for providing the overlay view
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *aView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
        // aView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];

        // Determine if this overlay is the one in focus.  If so, make it darker
        NSLog(@"[polyLineArray count] = %d", [polyLineArray count]);
        if ([polyLineArray count] > 0) {
            NSLog(@"first polyLine = %@, overlay = %@", [polyLineArray objectAtIndex:0], overlay);
        }
        for (int i=0; i<[polyLineArray count]; i++) {
            if (([polyLineArray objectAtIndex:i] == overlay)) {
                if (i == itineraryNumber-1) {
                    aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.6];
                }
            }
        }
        aView.lineWidth = 6;
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
