//
//  UberDetailViewController.h
//  Nimbler SF
//
//  Created by John Canfield on 9/12/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UberDetailViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView* mainTable;  // table showing locations to pick



@end
