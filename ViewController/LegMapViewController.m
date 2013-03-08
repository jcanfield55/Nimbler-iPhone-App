//
//  LegMapViewController.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 3/23/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "LegMapViewController.h"
#import "Step.h"
#import "twitterViewController.h"
#import "RestKit/RKJSONParserJSONKit.h"
#import "UtilityFunctions.h"
#import "Constants.h"
#import <CoreImage/CoreImageDefines.h>
#import "nc_AppDelegate.h"
#import "Leg.h"
#import "Itinerary.h"
#import "GtfsStopTimes.h"

#define LINE_WIDTH  5
#define ALPHA_LIGHT 0.7
#define ALPHA_MEDIUM 0.8
#define ALPHA_LIGHTER 0.4

@interface LegMapViewController() {
    // Internal variables
    MKPointAnnotation* startPoint;  // annotation for startPoint of the itinerary
    MKPointAnnotation* endPoint;    // annotation for the endPoint of the itinerary
    NSMutableArray* polyLineArray;  // Array of polylines for each element in legDescriptionTitleSortedArray
    NSMutableArray* dotAnnotationArray;  // Array of all dot annotations
    NSMutableArray* intermediateAnnotations;
    UIImage* dotImage;
    UIImage* pinImage;
}

// Utility routine for setting the region on the MapView based on the itineraryNumber
@end

@implementation LegMapViewController

@synthesize itinerary;
@synthesize itineraryNumber;
@synthesize mapView;

NSString *legID;

- (id)initWithMapView:(MKMapView *)m0
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        mapView = m0;
        polyLineArray = [NSMutableArray arrayWithCapacity:10];
        dotAnnotationArray = [NSMutableArray arrayWithCapacity:10];
        intermediateAnnotations = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)setItinerary:(Itinerary *)itin
{
    @try {
        if (itin != itinerary) {  // if something actually changed...
            itinerary = itin;  
            
            // Clear out any previous overlays and annotations
            [mapView removeAnnotations:dotAnnotationArray];
            [mapView removeOverlays:polyLineArray];
            [mapView removeAnnotation:intermediateAnnotations];
            [dotAnnotationArray removeAllObjects];
            [polyLineArray removeAllObjects];
            
            // Set up the startpoint, endpoint, overlays and annotations for the new itinerary
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"hh:mm:ss a" options:0 locale:[NSLocale currentLocale]]];
            NSArray *sortedLegs = [itinerary sortedLegs];
            for(int i=0;i<[sortedLegs count];i++){
                Leg *leg = [sortedLegs objectAtIndex:i];
                if([leg isScheduled]){
                    NSLog(@"tripId=%@",leg.tripId);
                    NSLog(@"fromStop=%@",leg.from.stopId);
                    NSLog(@"toStop=%@",leg.to.stopId);
                    NSArray *stopTimes = [[nc_AppDelegate sharedInstance].gtfsParser returnIntermediateStopForLeg:leg];
                    for(int i=0;i<[stopTimes count];i++){
                        GtfsStopTimes *stopTime = [stopTimes objectAtIndex:i];
                         NSLog(@"intermediateStop=%@",stopTime.stop.stopID);
                        float langcoord = [stopTime.stop.stopLat floatValue];
                        float longcoord = [stopTime.stop.stopLon floatValue];
                        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(langcoord, longcoord);
                        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
                        [point setCoordinate:coord];
                        [point setTitle:stopTime.stop.stopName];
                        if(stopTime.arrivalTime && ![stopTime.arrivalTime isEqualToString:@""]){
                            NSDate *arrivalTime = dateFromTimeString(stopTime.arrivalTime);
                            NSDate *realArrivalTime = nil;
                            if([leg isRealTimeLeg]){
                                NSLog(@"%d",leg.timeDiff);
                               realArrivalTime =  [arrivalTime dateByAddingTimeInterval:-(leg.timeDiff * 60)];
                            }
                            NSString *date;
                            if(realArrivalTime){
                               date = [dateFormatter stringFromDate:realArrivalTime];
                            }
                            else{
                                date = [dateFormatter stringFromDate:arrivalTime];
                            }
                            NSLog(@"time=%@",stopTime.arrivalTime);
                            NSLog(@"date=%@",date);
                           [point setSubtitle:[NSString stringWithFormat:@"Arrival: %@",date]];
                        }
                        [intermediateAnnotations addObject:point];
                        [mapView addAnnotation:point];
                    }
                }
           }
            // Take startpoint as the beginning of the first leg's polyline, and endpoint form the last leg's polyline
            startPoint = [[MKPointAnnotation alloc] init];
            [startPoint setCoordinate:[[[sortedLegs objectAtIndex:0] polylineEncodedString] startCoord]];
            [dotAnnotationArray addObject:startPoint];
            [mapView addAnnotation:startPoint];
            endPoint = [[MKPointAnnotation alloc] init];
            [endPoint setCoordinate:[[[sortedLegs objectAtIndex:([sortedLegs count]-1)] polylineEncodedString] endCoord]];
            [dotAnnotationArray addObject:endPoint];
            [mapView addAnnotation:endPoint];
            
            // Add the overlays and dot AnnotationViews for paths to the mapView
            for (int i=0; i < [itinerary itineraryRowCount]; i++) {
                if ([[itinerary legDescriptionToLegMapArray] objectAtIndex:i] == [NSNull null]) {
                    [polyLineArray addObject:[NSNull null]];
                }
                else {
                    Leg* l = [[itinerary legDescriptionToLegMapArray] objectAtIndex:i];
                    MKPolyline *polyLine = [[l polylineEncodedString] polyline];
                    [polyLineArray addObject:polyLine];
                    [mapView addOverlay:polyLine];
                    
                    if (i < [itinerary itineraryRowCount] - 1) {  // if not the last itinerary row
                        MKPointAnnotation* dotPoint = [[MKPointAnnotation alloc] init];
                        [dotPoint setCoordinate:[[l polylineEncodedString] endCoord]];
                        [dotAnnotationArray addObject:dotPoint];
                        [mapView addAnnotation:dotPoint];
                    }
                }
            }
            
            [self setMapViewRegion];   // update the mapView region to correspond to the numItinerary item
            [mapView setShowsUserLocation:YES];  // track user location
        }
    }
    @catch (NSException *exception) {
        logException(@"LegMapViewController -> setItinerary", @"", exception);
    }
}

