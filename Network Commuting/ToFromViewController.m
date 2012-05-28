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
#import "twitterSearch.h"

@interface ToFromViewController()
{
    // Variables for internal use
    
    NSDateFormatter *tripDateFormatter;  // Formatter for showing the trip date / time
    NSString *planURLResource; // URL resource sent to planner
    NSMutableArray *planRequestHistory; // Array of all the past plan request parameter histories in sequential order (most recent one last)
    Plan *plan;
    Plan *pl;
    SupportedRegion *sr;
    FeedBackForm *fbplan;
    BOOL routeRequested;   // True when the user has pressed the route button and a route has not yet been requested
    NSManagedObjectContext *managedObjectContext;
    BOOL toGeocodeRequestOutstanding;  // true if there is an outstanding To geocode request
    BOOL fromGeocodeRequestOutstanding;  // true if there is an outstanding From geocode request
    BOOL savetrip;
    double startButtontClickTime;
    float durationOfResponseTime;
    
}

- (BOOL)getPlan;


@end


@implementation ToFromViewController
@synthesize mainTable;
@synthesize toTable;
@synthesize toTableVC;
@synthesize fromTable;
@synthesize fromTableVC;
@synthesize routeButton;
@synthesize feedbackButton;
@synthesize rkGeoMgr;
@synthesize rkPlanMgr;
@synthesize rkSavePlanMgr;
@synthesize locations;
@synthesize fromLocation;
@synthesize toLocation;
@synthesize currentLocation;
@synthesize departOrArrive;
@synthesize tripDate;
@synthesize tripDateLastChangedByUser;
@synthesize connecting;
@synthesize rkBayArea;
@synthesize editMode;
static SupportedRegion *regionArea;
// Constants for animating up and down the To: field
int const MAIN_TABLE_HEIGHT = 358;
int const TOFROM_ROW_HEIGHT = 35;
int const TOFROM_TABLE_HEIGHT = 105;
int const TOFROM_TABLE_WIDTH = 300; 
int const TIME_DATE_HEIGHT = 45;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"Nimbler"];

        planRequestHistory = [NSMutableArray array]; // Initialize this array
        departOrArrive = DEPART;
        routeRequested = FALSE;
        toGeocodeRequestOutstanding = FALSE;
        fromGeocodeRequestOutstanding = FALSE;

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
        rect1.size.width = TOFROM_TABLE_WIDTH;
        rect1.size.height = TOFROM_TABLE_HEIGHT;
        toTable = [[UITableView alloc] initWithFrame:rect1 style:UITableViewStylePlain];
        [toTable setRowHeight:TOFROM_ROW_HEIGHT];
        toTableVC = [[ToFromTableViewController alloc] initWithTable:toTable isFrom:FALSE toFromVC:self locations:locations];
        [toTable setDataSource:toTableVC];
        [toTable setDelegate:toTableVC];
        
        CGRect rect2;
        rect2.origin.x = 0;
        rect2.origin.y = 0;
        rect2.size.width = TOFROM_TABLE_WIDTH; 
        rect2.size.height = TOFROM_TABLE_HEIGHT;
        fromTable = [[UITableView alloc] initWithFrame:rect2 style:UITableViewStylePlain];
        [fromTable setRowHeight:TOFROM_ROW_HEIGHT];
        fromTableVC = [[ToFromTableViewController alloc] initWithTable:fromTable isFrom:TRUE toFromVC:self locations: locations];
        [fromTable setDataSource:fromTableVC];
        [fromTable setDelegate:fromTableVC];   
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateTripDate];  // update tripDate if needed
    
    // Enforce height of main table
    CGRect rect0 = [mainTable frame];
    rect0.size.height = MAIN_TABLE_HEIGHT;
    [mainTable setFrame:rect0];

    @try {
        [toTable reloadData];
        [fromTable reloadData];
        [mainTable reloadData];
    }
    @catch (NSException *exception) {
        NSLog(@"------loading---------  %@", exception);
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Flash scrollbars on tables
    [toTable flashScrollIndicators];
    [fromTable flashScrollIndicators];
}

