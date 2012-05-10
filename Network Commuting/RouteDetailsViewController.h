//
//  RouteDetailsViewController.h
//  Network Commuting
//
//  Created by John Canfield on 2/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#
#import "Itinerary.h"

@interface RouteDetailsViewController : UITableViewController
{
    NSDateFormatter *timeFormatter;
}
@property(nonatomic, strong) Itinerary *itinerary;

@end
