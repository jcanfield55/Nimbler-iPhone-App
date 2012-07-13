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
#import "DateTimeViewController.h"
#import "TestFlightSDK1/TestFlight.h"
#import "Itinerary.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "FeedBackForm.h"
#import "TwitterSearch.h"
#import "LocationPickerViewController.h"
#import "twitterViewController.h"
#import "SettingInfoViewController.h"
#import "nc_AppDelegate.h"
#import "UIConstants.h"

@interface ToFromViewController()
{
    // Variables for internal use    
    NSDateFormatter *tripDateFormatter;  // Formatter for showing the trip date / time
    NSString *planURLResource; // URL resource sent to planner
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
    BOOL isTwitterLivaData ;
    double startButtonClickTime;
    float durationOfResponseTime;
    UIActivityIndicatorView* activityIndicator;
    NSTimer* activityTimer;
    RouteOptionsViewController *routeOptionsVC; 
    LocationPickerViewController *locationPickerVC;
    TwitterSearch* twitterSearchVC;
}

// Internal methods
- (BOOL)getPlan;
- (void)stopActivityIndicator;
- (void)startActivityIndicator;
// - (void)addLocationAction:(id) sender;
- (BOOL)setToFromHeightForTable:(UITableView *)table Height:(CGFloat)tableHeight;
- (CGFloat)toFromTableHeightByNumberOfRowsForMaxHeight:(CGFloat)maxHeight  isFrom:(BOOL)isFrom;
- (void)newLocationVisible;  // Callback for whenever a new location is made visible to update dynamic table height

@end


@implementation ToFromViewController

@synthesize mainTable;
@synthesize toTable;
@synthesize toTableVC;
@synthesize fromTable;
@synthesize fromTableVC;
@synthesize routeButton;
@synthesize feedbackButton;
@synthesize advisoriesButton;
@synthesize rkGeoMgr;
@synthesize rkPlanMgr;
@synthesize rkSavePlanMgr;
@synthesize locations;
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
@synthesize twitterCount;
@synthesize isContinueGetRealTimeData;
@synthesize continueGetTime;
@synthesize maxiWalkDistance;

// Constants for animating up and down the To: field
#define TO_SECTION 0
#define FROM_SECTION 1
#define TIME_DATE_SECTION 2


NSString *currentLoc;
float currentLocationResTime;

