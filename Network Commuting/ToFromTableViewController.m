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
#import "ToFromTableTextFieldView.h"

@interface ToFromTableViewController () 
{
    // Internal variables
    
    UITableViewCell* selectedCell; // Cell currently selected 
    Location* selectedLocation;  // Location currently selected
    ToFromTableTextFieldView* txtField;   // Cell for entering a new address
    NSString *rawAddress;    // user entered raw address
    NSString *urlResource;   // URL resource sent to geocoder for last raw address
    NSManagedObjectContext *managedObjectContext;
    BOOL isTypingReload1;  // True if we just reloaded the tableView due to updated typing.  Cleared after textSubmitted call
    BOOL isSelectionKillKeyboard1;  // True if we are forcing the txtField to resign first responder status because user has made a selection from existing addresses.  Cleared after textSubmitted call
    BOOL isSelectionKillKeyboard2;  // Same as above, but cleared after toFromTyping call
    NSString* lastRawAddressGeoRequest;  // Last raw address sent to the Geocoder, used to avoid duplicate requests
    NSDate* lastGeoRequestTime;  // Time of last Geocoding request, used to avoid duplicate requests
}

@end

@implementation ToFromTableViewController {
    BOOL isGeocodingOutstanding;  
}

@synthesize locations;
@synthesize isFrom;
@synthesize toFromVC;
@synthesize rkGeoMgr;
@synthesize myTableView;

int const TOFROM_ROW_HEIGHT = 35;

- (id)initWithTable:(UITableView *)t isFrom:(BOOL)isF toFromVC:(ToFromViewController *)tfVC locations:(Locations *)l;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        isFrom = isF;
        toFromVC = tfVC;
        locations = l;
        myTableView = t;
        
        isGeocodingOutstanding = FALSE;
        isTypingReload1 = FALSE;
        isSelectionKillKeyboard1 = FALSE;
        isSelectionKillKeyboard2 = FALSE;
        
        // Configure myTableView
        [myTableView setRowHeight:TOFROM_ROW_HEIGHT];

        
        // Create the textField for the first row of the tableView
        txtField=[[ToFromTableTextFieldView alloc]initWithFrame:CGRectMake(0,0,myTableView.frame.size.width,myTableView.rowHeight)];
        [txtField setIsTypingReload:FALSE];
        txtField.autoresizingMask=UIViewAutoresizingFlexibleHeight;
        txtField.autoresizesSubviews=YES;
        [txtField setPlaceholder:@"Enter new address"];
        [txtField addTarget:self action:@selector(toFromTyping:forEvent:) forControlEvents:UIControlEventEditingChanged];
        [txtField addTarget:self action:@selector(textSubmitted:forEvent:) forControlEvents:(UIControlEventEditingDidEnd | UIControlEventEditingDidEndOnExit)];
        [txtField addTarget:self action:@selector(txtFieldFocus:forEvent:) forControlEvents:UIControlEventEditingDidBegin];
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
    return 2; // one section for new address entry, the other for matching results
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;  // this is the new address entry section
    }
    else {
        return[locations numberOfLocations:isFrom]; // matching rows
    }
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] > 0) {   // if it is not the first row (which is the 'enter new address row'
        Location *loc = [locations locationAtIndex:([indexPath row]) isFrom:isFrom];  //selected Location 
        
        // Set the new checkmark and fill the corresponding text box with the formatted address from the selected location
        
        if (selectedCell) { // if a previous cell is selected
            selectedCell.accessoryType = UITableViewCellAccessoryNone; // turn off its selector
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
        } else {
            [locations setTypedToString:@""];  
        }

        if (!isFrom) {  // if it is the To Table
            [toFromVC moveToTable:DOWN];  // Move it back down again 
        }
        
        // Clear the keyboard if txtField is still first responder
        NSLog(@"Resigning first responder status");

        [myTableView endEditing:FALSE];

        [myTableView reloadData];  // Reload the table data with the new sorting  
        
        // scroll to the top of the table
        [myTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        
    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {  // If it is the 'Enter new address' row...
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"ToFromEnterNewLocationCell"];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                          reuseIdentifier:@"ToFromEnterNewLocationCell"];
        }
        
        UIView* cellView = [cell contentView];
        NSArray* subviews = [cellView subviews];
        if (subviews && [subviews count]>0 && [subviews indexOfObject:txtField] != NSNotFound) {
            // if txtField is already in the subview (due to recycling, no need to add again
        } else { 
            [cellView addSubview:txtField]; // add txtField
        }

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
    if (isSelectionKillKeyboard2) { // if user made a location selection and txtField resigned...
        NSLog(@"toFromTyping entered after killing keyboard");
        isSelectionKillKeyboard2 = FALSE; // reset the variable
        return;   // and return immediately (it is a false alarm)
    }
    // Deselect any selected cell
    NSLog(@"Entering toFromTyping: sender = %@, event type = %@, txtField text = '%@'", sender, 
          [event type], [txtField text]);
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
        isTypingReload1 = TRUE;
        [txtField setIsTypingReload:TRUE];
        
        [myTableView reloadData];
    }
}

