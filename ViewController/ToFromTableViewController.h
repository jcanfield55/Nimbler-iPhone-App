//
//  ToFromTableViewController.h
//  Nimbler
//
//  Created by John Canfield on 5/6/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
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
#import "Stations.h"

@class ToFromViewController;

@interface ToFromTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,LocationsGeocodeResultsDelegate,UITextFieldDelegate,UITextViewDelegate>

@property (nonatomic, unsafe_unretained) ToFromViewController* toFromVC;  // Parent view controller
@property (strong, nonatomic) RKObjectManager *rkGeoMgr;  // RestKit Object Manager for geocoding
@property (strong, nonatomic) Locations *locations;  // Wrapper for collection of all Locations
@property (nonatomic) BOOL isFrom;   // True if this is the fromTable, false if it is the toTable
@property (strong, nonatomic) IBOutlet UITableView* myTableView;  // Table View we are controlling
@property (strong, nonatomic) UITextField* txtField;
@property (strong, nonatomic) SupportedRegion* supportedRegion; // Geographic area supported by this app

// Items copied over from ToFromViewController.xib
@property (strong, nonatomic) IBOutlet UIView* fromView;
@property (strong, nonatomic) IBOutlet UIImageView* imgViewFromBG;
@property (strong, nonatomic) IBOutlet UIImageView* imgViewMainToFromBG;
@property (strong, nonatomic) IBOutlet UIView* mainToFromView;
@property (strong, nonatomic) IBOutlet UITextView* txtFromView;

@property (strong, nonatomic) IBOutlet UIButton* btnToFromEditCancel;


@property (strong, nonatomic) Stations *stations;
@property (nonatomic) BOOL isDeleteMode;
@property (nonatomic) BOOL isRearrangeMode;
@property (nonatomic) BOOL isRenameMode;
@property (strong, nonatomic) UIButton *btnEdit;
@property (nonatomic) int currentRowIndex;
@property (strong, nonatomic) UITextView *cellTextView;

// Textlabel that is separate from myTableView where text is entered
- (void)setupIsFrom:(BOOL)isF toFromVC:(ToFromViewController *)tfVC locations:(Locations *)l;
- (IBAction)toFromTyping:(id)sender forEvent:(UIEvent *)event;
- (IBAction)textSubmitted:(id)sender forEvent:(UIEvent *)event;
- (IBAction)editCancelClicked:(id)sender;


- (void)initializeCurrentLocation:(Location *)currentLoc; // Method called when currentLocation is first created and automatically picked as the fromLocation

// Method called by LocationPickerVC when a user picks a location
// Picks the location and clears out any other Locations in the list with to & from frequency = 0.0
- (void)setPickedLocation:(Location *)ploc locationArray:(NSArray *)locationArray isGeocodedResults:(BOOL)isGeocodedResult;

// Method to process a new incoming location from an IOS directions request
- (void)newDirectionsRequestLocation:(Location *)location;

- (void)markAndUpdateSelectedLocation:(Location *)loc;
-(BOOL)alertUsetForLocationService;

// Reload myTableView using MkLocalSearchResponse
-(void)reloadLocationWithLocalSearch;

- (void)editButtonClicked:(id)sender;
- (void)deleteButtonClicked:(id)sender;

@end
