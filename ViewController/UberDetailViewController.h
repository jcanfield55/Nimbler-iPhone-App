//
//  UberDetailViewController.h
//  Nimbler SF
//
//  Created by John Canfield on 9/12/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItineraryFromUber.h"
#import "Plan.h"

@interface UberDetailViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView* mainTable;  // table showing locations to pick
@property (strong, nonatomic) ItineraryFromUber *uberItin;
@property (strong, nonatomic) Plan *plan;
@property (nonatomic, strong) IBOutlet UIButton *btnFeedBack;
@property(nonatomic, strong) UIButton *btnGoToItinerary;

- (IBAction)feedBackClicked:(id)sender;
-(void)popOutToItinerary;
@end
