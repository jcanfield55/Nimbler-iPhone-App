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
    NSString *rawAddress;    // last user entered raw address
    NSString *urlResource;   // URL resource sent to geocoder for last raw address
    NSManagedObjectContext *managedObjectContext;
    NSString* lastRawAddressGeoRequest;  // Last raw address sent to the Geocoder, used to avoid duplicate requests
    NSDate* lastGeoRequestTime;  // Time of last Geocoding request, used to avoid duplicate requests
    NSString* supportedRegionGeocodeString; // Parameter to send to geocoder with the supported Region for viewport biasing

    double startTime;
    float durationResponseTime;
    NSString* geocodeStatus;  // Status string returned by last geocoder call

}

- (void)markAndUpdateSelectedLocation:(Location *)loc;  // Updates the selected location to be loc (in locations object, in toFromVC, and in the table selected cell
- (void)selectedGeocodedLocation:(Location *)loc;  // Internal method to process a new incoming geocoded location (if the only one returned by geocoder, or if this one picked by LocationPickerVC)

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
@synthesize supportedRegion;

- (id)initWithTable:(UITableView *)t isFrom:(BOOL)isF toFromVC:(ToFromViewController *)tfVC locations:(Locations *)l;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        isFrom = isF;
        toFromVC = tfVC;
        locations = l;
        myTableView = t;
        [self setSupportedRegion:[tfVC supportedRegion]]; // Get supportedRegion from parent ToFromViewController
        
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

// Method called when currentLocation is first created and automatically picked as the fromLocation
- (void)initializeCurrentLocation:(Location *)currentLoc
{
    [self markAndUpdateSelectedLocation:currentLoc];
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
    NSLog(@"Select Row: isFrom=%d, section=%d, row=%d", isFrom, [indexPath section], [indexPath row]);
    if ([toFromVC editMode] == NO_EDIT && [indexPath section] == 0) { // "Enter New Address" cell
        
        if (isFrom) {
            [toFromVC setEditMode:FROM_EDIT]; 
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



// Internal utility function to update the selected location to be loc 
// (in locations object, in toFromVC, and in the table selected cell)
- (void)markAndUpdateSelectedLocation:(Location *)loc
{
    
    // Update ToFromViewController with the geocode results
    
    
    [toFromVC updateToFromLocation:self isFrom:isFrom location:loc];
    [toFromVC updateGeocodeStatus:FALSE isFrom:isFrom];  // let it know Geocode no longer outstanding
    
    // Clear txtField and select the current item
    if ([[txtField text] length] > 0) {  // Fix to DE22
        [txtField setText:@""];  // reset txtField if it has been edited
    }
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
     cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
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
    /*
     Set rawAddress for tripSave in TPServer
     */
    if(isFrom){
        [locations setRawAddressFrom:rawAddress];
    } else {
        [locations setRawAddressTo:rawAddress];
    }
    
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
            // US108 implementation (using "bounds" parameter)
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: @"address", rawAddress, 
                                    @"bounds", supportedRegionGeocodeString, @"sensor", @"true", nil];
            urlResource = [@"json" appendQueryParams:params];

            NSLog(@"Geocode Parameter String = %@", urlResource);
            startTime = CFAbsoluteTimeGetCurrent();
                    
            @try {
                // Call the geocoder
                [rkGeoMgr loadObjectsAtResourcePath:urlResource delegate:self];
                if (!isGeocodingOutstanding) {
                    isGeocodingOutstanding = TRUE;
                    [toFromVC updateGeocodeStatus:TRUE isFrom:isFrom]; // alert toFromVC re: outstanding geocoding
                }
            }
            @catch (NSException *exception) {
                NSLog(@"geoLoad Object Error %@", exception);
            }
 
        }
    }
}


