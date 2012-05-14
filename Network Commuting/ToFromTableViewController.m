//
//  ToFromTableViewController.m
//  Nimbler
//
//  Created by John Canfield on 5/6/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "ToFromTableViewController.h"
#import "ToFromViewController.h"
#import "UtilityFunctions.h"

@interface ToFromTableViewController () 
{
    // Internal variables
    
    UITableViewCell* selectedCell; // Cell currently selected 
    Location* selectedLocation;  // Location currently selected
    NSString *rawAddress;    // user entered raw address
    NSString *urlResource;   // URL resource sent to geocoder for last raw address
    NSManagedObjectContext *managedObjectContext;
    NSString* lastRawAddressGeoRequest;  // Last raw address sent to the Geocoder, used to avoid duplicate requests
    NSDate* lastGeoRequestTime;  // Time of last Geocoding request, used to avoid duplicate requests
}

- (void)markAndUpdateSelectedLocation:(Location *)loc;  // Updates the selected location to be loc (in locations object, in toFromVC, and in the table selected cell

@end

@implementation ToFromTableViewController {
    BOOL isGeocodingOutstanding;  
}

@synthesize locations;
@synthesize isFrom;
@synthesize toFromVC;
@synthesize rkGeoMgr;
@synthesize myTableView;
@synthesize txtField;

- (id)initWithTable:(UITableView *)t isFrom:(BOOL)isF toFromVC:(ToFromViewController *)tfVC locations:(Locations *)l;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        isFrom = isF;
        toFromVC = tfVC;
        locations = l;
        myTableView = t;
        
        isGeocodingOutstanding = FALSE;
        
        // Create the textField for the first row of the tableView
        txtField=[[UITextField alloc]initWithFrame:CGRectMake(0,0,myTableView.frame.size.width,[myTableView rowHeight])];
        [txtField setPlaceholder:@"Enter new address"];
        [txtField addTarget:self action:@selector(toFromTyping:forEvent:) forControlEvents:UIControlEventEditingChanged];
        [txtField addTarget:self action:@selector(textSubmitted:forEvent:) forControlEvents:(UIControlEventEditingDidEndOnExit)];
    }
    return self;
}

