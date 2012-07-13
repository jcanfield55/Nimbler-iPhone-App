//
//  LocationPickerViewController.h
//  Nimbler
//
//  Created by John Canfield on 6/8/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

// This View Controller displays a list of locations for the user to choose from
// It is brought up when the Geocoder returns multiple matching locations

#import <UIKit/UIKit.h>
#import "ToFromViewController.h"
#import "ToFromTableViewController.h"

@interface LocationPickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView* mainTable;  // table showing locations to pick
@property (strong, nonatomic) IBOutlet UIButton *feedbackButton;
@property (nonatomic, unsafe_unretained) ToFromTableViewController* toFromTableVC; // tableVC that sent the locations for picking
@property (strong, nonatomic) NSArray* locationArray; // array of locations to pick from
@property (nonatomic) BOOL isFrom;  // Whether this is for the From field or the To field
@property (nonatomic) BOOL isGeocodeResults;  // True if the location picker called to disambiguate geocode results.  Falso if called to choose from a list.  

- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event;

@end
