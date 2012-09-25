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
#import "UIConstants.h"
#import "Constants.h"
#import "GeocodeRequestParameters.h"

#if FLURRY_ENABLED
#include "Flurry.h"
#endif


@interface ToFromTableViewController () 
{
    // Internal variables
    Location* selectedLocation;  // Location currently selected
    NSString *rawAddress;    // last user entered raw address
    NSManagedObjectContext *managedObjectContext;
    NSString* lastRawAddressGeoRequest;  // Last raw address sent to the Geocoder, used to avoid duplicate requests
    NSDate* lastGeoRequestTime;  // Time of last Geocoding request, used to avoid duplicate requests

    double startTime;
    float durationResponseTime;
}

- (void)selectedGeocodedLocation:(Location *)loc;  // Internal method to process a new incoming geocoded location (if the only one returned by geocoder, or if this one picked by LocationPickerVC)
- (NSInteger)adjustedForEnterNewAddressFor:(NSInteger)rawIndexRow;

@end

@implementation ToFromTableViewController {
    BOOL isGeocodingOutstanding;
    UIImage *imageDetailDisclosure;
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
        txtField=[[UITextField alloc]initWithFrame:CGRectMake(TOFROM_TEXT_FIELD_XPOS,TOFROM_TEXT_FIELD_YPOS,myTableView.frame.size.width-TOFROM_TEXT_FIELD_INDENT,[myTableView rowHeight]-TOFROM_INSERT_INTO_CELL_MARGIN)];
        [txtField setPlaceholder:@"Enter new address"];
        [txtField setClearButtonMode:UITextFieldViewModeAlways]; // Add a clear button for text field
        [txtField setFont:[UIFont MEDIUM_FONT]];
        [txtField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        
        [txtField addTarget:self action:@selector(toFromTyping:forEvent:) forControlEvents:UIControlEventEditingChanged];
        [txtField addTarget:self action:@selector(textSubmitted:forEvent:) forControlEvents:(UIControlEventEditingDidEndOnExit)];
        [txtField setBackgroundColor:[UIColor whiteColor]];
        imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
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
    return 1;  // one section only
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([toFromVC editMode] == NO_EDIT && !selectedLocation) {  // DE122 fix
        return ([locations numberOfLocations:isFrom] + 1); // matching rows + 1 for "Enter New Address" Row
    }
    else {
        return [locations numberOfLocations:isFrom];  // matching rows only
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NIMLOG_EVENT1(@"Select Row: isFrom=%d, section=%d, row=%d", isFrom, [indexPath section], [indexPath row]);
        
    if ([self adjustedForEnterNewAddressFor:[indexPath row]] == -1) {  // "Enter New Address" cell
        if (isFrom) {
            [toFromVC setEditMode:FROM_EDIT]; 
        } else {
            [toFromVC setEditMode:TO_EDIT];
        }
    }
    // Else it is one of the locations which was selected
    else {
        
        Location *loc = [locations 
                         locationAtIndex:[self adjustedForEnterNewAddressFor:[indexPath row]]
                         isFrom:isFrom];  //selected Location 
        // If user tapped the selected location, then go into Edit Mode if not there already
        if ([toFromVC editMode] == NO_EDIT && loc == selectedLocation) {
            if (isFrom) {
                [toFromVC setEditMode:FROM_EDIT]; 
            } else {
                [toFromVC setEditMode:TO_EDIT];
            }
        }
        else {
            [toFromVC setEditMode:NO_EDIT];  // Have toFromVC end the edit mode (DE96 fix)
            
            if ([[loc locationType] isEqualToString:TOFROM_LIST_TYPE]) { // If a list (like 'Caltrain Station List')
#if FLURRY_ENABLED          
                NSString* isFromString = (isFrom ? @"fromTable" : @"toTable");          
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                        FLURRY_TOFROM_WHICH_TABLE, isFromString,          
                                        FLURRY_SELECTED_ROW_NUMBER, [NSString stringWithFormat:@"%d",[indexPath row]],
                                        nil];          
                [Flurry logEvent:FLURRY_TOFROMTABLE_CALTRAIN_LIST withParameters:params];          
#endif
                // Increment frequency of the list header
                if (isFrom) {
                    [loc incrementFromFrequency];
                } else {
                    [loc incrementToFrequency];
                }
                
                // Call the location picker with the list
                NSArray* list = [locations locationsMembersOfList:[loc memberOfList]];
                [toFromVC callLocationPickerFor:self 
                                   locationList:list 
                                         isFrom:isFrom
                               isGeocodeResults:NO];
            }
            else {    // if a normal location
#if FLURRY_ENABLED      
                NSString* isFromString = (isFrom ? @"fromTable" : @"toTable");
                NSString* selectedAddressParam = (isFrom ? FLURRY_FROM_SELECTED_ADDRESS : FLURRY_TO_SELECTED_ADDRESS);
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                        FLURRY_TOFROM_WHICH_TABLE, isFromString,          
                                        FLURRY_SELECTED_ROW_NUMBER, [NSString stringWithFormat:@"%d",[indexPath row]],          
                                        selectedAddressParam, [loc shortFormattedAddress], nil];          
                [Flurry logEvent:FLURRY_TOFROMTABLE_SELECT_ROW withParameters:params];          
#endif
                [self markAndUpdateSelectedLocation:loc];  // Mark the selected location and send updates to locations and toFromVC
            }
        }
    }
}


