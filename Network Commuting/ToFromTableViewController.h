//
//  ToFromTableViewController.h
//  Nimbler
//
//  Created by John Canfield on 5/6/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

// ToFromTableViewController objects control either a To or a From TableView for the 
// ToFromViewController. 
// If a user enters a new address, this object will submit for geocoding and handle the response
// It is the callback delegate for the table, for the text entry, and for geocoding results
// It communicates back to ToFromViewController by calling its methods.  

#import <UIKit/UIKit.h> 
#import <RestKit/RestKit.h>
#import "Locations.h"
#import "Location.h"
#import "SupportedRegion.h"

@class ToFromViewController;

@interface ToFromTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKObjectLoaderDelegate>

@property (nonatomic, unsafe_unretained) ToFromViewController* toFromVC;  // Parent view controller
@property (strong, nonatomic) RKObjectManager *rkGeoMgr;  // RestKit Object Manager for geocoding
@property (strong, nonatomic) Locations *locations;  // Wrapper for collection of all Locations
@property (nonatomic) BOOL isFrom;   // True if this is the fromTable, false if it is the toTable
@property (strong, nonatomic) UITableView* myTableView;  // Table View we are controlling
@property (strong, nonatomic) UITextField* txtField;  
// Textlabel that is separate from myTableView where text is entered
- (id)initWithTable:(UITableView *)t isFrom:(BOOL)isF toFromVC:(ToFromViewController *)tfVC locations:(Locations *)l;
- (IBAction)toFromTyping:(id)sender forEvent:(UIEvent *)event;
- (IBAction)textSubmitted:(id)sender forEvent:(UIEvent *)event;

-(void)setBayAreas:(SupportedRegion *)bayAreaRegion;
-(BOOL)isValidRegion:(Location *)location;
@end
