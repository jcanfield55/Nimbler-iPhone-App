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

@interface ToFromViewController()

typedef enum {
    UP,
    DOWN
} moveToFieldsDirection;

// Utility function for moving the toFields up or down
- (void)moveToFields:(moveToFieldsDirection)direction;
@end

@implementation ToFromViewController
@synthesize timeDateTable;
@synthesize fromField;
@synthesize toField;
@synthesize toAutoFill;
@synthesize fromAutoFill;
@synthesize routeButton;
@synthesize rkGeoMgr;
@synthesize rkPlanMgr;
@synthesize rkErrorMgr;
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
int const TO_AUTOFILL_HIGH_Y = 118;
int const TO_AUTOFILL_NORMAL_Y = 228;
int const AUTOFILL_HEIGHT = 105;
int const TIME_DATE_HEIGHT = 45;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"Nimbler"];
    }
    planRequestHistory = [NSMutableArray array]; // Initialize this array
    departOrArrive = DEPART;
    
    // Initialize the trip date formatter for display
    tripDateFormatter = [[NSDateFormatter alloc] init];
    [tripDateFormatter setDoesRelativeDateFormatting:YES];
    [tripDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [tripDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateTripDate];  // update tripDate if needed
    
    // Enforce the right size for the AutoFill tables
    CGRect rect0 = [timeDateTable frame];
    rect0.size.height = TIME_DATE_HEIGHT;
    [timeDateTable setFrame:rect0];
    
    CGRect rect1 = [toAutoFill frame];
    rect1.size.height = AUTOFILL_HEIGHT;
    [toAutoFill setFrame:rect1];
    
    CGRect rect2 = [fromAutoFill frame];
    rect2.size.height = AUTOFILL_HEIGHT;
    [fromAutoFill setFrame:rect2];
    
    [timeDateTable reloadData];
    [toAutoFill reloadData];
    [fromAutoFill reloadData];
}

// Update trip date to the current time if needed
- (void)updateTripDate
{
    NSDate* currentTime = [[NSDate alloc] init];
    if (!tripDate) {
        tripDate = currentTime;   // if no date set, use current time
    }
    else { 
        if (!tripDateLastChangedByUser || [tripDateLastChangedByUser timeIntervalSinceNow] < -3600.0) { 
            // if tripDate not changed in the last hour, and tripDate in the past, update to currentTime
            tripDate = [tripDate laterDate:currentTime]; 
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
}

// One-time set-up of the RestKit Trip Planner Object Manager's mapping
- (void)setRkPlanMgr:(RKObjectManager *)rkPlanMgr0
{
    rkPlanMgr = rkPlanMgr0;
    
    // Add the mapper from Plan class to this Object Manager
    [[rkPlanMgr mappingProvider] setMapping:[Plan objectMappingforPlanner:OTP_PLANNER] forKeyPath:@"plan"];
    
    
}

- (void)setRkErrorMgr:(RKObjectManager *)rkErrorMgr0
{
    rkErrorMgr = rkErrorMgr0;
    
    // Add the mapper from Plan class to this Object Manager
    [[rkErrorMgr mappingProvider] setMapping:[Error objectMappingforError:ERROR_PLAN] forKeyPath:@"error"];
         
}

// Table view management methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == timeDateTable) {
        return 1;    // we only show one cell in the timeDateTable
    } else {
        BOOL isFrom = ((tableView == fromAutoFill) ? YES : NO);
        return [locations numberOfLocations:isFrom];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If it is the timeDateTable, handle that first
    if (tableView == timeDateTable) {
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
    
    // Otherwise, handle the toAutoFill and fromAutoFill table cases
    
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
        
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:@"UITableViewCell"];
    }

    // Set fonts for title 
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];

    BOOL isFrom = ((tableView == fromAutoFill) ? YES : NO);
    Location *loc = [locations locationAtIndex:[indexPath row] isFrom:isFrom];
    
    [[cell textLabel] setText:[loc shortFormattedAddress]];

    return cell;
    
    // In the future, we can support Nicknames by putting formatted address into subtitle, as shown below
    /* if ([loc nickName]) {   // if there is a nickname, put that in the top row
        [[cell textLabel] setText:[loc nickName]];
        NSLog(@"Subtitle formatted address: %@", [loc formattedAddress]);
        [[cell detailTextLabel] setText:[loc formattedAddress]];
    } else {  // if no nickname, just show one row with the formatted address */
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    NSLog(@"Number of cell %@", indexPath);
    // If timeDateTable, handle that first
    if (tableView == timeDateTable) {
        DateTimeViewController *dateTimeVC = [[DateTimeViewController alloc] initWithNibName:nil bundle:nil];
        [dateTimeVC setDate:tripDate];
        [dateTimeVC setDepartOrArrive:departOrArrive];
        [dateTimeVC setToFromViewController:self];
        [[self navigationController] pushViewController:dateTimeVC animated:YES];
        return;
    }
    
    // Now handle selections on the AutoFill tables
    // TODO if current location, get the current geolocation
    
    BOOL isFrom = ((tableView == fromAutoFill) ? YES : NO);
    Location *loc = [locations locationAtIndex:[indexPath row] isFrom:isFrom];  //selected Location
    
    // Set the new checkmark and fill the corresponding text box with the formatted address from the selected location
    if (isFrom) {
        if (fromSelectedCell) { // if a previous cell is selected
            fromSelectedCell.accessoryType = UITableViewCellAccessoryNone; // turn off its selector
        }
        fromSelectedCell = [fromAutoFill cellForRowAtIndexPath:indexPath];  // get the new selected cell
        //fromSelectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
         
        [fromField setText:[loc shortFormattedAddress]]; // fill the text in the from text box
        fromLocation = loc;
    } else {
        if (toSelectedCell) { // if a previous cell is selected
            toSelectedCell.accessoryType = UITableViewCellAccessoryNone; // turn off its selector
        }
        toSelectedCell = [toAutoFill cellForRowAtIndexPath:indexPath];  // get the new selected cell
       // toSelectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [toField setText:[loc shortFormattedAddress]];
        
        toLocation = loc;
    }
           
}

