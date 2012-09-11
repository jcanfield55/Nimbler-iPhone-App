//
//  ToFromViewController.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "ToFromViewController.h"
#import "Locations.h"
#import "UtilityFunctions.h"
#import "RouteOptionsViewController.h"
#import "Leg.h"
#import "PlanStore.h"
#import "DateTimeViewController.h"
#import "TestFlightSDK1/TestFlight.h"
#import "Itinerary.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "FeedBackForm.h"
#import "LocationPickerViewController.h"
#import "twitterViewController.h"
#import "SettingInfoViewController.h"
#import "nc_AppDelegate.h"
#import "UIConstants.h"
#import "Constants.h"
#import "TEXTConstant.h"
#import "UserPreferance.h"
#import "Logging.h"

#if FLURRY_ENABLED
#include "Flurry.h"
#endif


@interface ToFromViewController()
{
    // Variables for internal use    
    NSDateFormatter *tripDateFormatter;  // Formatter for showing the trip date / time
    NSString *planURLResource; // URL resource sent to planner
    NSString *reverseGeoURLResource;  // URL resource sent for reverse geocoding
    NSMutableArray *planRequestHistory; // Array of all the past plan request parameter histories in sequential order (most recent one last)
    Plan *plan;
    Plan *tpResponsePlan;
    SupportedRegion *sr;
    FeedBackForm *fbplan;
    
    CGFloat toTableHeight;   // Current height of the toTable (US123 implementation)
    NSManagedObjectContext *managedObjectContext;
    BOOL toGeocodeRequestOutstanding;  // true if there is an outstanding To geocode request
    BOOL fromGeocodeRequestOutstanding;  //true if there is an outstanding From geocode request
    BOOL savetrip;
    double startButtonClickTime;
    float durationOfResponseTime;
    UIActivityIndicatorView* activityIndicator;
    NSTimer* activityTimer;
    RouteOptionsViewController *routeOptionsVC; 
    LocationPickerViewController *locationPickerVC;
    NSArray* sectionUILabelArray;  // Array of UILabels containing main table section headers
    UIBarButtonItem *barButtonSwap;  // Swap left bar button (for when in NO_EDIT mode)
    UIBarButtonItem *barButtonCancel; // Cancel left bar button (for when in EDIT mode)
}

// Internal methods
- (BOOL)getPlan;
- (void)stopActivityIndicator;
- (void)startActivityIndicator;
// - (void)addLocationAction:(id) sender;
- (BOOL)setToFromHeightForTable:(UITableView *)table Height:(CGFloat)tableHeight;
- (CGFloat)toFromTableHeightByNumberOfRowsForMaxHeight:(CGFloat)maxHeight  isFrom:(BOOL)isFrom;
- (void)newLocationVisible;  // Callback for whenever a new location is made visible to update dynamic table height
-(void)segmentChange;
- (void)selectCurrentDate;
- (void)selectDate;

@end


@implementation ToFromViewController

@synthesize mainTable;
@synthesize toTable;
@synthesize toTableVC;
@synthesize fromTable;
@synthesize fromTableVC;
@synthesize routeButton;
@synthesize rkGeoMgr;
@synthesize rkPlanMgr;
@synthesize rkSavePlanMgr;
@synthesize locations;
@synthesize planStore;
@synthesize fromLocation;
@synthesize toLocation;
@synthesize currentLocation;
@synthesize isCurrentLocationMode;
@synthesize departOrArrive;
@synthesize tripDate;
@synthesize tripDateLastChangedByUser;
@synthesize isTripDateCurrentTime;
@synthesize editMode;
@synthesize supportedRegion;
@synthesize isContinueGetRealTimeData;
@synthesize continueGetTime;
@synthesize plan;
@synthesize timerGettingRealDataByItinerary;

@synthesize datePicker,toolBar,departArriveSelector,date,btnDone,btnNow;
// Constants for animating up and down the To: field
#define FROM_SECTION 0
#define TO_SECTION 1
#define TIME_DATE_SECTION 2

NSString *currentLoc;
float currentLocationResTime;
NSUserDefaults *prefs;
#pragma mark view Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    @try {
        if (self) {
            prefs  = [NSUserDefaults standardUserDefaults];
            planRequestHistory = [NSMutableArray array]; // Initialize this array
            departOrArrive = DEPART;
            toGeocodeRequestOutstanding = FALSE;
            fromGeocodeRequestOutstanding = FALSE;
            supportedRegion = [[SupportedRegion alloc] initWithDefault];
            
            editMode = NO_EDIT;
            
            // Initialize the trip date formatter for display
            tripDateFormatter = [[NSDateFormatter alloc] init];
            [tripDateFormatter setDoesRelativeDateFormatting:YES];
            [tripDateFormatter setTimeStyle:NSDateFormatterShortStyle];
            [tripDateFormatter setDateStyle:NSDateFormatterMediumStyle];
            
            // Initialize the to & from tables
            CGRect rect1;
            rect1.origin.x = 0;
            rect1.origin.y = 0;
            rect1.size.width = TOFROM_TABLE_WIDTH ;
            toTableHeight = TOFROM_TABLE_HEIGHT_NO_CL_MODE;
            rect1.size.height = toTableHeight;
            
            toTable = [[UITableView alloc] initWithFrame:rect1 style:UITableViewStylePlain];
            [toTable setRowHeight:TOFROM_ROW_HEIGHT];
            toTableVC = [[ToFromTableViewController alloc] initWithTable:toTable isFrom:FALSE toFromVC:self locations:locations];
            [toTable setDataSource:toTableVC];
            [toTable setDelegate:toTableVC];
            toTable.layer.cornerRadius = TOFROM_TABLE_CORNER_RADIUS;
            
            CGRect rect2;
            rect2.origin.x = 0;
            rect2.origin.y = 0;               
            rect2.size.width = TOFROM_TABLE_WIDTH; 
            rect2.size.height = TOFROM_TABLE_HEIGHT_NO_CL_MODE;
            
            fromTable = [[UITableView alloc] initWithFrame:rect2 style:UITableViewStylePlain];
            [fromTable setRowHeight:TOFROM_ROW_HEIGHT];
            fromTable.layer.cornerRadius = TOFROM_TABLE_CORNER_RADIUS;
            fromTableVC = [[ToFromTableViewController alloc] initWithTable:fromTable isFrom:TRUE toFromVC:self locations: locations];
            [fromTable setDataSource:fromTableVC];
            [fromTable setDelegate:fromTableVC];  
            
            // Initialize the section header label array
            
            NSMutableArray* sectionArray = [[NSMutableArray alloc] initWithCapacity:3];
            for (int i=0; i<3; i++) {
                UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TOFROM_SECTION_LABEL_WIDTH, TOFROM_SECTION_LABEL_HEIGHT)];
                UILabel *label = [[UILabel alloc] 
                                  initWithFrame:CGRectMake(TOFROM_SECTION_LABEL_INDENT, 0, 
                                                           TOFROM_SECTION_LABEL_WIDTH - TOFROM_SECTION_LABEL_INDENT, 
                                                           TOFROM_SECTION_LABEL_HEIGHT)];
                label.textColor = [UIColor lightGrayColor];
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont MEDIUM_OBLIQUE_FONT];
                if (i == TO_SECTION) {
                    label.text = @"To:";
                } else if (i == FROM_SECTION) {
                    label.text = @"From:";
                } else {
                    // No label for "Depart"
                }
                [headerView addSubview:label];
                [sectionArray addObject:headerView];
            }
            sectionUILabelArray = sectionArray;
            
            // Set up NavBar left buttons
            
            UIImage* btnSwapImage = [UIImage imageNamed:@"img_swapLocation.png"];
            UIButton *btnSwap = [[UIButton alloc] initWithFrame:CGRectMake(0,0,btnSwapImage.size.width,btnSwapImage.size.height)];
            [btnSwap setTag:101];
            [btnSwap addTarget:self action:@selector(doSwapLocation) forControlEvents:UIControlEventTouchUpInside];
            [btnSwap setBackgroundImage:btnSwapImage forState:UIControlStateNormal];
            barButtonSwap = [[UIBarButtonItem alloc] initWithCustomView:btnSwap];
            
            UIImage* btnCancelImage = [UIImage imageNamed:@"img_cancel.png"];
            UIButton *btnCancel = [[UIButton alloc] initWithFrame:CGRectMake(0,0,btnCancelImage.size.width,btnCancelImage.size.height)];
            [btnCancel addTarget:self action:@selector(endEdit) forControlEvents:UIControlEventTouchUpInside];
            [btnCancel setBackgroundImage:btnCancelImage forState:UIControlStateNormal];
            barButtonCancel = [[UIBarButtonItem alloc] initWithCustomView:btnCancel];

        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at init ToFromViewController");
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
//    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
//        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
//    }
//    else {
//        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_navigationbar.png"]] aboveSubview:self.navigationController.navigationBar];
//    }
    UIImage *imgTitle = [UIImage imageNamed:@"nimblr.png"];
    self.navigationItem.titleView = [[UIImageView alloc]  initWithImage:imgTitle];

    if(editMode == NO_EDIT){
        self.navigationItem.leftBarButtonItem = barButtonSwap;
    } else{
        self.navigationItem.leftBarButtonItem = barButtonCancel;
    }
    
    routeButton.layer.cornerRadius = CORNER_RADIUS_SMALL;
    [continueGetTime invalidate];
    continueGetTime = nil;
    [timerGettingRealDataByItinerary invalidate];
    timerGettingRealDataByItinerary = nil;
    
    datePicker = [[UIDatePicker alloc]initWithFrame:CGRectMake(0, 494, 320, 216)];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    datePicker.minuteInterval = 5;
    [self.view addSubview:datePicker];
    
    NSArray *array = [NSArray arrayWithObjects:DATE_PICKER_DEPART,DATE_PICKER_ARRIVE, nil];
    departArriveSelector = [[UISegmentedControl alloc] initWithItems:array];
    
    departArriveSelector.segmentedControlStyle = UISegmentedControlStyleBar;
    departArriveSelector.selectedSegmentIndex = 1;
    [departArriveSelector addTarget:self action:@selector(segmentChange) forControlEvents:UIControlEventValueChanged];
    
    btnDone = [[UIBarButtonItem alloc] initWithTitle:DATE_PICKER_DONE style:UIBarButtonItemStyleBordered target:self action:@selector(selectDate)];
    btnNow = [[UIBarButtonItem alloc] initWithTitle:DATE_PICKER_NOW style:UIBarButtonItemStyleBordered target:self action:@selector(selectCurrentDate)];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload{
    [super viewDidUnload];
    self.mainTable = nil;
    self.routeButton = nil;
}

