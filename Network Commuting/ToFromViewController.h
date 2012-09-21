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
#import "SupportedRegion.h"


@class PlanStore;

typedef enum {
    NO_EDIT,    // Neither to nor from address is being edited with the keyboard
    FROM_EDIT,  // From address is being edited with the keyboard
    TO_EDIT     // To address is being edited with the keyboard
} ToFromEditMode;


@interface ToFromViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKObjectLoaderDelegate,RKRequestDelegate,UIActionSheetDelegate,UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView* mainTable;  // grouped table for main page layout
@property (strong, nonatomic) UITableView *fromTable;  // from table embedded in mainTable
@property (strong, nonatomic) ToFromTableViewController* fromTableVC; // View controller for fromTable
@property (strong, nonatomic) UITableView *toTable;   // to table embedded in mainTable
@property (strong, nonatomic) ToFromTableViewController* toTableVC;  // View controller for toTable
@property (strong, nonatomic) IBOutlet UIButton *routeButton;
@property (strong, nonatomic) RKObjectManager *rkGeoMgr;  // RestKit Object Manager for geocoding
@property (strong, nonatomic) RKObjectManager *rkPlanMgr;  // RestKit object manager for trip planning
@property (strong, nonatomic) RKObjectManager *rkSavePlanMgr;  // RestKit object manager for trip planning
@property (strong, nonatomic) Locations *locations;  // Wrapper for collection of all Locations
@property (strong, nonatomic) PlanStore *planStore;  // Wrapper for collection of all plans
@property (strong, nonatomic) Location *fromLocation;
@property (strong, nonatomic) Location *toLocation;
@property (strong, nonatomic) Location *currentLocation;
@property (nonatomic) BOOL isCurrentLocationMode;  // true if From: is set to Current Location and we can show a single line From row and a larger toTable
@property (nonatomic) DepartOrArrive departOrArrive;  // whether trip is planned based on departure time or desired arrival time
@property (strong, nonatomic) NSDate *tripDate;
@property (strong, nonatomic) NSDate *tripDateLastChangedByUser;
@property (nonatomic) BOOL isTripDateCurrentTime;  // True if tripDate set to the current date
@property (nonatomic) ToFromEditMode editMode; // Specifies whether to or from address is being edited with the keyboard
@property (strong, nonatomic) SupportedRegion* supportedRegion; // geographic area supported by this app

@property (nonatomic) BOOL isContinueGetRealTimeData;
@property (strong, nonatomic) NSTimer *continueGetTime;


@property (strong, nonatomic) UIToolbar *toolBar;
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (strong, nonatomic) UISegmentedControl *departArriveSelector;
@property (strong, nonatomic) NSDate* date;   
@property (strong, nonatomic) UIBarButtonItem *btnDone;
@property (strong, nonatomic) UIBarButtonItem *btnNow;
@property (nonatomic, strong) Plan *plan;
@property (strong, nonatomic) NSTimer *timerGettingRealDataByItinerary;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicator;

- (IBAction)openPickerView:(id)sender;

- (IBAction)routeButtonPressed:(id)sender forEvent:(UIEvent *)event;

- (void)updateToFromLocation:(id)sender isFrom:(BOOL)isFrom location:(Location *)loc; // Callback from ToFromTableViewController to update a new user entered/selected location
- (void)updateGeocodeStatus:(BOOL)isGeocodeOutstanding isFrom:(BOOL)isFrom; // Callback from ToFromTableViewController to update geocoding status

//Request responder to push a LocationPickerViewController so the user can pick from the locations in locationList
//isGeocodeResults is true if LocationPicker called to disambiguate multiple geocode results, otherwise false
- (void)callLocationPickerFor:(ToFromTableViewController *)toFromTableVC0 locationList:(NSArray *)locationList0 isFrom:(BOOL)isFrom0 isGeocodeResults:(BOOL)isGeocodeResults; 

- (void)updateTripDate;
- (void)reloadTables;  // Reloads the tables in case something has changed in the model

-(BOOL)alertUsetForLocationService;
-(void)getRealTimeData;
-(void)getRealTimeDataForItinerary;
-(NSNumber *)getWalkDistance;
-(void)setFBParameterForGeneral;

// Call-back from PlanStore requestPlanFromLocation:... method when it has a plan
-(void)newPlanAvailable:(Plan *)newPlan status:(PlanRequestStatus)status;

-(void)doSwapLocation;
-(void)requestReverseGeo:(Location *)location;
- (void) hideTabBar;
- (void) showTabbar;
- (void)endEdit;
@end