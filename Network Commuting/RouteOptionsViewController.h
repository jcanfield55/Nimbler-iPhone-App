//
//  RouteOptionsViewController.h
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Plan.h"
#import "RouteDetailsViewController.h"

@interface RouteOptionsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKRequestDelegate>
{
    NSDateFormatter *timeFormatter;
}
@property(nonatomic, strong) IBOutlet UITableView* mainTable; // Table listing route options
@property(nonatomic, strong) IBOutlet UIButton* feedbackButton; 
@property(nonatomic, strong) IBOutlet UIButton* advisoryButton;  // Button to pull up Twitter feeds
@property(nonatomic, strong) Plan *plan;

@property(strong, nonatomic) id liveData;
@property( readwrite) BOOL isReloadRealData;
@property (strong, nonatomic) CustomBadge *twitterCount;


- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event;
- (IBAction)advisoryButtonPressed:(id)sender forEvent:(UIEvent *)event;

-(void)sendRequestForFeedback:(RKParams*)para;
-(void)setLiveFeed:(id)liveFeed;
- (void) setRealtimeData:(NSString *)legId arrivalTime:(NSString *)arrivalTime arrivalFlag:(NSString *)arrivalFlag itineraryId:(NSString *)ititId itineraryArrivalFlag:(NSString *)itinArrivalflag legDiffMins:(NSString *)timeDiff;

@end