// Update trip date to the current time if needed
- (void)updateTripDate
{
    NSDate* currentTime = [[NSDate alloc] init];
    if (!tripDate) {
        tripDate = currentTime;   // if no date set, use current time
        departOrArrive = DEPART;
    }
    else { 
        if (!tripDateLastChangedByUser || [tripDateLastChangedByUser timeIntervalSinceNow] < -7200.0) { 
            // if tripDate not changed in the last two hours by user, we may update it...
            NSDate* laterDate = [tripDate laterDate:currentTime]; 
            if (laterDate == currentTime) {  // if currentTime is later than tripDate, update to current time
                tripDate = currentTime;
                departOrArrive = DEPART; 
            }
        }
    }
}


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

- (void)saveRkPlanMgr:(RKObjectManager *)rkPlanMgr1
{
    rkSavePlanMgr = rkPlanMgr1;
    // Add the mapper from Plan class to this Object Manager
    [[rkSavePlanMgr mappingProvider] setMapping:[Plan objectMappingforPlanner:OTP_PLANNER] forKeyPath:@"plan"];
}
- (void)setRk:(RKObjectManager *)rkBayAreaa
{
    rkBayArea = rkBayAreaa;
    
    // Add the mapper from Plan class to this Object Manager
    [[rkBayArea mappingProvider] setMapping:[Plan objectMappingforPlanner:BAYAREA_PLANNER] forKeyPath:@"graphMetadata"];
}

- (void)setLocations:(Locations *)l
{
    locations = l;
    
    // Now also update the to & from Table View Controllers with the locations object
    [toTableVC setLocations:l];
    [fromTableVC setLocations:l];
}

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
    if (editMode == NO_EDIT && [indexPath section] == 0) {  // Time/Date section
        return TIME_DATE_HEIGHT;
    }  
    else if (editMode != NO_EDIT && [indexPath row] == 0) {  // txtField row in Edit mode
        return TOFROM_ROW_HEIGHT;
    }
    // Else To/From table sections
    return TOFROM_TABLE_HEIGHT;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (editMode == NO_EDIT) {
        if (section == 0) {
            return nil;  // no title for the time/date field section
        } else if (section == 1) {
            return @"From:";
        } else {
            return @"To:";
        }
    }
    // else, if in Edit mode
    if (editMode == FROM_EDIT) {
        return @"From:";
    }
    // else
    return @"To:";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editMode == NO_EDIT && [indexPath section] == 0) {  // the timeDate section
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"timeDateTableCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
                                          reuseIdentifier:@"timeDateTableCell"];
        }        
        [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
        [[cell textLabel] setText:((departOrArrive==DEPART) ? @"Depart at" : @"Arrive by")];
        [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:14.0]];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [[cell detailTextLabel] setText:[tripDateFormatter stringFromDate:tripDate]];
        return cell;
    }
    else if (editMode==NO_EDIT || [indexPath row] == 1) { // the to or from table sections
        BOOL isFrom = (editMode==FROM_EDIT || (editMode==NO_EDIT && [indexPath section]==1))
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
    //TO add Current Location
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [addButton addTarget:self action:@selector(addLocationAction:) forControlEvents:UIControlEventTouchUpInside];
    addButton.frame = CGRectMake(270, 5, 25, 25);
    [cellView addSubview:addButton];
    
    NSArray* subviews = [cellView subviews];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            
    if (isFrom) {
        if (subviews && [subviews count]>0 && [subviews indexOfObject:[fromTableVC txtField]] != NSNotFound) {
            NSLog(@"fromTable already in subview");
            [prefs setObject:@"fromEdit" forKey:@"isEdit"];
            // if From txtField is already in the subview (due to recycling, no need to add again
        } else { 
            [cellView addSubview:[fromTableVC txtField]]; // add From txtField
        }
    }
    else {   // do same for toTable case
        if (subviews && [subviews count]>0 && [subviews indexOfObject:[toTableVC txtField]] != NSNotFound) {
            NSLog(@"toTable already in subview");
            [prefs setObject:@"toEdit" forKey:@"isEdit"];
            // if To txtField is already in the subview (due to recycling, no need to add again
        } else { 
            [cellView addSubview:[toTableVC txtField]]; // add To txtfield
        }
    }        
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {  // if dateTime section
        DateTimeViewController *dateTimeVC = [[DateTimeViewController alloc] initWithNibName:nil bundle:nil];
        [dateTimeVC setDate:tripDate];
        [dateTimeVC setDepartOrArrive:departOrArrive];
        [dateTimeVC setToFromViewController:self];
        [[self navigationController] pushViewController:dateTimeVC animated:YES];
        return;
    }

}