// Delegate for when complete text entered into the UITextField
- (IBAction)textSubmitted:(id)sender forEvent:(UIEvent *)event 
{
    if (isTypingReload1) {  // if this is just a typing reload case...
        NSLog(@"textSubmitted after typingReload");
        isTypingReload1 = FALSE;  // reset the variable
        return;  // and return immediately (it is a false alarm)
    }
    if (isSelectionKillKeyboard1) { // if user made a location selection and txtField resigned...
        NSLog(@"textSubmitted entered after killing keyboard");
        isSelectionKillKeyboard1 = FALSE; // reset the variable
        return;   // and return immediately (it is a false alarm)
    }
    rawAddress = [sender text];
    
    // Check to make sure this is not a duplicate request
    if ([rawAddress isEqualToString:lastRawAddressGeoRequest] && [lastGeoRequestTime timeIntervalSinceNow] > -5.0) {
        NSLog(@"Skipping duplicate toFromTextSubmitted");
        return;  // if using the same rawAddress and less than 5 seconds between, treat as duplicate
    }
    
    NSLog(@"In toFromTextSubmitted and isFrom=%d", isFrom);

    if (!isFrom) {  // if it is the To Table
        [toFromVC moveToTable:DOWN];  // Move it back down again 
    }
    if ([rawAddress length] > 0) {
        
        // Check if we already have a geocoded location that has used this rawAddress before
        Location* matchingLocation = [locations locationWithRawAddress:rawAddress];
        if (!matchingLocation) {  // if no matching raw addresses, check for matching formatted addresses
            NSArray *matchingLocations = [locations locationsWithFormattedAddress:rawAddress];
            if ([matchingLocations count] > 0) {
                matchingLocation = [matchingLocations objectAtIndex:0];  // Get the first matching location
            }
        }
        if (matchingLocation) { //if we got a match, send that location back to toFromVC 
            [toFromVC updateToFromLocation:self isFrom:isFrom location:matchingLocation];
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

- (IBAction)txtFieldFocus:(id)sender forEvent:(UIEvent *)event
{
    if (!isFrom) { // if this is the ToField that received focus
        [toFromVC moveToTable:UP];  // Move to Table up so that you can see it above the keyboard
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
                
                // Update ToFromViewController with the geocode results
                [toFromVC updateToFromLocation:self isFrom:isFrom location:location];
                [toFromVC updateGeocodeStatus:FALSE isFrom:isFrom];  // let it know Geocode no longer outstanding

                // Save db context with the new location object
                saveContext(managedObjectContext);
                
                // Clear txtField and select the current item
                [txtField setText:@""];
                if (isFrom) {
                    [locations setSelectedFromLocation:location]; // Sort location to top of list  next time
                    [locations setTypedFromString:@""];
                } else {
                    [locations setSelectedToLocation:location]; // Sort location to top of list next time
                    [locations setTypedToString:@""];
                }
                if (selectedCell) { // if a previous cell is selected
                    selectedCell.accessoryType = UITableViewCellAccessoryNone; // turn off its selector
                }
                [myTableView reloadData];  // Reload the data with the new sorting
                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:1]; // The top row (which now should be the selected item)
                selectedCell = [myTableView cellForRowAtIndexPath:indexPath];  // get the new selected cell
                selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
                
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
