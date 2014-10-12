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
#import <CoreImage/CoreImageDefines.h>
#import "nc_AppDelegate.h"
#import "Leg.h"
#import "Itinerary.h"
#import "GtfsStopTimes.h"
#import "IntermediateStops.h"
#import "RealTimeManager.h"

#define ARRIVAL @"Arrival"
#define LIST_VEHICLE_POSITIONS @"lstVehiclePositions"
#define BUS  @"bus"
#define TRAM @"tram"
#define VEHICLE @"Vehicle"
#define VEHICLE_ID @"vehicleId"
#define ROUTE  @"Route"
#define ROUTE_SHORT_NAME @"routeShortName"
#define HEADSIGN  @"headsign"
#define LATITUDE  @"lat"
#define LONGITUDE @"lon"

@interface LegMapViewController() {
    // Internal variables
    MKPointAnnotation* startPoint;  // annotation for startPoint of the itinerary
    MKPointAnnotation* endPoint;    // annotation for the endPoint of the itinerary
    NSMutableArray* polyLineArray;  // Array of polylines for each element in legDescriptionTitleSortedArray
    NSMutableArray* dotAnnotationArray;  // Array of all dot annotations
    NSMutableArray* intermediateAnnotations;
    NSMutableArray * legStartEndPoint;
    NSMutableArray *movingAnnotations;
    UIImage* dotImage;
    UIImage* pinImage;
    UIImage* busImage;
    UIImage* tramImage;
    
    NSDateFormatter *dateFormatter;
    
    
}

// Utility routine for setting the region on the MapView based on the itineraryNumber
@end

@implementation LegMapViewController

@synthesize itinerary;
@synthesize itineraryNumber;
@synthesize mapView;
@synthesize timerVehiclePosition;

NSString *legID;