- (void)setRkGeoMgr:(RKObjectManager *)rkG
{
    rkGeoMgr = rkG;
    managedObjectContext = [[rkGeoMgr objectStore] managedObjectContext]; // Get the Managed Object Context associated with rkGeoMgr0
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

//
// Table view management methods
//

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([toFromVC editMode] == NO_EDIT) {
        return 2; // one section for new address entry, the other for matching results
    }
    // Else if in edit mode, do not show "Enter new address" mode
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([toFromVC editMode] == NO_EDIT &&  section == 0) {
        return 1;  // this is the new address entry section
    }
    else {
        return[locations numberOfLocations:isFrom]; // matching rows
    }
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
<<<<<<< HEAD
    NSLog(@"Select Row: isFrom=%d, section=%d, row=%d", isFrom, [indexPath section], [indexPath row]);
    if ([toFromVC editMode] == NO_EDIT && [indexPath section] == 0) { // "Enter New Address" cell
        if (isFrom) {
            [toFromVC setEditMode:FROM_EDIT]; 
=======
    if ([indexPath section] > 0) {   // if it is not the first row (which is the 'enter new address row'
        Location *loc = [locations locationAtIndex:([indexPath row]) isFrom:isFrom];  //selected Location 
        
        // Set the new checkmark and fill the corresponding text box with the formatted address from the selected location
        
        if (selectedCell) { // if a previous cell is selected
            //selectedCell.accessoryType = UITableViewCellAccessoryNone; // turn off its selector
            selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        selectedCell = [tableView cellForRowAtIndexPath:indexPath];  // get the new selected cell
        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        // Update the ToFromViewController
        [toFromVC updateGeocodeStatus:FALSE isFrom:isFrom]; // let know this table is no longer waiting for geocoding
        [toFromVC updateToFromLocation:self isFrom:isFrom location:loc]; // update with new location
        
        // Update selectedLocation in locations, 
        selectedLocation = loc;
        [locations updateSelectedLocation:loc isFrom:isFrom]; // puts loc at the top of the sort order
        
        // Prepare to kill the keyboard
        isSelectionKillKeyboard1 = TRUE;
        isSelectionKillKeyboard2 = TRUE;
        
        // Clear the txtField if it is not clear already
        [txtField setText:@""];
        // reload the matching text tables with latest data
        if (isFrom) {  
            [locations setTypedFromString:@""];  
>>>>>>> apprikaTP1
        } else {
            [toFromVC setEditMode:TO_EDIT];
        }
    }
    // Else it is one of the locations which was selected
    else {
        Location *loc = [locations locationAtIndex:([indexPath row]) isFrom:isFrom];  //selected Location 
        
        [self markAndUpdateSelectedLocation:loc];  // Mark the selected location and send updates to locations and toFromVC
        
        // Have toFromVC end the edit mode
        [toFromVC setEditMode:NO_EDIT];  
    }
}

// Internal utility function to pdates the selected location to be loc 
// (in locations object, in toFromVC, and in the table selected cell
- (void)markAndUpdateSelectedLocation:(Location *)loc
{
    // Update ToFromViewController with the geocode results
    [toFromVC updateToFromLocation:self isFrom:isFrom location:loc];
    [toFromVC updateGeocodeStatus:FALSE isFrom:isFrom];  // let it know Geocode no longer outstanding
    
    // Clear txtField and select the current item
    [txtField setText:@""];
    if (isFrom) {
        [locations setSelectedFromLocation:loc]; // Sort location to top of list  next time
        [locations setTypedFromString:@""];
    } else {
        [locations setSelectedToLocation:loc]; // Sort location to top of list next time
        [locations setTypedToString:@""];
    }
    selectedLocation = loc;   
    if (selectedCell) { // if a previous cell is selected
        selectedCell.accessoryType = UITableViewCellAccessoryNone; // turn off its selector
    }
    [myTableView reloadData];  // Reload the data with the new sorting
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:1]; // The top row (which now should be the selected item)
    selectedCell = [myTableView cellForRowAtIndexPath:indexPath];  // get the new selected cell
    [myTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];     // scroll to the top of the table
    selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([toFromVC editMode]==NO_EDIT && [indexPath section] == 0) {  // If it is the 'Enter new address' row...
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"ToFromEnterNewLocationCell"];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                          reuseIdentifier:@"ToFromEnterNewLocationCell"];
        }
        
        [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
        [[cell textLabel] setTextColor:[UIColor lightGrayColor]];
        [[cell textLabel] setText:@"Enter New Address"];
        return cell;

    }
    
    // If not the 'Enter new address row', show the appropriate location cell
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"ToFromTableLocationRow"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:@"ToFromTableLocationRow"];
    }
    
    // Prepare the cell settings
    
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
    Location *loc = [locations locationAtIndex:([indexPath row]) isFrom:isFrom];
    [[cell textLabel] setText:[loc shortFormattedAddress]];

    // Put a checkmark on the selected location, and remove checkmarks from all others
    if (loc == selectedLocation) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone; 
    }
    return cell;
    
    // In the future, we can support Nicknames by putting formatted address into subtitle, as shown below
    /* if ([loc nickName]) {   // if there is a nickname, put that in the top row
     [[cell textLabel] setText:[loc nickName]];
     NSLog(@"Subtitle formatted address: %@", [loc formattedAddress]);
     [[cell detailTextLabel] setText:[loc formattedAddress]];
     } else {  // if no nickname, just show one row with the formatted address */

}

// 
// txtField editing callback methods
//

