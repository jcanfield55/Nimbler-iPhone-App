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

@interface ToFromViewController()
{
    // Variables for internal use
    
    NSDateFormatter *tripDateFormatter;  // Formatter for showing the trip date / time
    NSString *planURLResource; // URL resource sent to planner
    NSMutableArray *planRequestHistory; // Array of all the past plan request parameter histories in sequential order (most recent one last)
    Plan *plan;
    BOOL routeRequested;   // True when the user has pressed the route button and a route has not yet been requested
    NSManagedObjectContext *managedObjectContext;
    BOOL toGeocodeRequestOutstanding;  // true if there is an outstanding To geocode request
    BOOL fromGeocodeRequestOutstanding;  // true if there is an outstanding From geocode request
    BOOL isToTableRaised;  // true if the To Field has been raised because of the keyboard
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
@synthesize locations;
@synthesize fromLocation;
@synthesize toLocation;
@synthesize currentLocation;
@synthesize departOrArrive;
@synthesize tripDate;
@synthesize tripDateLastChangedByUser;

// Constants for animating up and down the To: field
int const TO_FIELD_HIGH_Y = 87;
int const TO_FIELD_NORMAL_Y = 197;
int const TO_TABLE_HEIGHT_HIGH_Y = 118;
int const TO_TABLE_HEIGHT_NORMAL_Y = 228;
int const MAIN_TABLE_HEIGHT = 358;
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
        toTableVC = [[ToFromTableViewController alloc] initWithTable:toTable isFrom:FALSE toFromVC:self locations:locations];
        [toTable setDataSource:toTableVC];
        [toTable setDelegate:toTableVC];
        
        CGRect rect2;
        rect2.origin.x = 0;
        rect2.origin.y = 0;
        rect2.size.width = TOFROM_TABLE_WIDTH; 
        rect2.size.height = TOFROM_TABLE_HEIGHT;
        fromTable = [[UITableView alloc] initWithFrame:rect2 style:UITableViewStylePlain];
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

    [toTable reloadData];
    [fromTable reloadData];
    [mainTable reloadData];
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
    if (isToTableRaised) {
        return 2;  // Don't include from table
    } 
    return 3;  // 3 grouped sections in main table

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;  // each section in the mainTable has only one cell 
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {  // Time/Date section
        return TIME_DATE_HEIGHT;
    }  
    else {  // To/From table sections
        return TOFROM_TABLE_HEIGHT+1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;  // no title for the time/date field section
    } else if (section == 1 && !isToTableRaised) {
        return @"From:";
    } else {
        return @"To:";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {  // the timeDate section
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
    else { // the to or from table sections
        BOOL isFrom = (([indexPath section] == 1) && !isToTableRaised) ? TRUE : FALSE;
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
                NSLog(@"fromTable already in subview");
                // if fromTable is already in the subview (due to recycling, no need to add again
            } else { 
                [cellView addSubview:fromTable]; // add fromTable
            }
        }
        else {   // do same for toTable case
            if (subviews && [subviews count]>0 && [subviews indexOfObject:toTable] != NSNotFound) {
                NSLog(@"toTable already in subview");
                // if toTable is already in the subview (due to recycling, no need to add again
            } else { 
                [cellView addSubview:toTable]; // add toTable
            }
        }        
        return cell;
    }

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
    } else {
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
    
    // If there is an outstanding plan request that has not been submitted, and we are now clear in terms of no outstanding geocodes, go ahead and submit the plan
    if (routeRequested && !toGeocodeRequestOutstanding && !fromGeocodeRequestOutstanding) {
        [self getPlan];
        routeRequested = FALSE;
    }
}

// Requesting a plan

- (IBAction)routeButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    routeRequested = true;
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
}

- (void)moveToTable:(moveToTableDirection)direction 
{
    if (direction == UP && !isToTableRaised) {
        isToTableRaised = TRUE;
        [mainTable deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if (direction == DOWN && isToTableRaised) {
        isToTableRaised = FALSE;
        [mainTable insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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
                plan = [objects objectAtIndex:0];
                NSLog(@"Planning object: %@", [plan ncDescription]);
                [plan setToLocation:toLocation];
                [plan setFromLocation:fromLocation];
                
                // Pass control to the RouteOptionsViewController to display itinerary choices
                RouteOptionsViewController *routeOptionsVC = [[RouteOptionsViewController alloc] initWithStyle:UITableViewStylePlain];
                [routeOptionsVC setPlan:plan];
                [[self navigationController] pushViewController:routeOptionsVC animated:YES];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Error object ==============================: %@", exception);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:@"Trip is not possible. Your start or end point might not be safely accessible" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
            [alert show];            
            return ;
        }
        
    }
    // If returned value does not correspond to one of the most recent requests, do nothing...
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
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
            NSLog(@"Match----------->>>>>>>>>>>>");
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
        
        // Reload the to/from tables for next time
        [[self fromTable] reloadData];
        [[self toTable] reloadData];
    }
    return true; 
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
