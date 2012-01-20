//
//  ToFromViewController.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "ToFromViewController.h"

@implementation ToFromViewController
@synthesize fromField;
@synthesize toField;
@synthesize toAutoFill;
@synthesize fromAutoFill;
@synthesize rkGeoMgr;
@synthesize fromLocation;
@synthesize toLocation;
@synthesize locations;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// One-time set-up of the RestKit Geocoder Object Manager's mapping

- (void)setRkGeoMgr:(RKObjectManager *)rkGeoMgr0
{
    rkGeoMgr = rkGeoMgr0;  //set the property

    // Add the mapper from Location class to this Object Manager
    [[rkGeoMgr mappingProvider] setMapping:[Location objectMappingforGeocoder:GOOGLE] forKeyPath:@"results"];
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
    BOOL wasRouteKeyPressed = false;
    if (sender == fromField) {
        isFrom = true;
    }
    NSLog(@"In toFromTextEntry and isFrom=%d", isFrom);
    
    // Determine whether user pressed the "Route" button on the To: field 
    if (!isFrom) {
        // TODO determine whether the route button has been pressed.  For now assume true if it is the TO: field
        wasRouteKeyPressed = true;
    }
    
    NSString* rawAddress = [sender text];
    if ([rawAddress length] > 0) {
    
        // Check if we already have a geocoded location that has used this rawAddress before
        Location* matchingLocation = nil;
        for (NSString* key in locations) {
            Location* loc2 = [locations objectForKey:key];
            if ([loc2 isMatchingRawAddress:rawAddress]) {
                matchingLocation = loc2;
                break;
            }
        }
        if (matchingLocation) { //if we got a match, then use the existing location object and increase frequency
            if (isFrom) {
                fromLocation = matchingLocation;
            }
            else {
                toLocation = matchingLocation;
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

// Delegate methods for when the RestKit has results from the Geocoder
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{        
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

            
            // Determine whether this is the To: or the From: field geocoding
            bool isFrom = false;
            if ([[objectLoader resourcePath] isEqualToString:fromURLResource]) {
                isFrom = true;
                [location addRawAddress:fromRawAddress];
            }
            else {
                [location addRawAddress:toRawAddress];
            }
            
            // Check if an equivalent Location is already in the locations dictionary
            Location* matchingLocation = [locations objectForKey:[location formattedAddress]];
            if (!matchingLocation) {  // if no direct match, iterate through and look for equivalent
                for (NSString* key in locations) {
                    Location* loc2 = [locations objectForKey:key];
                    if ([location isEquivalent:loc2]) {
                        matchingLocation = loc2;
                    }
                }
            }
            if (matchingLocation) { // if there is a match, add the rawAddress and use the location from the dictionary
                [matchingLocation addRawAddress:(isFrom ? fromRawAddress : toRawAddress)];
                location = matchingLocation;  // use the location from the dictionary
            }
            else {   // if no match, insert this location into the dictionary
                [locations setObject:location forKey:[location formattedAddress]];
            }
            
            // Increment frequency counter
            if (isFrom) {
                [location setFromFrequency:([location fromFrequency]+1)];
            } else {
                [location setToFrequency:([location toFrequency]+1)];
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

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    NSLog(@"Error received from RKObjectManager:");
    NSLog(@"%@", error);
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