// ToFromTableViewController callbacks 
// (for when user has selected or entered a new location)


// Callback from ToFromTableViewController to update a new user entered/selected location
- (void)updateToFromLocation:(id)sender isFrom:(BOOL)isFrom location:(Location *)loc; {
    
    if (isFrom) {
        fromLocation = loc;
        [self bayAreaAvailibility:fromLocation];

        
    } else {
        toLocation = loc;
        [self bayAreaAvailibility:toLocation];

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
    
    // If there is an outstanding plan request that has not been submitted, and we are now clear in terms of no outstanding geocodes, go ahead and submit the plan
    if (routeRequested && !toGeocodeRequestOutstanding && !fromGeocodeRequestOutstanding) {
        [self getPlan];
        routeRequested = FALSE;
    }
}

// Requesting a plan

- (IBAction)routeButtonPressed:(id)sender forEvent:(UIEvent *)event
{
  //Alert with Progressbar 
    UIAlertView *alert;
    if ([fromLocation formattedAddress ] == NULL) {
        alert = [[UIAlertView alloc] initWithTitle:@"TripPlanner" message:@"Fill FromTrip location address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    } else if( [toLocation formattedAddress ] == NULL) {
        alert = [[UIAlertView alloc] initWithTitle:@"TripPlanner" message:@"Fill ToTrip location address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    } else {
        connecting = [self WaitPrompt];
    }
   // [alert dismissWithClickedButtonIndex:0 animated:NO];
    
    routeRequested = true;
    startButtontClickTime = CFAbsoluteTimeGetCurrent();
    
    // TODO put up a "thinking" graphic
    // if all the geolocations are here, get a plan.  
    if ([fromLocation formattedAddress] && [toLocation formattedAddress] &&
        !toGeocodeRequestOutstanding && !fromGeocodeRequestOutstanding) {
        [self getPlan];
        routeRequested = false;  
    }
    // if user has not entered/selected fromLocation, send them an alert
    else if (![fromLocation formattedAddress] && !fromGeocodeRequestOutstanding) {
        // TODO put up an alert asking them to type in or select a from address
    }
    // if user has not entered has not entered/selected toLocation, send them an alert
    else if (![toLocation formattedAddress] && !toGeocodeRequestOutstanding) {
        // TODO put up an alert asking them to type in or select a to address
    }    
    // otherwise, just wait for the geocoding and then submit the plan
    
}

- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    [TestFlight openFeedbackView];
    FeedBackForm *legMapVC = [[FeedBackForm alloc] initWithNibName:@"FeedBackForm" bundle:nil];   
    [[self navigationController] pushViewController:legMapVC animated:YES];
}

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
        // Delete first & second sections (moving To Table to top)
        range.location = 0;
        range.length = 2;
        [mainTable beginUpdates];
        [mainTable deleteSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationAutomatic];  // Leave only the To section
        [mainTable insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Add a row for txtField
        [mainTable endUpdates];
    } 
    else if (newEditMode == NO_EDIT && oldEditMode == TO_EDIT) {
        range.location = 0;
        range.length = 2;
        [mainTable beginUpdates];
        [mainTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone]; // Delete the row for txtField
        [mainTable insertSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationAutomatic];
        [mainTable endUpdates];
    }
    else if (newEditMode == FROM_EDIT && oldEditMode == NO_EDIT) {
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
                    durationOfResponseTime = CFAbsoluteTimeGetCurrent() - startButtontClickTime;
                    [connecting dismissWithClickedButtonIndex:0 animated:NO];
                    // Pass control to the RouteOptionsViewController to display itinerary choices
                    RouteOptionsViewController *routeOptionsVC = [[RouteOptionsViewController alloc] initWithStyle:UITableViewStylePlain];
                    //[routeOptionsVC setPlanIdFeedBack:pl];
                    [routeOptionsVC setFeedBackPlanId:pl];
                    [routeOptionsVC setPlan:plan];
                    
                    [[self navigationController] pushViewController:routeOptionsVC animated:YES];
                } else {
                    pl= [objects objectAtIndex:0];
                    [plan setPlanId:[pl planId]];                    
                    NSLog(@"obj foe plan = %@", [pl planId]);
                    
                    for (int i= 0; i< [[pl itineraries] count]; i++) {
                        Itinerary *itin = [[pl sortedItineraries] objectAtIndex:i];
                        [[[plan sortedItineraries] objectAtIndex:i] setItinId:[itin itinId]];
                        for (int j =0; j< [[itin legs] count] ; j++) {
                            Leg *lg = [[itin sortedLegs] objectAtIndex:j]; 
                            [[[[[plan sortedItineraries] objectAtIndex:i] sortedLegs] objectAtIndex:j] setLegId:[lg legId]];
                        }                                                            
                    }
                }
                
                if (savetrip) {
                    
                    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                    [prefs setObject:[[objectLoader  response] bodyAsString] forKey:@"tpPlanner"];
                    
                    savetrip = FALSE;
                    [self forFeedbackProceess];
                    [plan setToLocation:toLocation];
                    [plan setFromLocation:fromLocation];
                    fbplan = [FeedBackForm alloc];
                    NSLog(@"Planning object: %@", [[objectLoader  response] bodyAsString]);
                    
                }
                
            }
        }
        @catch (NSException *exception) {
             [connecting dismissWithClickedButtonIndex:0 animated:NO];
             durationOfResponseTime = CFAbsoluteTimeGetCurrent() - startButtontClickTime;
            NSLog(@"Error object ==============================: %@", exception);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:@"Trip is not possible. Your start or end point might not be safely accessible" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
            [alert show];
            savetrip = false;
            return ;
        }
        
    }
    // If returned value does not correspond to one of the most recent requests, do nothing...
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    [connecting dismissWithClickedButtonIndex:0 animated:NO];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Sorry, we are unable to calculate a route for that To & From address" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];    
    NSLog(@"Error received from RKObjectManager:");
    NSLog(@"%@", error);
}