- (void)dealloc{
    self.mainTable = nil;
    self.routeButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NIMLOG_PERF1(@"Entered ToFromView viewWillAppear");
    [nc_AppDelegate sharedInstance].isToFromView = YES;
    
    @try {
        // Enforce height of main table
        CGRect rect0 = [mainTable frame];
        rect0.size.height = TOFROM_MAIN_TABLE_HEIGHT;
        [mainTable setFrame:rect0];
#if FLURRY_ENABLED
        [Flurry logEvent:FLURRY_TOFROMVC_APPEAR];
#endif
        
        isContinueGetRealTimeData = false;
        [continueGetTime invalidate];
        continueGetTime = nil;
        [self updateTripDate];  // update tripDate if needed
        NIMLOG_PERF1(@"Ready to setFBParameterForGeneral");
        [self setFBParameterForGeneral];
        NIMLOG_PERF1(@"Ready to reload tables");
        
        [toTable reloadData];
        [fromTable reloadData];
        [mainTable reloadData];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at viewWillAppear: %@", exception);
    }
    NIMLOG_PERF1(@"Finished ToFromView viewWillAppear");
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [nc_AppDelegate sharedInstance].isToFromView = NO;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Flash scrollbars on tables
    [toTable flashScrollIndicators];
    [fromTable flashScrollIndicators];   
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// Update trip date to the current time if needed
- (void)updateTripDate
{
    NSDate* currentTime = [[NSDate alloc] init];
    if (isTripDateCurrentTime) {
        tripDate = currentTime;  // simply refresh the date 
    }
    if (!tripDate || !tripDateLastChangedByUser) {
        tripDate = currentTime;   // if no date set, or never set by user, use current time
        departOrArrive = DEPART;
        isTripDateCurrentTime = YES;
    }
    else if ([tripDateLastChangedByUser timeIntervalSinceNow] < -(24*3600.0)) {
        // if more than a day since last user update, use the current time
        tripDate = currentTime;  
        departOrArrive = DEPART;
        isTripDateCurrentTime = YES;
    }
    else if ([tripDateLastChangedByUser timeIntervalSinceNow] < -7200.0) { 
        // if tripDate not changed in the last two hours by user, update it if tripDate is in the past
        NSDate* laterDate = [tripDate laterDate:currentTime]; 
        if (laterDate == currentTime) {  // if currentTime is later than tripDate, update to current time
            tripDate = currentTime;
            departOrArrive = DEPART; 
        }
    }
}


#pragma mark table operation methods
// Reloads the tables in case something has changed in the model
- (void)reloadTables
{
    [toTable reloadData];
    [fromTable reloadData];
    [mainTable reloadData];
}

// Callback for whenever a new location is created to update dynamic table height
- (void)newLocationVisible
{
    // Check whether toTableHeight needs to be dynamically adjusted (due to additional locations)
    if (isCurrentLocationMode && editMode == NO_EDIT) {
        // Check if height is updated, and if it is, reload the tables
        if ([self setToFromHeightForTable:toTable Height:TO_TABLE_HEIGHT_CL_MODE]) {
            [self reloadTables];
        }
    }
}

// Returns TRUE if the height actually was changed from the previous value, otherwise false
- (BOOL)setToFromHeightForTable:(UITableView *)table Height:(CGFloat)tableHeight
{
    // If toTable and isCurrentLocationMode, allow for variable height (US123 implementation)
    if ((table == toTable) && isCurrentLocationMode && editMode == NO_EDIT) {
        toTableHeight = [self toFromTableHeightByNumberOfRowsForMaxHeight:tableHeight isFrom:FALSE];
        tableHeight = toTableHeight;
    }
    
    if (tableHeight != table.frame.size.height) {  // Only update if value is different
        @try {
            CGRect rect0 = [table frame];
            rect0.size.height = tableHeight;
            [table setFrame:rect0];
        }
        @catch (NSException *exception) {
            NSLog(@"exception at set height for table in ToFromView: %@", exception);
        }
        return TRUE;
    }
    return FALSE;
}

// Internal utility that computes the full height of the to or from table based on the number of rows.  
// Returns either that full table height or maxHeight, whichever is smaller.  
// Will always return maxHeight if there is typed text for the table.  
// US123 implementation
- (CGFloat)toFromTableHeightByNumberOfRowsForMaxHeight:(CGFloat)maxHeight  isFrom:(BOOL)isFrom
{
    // If locations is returning a subset due to type text, do not dynamically adjust table height
    NSString* typedText;
    if (isFrom) {
        typedText = [locations typedFromString];
    } else {
        typedText = [locations typedToString];
    }
    if (typedText && [typedText length] > 0) {
        return maxHeight;
    }

    CGFloat fullTableHeight;
    if (isFrom) {
        fullTableHeight = [fromTableVC tableView:fromTable numberOfRowsInSection:0] * TOFROM_ROW_HEIGHT; // DE122 fix
    } else {
        fullTableHeight = [toTableVC tableView:toTable numberOfRowsInSection:0] * TOFROM_ROW_HEIGHT; // DE122 fix
    }
    
    // Return fullTableHeight or maxHeight, whichever is smaller
    if (fullTableHeight > maxHeight) { 
        return maxHeight;
    } else {
        return fullTableHeight;
    }
}

#pragma mark UITableView delegate methods
//
// Table view management methods
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (editMode == NO_EDIT) {
        return 3;  // Include all three sections
    } 
    return 1;  // Include just the To or the From section
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (editMode == NO_EDIT) {
        return 1;  // each section in the mainTable has only one cell when not editng
    }
    return 2; 
    // In edit mode, the To or From section has two cells
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editMode == NO_EDIT && [indexPath section] == TIME_DATE_SECTION) {  
        return TOFROM_TIME_DATE_HEIGHT;
    }  
    else if (editMode != NO_EDIT && [indexPath row] == 0) {  // txtField row in Edit mode
        return TOFROM_ROW_HEIGHT;
    }
    else if (editMode != NO_EDIT) {  // to or from table in Edit mode
        return TOFROM_TABLE_HEIGHT_NO_CL_MODE + TOFROM_INSERT_INTO_CELL_MARGIN;
    }
    else if (isCurrentLocationMode) {  // NO_EDIT mode and CurrentLocationMode
        if ([indexPath section] == TO_SECTION) {  // Larger To Table
            return toTableHeight + TOFROM_INSERT_INTO_CELL_MARGIN;
        }
        else {
            return FROM_HEIGHT_CL_MODE;  // Single line From showing Current Location
        }
    }
    // Else NO_EDIT mode and no CurrentLocationMode
    
    return TOFROM_TABLE_HEIGHT_NO_CL_MODE + TOFROM_INSERT_INTO_CELL_MARGIN;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == FROM_SECTION) {
        return TOFROM_SECTION_LABEL_HEIGHT;
    } else if(section == TO_SECTION) {
         return TOFROM_SECTION_LABEL_HEIGHT;
    } else {
        return TOFROM_SECTION_NOLABEL_HEIGHT;
    } 
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView;
    if(editMode == NO_EDIT){
       headerView = [sectionUILabelArray objectAtIndex:section]; 
    }
    else{
        UIView *tempView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TOFROM_SECTION_LABEL_WIDTH, TOFROM_SECTION_LABEL_HEIGHT)];
        UILabel *label = [[UILabel alloc] 
                          initWithFrame:CGRectMake(TOFROM_SECTION_LABEL_INDENT, 0, 
                                                   TOFROM_SECTION_LABEL_WIDTH - TOFROM_SECTION_LABEL_INDENT, 
                                                   TOFROM_SECTION_LABEL_HEIGHT)];
        label.textColor = [UIColor lightGrayColor];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont MEDIUM_OBLIQUE_FONT];
        if(editMode == TO_EDIT){
            label.text = @"To:";
            [tempView addSubview:label];
            headerView = tempView;
        }
        else if(editMode == FROM_EDIT){
            label.text = @"From:";
            [tempView addSubview:label];
            headerView = tempView;
        }
    }
    return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return TOFROM_SECTION_FOOTER_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (editMode == NO_EDIT && [indexPath section] == TIME_DATE_SECTION) {  
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"timeDateTableCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
                                          reuseIdentifier:@"timeDateTableCell"];
            [[cell textLabel] setFont:[UIFont MEDIUM_BOLD_FONT]];
            [cell setBackgroundColor:[UIColor whiteColor]];
            UIImage *imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
            UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithImage:imageDetailDisclosure];
            [cell setAccessoryView:imgViewDetailDisclosure];
            cell.textLabel.textColor = [UIColor NIMBLER_RED_FONT_COLOR];
        }        
        
        if (isTripDateCurrentTime) { 
            [[cell textLabel] setText:@"Depart now"];
        } 
        else {
            if (departOrArrive==DEPART) {
                cell.textLabel.text=[NSString stringWithFormat:@"Depart %@", 
                                     [[tripDateFormatter stringFromDate:tripDate] lowercaseString]];
            } else {
                cell.textLabel.text=[NSString stringWithFormat:@"Arrive by %@", 
                                     [[tripDateFormatter stringFromDate:tripDate] lowercaseString]];
            }
        }
        return cell;
    }
    else if (editMode==NO_EDIT && isCurrentLocationMode==TRUE && [indexPath section] == FROM_SECTION) {
        // Single row from cell in CurrentLocationMode
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"singleRowFromCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
                                          reuseIdentifier:@"singleRowFromCell"];
            [cell setBackgroundColor:[UIColor whiteColor]];
            cell.textLabel.font = [UIFont MEDIUM_LARGE_BOLD_FONT];
            cell.textLabel.textColor = [UIColor NIMBLER_RED_FONT_COLOR];
            UIImage *imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
            UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithImage:imageDetailDisclosure];
            [cell setAccessoryView:imgViewDetailDisclosure];
            [[cell textLabel] setText:@"Current Location"];
        }        
        return cell;        
    }
    else if (editMode==NO_EDIT || [indexPath row] == 1) { // the to or from table sections
        BOOL isFrom = (editMode==FROM_EDIT || (editMode==NO_EDIT && [indexPath section]==FROM_SECTION))
        ? TRUE : FALSE;  
        NSString* cellIdentifier = isFrom ? @"fromTableCell" : @"toTableCell";
        
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
                                          reuseIdentifier:cellIdentifier];
        }
        UIView* cellView = [cell contentView];
        
        NSArray* subviews = [cellView subviews];
        if (isFrom) {
            if (subviews && [subviews count]>0 && [subviews indexOfObject:fromTable] != NSNotFound) {
                // if fromTable is already in the subview (due to recycling, no need to add again
            } else { 
                [cellView addSubview:fromTable]; // add fromTable
            }
        } else {   // do same for toTable case
            if (subviews && [subviews count]>0 && [subviews indexOfObject:toTable] != NSNotFound) {
                // if toTable is already in the subview (due to recycling, no need to add again
            } else { 
                [cellView addSubview:toTable]; // add toTable
            }
        }        
        return cell;
    }
    // Else it is the To or From txtField in Edit mode
    BOOL isFrom = (editMode == FROM_EDIT) ? TRUE : FALSE;
    NSString* cellIdentifier = isFrom ? @"fromTxtFieldCell" : @"toTxtFieldCell";
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:cellIdentifier];
    }
    

    UIView* cellView = [cell contentView];
    /* Comment out code for saving address as nickname, since not working yet
    //TO add Current Location
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [addButton addTarget:self action:@selector(addLocationAction:) forControlEvents:UIControlEventTouchUpInside];
    addButton.frame = CGRectMake(270, 5, 25, 25);
    [cellView addSubview:addButton];
     */
    
    NSArray* subviews = [cellView subviews];
    
    if (isFrom) {
        if (subviews && [subviews count]>0 && [subviews indexOfObject:[fromTableVC txtField]] != NSNotFound) {
            // if From txtField is already in the subview (due to recycling, no need to add again
        } else { 
            [cellView addSubview:[fromTableVC txtField]]; // add From txtField
        }
    }
    else {   // do same for toTable case
        if (subviews && [subviews count]>0 && [subviews indexOfObject:[toTableVC txtField]] != NSNotFound) {
            // if To txtField is already in the subview (due to recycling, no need to add again
        } else { 
            [cellView addSubview:[toTableVC txtField]]; // add To txtfield
        }
    }     
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == TIME_DATE_SECTION) {  
//        DateTimeViewController *dateTimeVC = [[DateTimeViewController alloc] initWithNibName:nil bundle:nil];
//        [dateTimeVC setDate:tripDate];
//        [dateTimeVC setDepartOrArrive:departOrArrive];
//        [dateTimeVC setToFromViewController:self];
//        [[self navigationController] pushViewController:dateTimeVC animated:YES];
        [datePicker setDate:tripDate];
        [self openPickerView:self];
        
        [self hideTabBar];
        RXCustomTabBar *rxCustomTabBar = (RXCustomTabBar *)self.tabBarController;
        [rxCustomTabBar hideNewTabBar];
        return;
    }
    else if (isCurrentLocationMode && [indexPath section] == FROM_SECTION) {  // if single-row From field selected
        [self setEditMode:FROM_EDIT]; // go into edit mode
    }
}


