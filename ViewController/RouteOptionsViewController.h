//
//  RouteOptionsViewController.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Plan.h"
#import "enums.h"
#import "RouteDetailsViewController.h"
#import "RouteMapViewController.h"

@interface RouteOptionsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKRequestDelegate>

@property(nonatomic, strong) IBOutlet UITableView* mainTable; // Table listing route options
@property(nonatomic, strong) Plan *plan;
@property(nonatomic, strong) UIButton *btnGoToNimbler;
@property(strong, nonatomic) id liveData;
@property( readwrite) BOOL isReloadRealData;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *btnMap;

-(void)setLiveFeed:(id)liveFeed;
- (void) setRealtimeData:(NSString *)legId arrivalTime:(NSString *)arrivalTime arrivalFlag:(NSString *)arrivalFlag itineraryId:(NSString *)ititId itineraryArrivalFlag:(NSString *)itinArrivalflag legDiffMins:(NSString *)timeDiff;
-(void)hideUnUsedTableViewCell;
-(void)setFBParameterForPlan;
-(void)popOutToNimbler;

// Call-back from PlanStore requestPlanFromLocation:... method when it has a plan
-(void)newPlanAvailable:(Plan *)newPlan status:(PlanRequestStatus)status;
@end