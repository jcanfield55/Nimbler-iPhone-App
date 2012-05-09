//
//  LegMapViewController.h
//  Network Commuting
//
//  Created by John Canfield on 3/23/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h> 
#import "Itinerary.h"
#import "Leg.h"


@interface LegMapViewController : UIViewController {
    MKPointAnnotation* startPoint;  // annotation for startPoint of the itinerary
    MKPointAnnotation* endPoint;    // annotation for the endPoint of the itinerary
    NSMutableArray* polyLineArray;       // Array of polylines for each leg
    UIImage* dotImage;
}

@property(nonatomic, strong) IBOutlet MKMapView *mapView;
@property(nonatomic, strong) IBOutlet UIView *directionsView;
@property(nonatomic, strong) IBOutlet UILabel *directionsTitle;
@property(nonatomic, strong) IBOutlet UILabel *directionsDetails;
@property (strong, nonatomic) IBOutlet UIButton *feedbackButton;
@property(nonatomic, strong, readonly) Itinerary *itinerary;
@property(nonatomic, readonly) int itineraryNumber;

// Set the LegMapView to display an itinerary leg specified in itineraryNumber
// Note:  num = 0 is the startpoint.  num=1 is the first leg.  
// num = [[itin sortedLegs] count]+1 is the endpoint
- (void)setItinerary:(Itinerary *)itin itineraryNumber:(int)num;

// Callback for when user presses the navigate back / forth button on the right navbar
- (IBAction)navigateBack:(id)sender;
- (IBAction)navigateForward:(id)sender;
- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event;
//Implemented by Sitanshu Joshi
- (IBAction)navigateStart:(id)sender;
-(void)walk;

@end
