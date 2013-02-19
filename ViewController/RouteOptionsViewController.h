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

@interface RouteOptionsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKRequestDelegate>{
    Plan *plan;
}

@property(nonatomic, strong) IBOutlet UITableView* mainTable; // Table listing route options
@property(nonatomic, strong) Plan *plan;
@property(nonatomic, strong) UIButton *btnGoToNimbler;
@property( readwrite) BOOL isReloadRealData;
@property(nonatomic, strong) IBOutlet UIButton* button1b;
@property(nonatomic, strong) IBOutlet UIButton* button1c;
@property(nonatomic, strong) IBOutlet UIButton* button1d;
@property(nonatomic, strong) IBOutlet UIButton* button2a;
@property(nonatomic, strong) IBOutlet UIButton* button2b;
@property(nonatomic, strong) IBOutlet UIButton* button2c;
@property(nonatomic, strong) IBOutlet UIButton* button2d;

- (IBAction)excludeButtonPressed:(id)sender forEvent:(UIEvent *)event;

-(void)hideUnUsedTableViewCell;
-(void)setFBParameterForPlan;
-(void)popOutToNimbler;

// Call-back from PlanStore requestPlanFromLocation:... method when it has a plan
-(void)newPlanAvailable:(Plan *)newPlan status:(PlanRequestStatus)status;

- (void) reloadData:(Plan *)newPlan;
-(void) toggleFirstButton:(id)sender;
-(void) toggleSecondButton:(id)sender;
@end
