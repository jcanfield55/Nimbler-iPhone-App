//
//  RouteDetailsViewController.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/25/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
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
@property(nonatomic, strong) LegMapViewController* legMapVC; // View Controller for managing the map
@property(nonatomic, strong) Itinerary *itinerary;
@property(nonatomic) int itineraryNumber; // selected row on the itinerary list
@property(nonatomic, readonly) CGFloat mainTableTotalHeight;  // the total height (height needed so that no scrolling needed) of the mainTable in pixels for a given itinerary

@property(nonatomic, strong)  UIButton *btnBackItem;
@property(nonatomic, strong)  UIButton *btnForwardItem;
@property(nonatomic, strong)  UIButton *btnGoToItinerary;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) int count;
@property (nonatomic, strong) IBOutlet UILabel *lblNextRealtime;
@property (nonatomic, strong) IBOutlet UIImageView *realTimeImageView;

- (IBAction)navigateBack:(id)sender;
- (IBAction)navigateForward:(id)sender;
-(void)ReloadLegWithNewData;
-(void)setFBParameterForItinerary;
-(void)popOutToItinerary;
-(void)setFBParamater:(int)ss;
-(void)setFBParameterForLeg:(NSString *)legId;
-(void)newItineraryAvailable:(Itinerary *)newItinerary
status:(ItineraryStatus)status ItineraryNumber:(int)itiNumber;
- (void) intermediateStopTimesReceived:(NSArray *)stopTimes Leg:(Leg *)leg;
- (void) setViewFrames;

// return Formatted string like 00:58
- (NSString *) returnFormattedStringFromSeconds:(int) seconds;;
@end