#pragma mark set RKObjectManager 
// One-time set-up of the RestKit Geocoder Object Manager's mapping
- (void)setRkGeoMgr:(RKObjectManager *)rkGeoMgr0
{
    rkGeoMgr = rkGeoMgr0;  //set the property
    
    // Add the mapper from Location class to this Object Manager
    [[rkGeoMgr mappingProvider] setMapping:[Location objectMappingForApi:GOOGLE_GEOCODER] forKeyPath:@"results"];
    
    // Get the Managed Object Context associated with rkGeoMgr0
    managedObjectContext = [[rkGeoMgr objectStore] managedObjectContext];
    
    // Pass rkGeoMgr to the To & From Table View Controllers
    [fromTableVC setRkGeoMgr:rkGeoMgr];
    [toTableVC setRkGeoMgr:rkGeoMgr];
}

// One-time set-up of the RestKit Trip Planner Object Manager's mapping
- (void)setRkPlanMgr:(RKObjectManager *)rkPlanMgr0
{
    rkPlanMgr = rkPlanMgr0;
    // Add the mapper from Plan class to this Object Manager
    [[rkPlanMgr mappingProvider] setMapping:[Plan objectMappingforPlanner:OTP_PLANNER] forKeyPath:@"plan"];
}

- (void)setPlanStore:(PlanStore *)planStore0
{
    planStore = planStore0;
    // Set the objects for callback with planStore
    if (!routeOptionsVC) {
        routeOptionsVC = [[RouteOptionsViewController alloc] initWithNibName:nil bundle:nil];
    }
    [planStore setToFromVC:self];
    [planStore setRouteOptionsVC:routeOptionsVC];
}

