//
//  ToFromViewController.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "ToFromViewController.h"
#import "Locations.h"

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
@synthesize modelDataStore;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"ToFro"];
    }
    return self;
}

// One-time set-up of the RestKit Geocoder Object Manager's mapping
- (void)setRkGeoMgr:(RKObjectManager *)rkGeoMgr0
{
    rkGeoMgr = rkGeoMgr0;  //set the property

    // Add the mapper from Location class to this Object Manager
    [[rkGeoMgr mappingProvider] setMapping:[Location objectMappingForApi:GOOGLE_GEOCODER] forKeyPath:@"results"];
}

// One-time set-up of the RestKit Trip Planner Object Manager's mapping
- (void)setRkPlanMgr:(RKObjectManager *)rkPlanMgr0
{
    rkPlanMgr = rkPlanMgr0;
    
    // Add the mapper from Plan class to this Object Manager
    // TODO  Get the right Key Path for trip planner results
    [[rkPlanMgr mappingProvider] setMapping:[Plan objectMappingforPlanner:OTP_PLANNER] forKeyPath:@"plan"];
}


// Table view management methods

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
        
    if (!cell) {
        cell = [[UITableViewCell alloc] 
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:@"UITableViewCell"];
    }
    
    // If this is the from table...
    if (tableView == fromAutoFill) {
        [[cell textLabel] setText:@"Current Location"];
    }
    else { // if this is the to table...
        [[cell textLabel] setText:@"Destination"];
    }
    return cell;
}

// Delegate for when text entered into the to: or from: UITextField
- (IBAction)toFromTextEntry:(id)sender forEvent:(UIEvent *)event 
{
    // Determine whether this is the To: or the From: field
    BOOL isFrom = false;
    routeRequested = false;
    if (sender == fromField) {
        isFrom = true;
    }
    NSLog(@"In toFromTextEntry and isFrom=%d", isFrom);
    
    // Determine whether user pressed the "Route" button on the To: field 
    if (!isFrom) {
        // TODO determine whether the route button has been pressed.  For now assume true if it is the TO: field
        routeRequested = true;
    }
    
    NSString* rawAddress = [sender text];
    if ([rawAddress length] > 0) {
    
        // Check if we already have a geocoded location that has used this rawAddress before
        Location* matchingLocation = [locations locationWithRawAddress:rawAddress];
        if (matchingLocation) { //if we got a match, then use the existing location object 
            if (isFrom) {
                fromLocation = matchingLocation;
            }
            else {
                toLocation = matchingLocation;
            }
            // If routeRequested by user and we have both latlngs, then request a route and reset to false
            if (routeRequested && [fromLocation latLng] && [toLocation latLng]) {
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
        NSString* response = [[objectLoader response] bodyAsString];
        NSInteger statusCode = [[objectLoader response] statusCode];
        NSLog(@"Planning HTTP status code = %d", statusCode);
        NSLog(@"Planning response: %@", response);
        if (objects && [objects objectAtIndex:0]) {
            plan = [objects objectAtIndex:0];
            NSLog(@"Planning object: %@", plan);
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
                NSLog(@"%@", location);
                NSLog(@"Formatted Address: %@", [location formattedAddress]);
                NSLog(@"Types: %@", [location types]);
                
                // Determine whether this is the To: or the From: field geocoding
                bool isFrom = false;
                if ([[objectLoader resourcePath] isEqualToString:fromURLResource]) {
                    isFrom = true;
                    [location addRawAddress:fromRawAddress];
                }
                else {
                    [location addRawAddress:toRawAddress];
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
                if (routeRequested && [fromLocation latLng] && [toLocation latLng]) {
                    [self getPlan];
                    routeRequested = false;  
                }
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
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    NSLog(@"Error received from RKObjectManager:");
    NSLog(@"%@", error);
}


// Routine for calling and populating a trip-plan object
- (bool)getPlan
{
    // Increment fromFrequency and toFrequency
    [fromLocation incrementFromFrequency];
    [toLocation incrementToFrequency];
    
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
                            @"fromPlace", [[fromLocation latLng] latLngPairStr], 
                            @"toPlace", [[toLocation latLng] latLngPairStr], 
                            @"date", [dFormat stringFromDate:dateTime],
                            @"time", [tFormat stringFromDate:dateTime], nil];
    planURLResource = [@"plan" appendQueryParams:params];

    NSLog(@"Plan resource: %@", planURLResource);
    
    // Call the trip planner
    [rkPlanMgr loadObjectsAtResourcePath:planURLResource delegate:self];
    
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
