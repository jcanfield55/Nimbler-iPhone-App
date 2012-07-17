//
//  RouteDetailsViewController.h
//  Network Commuting
//
//  Created by John Canfield on 2/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h> 
#import "Itinerary.h"
#import "LegMapViewController.h"

@interface RouteDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,RKRequestDelegate>
{
    NSDateFormatter *timeFormatter;
    UIBarButtonItem *twitterCaltrain;    
}
@property(nonatomic, strong) IBOutlet UITableView* mainTable; // Table listing route details
@property(nonatomic, strong) MKMapView *mapView; 
@property(nonatomic, strong) IBOutlet UIButton* feedbackButton; 
@property(nonatomic, strong) IBOutlet UIButton* advisoryButton;  // Button to pull up Twitter feeds
@property(nonatomic, strong) LegMapViewController* legMapVC; // View Controller for managing the map
@property(nonatomic, strong) Itinerary *itinerary;
@property(nonatomic) int itineraryNumber; // selected row on the itinerary list
@property(strong, nonatomic) CustomBadge *twitterCount;
@property(nonatomic, readonly) CGFloat mainTableTotalHeight;  // the total height (height needed so that no scrolling needed) of the mainTable in pixels for a given itinerary

- (IBAction)navigateBack:(id)sender;
- (IBAction)navigateForward:(id)sender;
- (IBAction)advisoryButtonPressed:(id)sender forEvent:(UIEvent *)event;
- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event;
-(void)ReloadLegWithNewData;

@end