- (id)initWithMapView:(MKMapView *)m0
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        mapView = m0;
        polyLineArray = [NSMutableArray arrayWithCapacity:10];
        dotAnnotationArray = [NSMutableArray arrayWithCapacity:10];
        intermediateAnnotations = [[NSMutableArray alloc] init];
        legStartEndPoint = [[NSMutableArray alloc] init];
        movingAnnotations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setItinerary:(Itinerary *)itin
{
    @try {
        if (itin != itinerary) {  // if something actually changed...
            itinerary = itin;  
            
            if(self.timerVehiclePosition){
                [self.timerVehiclePosition invalidate];
                self.timerVehiclePosition = nil;
            }
            [self requestVehicleDataFromServer];
            self.timerVehiclePosition =  [NSTimer scheduledTimerWithTimeInterval:TIMER_MEDIUM_REQUEST_DELAY target:self selector:@selector(requestVehicleDataFromServer) userInfo:nil repeats: YES];
            
            // Clear out any previous overlays and annotations
           // Fixed DE-307.
            [mapView removeAnnotations:legStartEndPoint];
            [mapView removeAnnotations:dotAnnotationArray];
            [mapView removeOverlays:polyLineArray];
            [mapView removeAnnotations:intermediateAnnotations];
            [dotAnnotationArray removeAllObjects];
            [polyLineArray removeAllObjects];
            [legStartEndPoint removeAllObjects];
            [intermediateAnnotations removeAllObjects];
            
            NSArray *sortedLegs = [itinerary sortedLegs];
            if(itinerary.isRealTimeItinerary){
                [[nc_AppDelegate sharedInstance].gtfsParser requestStopTimesDataForParticularTripFromServer:itinerary];
            }
            else{
               [self performSelector:@selector(addIntermediateStationsToMapView:) withObject:sortedLegs afterDelay:1.0]; 
            }
            if (!dateFormatter) {
                dateFormatter = [[NSDateFormatter alloc]init];
                [dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"hh:mm a" options:0 locale:[NSLocale currentLocale]]];
            }
            for(int i=0;i<[sortedLegs count];i++){
                MKPointAnnotation *fromPoint = [[MKPointAnnotation alloc] init];
                MKPointAnnotation *toPoint = [[MKPointAnnotation alloc] init];
                Leg *startLeg = [sortedLegs objectAtIndex:i];
                    float fromLat = [startLeg.from.lat floatValue];
                    float fromLng = [startLeg.from.lng floatValue];
                    CLLocationCoordinate2D fromCoordinate = CLLocationCoordinate2DMake(fromLat, fromLng);
                    [fromPoint setCoordinate:fromCoordinate];
                    
                    
                    float toLat = [startLeg.to.lat floatValue];
                    float toLng = [startLeg.to.lng floatValue];
                    CLLocationCoordinate2D toCoordinate = CLLocationCoordinate2DMake(toLat, toLng);
                    [toPoint setCoordinate:toCoordinate];
                
                if(startLeg.isScheduled){
                    [fromPoint setTitle:startLeg.from.name];
                    NSDate *arrivalTime = startLeg.startTime;
                    NSString *arrivalTimeString = [dateFormatter stringFromDate:arrivalTime];
                    [fromPoint setSubtitle:[NSString stringWithFormat:@"%@: %@",ARRIVAL,arrivalTimeString]];
                    [toPoint setTitle:startLeg.to.name];
                    NSDate *toArrivalTime = startLeg.endTime;
                    NSString *toArrivalTimeString = [dateFormatter stringFromDate:toArrivalTime];
                    [toPoint setSubtitle:[NSString stringWithFormat:@"%@: %@",ARRIVAL,toArrivalTimeString]];
                }
                else if(startLeg.isBike && startLeg.rentedBike){
                    if(i-1 >= 0){
                        Leg *previoueLeg = [sortedLegs objectAtIndex:i-1];
                        if(!previoueLeg.rentedBike){
                            [fromPoint setTitle:startLeg.from.name];
                            [fromPoint setSubtitle:@"Capital BikeShare Station"];
                        }
                    }
                    if([sortedLegs count] >= i + 1){
                        Leg *nextLeg = [sortedLegs objectAtIndex:i+1];
                        if(!nextLeg.rentedBike){
                            [toPoint setTitle:startLeg.to.name];
                            [toPoint setSubtitle:@"Capital BikeShare Station"];
                        }
                    }
                }
                [legStartEndPoint addObject:toPoint];
                [mapView addAnnotation:toPoint];
                [legStartEndPoint addObject:fromPoint];
                [mapView addAnnotation:fromPoint];
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

- (void) addIntermediateStationsToMapView:(NSArray *)sortedLegs{
    @try {
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"hh:mm a" options:0 locale:[NSLocale currentLocale]]];
        }
        for(int i=0;i<[sortedLegs count];i++){
            Leg *leg = [sortedLegs objectAtIndex:i];
            NIMLOG_PERF2(@"tripId=%@",leg.realTripId);
            NIMLOG_PERF2(@"fromStopId=%@",leg.from.stopId);
            NIMLOG_PERF2(@"toStopId=%@",leg.to.stopId);
            if(leg.isScheduled){
                if(!leg.isRealTimeLeg){
                    for(IntermediateStops *stop in leg.intermediateStops){
                        float langcoord = [stop.lat floatValue];
                        float longcoord = [stop.lon floatValue];
                        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(langcoord, longcoord);
                        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
                        [point setCoordinate:coord];
                        [point setTitle:stop.name];
                        NSDate *arrivalTime = [NSDate dateWithTimeIntervalSince1970:([stop.arrivalTime doubleValue]/1000.0)];
                        NSString *arrivalTimeString = [dateFormatter stringFromDate:arrivalTime];
                        [point setSubtitle:[NSString stringWithFormat:@"%@: %@",ARRIVAL,arrivalTimeString]];
                        [intermediateAnnotations addObject:point];
                        [mapView addAnnotation:point];
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"LegMapVC->addIntermediateStationsToMapView", @"", exception);
    }
}

- (void) addIntermediateStops:(NSArray *)stopTimes Leg:(Leg *)leg{
    //[mapView removeAnnotations:intermediateAnnotations];
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"hh:mm a" options:0 locale:[NSLocale currentLocale]]];
    }
    for(int k=0;k<[stopTimes count];k++){
        GtfsStopTimes *stopTime = [stopTimes objectAtIndex:k];
        GtfsStop *stop = [[nc_AppDelegate sharedInstance].gtfsParser fetchStopsFromStopId:stopTime.stopID];
        float langcoord = [stop.stopLat floatValue];
        float longcoord = [stop.stopLon floatValue];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(langcoord, longcoord);
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        [point setCoordinate:coord];
        [point setTitle:stop.stopName];
        if(stopTime.arrivalTime && ![stopTime.arrivalTime isEqualToString:@""]){
            NSDate *arrivalTime = dateFromTimeString(stopTime.arrivalTime);
            NSDate *realArrivalTime = nil;
            realArrivalTime =  [arrivalTime dateByAddingTimeInterval:(leg.timeDiff * 60)];
            NSString *arrivalTimeString;
            if(realArrivalTime){
                arrivalTimeString = [dateFormatter stringFromDate:realArrivalTime];
            }
            else{
                arrivalTimeString = [dateFormatter stringFromDate:arrivalTime];
            }
            [point setSubtitle:[NSString stringWithFormat:@"%@: %@",ARRIVAL,arrivalTimeString]];
        }
        [intermediateAnnotations addObject:point];
        [mapView addAnnotation:point];
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
            [mapView addOverlay:[polyLineArray objectAtIndex:itineraryNumber]];
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
            aView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:MAP_ALPHA_LIGHTER];
            aView.lineWidth = MAP_LINE_WIDTH;
            NIMLOG_EVENT1(@"itineraryNumber=%d",itineraryNumber);
            
            // Determine if this overlay is the one in focus.  If so, make it darker
            for (int i=0; i<[polyLineArray count]; i++) {
                if (([polyLineArray objectAtIndex:i] == overlay)) {
                    if (i == itineraryNumber) {
                        Leg *leg  = [[itinerary legDescriptionToLegMapArray] objectAtIndex:itineraryNumber];
                        if([leg isWalk] || [leg isBike]){
                            aView.strokeColor = [[UIColor blackColor] colorWithAlphaComponent:MAP_ALPHA_LIGHT] ;
                            aView.lineWidth = MAP_LINE_WIDTH;
                        } else if([leg isBus]){
                            aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:MAP_ALPHA_LIGHT];
                            aView.lineWidth = MAP_LINE_WIDTH;
                        } else if([leg isTrain]){                        
                            aView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:MAP_ALPHA_MEDIUM] ;
                            aView.lineWidth = MAP_LINE_WIDTH;
                        } else {
                            aView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:MAP_ALPHA_MEDIUM] ;
                            aView.lineWidth = MAP_LINE_WIDTH;
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

- (UIImage *)scale:(UIImage *)image toSize:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
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
        if (startPoint == annotation || endPoint == annotation) {
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
        else if([legStartEndPoint containsObject:annotation]){
            MKAnnotationView* dotView = (MKAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"IntermediateAnnotation"];
            
            if (!dotView)
            {
                // If an existing pin view was not available, create one.
                dotView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                       reuseIdentifier:@"IntermediateAnnotation"];
                dotView.canShowCallout = YES;
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
        else if([intermediateAnnotations containsObject:annotation]){
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
        
        else if([movingAnnotations containsObject:annotation]){
            MKAnnotationView* dotView = (MKAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"MyMovingAnnotationView"];
            if(!dotView){
                // If an existing pin view was not available, create one.
                dotView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                       reuseIdentifier:@"MyMovingAnnotationView"];
            }
            else{
                [dotView setAnnotation:annotation];
            }
            [mapView bringSubviewToFront:dotView];
                dotView.canShowCallout=YES;
                MKPointAnnotation *anno = (MKPointAnnotation *)annotation;
                if([anno.accessibilityLabel isEqualToString:@"bus"]){
                    if (!busImage) {
                        NSString* imageName = [[NSBundle mainBundle] pathForResource:@"bus" ofType:@"png"];
                        busImage = [self scale:[UIImage imageWithContentsOfFile:imageName] toSize:CGSizeMake(25,26)];
                    }
                    if (busImage) {
                        [dotView setImage:busImage];
                    }
                }
                else{
                    if (!tramImage) {
                        NSString* imageName = [[NSBundle mainBundle] pathForResource:@"tram" ofType:@"png"];
                        tramImage = [self scale:[UIImage imageWithContentsOfFile:imageName] toSize:CGSizeMake(25,26)];
                    }
                    if (tramImage) {
                        [dotView setImage:tramImage];
                    }
                }
            return dotView;
        }
        else{
            [mapView removeAnnotation:annotation];
        }
    }
    return nil;
}

// Request realtime data from server
- (void) requestVehicleDataFromServer{
    [[RealTimeManager realTimeManager] requestVehiclePositionForRealTimeLeg:itinerary.sortedLegs];
}
- (void) addVehicleTomapView:(NSArray *)vehiclesData{
    [mapView removeAnnotations:movingAnnotations];
    [movingAnnotations removeAllObjects];
    for(int i=0;i<[vehiclesData count];i++){
        NSDictionary *vehicleDictionary = [vehiclesData objectAtIndex:i];
        NSArray *vehiclePosistions = [vehicleDictionary objectForKey:LIST_VEHICLE_POSITIONS];
        for(int j=0;j<[vehiclePosistions count];j++){
            NSDictionary *tempVehicleDictionary = [vehiclePosistions objectAtIndex:j];
            MKPointAnnotation *movingAnnotation = [[MKPointAnnotation alloc] init];
            NSString *mode = [tempVehicleDictionary objectForKey:MODE];
            if([[mode lowercaseString] isEqualToString:BUS]){
                [movingAnnotation setAccessibilityLabel:BUS];
            }
            else{
                [movingAnnotation setAccessibilityLabel:TRAM];
            }
            NSString *vehicleId = [NSString stringWithFormat:@"%@:%@",VEHICLE,[tempVehicleDictionary objectForKey:VEHICLE_ID]];
            NSString *route = [NSString stringWithFormat:@"%@:%@",ROUTE,[tempVehicleDictionary objectForKey:ROUTE_SHORT_NAME]];
            [movingAnnotation setTitle:[NSString stringWithFormat:@"%@  %@",vehicleId,route]];
            NSString *headSign = [NSString stringWithFormat:@"%@",[tempVehicleDictionary objectForKey:HEADSIGN]];
            [movingAnnotation setSubtitle:headSign];
            float fromLat = [[tempVehicleDictionary objectForKey:LATITUDE] floatValue];
            float fromLng = [[tempVehicleDictionary objectForKey:LONGITUDE] floatValue];
            CLLocationCoordinate2D fromCoordinate = CLLocationCoordinate2DMake(fromLat, fromLng);

            [movingAnnotation setCoordinate:fromCoordinate];
            [movingAnnotations addObject:movingAnnotation];
            [mapView addAnnotation:movingAnnotation];
            
        }
    }
}

// Brings the bus and tram annotations to front and other annotations to back.
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView * annView in views) {
        MKPointAnnotation * ann = (MKPointAnnotation *) [annView annotation];
        if ([movingAnnotations containsObject:ann]) {
            [[annView superview] bringSubviewToFront:annView];
        } else {
            [[annView superview] sendSubviewToBack:annView];
        }
    }
}

- (void) removeMovingAnnotations{
    [mapView removeAnnotations:movingAnnotations];
    [movingAnnotations removeAllObjects];
}
@end