// Routine for calling and populating a trip-plan object
- (BOOL)getPlan
{
    // TODO See if we already have a similar plan that we can use
    
    // See if there has already been an identical plan request in the last 5 seconds.  
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
        // Increment fromFrequency and toFrequency
        [fromLocation incrementFromFrequency];
        [toLocation incrementToFrequency];
        // Update the dateLastUsed
        [fromLocation setDateLastUsed:[NSDate date]];
        [toLocation setDateLastUsed:[NSDate date]];
        // Save db context with the new location frequencies & dates
        saveContext(managedObjectContext);
        
        if(fromLocation == toLocation){
             [connecting dismissWithClickedButtonIndex:0 animated:NO];
            NSLog(@"Match----------->>>>>>>>>>>> %@  ,%@",fromLocation, toLocation);
                    
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
        
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:[fromLocation rawAddresses] forKey:@"fromRawAddr"];
        [prefs setObject:[toLocation rawAddresses] forKey:@"toRawAddr"];
        [prefs setObject:[fromLocation formattedAddress] forKey:@"fromFormatedAddr"];
        [prefs setObject:[toLocation formattedAddress] forKey:@"fromFormatedAddr"];

        
        // TODO detect and handle case where origin and destination are exactly the same
        
        // Build the parameters into a resource string
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                @"fromPlace", [fromLocation latLngPairStr], 
                                @"toPlace", [toLocation latLngPairStr], 
                                @"date", [dFormat stringFromDate:tripDate],
                                @"time", [tFormat stringFromDate:tripDate], 
                                @"arriveBy", ((departOrArrive == ARRIVE) ? @"true" : @"false"),
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
        [NSTimer scheduledTimerWithTimeInterval: 56.0f target: self selector: @selector(stopProcess) userInfo: nil repeats: NO];
        savetrip = TRUE;
        // Reload the to/from tables for next time
        [[self fromTable] reloadData];
        [[self toTable] reloadData];
    }
    return true; 
}