// Delegate methods for when the RestKit has results from the Geocoder

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{
    @try {
        UIAlertView  *alert;
        // Make sure this is the response from the latest geocoder request
        if ([[objectLoader resourcePath] isEqualToString:urlResource])
        {   
            // Get the status string the hard way by parsing the response string
            NSString* response = [[objectLoader response] bodyAsString];
           
            if (isFrom) {
                [locations setIsFromGeo:TRUE];
                durationResponseTime = CFAbsoluteTimeGetCurrent() - startTime;
                [locations setGeoRespTimeFrom:[[NSNumber numberWithFloat:durationResponseTime] stringValue]];
                [locations setGeoRespFrom:response];
            } else {
                [locations setIsToGeo:TRUE];
                durationResponseTime = CFAbsoluteTimeGetCurrent() - startTime;
                [locations setGeoRespTimeTo:[[NSNumber numberWithFloat:durationResponseTime] stringValue]];
                [locations setGeoRespTo:response];
            }
            
            NSRange range = [response rangeOfString:@"\"status\""];
            if (range.location != NSNotFound) {
                NSString* responseStartingFromStatus = [response substringFromIndex:(range.location+range.length)];
                
                NSArray* atoms = [responseStartingFromStatus componentsSeparatedByString:@"\""];
                geocodeStatus = [atoms objectAtIndex:1]; // status string is second atom (first after the first quote)
                NSLog(@"Status: %@", geocodeStatus);
                
                if ([geocodeStatus compare:@"OK" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                    NSLog(@"Returned Objects = %d", [objects count]);
                    
                    // Go through the returned objects and see which are in supportedRegion
                    // DE18 new fix
                    NSMutableArray* validLocations = [NSMutableArray arrayWithArray:objects];
                    for (Location* loc in objects) {
                        if (![supportedRegion isInRegionLat:[loc latFloat] Lng:[loc lngFloat]]) {
                            // if a location not in supported region, 
                            [validLocations removeObject:loc]; // take off the array
                            [locations removeLocation:loc]; // and out of Core Data
                        }
                    }
                    NSLog(@"Valid Locations = %d", [validLocations count]);
                    
                    // if no valid locations, give user an alert
                    if ([validLocations count] == 0) { 
                        NSString *msg = [NSString stringWithFormat:@"Did not find the address: '%@' in the San Francisco Bay Area", rawAddress];
                        
                        alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                        [txtField setText:@""];
                        if (isFrom) {
                            [locations setTypedFromString:@""];
                        } else {
                            [locations setTypedToString:@""];
                        }
                        [myTableView reloadData]; 
                    }
                    
                    // else if exactly one validLocation, use that
                    else if ([validLocations count] == 1) {
                        Location* location = [validLocations objectAtIndex:0]; // Get the location object
                        [self selectedGeocodedLocation:location]; // update with new location
                    }
                    
                    // else if more than one validLocation, call up LocationPickerView
                    else if ([validLocations count] > 1) { 
                        [toFromVC callLocationPickerFor:self locationList: validLocations isFrom:isFrom];
                    }
                }
                
                else if ([geocodeStatus compare:@"ZERO_RESULTS" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                    // TODO error handling for zero results
                    NSLog(@"Zero results geocoding address");
                  alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Sorry, No valid location found for your address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    
                    /*
                     Edited By Sitanshu Joshi
                     For Solving DE:27
                     */
                    [txtField setText:@""];
                    if (isFrom) {
                        [locations setTypedFromString:@""];
                    } else {
                        [locations setTypedToString:@""];
                    }
                    [myTableView reloadData];
                    return ;
                    
                }
                else if ([geocodeStatus compare:@"OVER_QUERY_LIMIT" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                    // TODO error handling for over query limit  (switch to other geocoder on my server...)
                    NSLog(@"Over query limit");
                    alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Sorry, Google says your address is over with parameter" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    
                }
                else if ([geocodeStatus compare:@"REQUEST_DENIED" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                    // TODO error handling for denied, invalid or unknown status (switch to other geocoder on my server...)
                    NSLog(@"Request rejected, status= %@", geocodeStatus);
                    alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Sorry, your request is not accepted by google" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
                
            }
            else {
                // TODO Geocoder did not respond with status field
                alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Sorry, geocode is not respond now. Try after some time." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception geocoder ---------------> %@", exception);
    }    
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    NSLog(@"Error received from RKObjectManager:");
    NSLog(@"%@", error);
}

// Internal method to process a new incoming geocoded location (if the only one returned by geocoder, or if this one picked by LocationPickerVC)
- (void)selectedGeocodedLocation:(Location *)location
{
    NSLog(@"Formatted Address: %@", [location formattedAddress]);
    
    // Initialize some of the values for location
    [location setGeoCoderStatus:geocodeStatus];
    [location setApiTypeEnum:GOOGLE_GEOCODER];
    
    // Add the raw address to this location
    [location addRawAddressString:rawAddress];
    
    // Check if an equivalent Location is already in the locations table
    location = [locations consolidateWithMatchingLocations:location];
    
    // Save db context with the new location object
    saveContext(managedObjectContext);
    
    // Mark and update the tableview and ToFromViewController
    [self markAndUpdateSelectedLocation:location];
    
}
// Method called by LocationPickerVC when a user picks a location
- (void)setPickedLocation:(Location *)pickedLocation locationArray:(NSArray *)locationArray
{
    // Remove the locations that were not picked from Core Data
    for (Location* loc in locationArray) {
        if (loc != pickedLocation) {
            [locations removeLocation:loc];
        }
    }
    
    // Use the picked location
    [self selectedGeocodedLocation:pickedLocation];
}


// Update of supportedRegion and generate the geocode parameter string
- (void)setSupportedRegion:(SupportedRegion *)sR0
{
    supportedRegion = sR0;
    
    // Calculate the supportedRegionGeocodeString
    supportedRegionGeocodeString = [NSString stringWithFormat:@"%@,%@|%@,%@", 
                                    [[supportedRegion minLatitude] stringValue],
                                    [[supportedRegion minLongitude] stringValue],
                                    [[supportedRegion maxLatitude] stringValue],
                                    [[supportedRegion maxLongitude] stringValue]];
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