- (void)setItineraryNumber:(int)i0
{
    @try {
        if (itineraryNumber != i0) { // if something has actually changed...
            //[self refreshLegOverlay:itineraryNumber];  // refreshes the last itinerary number
            //[self refreshLegOverlay:i0];   // refreshes the new itinerary number
            itineraryNumber = i0;
            [self setMapViewRegion];  // redefine the bounding box
        }
    }
    @catch (NSException *exception) {
        logException(@"LegMapViewController -> setItineraryNumber", @"", exception);
    }
}


- (void)setMapViewRegion {

    @try {
        if ([polyLineArray objectAtIndex:itineraryNumber] == [NSNull null]) {
            // If an added startpoint or endpoint, set a 200m x 200m box around the point
            if (itineraryNumber == 0) { // startpoint
                [mapView setRegion:MKCoordinateRegionMakeWithDistance([startPoint coordinate],200, 200)]; 
            }
            else { // endpoint
                [mapView setRegion:MKCoordinateRegionMakeWithDistance([endPoint coordinate],200, 200)]; 
            }
        }
        else { 
            // if inineraryNumber is pointing to a leg, then set the bound around the polyline
            MKMapRect mpRect = [[polyLineArray objectAtIndex:itineraryNumber] boundingMapRect];
            MKCoordinateRegion mpRegion = MKCoordinateRegionForMapRect(mpRect);
            mpRegion.center.latitude = mpRegion.center.latitude;
            // zoom out the map by 10% (lat) and 10% (long)
            mpRegion.span.latitudeDelta = mpRegion.span.latitudeDelta * 1.1; 
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
    @catch (NSException *exception) {
        logException(@"LegMapViewController -> setMapViewRegion", @"", exception);
    }
}

// Removes and re-inserts the polyline overlay for the specified iNumber (could be itineraryNumber)
- (void)refreshLegOverlay:(int)iNumber
{
    @try {
        if ([polyLineArray objectAtIndex:iNumber] != [NSNull null]) {  
            // only refresh if there is a corresponding polyline
            [mapView removeOverlay:[polyLineArray objectAtIndex:iNumber]];
            [mapView addOverlay:[polyLineArray objectAtIndex:iNumber]];
        }
    }
    @catch (NSException *exception) {
        logException(@"LegMapViewController -> refreshLegOverlay", @"", exception);
    }
}

// Callback for providing the overlay view
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay 
{
    @try {
        if ([overlay isKindOfClass:[MKPolyline class]]) {
            MKPolylineView *aView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
            // aView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
            aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:ALPHA_LIGHTER];
            aView.lineWidth = LINE_WIDTH;
            NIMLOG_EVENT1(@"itineraryNumber=%d",itineraryNumber);
            
            // Determine if this overlay is the one in focus.  If so, make it darker
            for (int i=0; i<[polyLineArray count]; i++) {
                if (([polyLineArray objectAtIndex:i] == overlay)) {
                    if (i == itineraryNumber) {
                        Leg *leg  = [[itinerary legDescriptionToLegMapArray] objectAtIndex:itineraryNumber];
                        if([leg isWalk] || [leg isBike]){
                            aView.strokeColor = [[UIColor blackColor] colorWithAlphaComponent:ALPHA_LIGHT] ;
                            aView.lineWidth = LINE_WIDTH;
                        } else if([leg isBus]){
                            aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:ALPHA_LIGHT];
                            aView.lineWidth = LINE_WIDTH;
                        } else if([leg isTrain]){                        
                            aView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:ALPHA_MEDIUM] ;
                            aView.lineWidth = LINE_WIDTH;
                        } else {
                            aView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:ALPHA_MEDIUM] ;
                            aView.lineWidth = LINE_WIDTH;
                        }
                        
                    }
                }
            } 
            return aView;
        }
        return nil;
    }
    @catch (NSException *exception) {
        logException(@"LegMapViewController -> viewForOverlay", @"", exception);
    }
}