-(void)stopProcess
{
    NSLog(@"stop Processing");
    [connecting dismissWithClickedButtonIndex:0 animated:NO];
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(UIAlertView *) WaitPrompt  
{  
    UIAlertView *alert = [[UIAlertView alloc]   
                           initWithTitle:@"Connecting to Trip Planner\nPlease Wait..."   
                           message:nil delegate:nil cancelButtonTitle:nil  
                           otherButtonTitles: nil];  
    
    [alert show];  
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]  
                                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];  
    
    indicator.center = CGPointMake(alert.bounds.size.width / 2,   
                                   alert.bounds.size.height - 50);  
    [indicator startAnimating];  
    [alert addSubview:indicator];  
        
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];  
    
    return alert;
}  
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)bayAreaAvailibility:(Location *)location
{
    if( [location formattedAddress] != nil){       
        
        if([location formattedAddress] == @"Current Location"){
         double latitude = [[location lat] doubleValue];
         double longitude = [[location lng] doubleValue];        
         NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps/geo?q=%f,%f&output=csv", latitude, longitude];   
         NSURL *url = [NSURL URLWithString:urlString];
         NSString *locationString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];   
         NSArray *streetName = [locationString componentsSeparatedByString:@"\""];
         NSLog(@"Reverse Geocode: %@", [streetName objectAtIndex:1]);
         [location setFormattedAddress:[streetName objectAtIndex:1]];

        }
        if (! ( ([[location lat] doubleValue]>=[[regionArea minLatitude] doubleValue]) && ([[location lng] doubleValue]>=[[regionArea minLongitude] doubleValue]) &&
            ([[location lat] doubleValue]<=[[regionArea maxLatitude] doubleValue]) && ([[location lng] doubleValue]<=[[regionArea maxLongitude] doubleValue])) ) 
        {
            NSString *addr = [location formattedAddress];
            NSString *msg = @"Did not find the address: "; 
            NSString *msg1 = @"in the San Francisco Bay Area";
                       
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:[NSString stringWithFormat:@"%@ %@ %@", msg, addr, msg1] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            return;
        }
    }
}

-(void)setBayArea:(SupportedRegion *)bayAreaRegion
{
    regionArea = [[SupportedRegion alloc] init];
    regionArea = bayAreaRegion;    
}