// Internal utility function to update the selected location to be loc 
// (in locations object, in toFromVC, and in the table selected cell)
- (void)markAndUpdateSelectedLocation:(Location *)loc
{
    if ([[loc formattedAddress] isEqualToString:CURRENT_LOCATION]) {
        if ([self alertUsetForLocationService]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler Location" message:@"Location Service is disabled for Nimbler, Do you want to enable?" delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"Cancel", nil];
            [alert show];
            return ;
        }
    }
    
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
    
    selectedLocation = loc;  // moved before updateToFromLocation as part of DE122 fix
    
    // Update ToFromViewController with the geocode results 
    // (should be done after the locations typedString cleared)
    [toFromVC updateToFromLocation:self isFrom:isFrom location:loc];
    [toFromVC updateGeocodeStatus:FALSE isFrom:isFrom];  // let it know Geocode no longer outstanding
 
    [myTableView reloadData];  // Reload the data with the new sorting
    [myTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];     // scroll to the top of the table
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([toFromVC editMode]==NO_EDIT && 
        [self adjustedForEnterNewAddressFor:[indexPath row]] == -1) {  
        // If it is the 'Enter new address' row...
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"ToFromEnterNewLocationCell"];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                          reuseIdentifier:@"ToFromEnterNewLocationCell"];
            [[cell textLabel] setFont:[UIFont MEDIUM_LARGE_OBLIQUE_FONT]];
            cell.textLabel.textColor = [UIColor lightGrayColor];
            [[cell textLabel] setText:TOFROMTABLE_ENTER_ADDRESS_TEXT];
            UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithImage:imageDetailDisclosure];
            [cell setAccessoryView:imgViewDetailDisclosure];
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
    
    Location *loc = [locations locationAtIndex:[self adjustedForEnterNewAddressFor:[indexPath row]] 
                                        isFrom:isFrom];
    [[cell textLabel] setText:[loc shortFormattedAddress]];
    
    if ([[loc locationType] isEqualToString:TOFROM_LIST_TYPE]) {
        // Bold italic if a list header
        [[cell textLabel] setFont:[UIFont MEDIUM_LARGE_OBLIQUE_FONT]];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        [cell setAccessoryView:nil];
    } 
    else if (loc == selectedLocation) {
        [[cell textLabel] setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        cell.textLabel.textColor = [UIColor NIMBLER_RED_FONT_COLOR];
        if ([toFromVC editMode] == NO_EDIT) {
            UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithImage:imageDetailDisclosure];
            [cell setAccessoryView:imgViewDetailDisclosure];
        } else {
            // cell.textLabel.text = @"Current Location"; // This line causes DE124
            [cell setAccessoryView:nil];
        }
    } else {
        // just bold for normal cell
        [[cell textLabel] setFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE]];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        [cell setAccessoryView:nil];
    }
    
    cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;

    return cell;
    
    // In the future, we can support Nicknames by putting formatted address into subtitle, as shown below
    /* if ([loc nickName]) {   // if there is a nickname, put that in the top row
     [[cell textLabel] setText:[loc nickName]];
     NSLog(@"Subtitle formatted address: %@", [loc formattedAddress]);
     [[cell detailTextLabel] setText:[loc formattedAddress]];
     } else {  // if no nickname, just show one row with the formatted address */

}