// Delegate for when text is typed into the to: or from: UITextField (see below for when text submitted)
// This method updates the autoFill table to reflect entries that match the text
- (IBAction)toFromTyping:(id)sender forEvent:(UIEvent *)event {
    BOOL isFrom = ((sender == fromField) ? YES : NO);
    if (isFrom) {
        // Deselect any selected cell
        if (fromSelectedCell) {
            [fromSelectedCell setAccessoryType:UITableViewCellAccessoryNone];
            fromSelectedCell = nil; 
        }
        [locations setTypedFromString:[fromField text]];
        if ([locations areMatchingLocationsChanged]) {  //if typing has changed matrix, reload the array
            [fromAutoFill reloadData];
        }
    }
    else {
        // Deselect any selected cell
        if (toSelectedCell) {
            [toSelectedCell setAccessoryType:UITableViewCellAccessoryNone];
            toSelectedCell = nil; 
        }
        [locations setTypedToString:[toField text]];
        if ([locations areMatchingLocationsChanged]) {
            [toAutoFill reloadData];
        }
    }
}

// Delegate for when complete text entered into the to: or from: UITextField
- (IBAction)toFromTextSubmitted:(id)sender forEvent:(UIEvent *)event 
{
    // Determine whether this is the To: or the From: field
    BOOL isFrom = ((sender == fromField) ? YES : NO);

    routeRequested = false;

    // If to field, move it back down
    [self moveToFields:DOWN];
    
    NSLog(@"In toFromTextSubmitted and isFrom=%d", isFrom);
    
    // Determine whether user pressed the "Route" button on the To: field 
    if (!isFrom) {
        // TODO determine whether the route button has been pressed.  For now assume true if it is the TO: field
        routeRequested = true;
    }
    
    NSString* rawAddress = [sender text];
    if ([rawAddress length] > 0) {
    
        // Check if we already have a geocoded location that has used this rawAddress before
        Location* matchingLocation = [locations locationWithRawAddress:rawAddress];
        if (!matchingLocation) {  // if no matching raw addresses, check for matching formatted addresses
            NSArray *matchingLocations = [locations locationsWithFormattedAddress:rawAddress];
            if ([matchingLocations count] > 0) {
                matchingLocation = [matchingLocations objectAtIndex:0];  // Get the first matching location
            }
        }
        if (matchingLocation) { //if we got a match, then use the existing location object 
            if (isFrom) {
                fromLocation = matchingLocation;
            }
            else {
                toLocation = matchingLocation;
            }
            // If routeRequested by user and we have both latlngs, then request a route and reset to false
            if (routeRequested && [fromLocation formattedAddress] && [toLocation formattedAddress]) {
                // TODO put up a "thinking" graphic
                [self getPlan];
                routeRequested = false;  
            }
        }
        else {  // if no match, Geocode this new rawAddress        
            // Build the parameters into a resource string
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: @"address", rawAddress, 
                                    @"sensor", @"true", nil];
            NSString* resource = [@"json" appendQueryParams:params];
            
            // Update the appropriate raw address and resource variables
            if (isFrom) {
                fromRawAddress = rawAddress;
                fromURLResource = resource;
            }
            else {
                toRawAddress = rawAddress;
                toURLResource = resource;
            }
            NSLog(@"Parameter String = %@", resource);
            
            // Call the geocoder
            [rkGeoMgr loadObjectsAtResourcePath:resource delegate:self];
        }
    }
}