#pragma mark view Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    @try {
        if (self) {
            [[self navigationItem] setTitle:@"Nimbler"];
            UIBarButtonItem *info = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(RedirectAtNimblerSetting)];
            self.navigationItem.rightBarButtonItem = info;
            
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
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at init ToFromViewController");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    isContinueGetRealTimeData = false;
    [continueGetTime invalidate];
    continueGetTime = nil;
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    @try {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        int tweetConut = [[prefs objectForKey:@"tweetCount"] intValue];
        BOOL isUrgent = [[prefs objectForKey:@"isUrgent"] boolValue];
        [twitterCount removeFromSuperview];
        if (isUrgent) {
            twitterCount = [[CustomBadge alloc] initWithString:[NSString stringWithFormat:@"%d!",tweetConut] withStringColor:[UIColor whiteColor] withInsetColor:[UIColor blueColor] withBadgeFrame:YES withBadgeFrameColor:[UIColor whiteColor]];
            [twitterCount setFrame:CGRectMake(50, 360, twitterCount.frame.size.width, twitterCount.frame.size.height)];
            if (tweetConut == 0) {
                [twitterCount setHidden:YES];
            } else {
                [self.view addSubview:twitterCount];
                [twitterCount setHidden:NO];
            }
        } else {
            twitterCount = [[CustomBadge alloc] init];
            twitterCount = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d",tweetConut]];
            [twitterCount setFrame:CGRectMake(60, 365, twitterCount.frame.size.width, twitterCount.frame.size.height)];        
            if (tweetConut == 0) {
                [twitterCount setHidden:YES];
            } else {
                [self.view addSubview:twitterCount];
                [twitterCount setHidden:NO];
            }
        } 
        [continueGetTime invalidate];
        continueGetTime = nil;

        [self updateTripDate];  // update tripDate if needed
        
        // Enforce height of main table
        CGRect rect0 = [mainTable frame];
        rect0.size.height = TOFROM_MAIN_TABLE_HEIGHT;
        [mainTable setFrame:rect0];        
        @try {
            [toTable reloadData];
            [fromTable reloadData];
            [mainTable reloadData];
        }
        @catch (NSException *exception) {
            NSLog(@"table view ------loading---------  %@", exception);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at viewWillAppear: %@", exception);
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Flash scrollbars on tables
    [toTable flashScrollIndicators];
    [fromTable flashScrollIndicators];   
    [self getWalkDistance];
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

    CGFloat fullTableHeight = ([locations numberOfLocations:isFrom] + 1) * TOFROM_ROW_HEIGHT; // +1 for 'Enter New Address' line
    
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
    return 2; // In edit mode, the To or From section has two cells
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (editMode == NO_EDIT) {
        if (section == TIME_DATE_SECTION) {
            return nil;  // no title for the time/date field section
        } else if (section==FROM_SECTION && isCurrentLocationMode) {
            return nil;
        } else if (section==FROM_SECTION && !isCurrentLocationMode) {
            return @"From:";
        }
        else if (section == TO_SECTION) {
            return @"Where are you going?";
        }
    }
    // else, if in Edit mode
    if (editMode == FROM_EDIT) {
        return @"From:";
    }
    // else
    return @"Where are you going?";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editMode == NO_EDIT && [indexPath section] == TIME_DATE_SECTION) {  
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"timeDateTableCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
                                          reuseIdentifier:@"timeDateTableCell"];
            [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
            [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:14.0]];
            [cell setBackgroundColor:[UIColor whiteColor]];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        }        
        
        if (isTripDateCurrentTime) { 
            [[cell textLabel] setText:@"Depart"];
            [[cell detailTextLabel] setText:@"Now"];
        } 
        else {
            [[cell textLabel] setText:((departOrArrive==DEPART) ? @"Depart at" : @"Arrive by")];
            [[cell detailTextLabel] setText:[tripDateFormatter stringFromDate:tripDate]];
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
        }        
        [cell setBackgroundColor:[UIColor whiteColor]];
        [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
        [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:14.0]];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [[cell textLabel] setText:@"From"];
        [[cell detailTextLabel] setText:@"Current Location"];
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
            NSLog(@"fromTable already in subview");
            // if From txtField is already in the subview (due to recycling, no need to add again
        } else { 
            [cellView addSubview:[fromTableVC txtField]]; // add From txtField
        }
    }
    else {   // do same for toTable case
        if (subviews && [subviews count]>0 && [subviews indexOfObject:[toTableVC txtField]] != NSNotFound) {
            NSLog(@"toTable already in subview");
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
        DateTimeViewController *dateTimeVC = [[DateTimeViewController alloc] initWithNibName:nil bundle:nil];
        [dateTimeVC setDate:tripDate];
        [dateTimeVC setDepartOrArrive:departOrArrive];
        [dateTimeVC setToFromViewController:self];
        [[self navigationController] pushViewController:dateTimeVC animated:YES];
        return;
    }
    else if (isCurrentLocationMode && [indexPath section] == FROM_SECTION) {  // if single-row From field selected
        [self setEditMode:FROM_EDIT];  // go into edit mode
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

-(NSString *)getCurrentLocationOfFormattedAddress:(Location *)location
{
    @try {
        double latitude = [[location lat] doubleValue];
        double longitude = [[location lng] doubleValue];  
        float startTime = CFAbsoluteTimeGetCurrent();
        NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps/geo?q=%f,%f&output=csv", latitude, longitude];   
        NSURL *url = [NSURL URLWithString:urlString];
        NSString *locationString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];   
        NSArray *streetName = [locationString componentsSeparatedByString:@"\""];
        currentLoc = [streetName objectAtIndex:1];
        currentLocationResTime =  CFAbsoluteTimeGetCurrent() - startTime;
        return currentLoc;
    }
    @catch (NSException *exception) {
        NSLog(@"exception at reverGeocod: %@", exception);
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
        NSLog(@"Route Button Pressed");
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

- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
        NSString *fromLocs;    
        NSDateFormatter* dFormat = [[NSDateFormatter alloc] init];
        [dFormat setDateStyle:NSDateFormatterShortStyle];
        [dFormat setTimeStyle:NSDateFormatterMediumStyle];
        if ([[fromLocation formattedAddress] isEqualToString:@"Current Location"]) {
            fromLocs = [self getCurrentLocationOfFormattedAddress:fromLocation];
        } else {
            fromLocs = [fromLocation formattedAddress];
        }
        NSLog(@"current Location %@", fromLocs);
        FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:FB_SOURCE_GENERAL uniqueId:nil date:[dFormat stringFromDate:tripDate] fromAddress:fromLocs toAddress:[toLocation formattedAddress]];
        FeedBackForm *feedbackVC =  [[FeedBackForm alloc] initWithFeedBack:@"FeedBackForm" fbParam:fbParam bundle:nil];  // DE56 fix
        [[self navigationController] pushViewController:feedbackVC animated:YES];

    }
    @catch (NSException *exception) {
        NSLog(@"exception at feedback button press from TOFromView: %@", exception);
    }
}

