//
//  ToFromViewController.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "ToFromViewController.h"
#import "Locations.h"
#import "LocationFromGoogle.h"
#import "UtilityFunctions.h"
#import "RouteOptionsViewController.h"
#import "Leg.h"
#import "PlanStore.h"
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
#import "OTPLeg.h"


@interface ToFromViewController()
{
    // Variables for internal use    
    NSDateFormatter *tripDateFormatter;  // Formatter for showing the trip date / time
    NSString *planURLResource; // URL resource sent to planner
    NSMutableArray *planRequestHistory; // Array of all the past plan request parameter histories in sequential order (most recent one last)
    Plan *plan;
    
    CGFloat toTableHeight;   // Current height of the toTable (US123 implementation)
    CGFloat fromTableHeight;  // Current height of the fromTable
    NSManagedObjectContext *managedObjectContext;
    BOOL toGeocodeRequestOutstanding;  // true if there is an outstanding To geocode request
    BOOL fromGeocodeRequestOutstanding;  //true if there is an outstanding From geocode request
    NSDate* lastReverseGeoReqTime; 
    BOOL savetrip;
    double startButtonClickTime;
    float durationOfResponseTime;
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
- (CGFloat)tableHeightFor:(UITableView *)table;  // Returns the height constant suitable for the particular table
- (BOOL)setToFromHeightForTable:(UITableView *)table Height:(CGFloat)tableHeight;
- (CGFloat)toFromTableHeightByNumberOfRowsForMaxHeight:(CGFloat)maxHeight  isFrom:(BOOL)isFrom;
- (void)newLocationVisible;  // Callback for whenever a new location is made visible to update dynamic table height
-(void)segmentChange;
- (void)selectCurrentDate;
- (void)selectDate;
- (void)reverseGeocodeCurrentLocationIfNeeded;

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
@synthesize timerGettingRealDataByItinerary;
@synthesize activityIndicator;
@synthesize strLiveDataURL;
@synthesize datePicker,toolBar,departArriveSelector,date,btnDone,btnNow;
// Constants for animating up and down the To: field
#define FROM_SECTION 0
#define TO_SECTION 1
#define TIME_DATE_SECTION 2

NSString *currentLoc;
NSUserDefaults *prefs;
UIImage *imageDetailDisclosure;
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
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                toTableHeight = TO_TABLE_HEIGHT_NO_CL_MODE_4INCH;
            }
            else{
                toTableHeight = TO_TABLE_HEIGHT_NO_CL_MODE;
            }
            rect1.size.height = toTableHeight;
            
            toTable = [[UITableView alloc] initWithFrame:rect1 style:UITableViewStylePlain];
            [toTable setRowHeight:TOFROM_ROW_HEIGHT];
            toTableVC = [[ToFromTableViewController alloc] initWithTable:toTable isFrom:FALSE toFromVC:self locations:locations];
            [toTable setDataSource:toTableVC];
            [toTable setDelegate:toTableVC];
            
            // Accessibility Label For UI Automation.
            self.mainTable.accessibilityLabel = TO_TABLE_VIEW;
            
            toTable.layer.cornerRadius = TOFROM_TABLE_CORNER_RADIUS;
            
            CGRect rect2;
            rect2.origin.x = 0;
            rect2.origin.y = 0;               
            rect2.size.width = TOFROM_TABLE_WIDTH; 
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                fromTableHeight = FROM_TABLE_HEIGHT_NO_CL_MODE_4INCH;
            }
            else{
                fromTableHeight = FROM_TABLE_HEIGHT_NO_CL_MODE;
            }
            rect2.size.height = fromTableHeight;
            
            fromTable = [[UITableView alloc] initWithFrame:rect2 style:UITableViewStylePlain];
            [fromTable setRowHeight:TOFROM_ROW_HEIGHT];
            fromTable.layer.cornerRadius = TOFROM_TABLE_CORNER_RADIUS;
            fromTableVC = [[ToFromTableViewController alloc] initWithTable:fromTable isFrom:TRUE toFromVC:self locations: locations];
            
            // Accessibility Label For UI Automation.
            fromTable.accessibilityLabel = FROM_TABLE_VIEW;
            
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
            
            // Accessibility Label For UI Automation.
            barButtonSwap.accessibilityLabel = SWAP_BUTTON;
            
            UIImage* btnCancelImage = [UIImage imageNamed:@"img_cancel.png"];
            UIButton *btnCancel = [[UIButton alloc] initWithFrame:CGRectMake(0,0,btnCancelImage.size.width,btnCancelImage.size.height)];
            [btnCancel addTarget:self action:@selector(endEdit) forControlEvents:UIControlEventTouchUpInside];
            [btnCancel setBackgroundImage:btnCancelImage forState:UIControlStateNormal];
            barButtonCancel = [[UIBarButtonItem alloc] initWithCustomView:btnCancel];
            
            // Accessibility Label For UI Automation.
            barButtonCancel.accessibilityLabel = CANCEL_BUTTON;

        }
        imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->initWithNibName", @"", exception);
    }
    return self;
}
- (void)viewDidLoad{
    [super viewDidLoad];
    
    // Accessibility Label For UI Automation.
    self.mainTable.accessibilityLabel = TO_FROM_TABLE_VIEW;
    
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
        [self.routeButton setFrame:CGRectMake(ROUTE_BUTTON_XPOS_4INCH, ROUTE_BUTTON_YPOS_4INCH, ROUTE_BUTTON_WIDTH_4INCH, ROUTE_BUTTON_HEIGHT_4INCH)];
    }
    //Added To clear The Background Color of UitableView in Ios - 6
    if([[[UIDevice currentDevice] systemVersion] intValue] >= 6){
       [self.mainTable setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_background.png"]]];
    }
    // Added To solve the crash related to ios 4.3
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc]initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
    }
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
    
    // Accessibility Label For UI Automation.
    departArriveSelector.accessibilityLabel = DEPART_OR_ARRIVE_SEGMENT_BUTTON;
    
    departArriveSelector.segmentedControlStyle = UISegmentedControlStyleBar;
    departArriveSelector.selectedSegmentIndex = 1;
    [departArriveSelector addTarget:self action:@selector(segmentChange) forControlEvents:UIControlEventValueChanged];
    
    btnDone = [[UIBarButtonItem alloc] initWithTitle:DATE_PICKER_DONE style:UIBarButtonItemStyleBordered target:self action:@selector(selectDate)];
    
    // Accessibility Label For UI Automation.
    btnDone.accessibilityLabel = DONE_BUTTON;
    
    btnNow = [[UIBarButtonItem alloc] initWithTitle:DATE_PICKER_NOW style:UIBarButtonItemStyleBordered target:self action:@selector(selectCurrentDate)];
    
    // Accessibility Label For UI Automation.
    btnNow.accessibilityLabel = NOW_BUTTON;
    
    // Added To Clear Color Of mainTable for ios 4.3
    if([[[UIDevice currentDevice] systemVersion] intValue] < 5.0){
        [self.mainTable setBackgroundColor: [UIColor clearColor]];
    }
    // Do any additional setup after loading the view from its nib.
}