#pragma mark Loacation methods
- (void)setLocations:(Locations *)l
{
    locations = l;
    // Now also update the to & from Table View Controllers with the locations object
    [toTableVC setLocations:l];
    [fromTableVC setLocations:l];
}

// Method to change isCurrentLocationMode.
// When isCurrentLocationMode = true, then a larger To table is shown, and only one row containing "Current Location" is showed in the from field
// When isCurrentLocationMode = false, then equal sized To and From tables are shown (traditional display)
- (void)setIsCurrentLocationMode:(BOOL) newCLMode
{
    if (isCurrentLocationMode != newCLMode) { // Only do something if there is a change
        isCurrentLocationMode = newCLMode;
        activityIndicator = nil;  // Nullify because activityIndicator changes per CLMode
        if (newCLMode && (fromLocation != currentLocation)) {  
            // DE55 fix: make sure that currentLocation is selected if this method called by nc_AppDelegate
            [fromTableVC initializeCurrentLocation:currentLocation]; 
        }
        // Adjust the toTable height
        if (newCLMode) {
            [self setToFromHeightForTable:toTable Height:TO_TABLE_HEIGHT_CL_MODE];
        }
        else {
            [self setToFromHeightForTable:toTable Height:TOFROM_TABLE_HEIGHT_NO_CL_MODE];
        }
        if (editMode != FROM_EDIT) {
            // DE59 fix -- only update table if not in FROM_EDIT mode
            [mainTable reloadData];
        }
    }
}

// ToFromTableViewController callbacks 
// (for when user has selected or entered a new location)
// Callback from ToFromTableViewController to update a new user entered/selected location

- (void)updateToFromLocation:(id)sender isFrom:(BOOL)isFrom location:(Location *)loc; {
    if (isFrom) {
        fromLocation = loc;
        [self setFBParameterForGeneral];
        if (loc == currentLocation && !isCurrentLocationMode) {
            [self setIsCurrentLocationMode:TRUE];
        }
        else if (loc != currentLocation && isCurrentLocationMode) {
            [self setIsCurrentLocationMode:FALSE];
        }
    } 
    else {
        
        BOOL locBecomingVisible = loc && ([loc toFrequencyFloat] < TOFROM_FREQUENCY_VISIBILITY_CUTOFF);
        BOOL toLocationBecomingInvisible = toLocation && ([toLocation toFrequencyFloat] < TOFROM_FREQUENCY_VISIBILITY_CUTOFF);
        if (locBecomingVisible ^ toLocationBecomingInvisible) { // if # of locations visible is changing
            [self newLocationVisible];  // Adjust dynamic toTable if toLocation chosen for first time
        }
        toLocation = loc;
        [self setFBParameterForGeneral];
    }
}

// Callback from ToFromTableViewController to update geocoding status
- (void)updateGeocodeStatus:(BOOL)isGeocodeOutstanding isFrom:(BOOL)isFrom
{
    // update the appropriate geocode status
    if (isFrom) {
        fromGeocodeRequestOutstanding = isGeocodeOutstanding;
    } else {
        toGeocodeRequestOutstanding = isGeocodeOutstanding;
    }
}

-(BOOL)alertUsetForLocationService {
    if (![locations isLocationServiceEnable]) {
        return TRUE;
    }
    return FALSE;
}

