//
//  ToFromViewController.h
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import "ToFromTableViewController.h"
#import "Locations.h"
#import "Plan.h"
#import "enums.h"

@interface ToFromViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKObjectLoaderDelegate>

@property (strong, nonatomic) IBOutlet UITableView* mainTable;  // grouped table for main page layout
@property (strong, nonatomic) UITableView *fromTable;  // from table embedded in mainTable
@property (strong, nonatomic) ToFromTableViewController* fromTableVC; // View controller for fromTable
@property (strong, nonatomic) UITableView *toTable;   // to table embedded in mainTable
@property (strong, nonatomic) ToFromTableViewController* toTableVC;  // View controller for toTable
@property (strong, nonatomic) IBOutlet UIButton *routeButton;
@property (strong, nonatomic) IBOutlet UIButton *feedbackButton;
@property (strong, nonatomic) RKObjectManager *rkGeoMgr;  // RestKit Object Manager for geocoding
@property (strong, nonatomic) RKObjectManager *rkPlanMgr;  // RestKit object manager for trip planning
@property (strong, nonatomic) Locations *locations;  // Wrapper for collection of all Locations
@property (strong, nonatomic) Location *fromLocation;
@property (strong, nonatomic) Location *toLocation;
@property (strong, nonatomic) Location *currentLocation;
@property (nonatomic) DepartOrArrive departOrArrive;  // whether trip is planned based on departure time or desired arrival time
@property (strong, nonatomic) NSDate *tripDate;
@property (strong, nonatomic) NSDate *tripDateLastChangedByUser;
@property (strong, nonatomic) UIAlertView * connecting;
@property (strong, nonatomic) RKObjectManager *rkBayArea;  // RestKit object manager for trip bay area

- (IBAction)routeButtonPressed:(id)sender forEvent:(UIEvent *)event;
- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event;

- (void)updateToFromLocation:(id)sender isFrom:(BOOL)isFrom location:(Location *)loc; // Callback from ToFromTableViewController to update a new user entered/selected location
- (void)updateGeocodeStatus:(BOOL)isGeocodeOutstanding isFrom:(BOOL)isFrom; // Callback from ToFromTableViewController to update geocoding status

typedef enum {
    UP,
    DOWN
} moveToTableDirection;

- (void)moveToTable:(moveToTableDirection)direction; // Moves To Table up or down for keyboard entry
- (void)updateTripDate;
-(UIAlertView *) WaitPrompt;
@end
