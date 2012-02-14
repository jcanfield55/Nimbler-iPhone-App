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

@interface ToFromViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKObjectLoaderDelegate>
{
    NSString *toRawAddress;
    NSString *toURLResource;
    NSString *fromRawAddress;
    NSString *fromURLResource;
    NSString *planURLResource;
    Plan *plan;
    bool routeRequested;   // True when the user has pressed the route button and a route has not yet been requested
    NSManagedObjectContext *managedObjectContext;
}
@property (strong, nonatomic) IBOutlet UITextField *fromField;
@property (strong, nonatomic) IBOutlet UITextField *toField;
@property (strong, nonatomic) IBOutlet UITableView *fromAutoFill;
@property (strong, nonatomic) IBOutlet UITableView *toAutoFill;
@property (strong, nonatomic) RKObjectManager *rkGeoMgr;  // RestKit Object Manager for geocoding
@property (strong, nonatomic) RKObjectManager *rkPlanMgr;  // RestKit object manager for trip planning
@property (strong, nonatomic) Locations *locations;  // Wrapper for collection of all Locations
@property (strong, nonatomic, readonly) Location *fromLocation;
@property (strong, nonatomic, readonly) Location *toLocation;

- (IBAction)toFromTextEntry:(id)sender forEvent:(UIEvent *)event;
- (bool)getPlan;

@end