- (IBAction)routeButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    routeRequested = true;
    // TODO put up a "thinking" graphic

    // if all the geolocations are here, get a plan.  
    if ([fromLocation formattedAddress] && [toLocation formattedAddress]) {
        [self getPlan];
        routeRequested = false;  
    }
    // if no formatted addresses...
    if (!fromRawAddress || !toRawAddress) {  // if no raw addresses, then alert the user
        // TODO put up an alert asking them to type in or select an address
    }
    // otherwise, just wait for the geocoding and then submit the plan    

}

// When focus comes to the To field, move it up
- (IBAction)toFieldFocus:(id)sender forEvent:(UIEvent *)event
{
    [self moveToFields:UP];
}

- (void)moveToFields:(moveToFieldsDirection)direction 
{
    if (direction == UP) {
        [fromAutoFill setHidden:TRUE];
    }
    CGRect newRect1 = [toField frame];
    newRect1.origin.y = ((direction == UP) ? TO_FIELD_HIGH_Y : TO_FIELD_NORMAL_Y);
    CGRect newRect2 = [toAutoFill frame];
    newRect2.origin.y = ((direction == UP) ? TO_AUTOFILL_HIGH_Y : TO_AUTOFILL_NORMAL_Y);
    [UIView animateWithDuration:0.5 animations:^{
        [toField setFrame:newRect1];
        [toAutoFill setFrame:newRect2];
    }];
    if (direction == DOWN) {
        [fromAutoFill setHidden:FALSE];
    }
}

