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

@interface RouteOptionsViewController : UITableViewController<RKRequestDelegate>
{
    NSDateFormatter *timeFormatter;
    UIBarButtonItem *feedback;
}
@property(nonatomic, strong) Plan *plan;
@property(nonatomic, strong) Plan *feedBackPlanId ;

-(void)sendRequestForTimingDelay;
@end