// Delegate for when text is typed into the to: or from: UITextField (see below for when text submitted)
// This method updates the to & from table to reflect entries that match the text
- (IBAction)toFromTyping:(id)sender forEvent:(UIEvent *)event {

    // Deselect any selected cell
    if (selectedCell) {
        [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
        selectedCell = nil; 
    }
    if (selectedLocation) {
        selectedLocation = nil;
        [locations updateSelectedLocation:nil isFrom:isFrom];
        [toFromVC updateToFromLocation:self isFrom:isFrom location:nil];
    }
    if (isFrom) {
        [locations setTypedFromString:[txtField text]];
    } else {
        [locations setTypedToString:[txtField text]];
    }
    
    if ([locations areMatchingLocationsChanged]) {  //if typing has changed matrix, reload the array
        [myTableView reloadData];
    }
}

// Delegate for when complete text entered into the UITextField
- (IBAction)textSubmitted:(id)sender forEvent:(UIEvent *)event 
{
    rawAddress = [sender text];
    
    // Check to make sure this is not a duplicate request
    NSLog(@"Raw address = %@", rawAddress);
    NSLog(@"Last raw address = %@", lastRawAddressGeoRequest);
    NSLog(@"time since last request = %f", [lastGeoRequestTime timeIntervalSinceNow]);
    if ([rawAddress isEqualToString:lastRawAddressGeoRequest] && [lastGeoRequestTime timeIntervalSinceNow] > -5.0) {
        NSLog(@"Skipping duplicate toFromTextSubmitted");
        return;  // if using the same rawAddress and less than 5 seconds between, treat as duplicate
    }
    
    NSLog(@"In toFromTextSubmitted and isFrom=%d", isFrom);

    [toFromVC setEditMode:NO_EDIT];  // Move back to NO_EDIT mode on the ToFrom view controller

    if ([rawAddress length] > 0) {
        
        // Check if we already have a geocoded location that has used this rawAddress before
        Location* matchingLocation = [locations locationWithRawAddress:rawAddress];
        if (!matchingLocation) {  // if no matching raw addresses, check for matching formatted addresses
            NSArray *matchingLocations = [locations locationsWithFormattedAddress:rawAddress];
            if ([matchingLocations count] > 0) {
                matchingLocation = [matchingLocations objectAtIndex:0];  // Get the first matching location
            }
        }
        if (matchingLocation) { //if we got a match, mark and send appropriate updates 
            [self markAndUpdateSelectedLocation:matchingLocation];
        }
        else {  // if no match, Geocode this new rawAddress
            // Keep a history to avoid duplicates
            lastRawAddressGeoRequest = rawAddress;
            lastGeoRequestTime = [[NSDate alloc] init];
            
            // Build the parameters into a resource string
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: @"address", rawAddress, 
                                    @"sensor", @"true", nil];
            urlResource = [@"json" appendQueryParams:params];

            NSLog(@"Geocode Parameter String = %@", urlResource);
            
            // Call the geocoder
            [rkGeoMgr loadObjectsAtResourcePath:urlResource delegate:self];
            if (!isGeocodingOutstanding) {
                isGeocodingOutstanding = TRUE;
                [toFromVC updateGeocodeStatus:TRUE isFrom:isFrom]; // alert toFromVC re: outstanding geocoding
            }
        }
    }
}


// Delegate methods for when the RestKit has results from the Geocoder

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{
    // Make sure this is the response from the latest geocoder request
    if ([[objectLoader resourcePath] isEqualToString:urlResource])
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
                NSLog(@"Formatted Address: %@", [location formattedAddress]);
                // NSLog(@"Lat/Lng: %@", [location latLngPairStr]);
                // NSLog(@"Types: %@", [location types]);
                // NSLog(@"Address Components: %@", [[location addressComponents] allObjects]);
                
                // Initialize some of the values for location
                [location setGeoCoderStatus:status];
                [location setApiTypeEnum:GOOGLE_GEOCODER];
                
                // Add the raw address to this location
                [location addRawAddressString:rawAddress];
                
                // Check if an equivalent Location is already in the locations table
                location = [locations consolidateWithMatchingLocations:location];
                
                // Save db context with the new location object
                saveContext(managedObjectContext);
                
                // Mark the 
                [self markAndUpdateSelectedLocation:location];
                
            }
            else if ([status compare:@"ZERO_RESULTS" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                // TODO error handling for zero results
                NSLog(@"Zero results geocoding address");
             UIAlertView  *alert = [[UIAlertView alloc] initWithTitle:@"TripLocation" message:@"No valid location found" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                return;
                
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


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