- (void)setSupportedRegion:(SupportedRegion *)supportedReg0
{
    supportedRegion = supportedReg0;
    [toTableVC setSupportedRegion:supportedReg0];
    [fromTableVC setSupportedRegion:supportedReg0];
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
// Added To Handle Orientation issue in ios-6

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger) supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(self.timerGettingRealDataByItinerary != nil){
        [self.timerGettingRealDataByItinerary invalidate];
        self.timerGettingRealDataByItinerary = nil;
    }
    NIMLOG_PERF1(@"Entered ToFromView viewWillAppear");
    [nc_AppDelegate sharedInstance].isToFromView = YES;
    
    @try {
        // Enforce height of main table
        CGRect rect0 = [mainTable frame];
         if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
             rect0.size.height = TOFROM_MAIN_TABLE_HEIGHT_4INCH;
         }
        else{
           rect0.size.height = TOFROM_MAIN_TABLE_HEIGHT; 
        }
        [mainTable setFrame:rect0];
        logEvent(FLURRY_TOFROMVC_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
        
        isContinueGetRealTimeData = NO;
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
        logException(@"ToFromViewController->viewWillAppear", @"", exception);
    }
    NIMLOG_PERF1(@"Finished ToFromView viewWillAppear");
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [nc_AppDelegate sharedInstance].isToFromView = NO;
    //Part Of US-177 Implementation
    [nc_AppDelegate sharedInstance].toLoc = self.toLocation;
    [nc_AppDelegate sharedInstance].fromLoc = self.fromLocation;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NIMLOG_PERF1(@"Entered ToFromView did appear");
    // Flash scrollbars on tables
    [toTable flashScrollIndicators];
    [fromTable flashScrollIndicators];
    if (isCurrentLocationMode) {
        [self reverseGeocodeCurrentLocationIfNeeded];
    }
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
        if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
            if ([self setToFromHeightForTable:toTable Height:TO_TABLE_HEIGHT_CL_MODE_4INCH]) {
                [self reloadTables];
            }
        }
        else{
            if ([self setToFromHeightForTable:toTable Height:TO_TABLE_HEIGHT_CL_MODE]) {
                [self reloadTables];
            }
        }
    }
}