- (IBAction)advisoriesButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        isTwitterLivaData = TRUE;
        NSString *udid = [UIDevice currentDevice].uniqueIdentifier;            
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                @"deviceid", udid,
                                nil];    
        NSString *advisoriesAll = [@"advisories/all" appendQueryParams:params];
        [[RKClient sharedClient]  get:advisoriesAll delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception at advisories button click from ToFromview: %@", exception);
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
    NSRange range;
    ToFromEditMode oldEditMode = editMode;
    editMode = newEditMode;  
    
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
        NSLog(@"to controller ----------------");
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
    // Check to make sure this is the response to the latest planner request
    if ([[objectLoader resourcePath] isEqualToString:planURLResource]) 
    {   
        NSInteger statusCode = [[objectLoader response] statusCode];
        NSLog(@"Planning HTTP status code = %d", statusCode);
        @try {
            if (objects && [objects objectAtIndex:0]) {
                if (savetrip) {
                    plan = [objects objectAtIndex:0];
                                        
                    durationOfResponseTime = CFAbsoluteTimeGetCurrent() - startButtonClickTime;
                    [self stopActivityIndicator];
                    
                    [plan setToLocation:toLocation];
                    [plan setFromLocation:fromLocation];
                    
                    // Pass control to the RouteOptionsViewController to display itinerary choices
                    if (!routeOptionsVC) {
                        routeOptionsVC = [[RouteOptionsViewController alloc] initWithNibName:nil bundle:nil];;
                    }
                    
                    [routeOptionsVC setPlan:plan];                                        
                    [[self navigationController] pushViewController:routeOptionsVC animated:YES];              
                    
                    savetrip = FALSE;
                    [self savePlanInTPServer:[[objectLoader  response] bodyAsString]];
                    NSLog(@"For Feedback Process called");
                } else {
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
                        isContinueGetRealTimeData = TRUE;
                        [self getRealTimeData];
                        continueGetTime =   [NSTimer scheduledTimerWithTimeInterval:59.0 target:self selector:@selector(getRealTimeData) userInfo:nil repeats: YES];
                    }
                    @catch (NSException *exception) {
                        NSLog(@"Exception while iterating over TP response plan: %@", exception);
                    }    
                }                
            }
        }
        @catch (NSException *exception) {            
            [self stopActivityIndicator];
            durationOfResponseTime = CFAbsoluteTimeGetCurrent() - startButtonClickTime ;
            NSLog(@"Exceptione while parsing TP response plan: %@", exception);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:@"Trip is not possible. Your start or end point might not be safely accessible" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
            [alert show];
            savetrip = false;
            return ;
        }
        
    }
    // If returned value does not correspond to one of the most recent requests, do nothing...
}

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
    // TODO See if we already have a similar plan that we can use
    
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
            // Create the date formatters we will use to output the date & time
            NSDateFormatter* dFormat = [[NSDateFormatter alloc] init];
            [dFormat setDateStyle:NSDateFormatterShortStyle];
            [dFormat setTimeStyle:NSDateFormatterNoStyle];
            NSDateFormatter* tFormat = [[NSDateFormatter alloc] init];
            [tFormat setTimeStyle:NSDateFormatterShortStyle];
            [tFormat setDateStyle:NSDateFormatterNoStyle];
            
            NSLog(@"maximum walk distance ------------------------------------ %f",[maxiWalkDistance floatValue]);
            // convert miles into meters. 1 mile = 1609.344 meters
            int maxDistance = (int)([maxiWalkDistance floatValue]*1609.544);
            
            NSLog(@"max walk distance: %d", maxDistance);
            // Build the parameters into a resource string       
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                    @"fromPlace", [fromLocation latLngPairStr], 
                                    @"toPlace", [toLocation latLngPairStr], 
                                    @"date", [dFormat stringFromDate:tripDate],
                                    @"time", [tFormat stringFromDate:tripDate], 
                                    @"arriveBy", ((departOrArrive == ARRIVE) ? @"true" : @"false"),
                                    @"maxWalkDistance", [NSNumber numberWithInt:maxDistance],
                                    nil];
            
            planURLResource = [@"plan" appendQueryParams:params];
            
            // add latest plan request to history array
            [planRequestHistory addObject:[NSDictionary dictionaryWithKeysAndObjects:
                                           @"fromPlace", fromLocation, 
                                           @"toPlace", toLocation,
                                           @"date", [NSDate date], nil]];  
            
            NSLog(@"Plan resource: %@", planURLResource);
            // Call the trip planner
            [rkPlanMgr loadObjectsAtResourcePath:planURLResource delegate:self];
            savetrip = TRUE;
            isContinueGetRealTimeData = FALSE;
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
        [NSTimer scheduledTimerWithTimeInterval:56.0f target:self selector: @selector(stopActivityIndicator) userInfo: nil repeats: NO];
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