#pragma mark Button Press Event
// Requesting a plan
- (IBAction)routeButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
        NIMLOG_EVENT1(@"Route Button Pressed");
        UIAlertView *alert;
        startButtonClickTime = CFAbsoluteTimeGetCurrent();
        
        if ([[fromLocation formattedAddress] isEqualToString:@"Current Location"]) {
            if ([self alertUsetForLocationService]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler Location" message:@"Location Service is disabled for Nimbler, Do you want to enable?" delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"Cancel", nil];
                [alert show];
                return ;
            }
        }
        // if all the geolocations are here, get a plan.  
        if ([fromLocation formattedAddress] && [toLocation formattedAddress] &&
            !toGeocodeRequestOutstanding && !fromGeocodeRequestOutstanding) {
            if (isTripDateCurrentTime) { // if current time, get the latest before getting plan
                [self updateTripDate];
            }
            [self getPlan];
        }
        // if user has not entered/selected fromLocation, send them an alert
        else if (![fromLocation formattedAddress] && !fromGeocodeRequestOutstanding) {
            alert = [[UIAlertView alloc] initWithTitle:@"TripPlanner" message:@"Select a 'From' address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        // if user has not entered has not entered/selected toLocation, send them an alert
        else if (![toLocation formattedAddress] && !toGeocodeRequestOutstanding) {
            alert = [[UIAlertView alloc] initWithTitle:@"TripPlanner" message:@"Select a destination address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }    
        // otherwise, just wait for the geocoding and then submit the plan
        else {
            NSLog(@"look for state");
            alert = [[UIAlertView alloc] initWithTitle:@"TripPlanner" message:@"Please select a location" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at press route button event: %@", exception);
    }
}

#pragma mark Edit events for ToFrom table
// Method to adjust the mainTable for editing mode
//
- (void)setEditMode:(ToFromEditMode)newEditMode
{
    if (editMode == newEditMode) {
        return;  // If no change in mode return immediately
    }
#if FLURRY_ENABLED
    NSString *edit_string;
    if (newEditMode==NO_EDIT){
        edit_string = @"NO_EDIT";
    } else if (newEditMode==TO_EDIT) {
        edit_string = @"TO_EDIT";        
    } else if (newEditMode==FROM_EDIT) {
        edit_string = @"FROM_EDIT";            
    }
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:FLURRY_EDIT_MODE_VALUE, edit_string, nil];
    [Flurry logEvent:FLURRY_TOFROMTABLE_NEW_EDIT_MODE withParameters:dictionary];
#endif
    
    NSRange range;
    ToFromEditMode oldEditMode = editMode;
    editMode = newEditMode;  
    
    // Change NavBar buttons accordingly
    if(editMode == NO_EDIT){
        self.navigationItem.leftBarButtonItem = barButtonSwap;
    } else{
        self.navigationItem.leftBarButtonItem = barButtonCancel;
    }
    
    if (newEditMode == TO_EDIT && oldEditMode == NO_EDIT) {
        // Delete second & third sections (moving To Table to top)
        range.location = 1;
        range.length = 2;
        if (isCurrentLocationMode) {
            // Set toTable to normal height when in TO_EDIT mode
            [self setToFromHeightForTable:toTable Height:TOFROM_TABLE_HEIGHT_NO_CL_MODE];
        }
        [mainTable beginUpdates];
        [mainTable deleteSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationAutomatic];  // Leave only the To section
        [mainTable insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Add a row for txtField
        [mainTable endUpdates];
    } else if (newEditMode == NO_EDIT && oldEditMode == TO_EDIT) {
        range.location = 1;
        range.length = 2;
        if (isCurrentLocationMode) {
            // Set toTable back to greater height when going to NO_EDIT mode
            [self setToFromHeightForTable:toTable Height:TO_TABLE_HEIGHT_CL_MODE];
        }
        [mainTable beginUpdates];
        [mainTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Delete the row for txtField
        [mainTable insertSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable endUpdates];
    } else if (newEditMode == FROM_EDIT && oldEditMode == NO_EDIT) {
        // Delete first & second sections (moving To Table to top)
        [mainTable beginUpdates];
        [mainTable deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable deleteSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Add a row for txtField
        [mainTable endUpdates];
    } 
    else if (newEditMode == NO_EDIT && oldEditMode == FROM_EDIT) {
        [mainTable beginUpdates];
        [mainTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Delete row for txtField
        [mainTable insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable insertSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable endUpdates];
    }
    else if (newEditMode == FROM_EDIT && oldEditMode == TO_EDIT) {
        // Note: this code is not used yet -- it is here as a placeholder
        [mainTable beginUpdates];
        [mainTable deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Add a row for txtField
        [mainTable endUpdates];
    }
    else if (newEditMode == TO_EDIT && oldEditMode == FROM_EDIT) {
        // Note: this code is not used yet -- it is here as a placeholder
        [mainTable beginUpdates];
        [mainTable deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Add a row for txtField
        [mainTable endUpdates];
    }  
    
    // Reload all the data
    [toTable reloadData];
    [fromTable reloadData];
    [mainTable reloadData];
    
    // If TO_EDIT or FROM_EDIT, make the txt field the first responder
    if (newEditMode == TO_EDIT) {
        [[toTableVC txtField] becomeFirstResponder];
    } 
    else if (newEditMode == FROM_EDIT) {
        [[fromTableVC txtField] becomeFirstResponder];
    }
    return;
}


#pragma mark RKObject loader with Plan responce from OTP 
// Delegate methods for when the RestKit has results from the Planner
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{        
    if ([[objectLoader resourcePath] isEqualToString:reverseGeoURLResource]) {
        // A reverse geocode result for currentLocation
        // TODO refactor some of this code and that in ToFromTableViewController into a general geocode class
        
        // Get the status string the hard way by parsing the response string
        NSString* response = [[objectLoader response] bodyAsString];
        [currentLocation setReverseGeoLocation:nil];  // Clear out previous reverse Geocode
        
        NSRange range = [response rangeOfString:@"\"status\""];
        if (range.location != NSNotFound) {
            NSString* responseStartingFromStatus = [response substringFromIndex:(range.location+range.length)];
            
            NSArray* atoms = [responseStartingFromStatus componentsSeparatedByString:@"\""];
            NSString* geocodeStatus = [atoms objectAtIndex:1]; // status string is second atom (first after the first quote)
            NSLog(@"Status: %@", geocodeStatus);
            
            if ([geocodeStatus compare:@"OK" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                if ([objects count] > 0) { // if we have an reverse geocode object
                    
                    // Grab the first reverse-geo, which will be the most specific one
                    Location* reverseGeoLocation = [objects objectAtIndex:0];
                    
                    // Check if an equivalent Location is already in the locations table
                    reverseGeoLocation = [locations consolidateWithMatchingLocations:reverseGeoLocation keepThisLocation:NO];
                    
                    // Save db context with the new location object
                    saveContext(managedObjectContext);
                    NSLog(@"Reverse Geocode: %@", [reverseGeoLocation formattedAddress]);
                    // Update the Current Location with pointer to the Reverse Geo location
                    [currentLocation setReverseGeoLocation:reverseGeoLocation];
                }
            }
        }
        // if no result or non-OK status, leave the reverse Geocode as nil
    }
    
    // If returned value does not correspond to one of the most recent requests, do nothing...
    else{
        // Add The Plan ID,Itinerary ID and leg ID to The Plan. 
        @try {
            tpResponsePlan = [objects objectAtIndex:0];
            [plan setPlanId:[tpResponsePlan planId]];
            for (int i= 0; i< [[tpResponsePlan itineraries] count]; i++) {
                Itinerary *itin = [[tpResponsePlan sortedItineraries] objectAtIndex:i];
                [[[plan sortedItineraries] objectAtIndex:i] setItinId:[itin itinId]];
                NSLog(@"===========================================");
                NSLog(@"itinarary.. %@",[itin itinId]);
                for (int j =0; j< [[itin legs] count] ; j++) {
                    Leg *lg = [[itin sortedLegs] objectAtIndex:j];
                    [[[[[plan sortedItineraries] objectAtIndex:i] sortedLegs] objectAtIndex:j] setLegId:[lg legId]];
                    NSLog(@"------------------------------------------");
                    NSLog(@"leg... %@",[lg legId]);
                }
            }
            // Call The Method From PlaneStore To Perform Plancaching on The Plan With Plan ID,Itinerary ID and Leg ID.
            [planStore PlanToStoreInCache:plan :toLocation :fromLocation];
        }
        @catch (NSException *exception) {
            NSLog(@"exception while loading ID's=%@",exception);
        }
    }
}

// Call-back from PlanStore requestPlanFromLocation:... method when it has a plan
-(void)newPlanAvailable:(Plan *)newPlan status:(PlanRequestStatus)status
{
    [self stopActivityIndicator];
    durationOfResponseTime = CFAbsoluteTimeGetCurrent() - startButtonClickTime;

    if (status == STATUS_OK) {
        plan = newPlan;
        savetrip = FALSE;
        
        // Pass control to the RouteOptionsViewController to display itinerary choices
        if (!routeOptionsVC) {
            routeOptionsVC = [[RouteOptionsViewController alloc] initWithNibName:nil bundle:nil];
        }
        
        [routeOptionsVC setPlan:plan];
        [[self navigationController] pushViewController:routeOptionsVC animated:YES];
    }
    else { // if (status == GENERIC_EXCEPTION)
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:@"Sorry, we are unable to calculate a route for that To & From address" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
        [alert show];
        savetrip = false;
        return ;
    }
    
    // TODO -- move logic for saving PlanInTP Server to PlanStore class or a new class
    // [self savePlanInTPServer:[[objectLoader  response] bodyAsString]];
    // NSLog(@"For Feedback Process called");
    
    
    /* } else {   // code for saveTrip=FALSE case
     tpResponsePlan = [objects objectAtIndex:0];
     [plan setPlanId:[tpResponsePlan planId]];
     NSLog(@"obj foe plan = %@", [tpResponsePlan planId]);
     
     @try {
     for (int i= 0; i< [[tpResponsePlan itineraries] count]; i++) {
     Itinerary *itin = [[tpResponsePlan sortedItineraries] objectAtIndex:i];
     [[[plan sortedItineraries] objectAtIndex:i] setItinId:[itin itinId]];
     NSLog(@"===========================================");
     NSLog(@"itinarary.. %@",[itin itinId]);
     for (int j =0; j< [[itin legs] count] ; j++) {
     Leg *lg = [[itin sortedLegs] objectAtIndex:j];
     [[[[[plan sortedItineraries] objectAtIndex:i] sortedLegs] objectAtIndex:j] setLegId:[lg legId]];
     NSLog(@"------------------------------------------");
     NSLog(@"leg... %@",[lg legId]);
     }
     }
     
     [routeOptionsVC setFBParameterForPlan];
     [self getRealTimeData];
     continueGetTime =   [NSTimer scheduledTimerWithTimeInterval:TIMER_STANDARD_REQUEST_DELAY target:self selector:@selector(getRealTimeData) userInfo:nil repeats: YES];
     }
     @catch (NSException *exception) {
     NSLog(@"Exception while iterating over TP response plan: %@", exception);
     } */
}

// TODO Move geocoding and reverse-geocoding into a separate class (like Locations)
- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    [self stopActivityIndicator];
    if (savetrip) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Sorry, we are unable to calculate a route for that To & From address" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        NSLog(@"Error received from RKObjectManager: %@", error);
    }
}


#pragma mark get Plan Request
// Routine for calling and populating a trip-plan object
- (BOOL)getPlan
{
    // See if there has already been an identical plan request in the last 5 seconds.
    @try {
        NSLog(@"Plan routine entered");
        BOOL isDuplicatePlan = NO;
        NSString *frForm = [fromLocation formattedAddress];
        NSString *toForm = [toLocation formattedAddress];
        NSDate *cutoffDate = [NSDate dateWithTimeIntervalSinceNow:-5.0];  // 5 seconds before now 
        for (int i=[planRequestHistory count]-1; i>=0; i--) {  // go thru request history backwards
            NSDictionary *d = [planRequestHistory objectAtIndex:i];
            if ([[d objectForKey:@"date"] laterDate:cutoffDate] == cutoffDate) { // if more than 5 seconds ago, stop looking
                break;  
            }
            else if ([[[d objectForKey:@"fromPlace"] formattedAddress] isEqualToString:frForm] &&
                     [[[d objectForKey:@"toPlace"] formattedAddress] isEqualToString:toForm]) {
                isDuplicatePlan = YES;
                break;
            }
        }
        
        if (!isDuplicatePlan)  // if not a recent duplicate request
        {

            [self startActivityIndicator];

            // Update dynamic table height if a new location is becoming visible
            if ([fromLocation fromFrequencyFloat] < TOFROM_FREQUENCY_VISIBILITY_CUTOFF ||
                [toLocation toFrequencyFloat] < TOFROM_FREQUENCY_VISIBILITY_CUTOFF) {
                [self newLocationVisible];
            }
            
            // Increment fromFrequency and toFrequency
            [fromLocation incrementFromFrequency];
            [toLocation incrementToFrequency];
            // Update the dateLastUsed
            NSDate* now = [NSDate date];
            [fromLocation setDateLastUsed:now];
            [toLocation setDateLastUsed:now];
            // Save db context with the new location frequencies & dates
            saveContext(managedObjectContext);
            
            if(fromLocation == toLocation){
                [self stopActivityIndicator];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:@"The To: and From: address are the same location.  Please choose a different destination." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil ];
                [alert show];
                return true;
            }
            
#if FLURRY_ENABLED
            NSDictionary *flurryParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                          FLURRY_FROM_SELECTED_ADDRESS, [fromLocation shortFormattedAddress],
                                          FLURRY_TO_SELECTED_ADDRESS, [toLocation shortFormattedAddress],
                                          nil];
            [Flurry logEvent: FLURRY_ROUTE_REQUESTED withParameters:flurryParams];
#endif
            


            
            // add latest plan request to history array
            [planRequestHistory addObject:[NSDictionary dictionaryWithKeysAndObjects:
                                           @"fromPlace", fromLocation, 
                                           @"toPlace", toLocation,
                                           @"date", [NSDate date], nil]];
            
            NSNumber* maxiWalkDistance = [self getWalkDistance];
            NSLog(@"maximum walk distance ------------------------------------ %f",[maxiWalkDistance floatValue]);
            // convert miles into meters. 1 mile = 1609.344 meters
            int maxDistance = (int)([maxiWalkDistance floatValue]*1609.544);
            
            // Request the plan (callback will come in newPlanAvailable method)
            PlanRequestParameters* parameters = [[PlanRequestParameters alloc] init];
            parameters.fromLocation = fromLocation;
            parameters.toLocation = toLocation;
            parameters.originalTripDate = tripDate;
            parameters.thisRequestTripDate = tripDate;
            parameters.departOrArrive = departOrArrive;
            parameters.maxWalkDistance = maxDistance;
            parameters.planDestination = PLAN_DESTINATION_TO_FROM_VC;
            [planStore requestPlanWithParameters:parameters];
            
            savetrip = TRUE;
            isContinueGetRealTimeData = FALSE;
            
            // Do reverse geocoding if coming from current location
            if (fromLocation == currentLocation) {
                [self requestReverseGeo:fromLocation];
            }
            
            // Reload the to/from tables for next time
            [[self fromTable] reloadData];
            [[self toTable] reloadData];
        }
        return true; 
    }
    @catch (NSException *exception) {
        NSLog(@"exception at route request: %@", exception);
    }
}


#pragma mark Indicator Activity to notify user about processing 
-(void)startActivityIndicator
{
    @try {
        self.view.userInteractionEnabled = NO;
        if (!activityIndicator) {
            UIActivityIndicatorViewStyle style;
            BOOL setColorToBlack = NO;
            if ([UIActivityIndicatorView instancesRespondToSelector:@selector(color)]) {
                style = UIActivityIndicatorViewStyleWhiteLarge;
                setColorToBlack = YES;
            }
            else {
                style = UIActivityIndicatorViewStyleGray;
            }
            activityIndicator = [[UIActivityIndicatorView alloc]  
                                 initWithActivityIndicatorStyle:style]; 
            if (setColorToBlack) {
                [activityIndicator setColor:[UIColor blackColor]];
            }
        }
        activityIndicator.center = CGPointMake(self.view.bounds.size.width / 2,   
                                               (self.view.bounds.size.height/2));
        if (![activityIndicator isAnimating]) {
            [activityIndicator setUserInteractionEnabled:FALSE];
            [activityIndicator startAnimating]; // if not already animating, start
        }
        if (![activityIndicator superview]) {
            [[self view] addSubview:activityIndicator]; // if not already in the view, add it
        }
        // Set up timer to remove activity indicator after 60 seconds
        if (activityTimer && [activityTimer isValid]) {
            [activityTimer invalidate];  // if old activity timer still valid, invalidate it
        }
        [NSTimer scheduledTimerWithTimeInterval:TIMER_STANDARD_REQUEST_DELAY target:self selector: @selector(stopActivityIndicator) userInfo: nil repeats: NO];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at start IndicatorView: %@", exception);
    }
}

-(void)stopActivityIndicator
{
    self.view.userInteractionEnabled = YES;
    [activityIndicator stopAnimating];
    [activityIndicator removeFromSuperview];
    if (activityTimer && [activityTimer isValid]) {
        [activityTimer invalidate];  // if activity timer still valid, invalidate it
    }
}


#pragma mark save Plan and other logging features to TPServer

-(void)savePlanInTPServer:(NSString *)tripResponse{
    @try {
        NSString *timeResponseTime =  [[NSNumber numberWithFloat:durationOfResponseTime] stringValue];
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        RKParams *rkp = [RKParams params];
        [RKClient setSharedClient:client];
        [rkp setValue:[prefs objectForKey:DEVICE_CFUUID] forParam:DEVICE_ID]; 
        [rkp setValue:tripResponse forParam:PLAN_JSON_STRING]; 
        [rkp setValue:timeResponseTime forParam:TIME_TRIP_PLAN];
        [rkp setValue:[toLocation formattedAddress]  forParam:FORMATTED_ADDRESS_TO];
        [rkp setValue:[fromLocation formattedAddress]  forParam:FORMATTED_ADDRESS_FROM];
        [rkp setValue:[toLocation lat] forParam:LATITUDE_FROM];
        [rkp setValue:[toLocation lng] forParam:LONGITUDE_FROM];
        [rkp setValue:[fromLocation lat] forParam:LATITUDE_TO];
        [rkp setValue:[fromLocation lng] forParam:LONGITUDE_TO];
        
        if([[fromLocation formattedAddress] isEqualToString:CURRENT_LOCATION]) {
            [rkp setValue:REVERSE_GEO_FROM forParam:FROM_TYPE];
            [rkp setValue:currentLoc  forParam:FORMATTED_ADDRESS_FROM];
            [rkp setValue:[toLocation lat] forParam:LATITUDE_FROM];
            [rkp setValue:[toLocation lng] forParam:LONGITUDE_FROM];
            [rkp setValue:[[NSNumber numberWithFloat:currentLocationResTime] stringValue] forParam:@""];
        } else if([[toLocation formattedAddress] isEqualToString:CURRENT_LOCATION]) {
            [rkp setValue:REVERSE_GEO_TO forParam:TO_TYPE];
            [rkp setValue:currentLoc  forParam:FORMATTED_ADDRESS_TO];
            [rkp setValue:[fromLocation lat] forParam:LATITUDE_TO];
            [rkp setValue:[fromLocation lng] forParam:LONGITUDE_TO];
            [rkp setValue:[[NSNumber numberWithFloat:currentLocationResTime] stringValue] forParam:@""];
        }
        
        if ([locations isFromGeo]) {
            [rkp setValue:GEO_FROM forParam:FROM_TYPE];
            [rkp setValue:[fromLocation formattedAddress] forParam:RAW_ADDRESS_FROM];
            [rkp setValue:[locations geoRespFrom] forParam:GEO_RES_FROM];
            [rkp setValue:[locations geoRespTimeFrom] forParam:TIME_FROM];
        } else if ([locations isToGeo]) {
            [rkp setValue:GEO_TO forParam:TO_TYPE];
            [rkp setValue:[fromLocation formattedAddress] forParam:RAW_ADDRESS_TO];
            [rkp setValue:[locations geoRespTo] forParam:GEO_RES_TO];
            [rkp setValue:[locations geoRespTimeTo] forParam:TIME_TO];
        }
        
        [[RKClient sharedClient] post:NEW_PLAN_REQUEST params:rkp delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at save trip plan in TPServer: %@", exception);
    }
}

#pragma mark RKResponse Delegate method
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    @try {
        if (isContinueGetRealTimeData) {
            if ([request isGET]) {       
                NSLog(@"response %@", [response bodyAsString]);
                isContinueGetRealTimeData = false;
                RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];    
                [routeOptionsVC setIsReloadRealData:false];
                [routeOptionsVC setLiveFeed:res];
            } 
        }
        if ([request isPOST]) {           
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID], 
                                    nil];            
            rkSavePlanMgr = [RKObjectManager objectManagerWithBaseURL:TRIP_PROCESS_URL];            
            [[rkSavePlanMgr mappingProvider] setMapping:[Plan objectMappingforPlanner:OTP_PLANNER] forKeyPath:PLAN];
            planURLResource = [GET_PLAN_URL appendQueryParams:params];            
            [rkSavePlanMgr loadObjectsAtResourcePath:planURLResource delegate:self];            
        } 
    }  @catch (NSException *exception) {
        NSLog( @"Exception while getting unique IDs from TP Server response: %@", exception);
    } 
}

//Request responder to push a LocationPickerViewController so the user can pick from the locations in locationList
- (void)callLocationPickerFor:(ToFromTableViewController *)toFromTableVC0 locationList:(NSArray *)locationList0 isFrom:(BOOL)isFrom0 isGeocodeResults:(BOOL)isGeocodeResults0
{
    @try {
        if (!locationPickerVC) {
            locationPickerVC = [[LocationPickerViewController alloc] initWithNibName:nil bundle:nil];
        }
        [locationPickerVC setToFromTableVC:toFromTableVC0];
        [locationPickerVC setLocationArray:locationList0];
        [locationPickerVC setIsFrom:isFrom0];
        [locationPickerVC setIsGeocodeResults:isGeocodeResults0];
        [[self navigationController] pushViewController:locationPickerVC animated:YES];  
    }
    @catch (NSException *exception) {
        NSLog(@"exception at navigating to LocationPickerViewController: %@", exception);
    }
}

#pragma mark Redirect to IPhone LocationServices Setting 
-(void)alertView: (UIAlertView *)UIAlertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    @try {
        NSString *btnName = [UIAlertView buttonTitleAtIndex:buttonIndex];
        if ([btnName isEqualToString:@"Yes"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=LocationServices"]];
        }    
    }
    @catch (NSException *exception) {
        NSLog(@"exception at navigate to iPhone LocationServices: %@", exception);
    }
}

// Get RealTime Data By Plan 
-(void)getRealTimeData
{
    @try {
        isContinueGetRealTimeData = TRUE;
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];   
        NSDictionary *dict = [NSDictionary dictionaryWithKeysAndObjects:
                              PLAN_ID,[plan planId] ,
                              nil];
        NSString *req = [LIVE_FEEDS_BY_PLAN_URL appendQueryParams:dict];
        [[RKClient sharedClient]  get:req  delegate:self];  
    }
    @catch (NSException *exception) {
        NSLog(@"exception at real time data request: %@", exception);
    }
}

// Get RealTime Data By Itinerary
-(void)getRealTimeDataForItinerary{
    @try {
        NSMutableString *strItineraries = [[NSMutableString alloc] init];
        NSLog(@"%@",plan);
        NSLog(@"%@",[plan sortedItineraries]);
        for (int i= 0; i< [[plan sortedItineraries] count]; i++) {
            Itinerary *itin = [[plan sortedItineraries] objectAtIndex:i];
            [strItineraries appendFormat:[NSString stringWithFormat:@"%@,",[itin itinId]]];
        }
        [strItineraries deleteCharactersInRange:NSMakeRange([strItineraries length]-1, 1)];
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];  
        NSDictionary *tempDictionary =[NSDictionary dictionaryWithObjectsAndKeys:strItineraries,ITINERARY_ID,@"true",FOR_TODAY, nil ];
        NSString *req = [LIVE_FEEDS_BY_ITINERARIES_URL appendQueryParams:tempDictionary];
        [[RKClient sharedClient]  get:req  delegate:self];
        isContinueGetRealTimeData = TRUE;
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
}

#pragma mark Navigate in SettingInfoViewController view
-(void)redirectAtNimblerSetting{
    @try {
//        SettingInfoViewController *settingView = [[SettingInfoViewController alloc] init];
//        [[self navigationController] pushViewController:settingView animated:YES];
        [self routeButtonPressed:self forEvent:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at navigate to settingInfo view: %@", exception);
    }
}

#pragma mark get walk distance from User Defaults
-(NSNumber *)getWalkDistance
{
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    return [userPrefs walkDistance];
    
}

-(void)setFBParameterForGeneral
{
    @try {
        NSString *fromLocs = NULL_STRING;    
        NSDateFormatter* dFormat = [[NSDateFormatter alloc] init];
        [dFormat setDateStyle:NSDateFormatterShortStyle];
        [dFormat setTimeStyle:NSDateFormatterMediumStyle];
        if ([[fromLocation formattedAddress] isEqualToString:@"Current Location"]) {
            if ([fromLocation reverseGeoLocation]) {
                fromLocs = [NSString stringWithFormat:@"Current Location Reverse Geocode: %@",[[fromLocation reverseGeoLocation] formattedAddress]];
                } else {
                    fromLocs = @"Current Location";
                }
        } else {
            fromLocs = [fromLocation formattedAddress];
        }
        [nc_AppDelegate sharedInstance].FBSource = [NSNumber numberWithInt:FB_SOURCE_GENERAL];
        [nc_AppDelegate sharedInstance].FBDate = [dFormat stringFromDate:tripDate];
        [nc_AppDelegate sharedInstance].FBToAdd = [toLocation formattedAddress];
        [nc_AppDelegate sharedInstance].FBSFromAdd = fromLocs;
        [nc_AppDelegate sharedInstance].FBUniqueId = nil;
    }
    @catch (NSException *exception) {
        NIMLOG_ERR1(@"exception at reverGeocode: %@", exception);
    }
}

// US132 implementation
-(void)doSwapLocation
{
    
    if (fromLocation == currentLocation && [currentLocation reverseGeoLocation] &&
        [currentLocation reverseGeoLocation] != toLocation) {
        // If from = currentLocation and there is a reverse geolocation
        [toTableVC markAndUpdateSelectedLocation:[currentLocation reverseGeoLocation]];
    }
    else {  // do a normal swap
        Location *fromloc = fromLocation;
        Location *toLoc = toLocation;
        // Swap Location (could be nil)
        [toTableVC markAndUpdateSelectedLocation:fromloc];
        [fromTableVC markAndUpdateSelectedLocation:toLoc];
    }
    
#if FLURRY_ENABLED
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                FLURRY_TO_SELECTED_ADDRESS, [[self toLocation] shortFormattedAddress],
                                FLURRY_FROM_SELECTED_ADDRESS, [[self fromLocation] shortFormattedAddress],
                                nil];

    [Flurry logEvent:FLURRY_TOFROM_SWAP_LOCATION withParameters:dictionary];
#endif

}

//US 137 implementation
- (void)endEdit{
    [self setEditMode:NO_EDIT]; 
    self.toTableVC.txtField.text = NULL_STRING;
    self.fromTableVC.txtField.text = NULL_STRING;
//    [self.toTableVC toFromTyping:self.toTableVC.txtField forEvent:nil];
//    [self.toTableVC textSubmitted:self.toTableVC.txtField forEvent:nil];
//    [self.fromTableVC toFromTyping:self.fromTableVC.txtField forEvent:nil];
//    [self.fromTableVC textSubmitted:self.fromTableVC.txtField forEvent:nil];
    [self.toTableVC markAndUpdateSelectedLocation:toLocation];
    [self.fromTableVC markAndUpdateSelectedLocation:fromLocation];
}
- (void)requestReverseGeo:(Location *)location
{

    @try {
        float startTime = CFAbsoluteTimeGetCurrent();
        NSString* latLngString = [NSString stringWithFormat:@"%f,%f",[location latFloat], [location lngFloat]];
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                                @"latlng", latLngString,
                                @"sensor", @"true", nil];
        reverseGeoURLResource = [@"json" appendQueryParams:params];
        [rkGeoMgr loadObjectsAtResourcePath:reverseGeoURLResource delegate:self]; // Call the reverse Geocoder
        
        currentLocationResTime =  CFAbsoluteTimeGetCurrent() - startTime;
    }
    @catch (NSException *exception) {
        NSLog(@"exception at reverGeocod: %@", exception);
    }
}

#pragma mark UIdatePicker functionality

- (void)selectDate {
    [self.mainTable setUserInteractionEnabled:YES];
     [self.navigationController.navigationBar setUserInteractionEnabled:YES];
    [self showTabbar];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:ANIMATION_STANDART_MOTION_SPEED];
    [toolBar setFrame:CGRectMake(0, 450, 320, 44)];
    [datePicker setFrame:CGRectMake(0, 494, 320, 216)];
    [UIView commitAnimations];
    
    date = [datePicker date];
    [self setTripDate:date];
    [self setTripDateLastChangedByUser:[[NSDate alloc] init]];
    [self setIsTripDateCurrentTime:NO];
    [self setDepartOrArrive:departOrArrive];
    [self updateTripDate];
    [self reloadTables];
}