// Delegate methods for when the RestKit has results from the Geocoder or the Planner
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{        
    // See whether this is a response from Geocoding or from the planner
    if ([[objectLoader resourcePath] isEqualToString:planURLResource]) 
    {   // this is a planner result
        NSInteger statusCode = [[objectLoader response] statusCode];
        NSLog(@"Planning HTTP status code = %d", statusCode);
        
        @try {
            if (objects && [objects objectAtIndex:0]) {
                plan = [objects objectAtIndex:0];
                
                NSLog(@"Planning object: %@", [plan ncDescription]);
                [plan setToLocation:toLocation];
                [plan setFromLocation:fromLocation];
                
                // The following is commented out code to pre-fetch the maps using Google Maps API for each route
                // This is not needed because using MKMapView object instead
                /*
                 for (Itinerary *itin in [plan itineraries]) {
                 for (Leg *leg in [itin legs]) {
                 NSString *pathParam = [NSString stringWithFormat:@"weight:3|color:orange|enc:%@",
                 [leg legGeometryPoints]];
                 NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                 @"size", @"512x512", @"sensor", @"true",
                 @"path" , pathParam, nil];
                 NSString* resource = [@"json" appendQueryParams:params];
                 NSLog(@"%@ leg path=%@",[leg mode], resource);
                 }
                 }
                 */            
                
                // Pass control to the RouteOptionsViewController to display itinerary choices
                RouteOptionsViewController *routeOptionsVC = [[RouteOptionsViewController alloc] initWithStyle:UITableViewStylePlain];
                [routeOptionsVC setPlan:plan];
                [[self navigationController] pushViewController:routeOptionsVC animated:YES];
                
            }

        }
        @catch (NSException* ex) {
            NSLog(@"doSomethingFancy failed: %@",ex);            
             NSLog(@"Error object ==============================: %@", [error msg]);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:@"Trip is not possible. Your start or end point might not be safely accessible" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
            [alert show];            
            return ;
        }        
        
    }else if ([[objectLoader resourcePath] isEqualToString:fromURLResource] ||
             [[objectLoader resourcePath] isEqualToString:toURLResource])
    {   // this is a Geocoder result
        
        // Get the status string the hard way by parsing the response string
        NSString* response = [[objectLoader response] bodyAsString];
        NSRange range = [response rangeOfString:@"\"status\""];
        if (range.location != NSNotFound) {
            NSString* responseStartingFromStatus = [response substringFromIndex:(range.location+range.length)]; 
            NSArray* atoms = [responseStartingFromStatus componentsSeparatedByString:@"\""];
            NSString* status = [atoms objectAtIndex:1]; // status string is second atom (first after the first quote)
            NSLog(@"Status: %@", status);            
            
            if ([status compare:@"OK" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                if (!objects || [objects count]<1) {
                    // TODO error handling for no object
                }
                else if ([objects count]>1) {
                    // TODO error handling for more than one result
                    NSLog(@"Number of returned Geocodes = %d", [objects count]);
                }
                
                // Get the location object
                Location* location = [objects objectAtIndex:0];
                NSLog(@"Formatted Address: %@", [location formattedAddress]);
                // NSLog(@"Lat/Lng: %@", [location latLngPairStr]);
                // NSLog(@"Types: %@", [location types]);
                // NSLog(@"Address Components: %@", [[location addressComponents] allObjects]);
                
                // Initialize some of the values for location
                [location setGeoCoderStatus:status];
                [location setApiTypeEnum:GOOGLE_GEOCODER];
                
                // Determine whether this is the To: or the From: field geocoding
                BOOL isFrom = false;
                if ([[objectLoader resourcePath] isEqualToString:fromURLResource]) {
                    isFrom = true;
                    [location addRawAddressString:fromRawAddress];
                }
                else {
                    [location addRawAddressString:toRawAddress];
                }
                NSLog(@"RawAddresses: %@", [[location rawAddresses] allObjects]);
                
                // Check if an equivalent Location is already in the locations table
                location = [locations consolidateWithMatchingLocations:location];
                
                // Set toLocation or fromLocation
                if (isFrom) {
                    fromLocation = location;
                } else {
                    toLocation = location;
                }
                
                // If routeRequested by user and we have both latlngs, then request a route and reset to false
                if (routeRequested && [fromLocation formattedAddress] && [toLocation formattedAddress]) {
                    [self getPlan];
                    routeRequested = false;  
                }
                
                // TODO remove this temp test code
                if ([[fromLocation formattedAddress] hasPrefix:@"1350 Hull"]) {
                    [fromLocation setNickName:@"Home"];
                }
                
                // Save db context with the new location object
                saveContext(managedObjectContext);
            }
            else if ([status compare:@"ZERO_RESULTS" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                // TODO error handling for zero results
                NSLog(@"Zero results geocoding address");
            }
            else if ([status compare:@"OVER_QUERY_LIMIT" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                // TODO error handling for over query limit  (switch to other geocoder on my server...)
                NSLog(@"Over query limit");
            }
            else {
                // TODO error handling for denied, invalid or unknown status (switch to other geocoder on my server...)
                NSLog(@"Request rejected, status= %@", status);
            }
        }
        else {
            // TODO Geocoder did not respond with status field
        }
    }
    // If returned value does not correspond to one of the most recent requests, do nothing...
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)errors {
    NSLog(@"Error received from RKObjectManager:");
    NSLog(@"  %@", errors);
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
       
        /*
        Edited by Sitanshu Joshi.
        */
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
                                @"DeviceId", [[UIDevice currentDevice] uniqueIdentifier],
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
        [rkErrorMgr loadObjectsAtResourcePath:planURLResource delegate:self];
        
        // Reload the to/from tables for next time
        [[self fromAutoFill] reloadData];
        [[self toAutoFill] reloadData];
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
