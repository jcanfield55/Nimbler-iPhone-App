//
//  RouteOptionsViewController.h
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Plan.h"

@interface RouteOptionsViewController : UITableViewController
{
    NSDateFormatter *timeFormatter;
}
@property(nonatomic, strong) Plan *plan;

@end