/* Implemented by Sitanshu Joshi
 To show Direction at  
 */



#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];        
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger) supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    @try {
        if ([request isGET]) {       
            RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
            id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];                
            twitterViewController *twit = [[twitterViewController alloc] init];
            [twit setTwitterLiveData:res];
            [[self navigationController] pushViewController:twit animated:YES];     
        } 
        
    }  @catch (NSException *exception) {
        logException(@"LegMapViewController -> didLoadResponse", @"", exception);
    } 
}


// Callback for providing any annotation views
- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]){
        return nil;
    }       
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
        else if([dotAnnotationArray containsObject:annotation]){
            MKAnnotationView* dotView = (MKAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"IntermediateAnnotation"];
            
            if (!dotView)
            {
                // If an existing pin view was not available, create one.
                dotView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                       reuseIdentifier:@"IntermediateAnnotation"];
                if (!dotImage) {
                    NSString* imageName = [[NSBundle mainBundle] pathForResource:LEGMAP_DOT_IMAGE_FILE ofType:@"png"];
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
        // Otherwise, use the dot view controller
        else {
            MKAnnotationView* dotView = (MKAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"MyDotAnnotationView"];
            
            if (!dotView)
            {
                // If an existing pin view was not available, create one.
                dotView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                       reuseIdentifier:@"MyDotAnnotation"];
                dotView.canShowCallout=YES;
                if (!pinImage) {
                    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"pin" ofType:@"png"];
                    pinImage = [UIImage imageWithContentsOfFile:imageName];
                }
                if (pinImage) {
                    [dotView setImage:pinImage];
                }
            }
            else
                dotView.annotation = annotation;
            
            return dotView;
        }
    }
    return nil;
}

@end