/*  Commenting this section out, since it is unused for now, John C 7/3/2012
 
-(void)addLocationAction:(id) sender{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Current Location",@"Set Location",@"Cancel",nil];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.destructiveButtonIndex = 2;    // make the third button red (destructive)
    [actionSheet showInView:self.navigationController.view]; // show from our table view (pops up in the middle of the table)
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{    
    if (buttonIndex == 0){
        
    } else if(buttonIndex == 1){
        
    } else if(buttonIndex == 2){
        NSLog(@"cancel");
        [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    }
}
 */

#pragma mark save Plan and other logging features to TPServer

-(void)savePlanInTPServer:(NSString *)tripResponse
{
        
    @try {
        NSString *udid = [UIDevice currentDevice].uniqueIdentifier;   
        NSString *timeResponseTime =  [[NSNumber numberWithFloat:durationOfResponseTime] stringValue];
        
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        RKParams *rkp = [RKParams params];
        [RKClient setSharedClient:client];
        
        [rkp setValue:udid forParam:@"deviceid"]; 
        [rkp setValue:tripResponse forParam:@"planJsonString"]; 
        [rkp setValue:timeResponseTime forParam:@"timeTripPlan"];
        [rkp setValue:[toLocation formattedAddress]  forParam:@"frmtdAddTo"];
        [rkp setValue:[fromLocation formattedAddress]  forParam:@"frmtdAddFrom"];
        [rkp setValue:[toLocation lat] forParam:@"latFrom"];
        [rkp setValue:[toLocation lng] forParam:@"lonFrom"];
        [rkp setValue:[fromLocation lat] forParam:@"latTo"];
        [rkp setValue:[fromLocation lng] forParam:@"lonTo"];
        
        if([[fromLocation formattedAddress] isEqualToString:@"Current Location"]) {
            [rkp setValue:REVERSE_GEO_FROM forParam:@"fromType"];
            [rkp setValue:currentLoc  forParam:@"frmtdAddFrom"];
            [rkp setValue:[toLocation lat] forParam:@"latFrom"];
            [rkp setValue:[toLocation lng] forParam:@"lonFrom"];
            [rkp setValue:[[NSNumber numberWithFloat:currentLocationResTime] stringValue] forParam:@""];
        } else if([[toLocation formattedAddress] isEqualToString:@"Current Location"]) {
            [rkp setValue:REVERSE_GEO_TO forParam:@"toType"];
            [rkp setValue:currentLoc  forParam:@"frmtdAddTo"];
            [rkp setValue:[fromLocation lat] forParam:@"latTo"];
            [rkp setValue:[fromLocation lng] forParam:@"lonTo"];
            [rkp setValue:[[NSNumber numberWithFloat:currentLocationResTime] stringValue] forParam:@""];
        }
        
        if ([locations isFromGeo]) {
            [rkp setValue:GEO_FROM forParam:@"fromType"];
            [rkp setValue:[fromLocation formattedAddress] forParam:@"rawAddFrom"];
            [rkp setValue:[locations geoRespFrom] forParam:@"geoResFrom"];
            [rkp setValue:[locations geoRespTimeFrom] forParam:@"timeFrom"];
        } else if ([locations isToGeo]) {
            [rkp setValue:GEO_TO forParam:@"toType"];
            [rkp setValue:[fromLocation formattedAddress] forParam:@"rawAddTo"];
            [rkp setValue:[locations geoRespTo] forParam:@"geoResTo"];
            [rkp setValue:[locations geoRespTimeTo] forParam:@"timeTo"];
        }
        
        [[RKClient sharedClient] post:@"plan/new" params:rkp delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at save trip plan in TPServer: %@", exception);
    }
}

#pragma mark RKResponse Delegate method
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    @try {
        RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
        if (isContinueGetRealTimeData) {
            if ([request isGET]) {       
                NSLog(@"response %@", [response bodyAsString]);                
                id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];    
                [routeOptionsVC setIsReloadRealData:false];
                [routeOptionsVC setLiveFeed:res];
            } 
        }
        if (isTwitterLivaData) {
            if ([request isGET]) {       
                NSLog(@"response %@", [response bodyAsString]);
                RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];                
                twitterViewController *twit = [[twitterViewController alloc] init];
                [twit setTwitterLiveData:res];
                [[self navigationController] pushViewController:twit animated:YES];
                isTwitterLivaData = FALSE;
            }
        }
        if ([request isPOST]) {      
            NSString *udid = [UIDevice currentDevice].uniqueIdentifier;            
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                    @"deviceid", udid, 
                                    nil];            
            rkSavePlanMgr = [RKObjectManager objectManagerWithBaseURL:TRIP_PROCESS_URL];            
            [[rkSavePlanMgr mappingProvider] setMapping:[Plan objectMappingforPlanner:OTP_PLANNER] forKeyPath:@"plan"];
            planURLResource = [@"plan/get" appendQueryParams:params];            
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