// This function makes adjustments for inserting the "Enter New Address" row in the right location
// If there is a selectedLocation, there is no "Enter New Address" row 
// If there is no selectedLocation, "Enter New Address" appears at the top of the list
// Given a raw IndexRow (from iOS), this method returns -1 if this is the "Enter New Address" row
// Otherwise it returns an index that can be passed to [locations locationAtIndex...] to get
// the right location.  
- (NSInteger)adjustedForEnterNewAddressFor:(NSInteger)rawIndexRow
{
    if ([toFromVC editMode] != NO_EDIT) {
        return rawIndexRow; // "Enter New Address" does not show up when not in NO_EDIT
    }
    else if (selectedLocation) { 
        return rawIndexRow; // "Enter New Address" does not show up when there is a selected location
    }
    else {  // if no selected address, ENTER_NEW_ADDRESS is in row 0
        return (rawIndexRow - 1);
    }
}

// 
// txtField editing callback methods
//

// Delegate for when text is typed into the to: or from: UITextField (see below for when text submitted)
// This method updates the to & from table to reflect entries that match the text
- (IBAction)toFromTyping:(id)sender forEvent:(UIEvent *)event {

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
    
    if (rawAddress == nil) {
        rawAddress = NULL_STRING;
    } 
    // Serch with numeric street address
//    if (rawAddress != @"") {
//        NSCharacterSet *numeric = [NSCharacterSet alphanumericCharacterSet];
//        BOOL valid = [[rawAddress stringByTrimmingCharactersInSet:numeric] isEqualToString:@""];
//        if (valid) {
//            rawAddress = [rawAddress stringByAppendingString:@" sanfrancisco bay area"];
//        }
//    }
    /*
     Set rawAddress for tripSave in TPServer
     */
    if(isFrom){
        [locations setRawAddressFrom:rawAddress];
    } else {
        [locations setRawAddressTo:rawAddress];
    }
    
    NIMLOG_EVENT1(@"Raw address = %@", rawAddress);
    if ([rawAddress isEqualToString:lastRawAddressGeoRequest] && [lastGeoRequestTime timeIntervalSinceNow] > -5.0) {
        NIMLOG_EVENT1(@"Skipping duplicate toFromTextSubmitted");
        return;  // if using the same rawAddress and less than 5 seconds between, treat as duplicate
    }
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
            
            startTime = CFAbsoluteTimeGetCurrent();
                    
            @try {
                GeocodeRequestParameters* parameters = [[GeocodeRequestParameters alloc] init];
                parameters.rawAddress = rawAddress;
                parameters.supportedRegion = [self supportedRegion];
                parameters.apiType = GOOGLE_GEOCODER;
                parameters.isFrom = isFrom;

                // Call the geocoder
                [locations forwardGeocodeWithParameters:parameters callBack:self];
                
                if (!isGeocodingOutstanding) {
                    isGeocodingOutstanding = TRUE;
                    [toFromVC updateGeocodeStatus:TRUE isFrom:isFrom]; // alert toFromVC re: outstanding geocoding
                }
#if FLURRY_ENABLED          
                NSString* isFromString = (isFrom ? @"fromTable" : @"toTable");          
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                        FLURRY_TOFROM_WHICH_TABLE, isFromString,
                                        FLURRY_GEOCODE_RAWADDRESS , rawAddress, nil];          
                [Flurry logEvent:FLURRY_TOFROMTABLE_GEOCODE_REQUEST withParameters:params];          
#endif
                
            }
            @catch (NSException *exception) {
                logException(@"ToFromTableViewController->textSubmitted", @"Loading geocode info", exception);
            }
 
        }
    }
}