//---------------------------------------------------------------------------


- (void)selectCurrentDate {
    [self.navigationController.navigationBar setUserInteractionEnabled:YES];
    [self.mainTable setUserInteractionEnabled:YES];
    [self showTabbar];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:ANIMATION_STANDART_MOTION_SPEED];
    [toolBar setFrame:CGRectMake(0, 450, 320, 44)];
    [datePicker setFrame:CGRectMake(0, 494, 320, 216)];
    [UIView commitAnimations];
    
    isTripDateCurrentTime = TRUE;

    [self setTripDateLastChangedByUser:[[NSDate alloc] init]];
    [self setIsTripDateCurrentTime:YES];
    [self setDepartOrArrive:departOrArrive];
    [self updateTripDate];
    [self reloadTables];
}

//---------------------------------------------------------------------------

- (IBAction)openPickerView:(id)sender {
    [self.mainTable setUserInteractionEnabled:NO];
     [self.navigationController.navigationBar setUserInteractionEnabled:NO];
    toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 450, 320, 44)];
    [toolBar setTintColor:[UIColor darkGrayColor]];
    
    if (departOrArrive == DEPART) {
        [departArriveSelector setSelectedSegmentIndex:0];
    } else {
        [departArriveSelector setSelectedSegmentIndex:1];
    }
    UIBarButtonItem *segmentBtn = [[UIBarButtonItem alloc] initWithCustomView:departArriveSelector];
    UIBarButtonItem *flexibaleSpaceBarButton1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *flexibaleSpaceBarButton2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolBar setItems:[NSArray arrayWithObjects:btnNow,flexibaleSpaceBarButton1,segmentBtn,flexibaleSpaceBarButton2,btnDone, nil]];
    [self.view bringSubviewToFront:toolBar];
    [self.view bringSubviewToFront:datePicker];

    [self.view addSubview:toolBar];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:ANIMATION_STANDART_MOTION_SPEED];
    [toolBar setFrame:CGRectMake(0, 160, 320, 44)];
    [datePicker setFrame:CGRectMake(0, 204, 320, 216)];
    [UIView commitAnimations];
}

