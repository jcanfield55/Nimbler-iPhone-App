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
#import "PlanStore.h"

@interface RouteOptionsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKRequestDelegate,
NewPlanAvailableDelegate>

@property(nonatomic, strong) IBOutlet UITableView* mainTable; // Table listing route options
@property(nonatomic, strong) IBOutlet UILabel* noItineraryWarning;  
@property(nonatomic, strong, readonly) Plan *plan;  // use newPlanAvailable method to update the plan
@property(nonatomic, strong) UIButton *btnGoToNimbler;
@property( readwrite) BOOL isReloadRealData;
@property (nonatomic, strong) PlanRequestParameters *planRequestParameters;
@property(nonatomic, strong) RouteDetailsViewController* routeDetailsVC;
@property(nonatomic, strong) PlanStore* planStore;


-(void)hideUnUsedTableViewCell;
-(void)setFBParameterForPlan;
-(void)popOutToNimbler;

- (void) reloadData:(Plan *)newPlan;
-(void) toggleExcludeButton:(id)sender;

- (int) calculateTotalHeightOfButtonView;
- (void) createViewWithButtons:(int)height;
- (void) changeMainTableSettings;

@end