-(void)addLocationAction:(id) sender{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Current Location",@"Set Location",@"Cancel",nil];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.destructiveButtonIndex = 2;	// make the third button red (destructive)
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

-(void)forFeedbackProceess
{
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *tpPlan = [prefs objectForKey:@"tpPlanner"];
    NSString *udid = [UIDevice currentDevice].uniqueIdentifier;   
    
    RKClient *client = [RKClient clientWithBaseURL:@"http://23.23.210.156:8080/TPServer/ws/plan/"];
    RKParams *rkp = [RKParams params];
    [RKClient setSharedClient:client];
    
    [rkp setValue:udid forParam:@"deviceid"]; 
    [rkp setValue:tpPlan forParam:@"planJsonString"]; 
    NSString *time =  [[NSNumber numberWithFloat:durationOfResponseTime] stringValue]; 
    [rkp setValue:time forParam:@"timeTripPlan"];
    
    [rkp setValue:[prefs objectForKey:@"rawTo"] forParam:@"rawAddTo"];
    [rkp setValue:[toLocation formattedAddress]  forParam:@"frmtdAddTo"];
    [rkp setValue:[prefs objectForKey:@"toType"] forParam:@"toType"];
    [rkp setValue:[prefs objectForKey:@"timeTo"] forParam:@"timeTo"];
    [rkp setValue:[prefs objectForKey:@"geoResponseTo"] forParam:@"geoResTo"];
    
    if([[prefs objectForKey:@"toType"] isEqualToString:REVERSE_GEO_TO])
    {
        [rkp setValue:[toLocation lat] forParam:@"latTo"];
        [rkp setValue:[toLocation lng] forParam:@"lonTo"];
    }
    
    [rkp setValue:[prefs objectForKey:@"rawFrom"] forParam:@"rawAddFrom"];
    [rkp setValue:[fromLocation formattedAddress] forParam:@"frmtdAddFrom"];
    [rkp setValue:[prefs objectForKey:@"fromType"]forParam:@"fromType"];
    [rkp setValue:[prefs objectForKey:@"timeFrom"] forParam:@"timeFrom"];
    [rkp setValue:[prefs objectForKey:@"geoResponseFrom"] forParam:@"geoResFrom"];
    
    if([[prefs objectForKey:@"fromType"] isEqualToString:REVERSE_GEO_FROM])
    {
        [rkp setValue:[fromLocation lat] forParam:@"latTo"];
        [rkp setValue:[fromLocation lng] forParam:@"lonTo"];
    }
    
    [[RKClient sharedClient] post:@"new" params:rkp delegate:self]; 
    
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    if ([request isPOST]) {  
        NSLog(@"Got aresponse back from our POST! %@", [response bodyAsString]);      
        @try {            
            
            NSString *udid = [UIDevice currentDevice].uniqueIdentifier;
            
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                    @"deviceid", udid, 
                                    nil];
            
            rkSavePlanMgr = [RKObjectManager objectManagerWithBaseURL:@"http://23.23.210.156:8080/TPServer/ws/plan/"];
            
            [[rkSavePlanMgr mappingProvider] setMapping:[Plan objectMappingforPlanner:OTP_PLANNER] forKeyPath:@"plan"];
            planURLResource = [@"get" appendQueryParams:params];
            
            [rkSavePlanMgr loadObjectsAtResourcePath:planURLResource delegate:self];

            
        } @catch (NSException *exception) {
          NSLog( @"sfsdfsdfsdf %@", exception);
        }
        
    } 
}


-(void)LogGeoCodingEvent
{    
//    NSString *udid = [UIDevice currentDevice].uniqueIdentifier;
//    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//    
//    [prefs setObject:[fromLocation rawAddresses] forKey:@"fromRawAddr"];
//    [prefs setObject:[toLocation rawAddresses] forKey:@"toRawAddr"];
//    [prefs setObject:[fromLocation formattedAddress] forKey:@"fromFormatedAddr"];
//    [prefs setObject:[toLocation formattedAddress] forKey:@"fromFormatedAddr"];
//    
//    RKClient *client = [RKClient clientWithBaseURL:URL_TPSERVER_GEOCODE];
//    RKParams *rkp = [RKParams params];
//    [RKClient setSharedClient:client];
//
//    [[RKClient sharedClient] post:@"new" params:rkp delegate:self];
    
}

@end
