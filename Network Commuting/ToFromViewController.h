//
//  ToFromViewController.h
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import "Location.h"

@interface ToFromViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKObjectLoaderDelegate>
{
    NSString *toRawAddress;
    NSString *toURLResource;
    NSString *fromRawAddress;
    NSString *fromURLResource;
}
@property (strong, nonatomic) IBOutlet UITextField *fromField;
@property (strong, nonatomic) IBOutlet UITextField *toField;
@property (strong, nonatomic) IBOutlet UITableView *fromAutoFill;
@property (strong, nonatomic) IBOutlet UITableView *toAutoFill;
@property (strong, nonatomic) RKObjectManager *rkGeoMgr;  // RestKit Object Manager for geocoding
@property (strong, nonatomic) NSMutableDictionary *locations;  // Dictionary of all stored Locations, formattedAddress is the key
@property (strong, nonatomic, readonly) Location *fromLocation;
@property (strong, nonatomic, readonly) Location *toLocation;

- (IBAction)toFromTextEntry:(id)sender forEvent:(UIEvent *)event;

@end