#pragma mark get Real time data after plan is generated 
-(void)getRealTimeData
{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];   
        NSDictionary *dict = [NSDictionary dictionaryWithKeysAndObjects:
                              @"planid",[plan planId] ,
                              nil];
        NSString *req = [@"livefeeds/plan" appendQueryParams:dict];
        [[RKClient sharedClient]  get:req  delegate:self];  
    }
    @catch (NSException *exception) {
        NSLog(@"exception at real time data request: %@", exception);
    }
}

#pragma mark Navigate in SettingInfoViewController view
-(void)RedirectAtNimblerSetting
{
    @try {
        SettingInfoViewController *settingView = [[SettingInfoViewController alloc] init];
        [[self navigationController] pushViewController:settingView animated:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at navigate to settingInfo view: %@", exception);
    }
}

#pragma mark get walk distance from core data
-(void)getWalkDistance
{
    @try {
        NSManagedObjectContext *moc = [[nc_AppDelegate sharedInstance] managedObjectContext];
        NSEntityDescription *entityDescription = [NSEntityDescription
                                                  entityForName:@"UserPreferance" inManagedObjectContext:moc];
        NSFetchRequest *request = [[NSFetchRequest alloc] init] ;
        [request setEntity:entityDescription];
        
        NSError *error = nil;
        NSArray *arrayUserSetting  = [moc executeFetchRequest:request error:&error];
        if (arrayUserSetting == nil)
        {
            // Deal with error...
        } else {
            // set stored value for userSettings       
            maxiWalkDistance = [[arrayUserSetting valueForKey:@"walkDistance"] objectAtIndex:0] ;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at get data from core data: %@", exception);
    }
}

#pragma mark call Advisories button click at tweeter push notification
-(void)redirectInTwitterAtPushnotification
{
    [self advisoriesButtonPressed:self forEvent:nil];
}

@end