// Returns the height constant suitable for the particular to or from table with editMode and isCurrentLocationMode
- (CGFloat)tableHeightFor:(UITableView *)table
{
    BOOL is4Inch = ([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT);
    if (table == toTable) {
        if (editMode == NO_EDIT) {
            if (isCurrentLocationMode) {
                return (is4Inch ? TO_TABLE_HEIGHT_CL_MODE_4INCH : TO_TABLE_HEIGHT_CL_MODE);
            } else {
                return (is4Inch ? TO_TABLE_HEIGHT_NO_CL_MODE_4INCH : TO_TABLE_HEIGHT_NO_CL_MODE);
            }
        } else { // EDIT mode
            return (is4Inch ? TO_TABLE_HEIGHT_EDIT_MODE_4INCH : TO_TABLE_HEIGHT_EDIT_MODE);
        }
    }
    else {  // fromTable
        if (editMode == NO_EDIT) {
            if (isCurrentLocationMode) {
                return (is4Inch ? FROM_TABLE_HEIGHT_CL_MODE_4INCH : FROM_TABLE_HEIGHT_CL_MODE);
            } else {
                return (is4Inch ? FROM_TABLE_HEIGHT_NO_CL_MODE_4INCH : FROM_TABLE_HEIGHT_NO_CL_MODE);
            }
        } else { // EDIT mode
            return (is4Inch ? FROM_TABLE_HEIGHT_EDIT_MODE_4INCH : FROM_TABLE_HEIGHT_EDIT_MODE);
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
            logException(@"ToFromViewController->setToFromHeightForTable", @"", exception);
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
    else if ([indexPath section] == TO_SECTION && isCurrentLocationMode && editMode == NO_EDIT) {
        // Special case -- use dynamic toTableHeight for toTable in NO_EDIT and currentLocationMode
        return toTableHeight + TOFROM_INSERT_INTO_CELL_MARGIN;
    }
    else {
        UITableView *toOrFromTable = (([indexPath section] == TO_SECTION) ? toTable : fromTable);
        return TOFROM_INSERT_INTO_CELL_MARGIN + [self tableHeightFor:toOrFromTable]; // Get the right table height constant
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == FROM_SECTION) {
        return TOFROM_SECTION_LABEL_HEIGHT;
    } else if(section == TO_SECTION) {
         return TOFROM_SECTION_LABEL_HEIGHT;
    } else {
        if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
            return TOFROM_SECTION_NOLABEL_HEIGHT_4INCH;
        }
        else{
            return TOFROM_SECTION_NOLABEL_HEIGHT;
        }
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
                
                //Accessibility Label For UIAutomation
                fromTable.accessibilityLabel = @"From Table";
                [cellView addSubview:fromTable]; // add fromTable
            }
        } else {   // do same for toTable case
            if (subviews && [subviews count]>0 && [subviews indexOfObject:toTable] != NSNotFound) {
                // if toTable is already in the subview (due to recycling, no need to add again
            } else {
                 //Accessibility Label For UIAutomation
                toTable.accessibilityLabel = @"To Table";
                [cellView addSubview:toTable]; // add toTable
            }
        }        
        return cell;
    }
    // Else it is the To or From txtField in Edit mode
    BOOL isFrom = (editMode == FROM_EDIT) ? TRUE : FALSE;
    NSString* cellIdentifier = isFrom ? @"fromTxtFieldCell" : @"toTxtFieldCell";
    UITableViewCell *cell =
    
    // By taking out the check for a re-usable cell, we get DE176 fix 1 of 4 (iOS6 keyboard not coming up)
    // [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:cellIdentifier];
    
    UIView* cellView = [cell contentView];
    NSArray* subviews = [cellView subviews];
    
    if (isFrom) {
        if (subviews && [subviews count]>0 && [subviews indexOfObject:[fromTableVC txtField]] != NSNotFound) {
            // if From txtField is already in the subview (due to recycling, no need to add again
        } else { 
            [cellView addSubview:[fromTableVC txtField]]; // add From txtField
        }
        if (![[fromTableVC txtField] isFirstResponder]) {
            [[fromTableVC txtField] becomeFirstResponder]; // DE176 fix 2 of 4
        }
    }
    else {   // do same for toTable case
        if (subviews && [subviews count]>0 && [subviews indexOfObject:[toTableVC txtField]] != NSNotFound) {
            // if To txtField is already in the subview (due to recycling, no need to add again
        } else { 
            [cellView addSubview:[toTableVC txtField]]; // add To txtfield
        }
        if (![[toTableVC txtField] isFirstResponder]) {
            [[toTableVC txtField] becomeFirstResponder]; // DE176 fix 3 of 4
            // NSLog(@"Cell becomeFirstReponder: %d", [cell becomeFirstResponder]);
        }
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == TIME_DATE_SECTION) {  
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
    [[rkGeoMgr mappingProvider] setMapping:[LocationFromGoogle objectMappingForApi:GOOGLE_GEOCODER] forKeyPath:@"results"];
    
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
        // Adjust the toTable & fromTable heights
        [self setToFromHeightForTable:toTable Height:[self tableHeightFor:toTable]];
        [self setToFromHeightForTable:fromTable Height:[self tableHeightFor:fromTable]];

        if (editMode != FROM_EDIT) {
            // DE59 fix -- only update table if not in FROM_EDIT mode
            [mainTable reloadData];
        }
        if (newCLMode) {
            [self reverseGeocodeCurrentLocationIfNeeded];
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
        if (currentLocation && loc == currentLocation && !isCurrentLocationMode) { // Part of DE194 fix
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
        if (loc == currentLocation) {  // if current location chosen for toLocation
            [self reverseGeocodeCurrentLocationIfNeeded];
        }
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
        
        if ([fromLocation isCurrentLocation]) {
            if ([self alertUsetForLocationService]) {
                NSString* msg;   // DE193 fix
                if([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
                    msg = ALERT_LOCATION_SERVICES_DISABLED_MSG;
                } else {
                    msg = ALERT_LOCATION_SERVICES_DISABLED_MSG_V6;
                }
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ALERT_LOCATION_SERVICES_DISABLED_TITLE message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
            NIMLOG_PERF1(@"look for state");
            alert = [[UIAlertView alloc] initWithTitle:@"TripPlanner" message:@"Please select a location" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->routeButtonPressed", @"", exception);
    }
}

// Process an event from MapKit URL directions request
- (void)getRouteForMKDirectionsRequest
{
    NIMLOG_EVENT1(@"MapKit URL request");
    startButtonClickTime = CFAbsoluteTimeGetCurrent();
    
    [self setIsTripDateCurrentTime:YES];
    departOrArrive = DEPART;  // DE203 fix
    [self updateTripDate];
    
    logEvent(FLURRY_MAPKIT_DIRECTIONS_REQUEST,
             FLURRY_FROM_SELECTED_ADDRESS, [fromLocation shortFormattedAddress],
             FLURRY_TO_SELECTED_ADDRESS, [toLocation shortFormattedAddress],
             nil, nil, nil, nil);
    
    [self getPlan];
}

#pragma mark Edit events for ToFrom table
// Method to adjust the mainTable for editing mode
//
- (void)setEditMode:(ToFromEditMode)newEditMode
{
    if (editMode == newEditMode) {
        return;  // If no change in mode return immediately
    }
    NSString *edit_string;
    if (newEditMode==NO_EDIT){
        edit_string = @"NO_EDIT";
    } else if (newEditMode==TO_EDIT) {
        edit_string = @"TO_EDIT";        
    } else if (newEditMode==FROM_EDIT) {
        edit_string = @"FROM_EDIT";            
    }
    logEvent(FLURRY_TOFROMTABLE_NEW_EDIT_MODE,
             FLURRY_EDIT_MODE_VALUE, edit_string,
             nil, nil, nil, nil, nil, nil);
    
    NSRange range;
    ToFromEditMode oldEditMode = editMode;
    editMode = newEditMode;  
    
    // Adjust the heights of the to & from tables, as needed
    [self setToFromHeightForTable:toTable Height:[self tableHeightFor:toTable]];
    [self setToFromHeightForTable:fromTable Height:[self tableHeightFor:fromTable]];
    
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
        [mainTable beginUpdates];
        [mainTable deleteSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationAutomatic];  // Leave only the To section
        [mainTable insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Add a row for txtField
        [mainTable endUpdates];
    } else if (newEditMode == NO_EDIT && oldEditMode == TO_EDIT) {
        range.location = 1;
        range.length = 2;
        [mainTable beginUpdates];
        [mainTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Delete the row for txtField
        [mainTable insertSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable endUpdates];
    } else if (newEditMode == FROM_EDIT && oldEditMode == NO_EDIT) {
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

#pragma mark Reverse Geocoding

- (void)reverseGeocodeCurrentLocationIfNeeded
{
    if (!lastReverseGeoReqTime || 
        [lastReverseGeoReqTime timeIntervalSinceNow] < -(REVERSE_GEO_TIME_THRESHOLD)) {
        if (currentLocation && ![currentLocation isReverseGeoValid]) {
            // If we do not have a reverseGeoLocation that is within threshold, do another reverse geo
            lastReverseGeoReqTime = [NSDate date];
            GeocodeRequestParameters* geoParams = [[GeocodeRequestParameters alloc] init];
            geoParams.lat = [currentLocation latFloat];
            geoParams.lng = [currentLocation lngFloat];
            geoParams.supportedRegion = [self supportedRegion];
            geoParams.isFrom = true;
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= IOS_GEOCODE_VER_THRESHOLD) {
                geoParams.apiType = IOS_GEOCODER;
            } else {
                geoParams.apiType = GOOGLE_GEOCODER;
            }
            [locations reverseGeocodeWithParameters:geoParams callBack:self];
        }
    }
}

// Delegate callback from calling Locations --> reverseGeocodeWithParameters (forward Geocodes do not come from toFromViewController)
-(void)newGeocodeResults:(NSArray *)locationArray withStatus:(GeocodeRequestStatus)status parameters:(GeocodeRequestParameters *)parameters
{
    if (status == GEOCODE_STATUS_OK) {
        if ([locationArray count] > 0) { // if we have an reverse geocode object
            
            // Grab the first reverse-geo, which will be the most specific one
            Location* reverseGeoLocation = [locationArray objectAtIndex:0];
            
            // Check if an equivalent Location is already in the locations table
            reverseGeoLocation = [locations consolidateWithMatchingLocations:reverseGeoLocation keepThisLocation:NO];
            
            // Delete all the other objects out of CoreData (DE152 fix)
            for (int i=1; i<[locationArray count]; i++) {  // starting at the instance after i=0
                [[self locations] removeLocation:[locationArray objectAtIndex:i]];
            }
            // Save db context with the new location object
            saveContext(managedObjectContext);
            NIMLOG_EVENT1(@"Reverse Geocode: %@", [reverseGeoLocation formattedAddress]);
            // Update the Current Location with pointer to the Reverse Geo location
            [currentLocation setReverseGeoLocation:reverseGeoLocation];
        }
    }
    // If there is an error for reverse geocoding, do nothing
}

// Call-back from PlanStore requestPlanFromLocation:... method when it has a plan
-(void)newPlanAvailable:(Plan *)newPlan status:(PlanRequestStatus)status
{
    @try {
        [self stopActivityIndicator];
        durationOfResponseTime = CFAbsoluteTimeGetCurrent() - startButtonClickTime;
        NIMLOG_OBJECT1(@"Plan =%@",newPlan);
        if (status == PLAN_STATUS_OK) {
            plan = newPlan;
            savetrip = FALSE;
            
            // Pass control to the RouteOptionsViewController to display itinerary choices
            if (!routeOptionsVC) {
                routeOptionsVC = [[RouteOptionsViewController alloc] initWithNibName:nil bundle:nil];
            }
            // DE - 155 Fixed
            if([[plan sortedItineraries] count] != 0){
                if(self.timerGettingRealDataByItinerary != nil){
                    [self.timerGettingRealDataByItinerary invalidate];
                    self.timerGettingRealDataByItinerary = nil;
                }
                NSArray *ities = [plan sortedItineraries];
                for (int i=0; i <ities.count ; i++) {
                    [[ities objectAtIndex:i] setItinArrivalFlag:nil];
                    Itinerary *it = [ities objectAtIndex:i];
                    NSArray *legs =  [it sortedLegs];
                    for (int i=0;i<legs.count;i++) {
                        [[legs objectAtIndex:i] setArrivalFlag:nil];
                        [[legs objectAtIndex:i] setArrivalTime:nil];
                        [[legs objectAtIndex:i] setTimeDiffInMins:nil];
                    }
                }
                [routeOptionsVC setPlan:plan];
                [self getRealTimeDataForItinerary];
                self.timerGettingRealDataByItinerary =  [NSTimer scheduledTimerWithTimeInterval:TIMER_STANDARD_REQUEST_DELAY target:self selector:@selector(getRealTimeDataForItinerary) userInfo:nil repeats: YES];
                
                if (fromLocation == currentLocation) {
                    // Update lastRequestReverseGeoLocation if the current one is valid, DE232 fix
                    if ([currentLocation isReverseGeoValid]) {
                        currentLocation.lastRequestReverseGeoLocation = currentLocation.reverseGeoLocation;
                    } else {
                        currentLocation.lastRequestReverseGeoLocation = nil;
                    }
                    // Part Of DE-236 Fxed
                    [[NSUserDefaults standardUserDefaults] setObject:currentLocation.lastRequestReverseGeoLocation.formattedAddress forKey:LAST_REQUEST_REVERSE_GEO];
                    [[NSUserDefaults standardUserDefaults] synchronize];

                }
                // Push the Route Options View Controller
                if([[[UIDevice currentDevice] systemVersion] intValue] < 5.0){
                    CATransition *animation = [CATransition animation];
                    [animation setDuration:0.3];
                    [animation setType:kCATransitionPush];
                    [animation setSubtype:kCATransitionFromRight];
                    [animation setRemovedOnCompletion:YES];
                    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
                    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
                    [[self navigationController] pushViewController:routeOptionsVC animated:NO];
                }
                else{
                    [[self navigationController] pushViewController:routeOptionsVC animated:YES];
                }
            }
            else{
                if([nc_AppDelegate sharedInstance].isToFromView){
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:ALERT_TRIP_NOT_AVAILABLE delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil] ;
                    [alert show];
                }
            }
        }
        else if (status==PLAN_NO_NETWORK) {
            if([nc_AppDelegate sharedInstance].isToFromView){
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Unable to connect to server.  Please try again when you have network connectivity." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                savetrip = false;
            }
        }
        else if (status==PLAN_NOT_AVAILABLE_THAT_TIME) {
            if([nc_AppDelegate sharedInstance].isToFromView){
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"No trips available for the requested time." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                savetrip = false;
            }
        }
        else { // if (status == PLAN_GENERIC_EXCEPTION)
            if([nc_AppDelegate sharedInstance].isToFromView){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:ALERT_TRIP_NOT_AVAILABLE delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
                [alert show];
                savetrip = false;
            }
        }
    }
    @catch (NSException *exception) { 
        logException(@"ToFromViewController->newPlanAvailable", @"", exception);
    }
}


#pragma mark get Plan Request
// Routine for calling and populating a trip-plan object
- (BOOL)getPlan
{
    // See if there has already been an identical plan request in the last 5 seconds.
    @try {
        NIMLOG_PERF1(@"Plan routine entered");
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
            
            if(fromLocation == toLocation ||
               ([fromLocation isCurrentLocation] && [fromLocation isReverseGeoValid] && [fromLocation reverseGeoLocation] == toLocation)) {
                [self stopActivityIndicator];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:@"The To: and From: address are the same location.  Please choose a different destination." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil ];
                [alert show];
                logEvent(FLURRY_ROUTE_TO_FROM_SAME,
                         FLURRY_FROM_SELECTED_ADDRESS, [fromLocation shortFormattedAddress],
                         FLURRY_TO_SELECTED_ADDRESS, [toLocation shortFormattedAddress],
                         nil, nil, nil, nil);
                return true;
            }
            // if using currentLocation, make sure it is in supported region
            if (fromLocation == currentLocation || toLocation == currentLocation) {
                if (![[self supportedRegion] isInRegionLat:[currentLocation latFloat] Lng:[currentLocation lngFloat]]) {
                    [self stopActivityIndicator];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:
                                          @"Your current location does not appear to be in the Bay Area.  Please choose a different location." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil ];
                    [alert show];
                    NSString *supportedRegString = [NSString stringWithFormat:
                                                    @"supportedRegion minLat = %f, minLng = %f, maxLat = %f, maxLng = %f",
                                                    [[supportedRegion minLatitude] floatValue],
                                                    [[supportedRegion minLongitude] floatValue],
                                                    [[supportedRegion maxLatitude] floatValue],
                                                    [[supportedRegion maxLongitude] floatValue]];
                    logEvent(FLURRY_CURRENT_LOCATION_NOT_IN_SUPPORTED_REGION,
                             FLURRY_TOFROM_WHICH_TABLE, (fromLocation == currentLocation ? @"From" : @"To"),
                             FLURRY_LAT, [NSString stringWithFormat:@"%f", [currentLocation latFloat]],
                             FLURRY_LNG, [NSString stringWithFormat:@"%f", [currentLocation lngFloat]],
                             FLURRY_SUPPORTED_REGION_STRING,supportedRegString);
                    NIMLOG_EVENT1(@"Current Location not in supported region\n   currLoc lat = %f\n   currLoc lng = %f\n   supportedRegString = %@",
                                  [currentLocation latFloat], [currentLocation lngFloat] ,supportedRegString);
                    return true;
                }
            }
            logEvent(FLURRY_ROUTE_REQUESTED,
                     FLURRY_FROM_SELECTED_ADDRESS, [fromLocation shortFormattedAddress],
                     FLURRY_TO_SELECTED_ADDRESS, [toLocation shortFormattedAddress],
                     nil, nil, nil, nil);
            
            // add latest plan request to history array
            [planRequestHistory addObject:[NSDictionary dictionaryWithKeysAndObjects:
                                           @"fromPlace", fromLocation, 
                                           @"toPlace", toLocation,
                                           @"date", [NSDate date], nil]];

            // convert miles into meters. 1 mile = 1609.344 meters
            int maxDistance = (int)([[UserPreferance userPreferance] walkDistance]*1609.544);
            
            // Request the plan (callback will come in newPlanAvailable method)
            PlanRequestParameters* parameters = [[PlanRequestParameters alloc] init];
            parameters.fromLocation = fromLocation;
            parameters.toLocation = toLocation;
            parameters.originalTripDate = tripDate;
            parameters.thisRequestTripDate = tripDate;
            parameters.departOrArrive = departOrArrive;
            parameters.maxWalkDistance = maxDistance;
            parameters.planDestination = PLAN_DESTINATION_TO_FROM_VC;
            
            parameters.formattedAddressTO = [toLocation formattedAddress];
            parameters.formattedAddressFROM = [fromLocation formattedAddress];
            parameters.latitudeTO = (NSString *)[toLocation lat];
            parameters.longitudeTO = (NSString *)[toLocation lng];
            parameters.latitudeFROM = (NSString *)[fromLocation lat];
            parameters.longitudeFROM = (NSString *)[fromLocation lng];
            if([fromLocation isCurrentLocation]) {
                parameters.fromType = REVERSE_GEO_FROM;
                parameters.formattedAddressFROM = currentLoc;
                parameters.latitudeTO = (NSString *)[toLocation lat];
                parameters.longitudeTO = (NSString *)[toLocation lng];
            }else if([toLocation isCurrentLocation]) {
                parameters.toType = REVERSE_GEO_TO;
                parameters.formattedAddressTO = currentLoc;
                parameters.latitudeFROM = (NSString *)[fromLocation lat];
                parameters.longitudeFROM = (NSString *)[fromLocation lng];
            }
            if ([locations isFromGeo]) {
                parameters.fromType = GEO_FROM;
                parameters.rawAddressFROM = [fromLocation formattedAddress];
                parameters.timeFROM = [locations geoRespTimeFrom];
            } else if ([locations isToGeo]) {
                parameters.toType = GEO_TO;
                parameters.rawAddressFROM = [fromLocation formattedAddress] ;
                parameters.timeTO = [locations geoRespTimeTo];
            }
            [planStore requestPlanWithParameters:parameters];
            savetrip = TRUE;
            isContinueGetRealTimeData = NO;
            
            // Reload the to/from tables for next time
            [[self fromTable] reloadData];
            [[self toTable] reloadData];
        }
        return true; 
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->getPlan", @"", exception);
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
        logException(@"ToFromViewController->startActivityIndicator", @"", exception);
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


#pragma mark RKResponse Delegate method
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    
    @try {
        NSString *strResuorcePath = [request resourcePath];
        // DE 175 Fixed
        if ([strResuorcePath isEqualToString:strLiveDataURL]) {
                [nc_AppDelegate sharedInstance].isNeedToLoadRealData = YES;
                NIMLOG_OBJECT1(@"response %@", [response bodyAsString]);
                isContinueGetRealTimeData = NO;
                RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];    
                [routeOptionsVC setIsReloadRealData:false];
                [routeOptionsVC setLiveFeed:res];
        }
    }  @catch (NSException *exception) {
        logException(@"ToFromViewController->viewWillAppear", @"getting unique IDs from TP Server response", exception);
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
        if([[[UIDevice currentDevice] systemVersion] intValue] < 5.0){
            CATransition *animation = [CATransition animation];
            [animation setDuration:0.3];
            [animation setType:kCATransitionPush];
            [animation setSubtype:kCATransitionFromRight];
            [animation setRemovedOnCompletion:YES];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [[self.navigationController.view layer] addAnimation:animation forKey:nil];
            [[self navigationController] pushViewController:locationPickerVC animated:NO];
        }
        else{
            [[self navigationController] pushViewController:locationPickerVC animated:YES];
        } 
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->callLocationPickerFor", @"", exception);
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
        logException(@"ToFromViewController->clickedButtonAtIndex", @"", exception);
    }
}

// Get RealTime Data By Itinerary
// DE-252 Fixed.
-(void)getRealTimeDataForItinerary{
    @try {
        isContinueGetRealTimeData = YES;
        NSMutableString *strItineraries = [[NSMutableString alloc] init];
        NSDate *currentDate = [NSDate date];
        NSDate *tripTimeFromDate = timeOnlyFromDate(tripDate);
        NSDate *tripDateFromDate = dateOnlyFromDate(tripDate);
        NSDate *finalTripDate = addDateOnlyWithTimeOnly(tripDateFromDate,tripTimeFromDate);
        NSDate *incCurrentDate = [currentDate dateByAddingTimeInterval:CURRENT_DATE_INC_DEC_INTERVAL];
        NSDate *decCurrentDate = [currentDate dateByAddingTimeInterval:(-CURRENT_DATE_INC_DEC_INTERVAL)];
        NSDate *dateForItineraryComparision = [currentDate dateByAddingTimeInterval:ITINERARY_START_DATE_INC_DEC_INTERVAL];
        
        NSCalendar *calendarCurrentDate = [NSCalendar currentCalendar];
        NSDateComponents *componentsCurrentDate = [calendarCurrentDate components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
        int hourCurrentDate = [componentsCurrentDate hour];
        int minuteCurrentDate = [componentsCurrentDate minute];
        int intervalCurrentDate = hourCurrentDate*60*60 + minuteCurrentDate*60;
        
        NSCalendar *calendarUpdatedCurrentDate = [NSCalendar currentCalendar];
        NSDateComponents *componentsUpdatedCurrentDate = [calendarUpdatedCurrentDate components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
        int hourUpdatedCurrentDate = [componentsUpdatedCurrentDate hour];
        int minuteUpdatedCurrentDate = [componentsUpdatedCurrentDate minute];
        int intervalUpdatedCurrentDate = (hourUpdatedCurrentDate+4)*60*60 + minuteUpdatedCurrentDate*60;
        
        NSCalendar *calendarScheduleDate = [NSCalendar currentCalendar];
        NSDateComponents *componentsScheduleDate = [calendarScheduleDate components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:finalTripDate];
        int hourScheduleDate = [componentsScheduleDate hour];
        int minuteScheduleDate = [componentsScheduleDate minute];
        int intervalScheduleDate = (hourScheduleDate+3)*60*60 + minuteScheduleDate*60;
        
        if(finalTripDate && [finalTripDate compare:decCurrentDate] == NSOrderedDescending && [finalTripDate compare:incCurrentDate] == NSOrderedAscending){
            for (int i= 0; i< [[plan sortedItineraries] count]; i++) {
                Itinerary *itin = [[plan sortedItineraries] objectAtIndex:i];
                                
                NSDate *itineraryCreationdate = [itin startTime];
                NSCalendar *calendarItineraryStartTime = [NSCalendar currentCalendar];
                NSDateComponents *componentsItineraryStartTime = [calendarItineraryStartTime components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[itin startTime]];
                int hourItineraryStartTime = [componentsItineraryStartTime hour];
                int minuteItineraryStartTime = [componentsItineraryStartTime minute];
                int intervalItineraryStartTime = hourItineraryStartTime*60*60 + minuteItineraryStartTime*60;
                
                if(itineraryCreationdate && (([itineraryCreationdate compare:currentDate] == NSOrderedDescending && [itineraryCreationdate compare:dateForItineraryComparision] == NSOrderedAscending) || (intervalItineraryStartTime > intervalCurrentDate && intervalItineraryStartTime < intervalUpdatedCurrentDate))){
                    // Ask for The Real Time Only If itinerary start time is less than schedule Time + 3 hours
                    if(intervalItineraryStartTime < intervalScheduleDate){
                       [strItineraries appendFormat:@"%@,",[itin itinId]]; 
                    }
                }
            }
            if(strItineraries.length > 0){
                [strItineraries deleteCharactersInRange:NSMakeRange([strItineraries length]-1, 1)];
                RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
                [RKClient setSharedClient:client];
                NSDictionary *tempDictionary =[NSDictionary dictionaryWithObjectsAndKeys:strItineraries,ITINERARY_ID,@"true",FOR_TODAY, nil ];
                NSString *req = [LIVE_FEEDS_BY_ITINERARIES_URL appendQueryParams:tempDictionary];
                strLiveDataURL = req;
                [[RKClient sharedClient]  get:req  delegate:self];
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->getRealTimeDataForItinerary", @"", exception);
    }
}

#pragma mark get walk distance from User Defaults

-(void)setFBParameterForGeneral
{
    @try {
        NSString *fromLocs = NULL_STRING;    
        NSDateFormatter* dFormat = [[NSDateFormatter alloc] init];
        [dFormat setDateStyle:NSDateFormatterShortStyle];
        [dFormat setTimeStyle:NSDateFormatterMediumStyle];
        if ([fromLocation isCurrentLocation]) {
            if ([fromLocation reverseGeoLocation]) {
                fromLocs = [NSString stringWithFormat:@"Current Location Reverse Geocode: %@",[[fromLocation reverseGeoLocation] formattedAddress]];
                } else {
                    fromLocs = CURRENT_LOCATION;
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
        logException(@"ToFromViewController->setFBParametersForGeneral", @"", exception);
    }
}

// US132 implementation
-(void)doSwapLocation
{
     // Part Of DE-236 Fxed
    if([[NSUserDefaults standardUserDefaults] objectForKey:LAST_REQUEST_REVERSE_GEO]){
        NSArray* toLocations = [locations locationsWithFormattedAddress:[[NSUserDefaults standardUserDefaults] objectForKey:LAST_REQUEST_REVERSE_GEO]];
        if([toLocations count] > 0){
            currentLocation.lastRequestReverseGeoLocation = [toLocations objectAtIndex:0];
        }
    }
    //DE-237 Fixed
    if(fromLocation == toLocation ||
       ([fromLocation isCurrentLocation] && [fromLocation isReverseGeoValid] && [fromLocation reverseGeoLocation] == toLocation)) {
    }
    else{
        if (fromLocation == currentLocation && [currentLocation lastRequestReverseGeoLocation] &&
            [currentLocation lastRequestReverseGeoLocation] != toLocation) {
            // If from = currentLocation and there is a reverse geolocation
            [toTableVC markAndUpdateSelectedLocation:[currentLocation lastRequestReverseGeoLocation]];
        }
        else {  // do a normal swap
            Location *fromloc = fromLocation;
            Location *toLoc = toLocation;
            // Swap Location (could be nil)
            [toTableVC markAndUpdateSelectedLocation:fromloc];
            [fromTableVC markAndUpdateSelectedLocation:toLoc];
        }
    }
    logEvent(FLURRY_TOFROM_SWAP_LOCATION,
             FLURRY_TO_SELECTED_ADDRESS, [[self toLocation] shortFormattedAddress],
             FLURRY_FROM_SELECTED_ADDRESS, [[self fromLocation] shortFormattedAddress],
             nil, nil, nil, nil);
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

#pragma mark UIdatePicker functionality

- (void)selectDate {
    [self.mainTable setUserInteractionEnabled:YES];
     [self.navigationController.navigationBar setUserInteractionEnabled:YES];
    [nc_AppDelegate sharedInstance].isDatePickerOpen = NO;
    [self showTabbar];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:ANIMATION_STANDART_MOTION_SPEED];
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
        [toolBar setFrame:CGRectMake(0, 500, 320, 44)];
        [datePicker setFrame:CGRectMake(0, 544, 320, 216)];
    }
    else{
        [toolBar setFrame:CGRectMake(0, 450, 320, 44)];
        [datePicker setFrame:CGRectMake(0, 494, 320, 216)];
    }
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
    [nc_AppDelegate sharedInstance].isDatePickerOpen = NO;
    [self.mainTable setUserInteractionEnabled:YES];
    [self showTabbar];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:ANIMATION_STANDART_MOTION_SPEED];
     if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
         [toolBar setFrame:CGRectMake(0, 500, 320, 44)];
         [datePicker setFrame:CGRectMake(0, 544, 320, 216)];
     }
     else{
         [toolBar setFrame:CGRectMake(0, 450, 320, 44)];
         [datePicker setFrame:CGRectMake(0, 494, 320, 216)];
     }
    [UIView commitAnimations];
    
    isTripDateCurrentTime = TRUE;

    [self setTripDateLastChangedByUser:[[NSDate alloc] init]];
    [self setIsTripDateCurrentTime:YES];
    [self setDepartOrArrive:DEPART];  // DE201 fix -- always select Depart if we pick the Now button
    [self updateTripDate];
    [self reloadTables];
}

//---------------------------------------------------------------------------

- (IBAction)openPickerView:(id)sender {
    [self.mainTable setUserInteractionEnabled:NO];
    [nc_AppDelegate sharedInstance].isDatePickerOpen = YES;
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
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
        [toolBar setFrame:CGRectMake(0, 246, 320, 44)];
        [datePicker setFrame:CGRectMake(0, 290, 320, 216)];

    }
    else{
        [toolBar setFrame:CGRectMake(0, 160, 320, 44)];
        [datePicker setFrame:CGRectMake(0, 204, 320, 216)]; 
    }
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
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                _rect.origin.y = 568;
            }
            else{
                _rect.origin.y = 480;
            }
            [view setFrame:_rect];
        }
        else if([view isKindOfClass:[UIImageView class]]){
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                _rect.origin.y = 568;
            }
            else{
                _rect.origin.y = 480;
            }
            [view setFrame:_rect];
        }
        else {
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                _rect.size.height = 568;
            }
            else{
               _rect.size.height = 480; 
            }
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
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                _rect.origin.y = 517;
            }
            else{
               _rect.origin.y = 431; 
            }
            [view setFrame:_rect];
        }
        else if([view isKindOfClass:[UIButton class]]){
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                _rect.size.height = 49;
            }
            else{
               _rect.size.height = 42; 
            }
            [view setFrame:_rect];
            
        }
        else if([view isKindOfClass:[UIImageView class]]){
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                _rect.origin.y = 517;
            }
            else{
                _rect.origin.y = 431;
            }
            [view setFrame:_rect];
        }
        else {
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                 _rect.size.height = 517;
            }
            else{
                _rect.size.height = 431; 
            }
            [view setFrame:_rect];
        }
    }   
    RXCustomTabBar *rxCustomTabbar = (RXCustomTabBar *)self.tabBarController;
    [rxCustomTabbar showNewTabBar];
}
@end