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

@implementation ToFromViewController
@synthesize fromField;
@synthesize toField;
@synthesize toAutoFill;
@synthesize fromAutoFill;
@synthesize rkGeoMgr;
@synthesize rkPlanMgr;
@synthesize locations;
@synthesize fromLocation;
@synthesize toLocation;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"Nimbler"];
    }
    planRequestHistory = [NSMutableArray array]; // Initialize this array
    return self;
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


// Table view management methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BOOL isFrom = ((tableView == fromAutoFill) ? YES : NO);
    return [locations numberOfLocations:isFrom];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
        
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:@"UITableViewCell"];
    }

    // Set fonts for title and 
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];

    BOOL isFrom = ((tableView == fromAutoFill) ? YES : NO);
    Location *loc = [locations locationAtIndex:[indexPath row] isFrom:isFrom];
    
    [[cell textLabel] setText:[loc formattedAddress]];

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
    BOOL isFrom = ((tableView == fromAutoFill) ? YES : NO);
    Location *loc = [locations locationAtIndex:[indexPath row] isFrom:isFrom];  //selected Location
    
    // Set the new checkmark and fill the corresponding text box with the formatted address from the selected location
    if (isFrom) {
        if (fromSelectedCell) { // if a previous cell is selected
            fromSelectedCell.accessoryType = UITableViewCellAccessoryNone; // turn off its selector
        }
        fromSelectedCell = [fromAutoFill cellForRowAtIndexPath:indexPath];  // get the new selected cell
        fromSelectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [fromField setText:[loc formattedAddress]]; // fill the text in the from text box
    } 
    else {
        if (toSelectedCell) { // if a previous cell is selected
            toSelectedCell.accessoryType = UITableViewCellAccessoryNone; // turn off its selector
        }
        toSelectedCell = [toAutoFill cellForRowAtIndexPath:indexPath];  // get the new selected cell
        toSelectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [toField setText:[loc formattedAddress]];
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

// Delegate methods for when the RestKit has results from the Geocoder or the Planner
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{        
    // See whether this is a response from Geocoding or from the planner
    if ([[objectLoader resourcePath] isEqualToString:planURLResource]) 
    {   // this is a planner result
        NSInteger statusCode = [[objectLoader response] statusCode];
        NSLog(@"Planning HTTP status code = %d", statusCode);
        if (objects && [objects objectAtIndex:0]) {
            plan = [objects objectAtIndex:0];
            NSLog(@"Planning object: %@", [plan ncDescription]);
        }
    }
    else if ([[objectLoader resourcePath] isEqualToString:fromURLResource] ||
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

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    NSLog(@"Error received from RKObjectManager:");
    NSLog(@"%@", error);
}


// Routine for calling and populating a trip-plan object
- (BOOL)getPlan
{
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
        
        // Create the date formatters we will use to output the date & time
        NSDateFormatter* dFormat = [[NSDateFormatter alloc] init];
        [dFormat setDateStyle:NSDateFormatterShortStyle];
        [dFormat setTimeStyle:NSDateFormatterNoStyle];
        NSDateFormatter* tFormat = [[NSDateFormatter alloc] init];
        [tFormat setTimeStyle:NSDateFormatterShortStyle];
        [tFormat setDateStyle:NSDateFormatterNoStyle];
        
        // TODO get the date from the UI, rather than just using current date & time
        NSDate* dateTime = [NSDate date];
        
        // Build the parameters into a resource string
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                @"fromPlace", [fromLocation latLngPairStr], 
                                @"toPlace", [toLocation latLngPairStr], 
                                @"date", [dFormat stringFromDate:dateTime],
                                @"time", [tFormat stringFromDate:dateTime], nil];
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