// Delegate methods for when the RestKit has results from the Geocoder
-(void)newGeocodeResults:(NSArray *)locationArray withStatus:(GeocodeRequestStatus)status parameters:reqParameters
{
    UIAlertView  *alert;
    if (isFrom) {
        [locations setIsFromGeo:TRUE];
        durationResponseTime = CFAbsoluteTimeGetCurrent() - startTime;
        [locations setGeoRespTimeFrom:[[NSNumber numberWithFloat:durationResponseTime] stringValue]];
    } else {
        [locations setIsToGeo:TRUE];
        durationResponseTime = CFAbsoluteTimeGetCurrent() - startTime;
        [locations setGeoRespTimeTo:[[NSNumber numberWithFloat:durationResponseTime] stringValue]];
    }
    
    if (status==GEOCODE_STATUS_OK && [locationArray count]>=1) {

        // if exactly one validLocation, use that
        if ([locationArray count] == 1) {
            Location* location = [locationArray objectAtIndex:0]; // Get the location object

            [self selectedGeocodedLocation:location]; // update with new location
        }
        
        // else if more than one validLocation, call up LocationPickerView
        else if ([locationArray count] > 1) {
            [toFromVC callLocationPickerFor:self
                               locationList:locationArray
                                     isFrom:isFrom
                           isGeocodeResults:YES];
        }
    }
    else {  // Error cases
        // if no valid locations (ie non in supported region), 
        if (status==GEOCODE_STATUS_OK && [locationArray count]==0) {
            NSString *msg = [NSString stringWithFormat:@"Did not find the address: '%@' in the San Francisco Bay Area", rawAddress];
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if (status==GEOCODE_ZERO_RESULTS)  {
            NSString *msg = [NSString stringWithFormat:@"Sorry, no valid locaton found for: '%@'", rawAddress];
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if (status==GEOCODE_OVER_QUERY_LIMIT) {
            // TODO error handling for over query limit  (switch to other geocoder on my server...)
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Error while trying to locate your address.  Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if (status==GEOCODE_REQUEST_DENIED) {
            // TODO error handling for denied, invalid or unknown status (switch to other geocoder on my server...)
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Error while trying to locate your address.  Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if (status==GEOCODE_NO_NETWORK) {
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Unable to connect to server.  Please try again when you have network connectivity." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else  { // status==GEOCODE_GENERIC_ERROR
            // Geocoder did not respond with status field
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Error while trying to locate your address.  Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
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
}



// Internal method to process a new incoming geocoded location (if the only one returned by geocoder, or if this one picked by LocationPickerVC)
- (void)selectedGeocodedLocation:(Location *)location
{
    NIMLOG_EVENT1(@"Formatted Address: %@", [location formattedAddress]);
    
    // Initialize some of the values for location
    [location setApiTypeEnum:GOOGLE_GEOCODER];

    // Add the raw address to this location
    [location addRawAddressString:rawAddress];
    
    // Check if an equivalent Location is already in the locations table
    location = [locations consolidateWithMatchingLocations:location keepThisLocation:NO];
    
    // Save db context with the new location object
    saveContext(managedObjectContext);
    
    // Mark and update the tableview and ToFromViewController
    [self markAndUpdateSelectedLocation:location];
    
}
// Method called by LocationPickerVC when a user picks a location
// Picks the location and clears out any other Locations in the list with to & from frequency = 0.0
- (void)setPickedLocation:(Location *)pickedLocation locationArray:(NSArray *)locationArray isGeocodedResults:(BOOL)isGeocodedResults
{
    if (isGeocodedResults) {
        // Remove the locations that were not picked from Core Data (if frequency = 0)
        for (Location* loc in locationArray) {
            if (loc != pickedLocation && [loc fromFrequencyFloat]<TINY_FLOAT && [loc toFrequencyFloat]<TINY_FLOAT) {
                [locations removeLocation:loc];
            }
        }
        
        // Use the picked location
        [self selectedGeocodedLocation:pickedLocation];
    }
    else {  // for location picked from a preloaded list...
        
        [self markAndUpdateSelectedLocation:pickedLocation];
    }
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

-(BOOL)alertUsetForLocationService {
    if (![locations isLocationServiceEnable]) {
                return TRUE;
    }
    return FALSE;
}

-(void)alertView: (UIAlertView *)UIAlertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *btnName = [UIAlertView buttonTitleAtIndex:buttonIndex];
    
    if ([btnName isEqualToString:@"Yes"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"]];
    }     
}
@end
