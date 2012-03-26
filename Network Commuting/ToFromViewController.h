//
//  ToFromViewController.h
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import "Locations.h"
#import "Plan.h"
#import "enums.h"

@interface ToFromViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKObjectLoaderDelegate>
{
    NSDateFormatter *tripDateFormatter;  // Formatter for showing the trip date / time
    NSString *toRawAddress;    // user entered To address
    NSString *toURLResource;   // URL resource sent to geocoder for the to address
    NSString *fromRawAddress;  // user entered From address
    NSString *fromURLResource; // URL resource sent to geocoder for the from address
    NSString *planURLResource; // URL resource sent to planner
    UITableViewCell *toSelectedCell; // Cell currently selected on To view table
    UITableViewCell *fromSelectedCell;  // Cell currently selected on the From view table
    NSMutableArray *planRequestHistory; // Array of all the past plan request parameter histories in sequential order (most recent one last)
    Plan *plan;
    BOOL routeRequested;   // True when the user has pressed the route button and a route has not yet been requested
    NSManagedObjectContext *managedObjectContext;
}
@property (strong, nonatomic) IBOutlet UITableView* timeDateTable;
@property (strong, nonatomic) IBOutlet UITextField *fromField;
@property (strong, nonatomic) IBOutlet UITextField *toField;
@property (strong, nonatomic) IBOutlet UITableView *fromAutoFill;
@property (strong, nonatomic) IBOutlet UITableView *toAutoFill;
@property (strong, nonatomic) IBOutlet UIButton *routeButton;
@property (strong, nonatomic) RKObjectManager *rkGeoMgr;  // RestKit Object Manager for geocoding
@property (strong, nonatomic) RKObjectManager *rkPlanMgr;  // RestKit object manager for trip planning
@property (strong, nonatomic) Locations *locations;  // Wrapper for collection of all Locations
@property (strong, nonatomic, readonly) Location *fromLocation;
@property (strong, nonatomic, readonly) Location *toLocation;
@property (nonatomic) DepartOrArrive departOrArrive;  // True if routing from departure time, false if by arrival time
@property (strong, nonatomic) NSDate *tripDate;

- (IBAction)toFromTyping:(id)sender forEvent:(UIEvent *)event;
- (IBAction)toFromTextSubmitted:(id)sender forEvent:(UIEvent *)event;
- (IBAction)routeButtonPressed:(id)sender forEvent:(UIEvent *)event;
- (IBAction)toFieldFocus:(id)sender forEvent:(UIEvent *)event;
- (BOOL)getPlan;

@end