// at Segment change 
-(void)segmentChange {
    if ([departArriveSelector selectedSegmentIndex] == 0) {
        departOrArrive = DEPART;
    } else {
        departOrArrive = ARRIVE;
        // Move date to at least one hour from now if not already
        NSDate* nowPlus1hour = [[NSDate alloc] initWithTimeIntervalSinceNow:(60.0*60)];  // 1 hour from now
        if ([date earlierDate:nowPlus1hour] == date) { // if date is earlier than 1 hour from now
            date = nowPlus1hour;
            [datePicker setDate:date animated:YES];
        }
    }
}

#pragma mark Hide and Show Tabbar

- (void) hideTabBar {
    [[nc_AppDelegate sharedInstance].twitterCount setHidden:YES];
    for(UIView *view in self.tabBarController.view.subviews)
    {
        CGRect _rect = view.frame;
        if([view isKindOfClass:[UITabBar class]])
        {
            _rect.origin.y = 480;
            [view setFrame:_rect];
        } else {
            _rect.size.height = 480;
            [view setFrame:_rect];
        }
    }   
}

- (void) showTabbar {
    [[nc_AppDelegate sharedInstance].twitterCount setHidden:NO];
    for(UIView *view in self.tabBarController.view.subviews)
    {
        CGRect _rect = view.frame;
        if([view isKindOfClass:[UITabBar class]]){
            _rect.origin.y = 431;
            [view setFrame:_rect];
        }
        else if([view isKindOfClass:[UIButton class]]){
            _rect.size.height = 42;
            [view setFrame:_rect];
            
        }
        else {
            _rect.size.height = 431;
            [view setFrame:_rect];
        }
    }   
    RXCustomTabBar *rxCustomTabbar = (RXCustomTabBar *)self.tabBarController;
    [rxCustomTabbar showNewTabBar];
}


@end