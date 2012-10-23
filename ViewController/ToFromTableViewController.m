//
//  ToFromTableViewController.m
//  Nimbler
//
//  Created by John Canfield on 5/6/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "ToFromTableViewController.h"
#import "ToFromViewController.h"
#import "UtilityFunctions.h"
#import "UIConstants.h"
#import "Constants.h"
#import "GeocodeRequestParameters.h"
#import "nc_AppDelegate.h"


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
        
        // Accessibility Label For UI Automation.
        txtField.accessibilityLabel = TEXTFIELD_TOFROMTABLEVIEW;
        
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
            
            NSString* isFromString = (isFrom ? @"fromTable" : @"toTable");

            if ([[loc locationType] isEqualToString:TOFROM_LIST_TYPE]) { // If a list (like 'Caltrain Station List')
                logEvent(FLURRY_TOFROMTABLE_CALTRAIN_LIST,
                         FLURRY_TOFROM_WHICH_TABLE, isFromString,
                         FLURRY_SELECTED_ROW_NUMBER, [NSString stringWithFormat:@"%d",[indexPath row]],
                         nil, nil, nil, nil);

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
                NSString* selectedAddressParam = (isFrom ? FLURRY_FROM_SELECTED_ADDRESS : FLURRY_TO_SELECTED_ADDRESS);
                logEvent(FLURRY_TOFROMTABLE_SELECT_ROW,
                         FLURRY_TOFROM_WHICH_TABLE, isFromString,
                         FLURRY_SELECTED_ROW_NUMBER, [NSString stringWithFormat:@"%d",[indexPath row]],
                         selectedAddressParam, [loc shortFormattedAddress],
                         nil, nil);

                [self markAndUpdateSelectedLocation:loc];  // Mark the selected location and send updates to locations and toFromVC
            }
        }
    }
}


// Utility function to update the selected location to be loc
// (in locations object, in toFromVC, and in the table selected cell)
- (void)markAndUpdateSelectedLocation:(Location *)loc
{
    if ([loc isCurrentLocation]) {
        if ([self alertUsetForLocationService]) {
            NSString* msg;  // DE193 fix
            if([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {  
                msg = ALERT_LOCATION_SERVICES_DISABLED_MSG;
            } else {
                msg = ALERT_LOCATION_SERVICES_DISABLED_MSG_V6;
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ALERT_LOCATION_SERVICES_DISABLED_TITLE message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [myTableView reloadData]; // Clear out selection on the table
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
    
    // DE176 fix 4 of 4.  Check if we need firstResponderSetting set, and if so, set it
    if (([toFromVC editMode]==FROM_EDIT && [self isFrom] && ![[self txtField] isFirstResponder]) ||
        ([toFromVC editMode]==TO_EDIT && ![self isFrom] && ![[self txtField] isFirstResponder])) {
        BOOL status = [[self txtField] becomeFirstResponder];
        NSLog(@"becomeFirstResponder: %d, isFrom: %d", status, [self isFrom]);
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

// DE-207 Implementation

-(NSInteger)smallestOf:(NSInteger)a andOf:(NSInteger)b andOf:(NSInteger)c
{
    NSInteger min = a;
    if ( b < min )
        min = b;
    
    if( c < min )
        min = c;
    
    return min;
}

-(NSInteger)smallestOf:(NSInteger)a andOf:(NSInteger)b
{
    NSInteger min=a;
    if (b < min)
        min=b;
    
    return min;
}

// Levenshtein Algorithm To calculate The Distance between Two String
-(float)calculateLevenshteinDistance:(NSString *)originalString withString:(NSString *)comparisonString
{
    // Normalize strings
    [originalString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [comparisonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    originalString = [originalString lowercaseString];
    comparisonString = [comparisonString lowercaseString];
    NSInteger k, i, j, cost, * d, distance;
    
    NSInteger n = [originalString length];
    NSInteger m = [comparisonString length];
    
    if( n++ != 0 && m++ != 0 ) {
        
        d = malloc( sizeof(NSInteger) * m * n );
        
        // Step 2
        for( k = 0; k < n; k++)
            d[k] = k;
        
        for( k = 0; k < m; k++)
            d[ k * n ] = k;
        
        // Step 3 and 4
        for( i = 1; i < n; i++ )
            for( j = 1; j < m; j++ ) {
                
                // Step 5
                if( [originalString characterAtIndex: i-1] ==
                   [comparisonString characterAtIndex: j-1] )
                    cost = 0;
                else
                    cost = 1;
                
                // Step 6
                d[ j * n + i ] = [self smallestOf: d [ (j - 1) * n + i ] + 1
                                            andOf: d[ j * n + i - 1 ] + 1
                                            andOf: d[ (j - 1) * n + i - 1 ] + cost ];
                if( i>1 && j>1 && [originalString characterAtIndex: i-1] ==
                   [comparisonString characterAtIndex: j-2] &&
                   [originalString characterAtIndex: i-2] ==
                   [comparisonString characterAtIndex: j-1] )
                {
                    d[ j * n + i] = [self smallestOf: d[ j * n + i ]
                                               andOf: d[ (j - 2) * n + i - 2 ] + cost ];
                }
            }
        
        distance = d[ n * m - 1 ];
        
        free( d );
        
        return distance;
    }
    return 0.0;
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
           // DE-207 & US-166 Implementation
            @try {
                NSString *strBART1 = @" bart";
                NSString *strBART2 = @"bart ";
                NSString *strCaltrain1 = @" caltrain";
                NSString *strCaltrain2 = @"caltrain ";
                NSString *strAirBart1 = @" airbart";
                NSString *strAirBart2 = @"airbart ";
                NSString *strStreet1 = @" street";
                NSString *strStreet2 = @"street ";
                // DE-225 Fixed.Converted The raw Address into  lowerCase string.
                rawAddress = [rawAddress lowercaseString];
                NSRange range;
                if ([rawAddress rangeOfString:strBART1 options:NSCaseInsensitiveSearch].location != NSNotFound || [rawAddress rangeOfString:strBART2 options:NSCaseInsensitiveSearch].location != NSNotFound ||  [rawAddress rangeOfString:strAirBart1 options:NSCaseInsensitiveSearch].location != NSNotFound || [rawAddress rangeOfString:strAirBart2 options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    if ([rawAddress rangeOfString:strStreet1 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strStreet1];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress replaceCharactersInRange:range withString:@" st"];
                        rawAddress = strMutableRawAddress;
                    }
                    else if([rawAddress rangeOfString:strStreet2 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strStreet2];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress replaceCharactersInRange:range withString:@"st "];
                        rawAddress = strMutableRawAddress;
                    }
                    
                    if ([rawAddress rangeOfString:strBART1 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strBART1];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress deleteCharactersInRange:range];
                        rawAddress = strMutableRawAddress;
                    }
                    else if([rawAddress rangeOfString:strBART2 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strBART2];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress deleteCharactersInRange:range];
                        rawAddress = strMutableRawAddress;
                    }
                    else if([rawAddress rangeOfString:strAirBart1 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strAirBart1];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress deleteCharactersInRange:range];
                        rawAddress = strMutableRawAddress;
                    }
                    else if([rawAddress rangeOfString:strAirBart2 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strAirBart2];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress deleteCharactersInRange:range];
                        rawAddress = strMutableRawAddress;
                    }
                    
                    NSMutableArray *arrMultiPleStationList = [[NSMutableArray alloc] init];
                    NSMutableArray *arrUnFilteredStationList = [[NSMutableArray alloc] init];
                    NSMutableArray *arrDistance = [[NSMutableArray alloc] init];
                    NSManagedObjectContext * context = [[nc_AppDelegate sharedInstance] managedObjectContext];
                    NSFetchRequest * fetchPlanRequestChunk = [[NSFetchRequest alloc] init];
                    
                    [fetchPlanRequestChunk setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:context]];
                    
                    NSArray * arrayLocations = [context executeFetchRequest:fetchPlanRequestChunk error:nil];
                    for (id location in arrayLocations){
                        NSString *strshortFormattedAddress = [[location shortFormattedAddress]lowercaseString];
                        if(![strshortFormattedAddress isEqualToString:@"current location"] && ![strshortFormattedAddress isEqualToString:@"caltrain station list"] && [strshortFormattedAddress rangeOfString:@"caltrain" options:NSCaseInsensitiveSearch].location == NSNotFound){
                            [arrUnFilteredStationList addObject:location];
                        }
                    }
                    for (int i=0;i<[arrUnFilteredStationList count];i++){
                        Location *location = [arrUnFilteredStationList objectAtIndex:i];
                        NSString *strshortFormattedAddress = [[location shortFormattedAddress]lowercaseString];
                        if ([strshortFormattedAddress rangeOfString:strBART1 options:NSCaseInsensitiveSearch].location != NSNotFound){
                            range = [strshortFormattedAddress rangeOfString:strBART1];
                            NSMutableString *strMutableRawAddress =  (NSMutableString *)strshortFormattedAddress;
                            [strMutableRawAddress deleteCharactersInRange:range];
                            strshortFormattedAddress = strMutableRawAddress;
                        }
                        else if([strshortFormattedAddress rangeOfString:strBART2 options:NSCaseInsensitiveSearch].location != NSNotFound){
                            range = [strshortFormattedAddress rangeOfString:strBART2];
                            NSMutableString *strMutableRawAddress =  (NSMutableString *)strshortFormattedAddress;
                            [strMutableRawAddress deleteCharactersInRange:range];
                            strshortFormattedAddress = strMutableRawAddress;
                        }
                        if([rawAddress isEqualToString:strshortFormattedAddress]){
                            [self markAndUpdateSelectedLocation:location];
                            return;
                        }
                        float distance = [self calculateLevenshteinDistance:strshortFormattedAddress withString:rawAddress];
                        float finalDistance = distance + rawAddress.length - strshortFormattedAddress.length;
                        [arrUnFilteredStationList replaceObjectAtIndex:i withObject:[arrUnFilteredStationList objectAtIndex:i]];
                        [arrDistance addObject:[NSString stringWithFormat:@"%f",finalDistance]];
                    }
                    if([arrUnFilteredStationList count] > 1){
                        int minDistance, nTempDistance,min1;
                        NSString *tempStationName;
                        int i,j;
                        for (i = 0; i < [arrDistance count]-1; i++){
                            minDistance = i;
                            min1 = i;
                            for (j = i+1; j < [arrDistance count]; j++){
                                if ([[arrDistance objectAtIndex:j] intValue] < [[arrDistance objectAtIndex:minDistance] intValue])
                                    minDistance = j;
                                min1 = j;
                            }
                            nTempDistance = [[arrDistance objectAtIndex:i] intValue];
                            tempStationName = [arrUnFilteredStationList objectAtIndex:i];
                            [arrDistance replaceObjectAtIndex:i withObject:[arrDistance objectAtIndex:minDistance]];
                            [arrUnFilteredStationList replaceObjectAtIndex:i withObject:[arrUnFilteredStationList objectAtIndex:minDistance]];
                            [arrDistance replaceObjectAtIndex:minDistance withObject:[NSString stringWithFormat:@"%d",nTempDistance]];
                            [arrUnFilteredStationList replaceObjectAtIndex:minDistance withObject:tempStationName];
                        }
                    }
                    int nVariation = rawAddress.length/3;
                    if(nVariation == 0){
                        nVariation = 1;
                    }
                    for (int i=0;i<[arrUnFilteredStationList count];i++){
                        int finalDistance = [[arrDistance objectAtIndex:i] intValue];
                        if((finalDistance < 2.0 || (finalDistance <= nVariation && [arrMultiPleStationList count] < 3)) && finalDistance < rawAddress.length){
                            [arrMultiPleStationList addObject:[arrUnFilteredStationList objectAtIndex:i]];
                        }
                    }
//                    if([arrMultiPleStationList count] == 1){
//                        [self markAndUpdateSelectedLocation:[arrMultiPleStationList objectAtIndex:0]];
//                        return;
//                    }
                    if([arrMultiPleStationList count] > 0){
                        [toFromVC callLocationPickerFor:self
                                           locationList:arrMultiPleStationList
                                                 isFrom:isFrom
                                       isGeocodeResults:YES];
                        return;
                    }
                }
                
                if ([rawAddress rangeOfString:strCaltrain1 options:NSCaseInsensitiveSearch].location != NSNotFound || [rawAddress rangeOfString:strCaltrain2 options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    if ([rawAddress rangeOfString:strCaltrain1 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strCaltrain1];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress deleteCharactersInRange:range];
                        rawAddress = strMutableRawAddress;
                    }
                    else if([rawAddress rangeOfString:strCaltrain2 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strCaltrain2];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress deleteCharactersInRange:range];
                        rawAddress = strMutableRawAddress;
                    }
                    if ([rawAddress rangeOfString:strStreet1 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strStreet1];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress replaceCharactersInRange:range withString:@"street"];
                        rawAddress = strMutableRawAddress;
                    }
                    else if([rawAddress rangeOfString:strStreet2 options:NSCaseInsensitiveSearch].location != NSNotFound){
                        range = [rawAddress rangeOfString:strStreet2];
                        NSMutableString *strMutableRawAddress =  (NSMutableString *)rawAddress;
                        [strMutableRawAddress replaceCharactersInRange:range withString:@"street"];
                        rawAddress = strMutableRawAddress;
                    }
                    
                    NSMutableArray *arrMultiPleStationList = [[NSMutableArray alloc] init];
                    NSMutableArray *arrUnFilteredStationList = [[NSMutableArray alloc] init];
                    NSMutableArray *arrDistance = [[NSMutableArray alloc] init];
                    NSManagedObjectContext * context = [[nc_AppDelegate sharedInstance] managedObjectContext];
                    NSFetchRequest * fetchPlanRequestChunk = [[NSFetchRequest alloc] init];
                    
                    [fetchPlanRequestChunk setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:context]];
                    NSArray * arrayLocations = [context executeFetchRequest:fetchPlanRequestChunk error:nil];
                    for (id location in arrayLocations){
                        NSString *strshortFormattedAddress = [[location shortFormattedAddress]lowercaseString];
                        if(![strshortFormattedAddress isEqualToString:@"current location"] && ![strshortFormattedAddress isEqualToString:@"caltrain station list"] && [strshortFormattedAddress rangeOfString:@"caltrain" options:NSCaseInsensitiveSearch].location != NSNotFound){
                            [arrUnFilteredStationList addObject:location];
                        }
                    }
                    for (int i=0;i<[arrUnFilteredStationList count];i++){
                        Location *location = [arrUnFilteredStationList objectAtIndex:i];
                        NSString *strshortFormattedAddress = [[location shortFormattedAddress]lowercaseString];
                        if ([strshortFormattedAddress rangeOfString:strCaltrain1 options:NSCaseInsensitiveSearch].location != NSNotFound){
                            range = [strshortFormattedAddress rangeOfString:strCaltrain1];
                            NSMutableString *strMutableRawAddress =  (NSMutableString *)strshortFormattedAddress;
                            [strMutableRawAddress deleteCharactersInRange:range];
                            strshortFormattedAddress = strMutableRawAddress;
                        }
                        if([strshortFormattedAddress rangeOfString:strCaltrain2 options:NSCaseInsensitiveSearch].location != NSNotFound){
                            range = [strshortFormattedAddress rangeOfString:strCaltrain2];
                            NSMutableString *strMutableRawAddress =  (NSMutableString *)strshortFormattedAddress;
                            [strMutableRawAddress deleteCharactersInRange:range];
                            strshortFormattedAddress = strMutableRawAddress;
                        }
                        if([rawAddress isEqualToString:strshortFormattedAddress]){
                            [self markAndUpdateSelectedLocation:location];
                            return;
                        }
                        float distance = [self calculateLevenshteinDistance:strshortFormattedAddress withString:rawAddress];
                        float finalDistance = distance + rawAddress.length - strshortFormattedAddress.length;
                        [arrUnFilteredStationList replaceObjectAtIndex:i withObject:[arrUnFilteredStationList objectAtIndex:i]];
                        [arrDistance addObject:[NSString stringWithFormat:@"%f",finalDistance]];
                    }
                    if([arrUnFilteredStationList count] > 1){
                        int minDistance, tempDistance,min1;
                        NSString *tempStation;
                        int i,j;
                        for (i = 0; i < [arrDistance count]-1; i++){
                            minDistance = i;
                            min1 = i;
                            for (j = i+1; j < [arrDistance count]; j++){
                                if ([[arrDistance objectAtIndex:j] intValue] < [[arrDistance objectAtIndex:minDistance] intValue])
                                    minDistance = j;
                                min1 = j;
                            }
                            tempDistance = [[arrDistance objectAtIndex:i] intValue];
                            tempStation = [arrUnFilteredStationList objectAtIndex:i];
                            [arrDistance replaceObjectAtIndex:i withObject:[arrDistance objectAtIndex:minDistance]];
                            [arrUnFilteredStationList replaceObjectAtIndex:i withObject:[arrUnFilteredStationList objectAtIndex:minDistance]];
                            [arrDistance replaceObjectAtIndex:minDistance withObject:[NSString stringWithFormat:@"%d",tempDistance]];
                            [arrUnFilteredStationList replaceObjectAtIndex:minDistance withObject:tempStation];
                        }
                    }
                    int nVariation = rawAddress.length/3;
                    if(nVariation == 0){
                        nVariation = 1;
                    }
                    for (int i=0;i<[arrUnFilteredStationList count];i++){
                        int finalDistance = [[arrDistance objectAtIndex:i] intValue];
                        if((finalDistance < 2.0 || (finalDistance <= nVariation && [arrMultiPleStationList count] < 3)) && finalDistance < rawAddress.length){
                            [arrMultiPleStationList addObject:[arrUnFilteredStationList objectAtIndex:i]];
                        }
                    }
//                    if([arrMultiPleStationList count] == 1){
//                        [self markAndUpdateSelectedLocation:[arrMultiPleStationList objectAtIndex:0]];
//                        return;
//                    }
                     if([arrMultiPleStationList count] > 0){
                        [toFromVC callLocationPickerFor:self
                                           locationList:arrMultiPleStationList
                                                 isFrom:isFrom
                                       isGeocodeResults:YES];
                        return;
                    }
                }
                GeocodeRequestParameters* parameters = [[GeocodeRequestParameters alloc] init];
                parameters.rawAddress = rawAddress;
                parameters.supportedRegion = [self supportedRegion];
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= IOS_GEOCODE_VER_THRESHOLD) {
                    parameters.apiType = IOS_GEOCODER;
                } else {
                    parameters.apiType = GOOGLE_GEOCODER;
                }
                parameters.isFrom = isFrom;
                
                // Call the geocoder
                [locations forwardGeocodeWithParameters:parameters callBack:self];
                
                if (!isGeocodingOutstanding) {
                    isGeocodingOutstanding = TRUE;
                    [toFromVC updateGeocodeStatus:TRUE isFrom:isFrom]; // alert toFromVC re: outstanding geocoding
                }
                logEvent(FLURRY_TOFROMTABLE_GEOCODE_REQUEST,
                         FLURRY_TOFROM_WHICH_TABLE, (isFrom ? @"fromTable" : @"toTable"),
                         FLURRY_GEOCODE_RAWADDRESS, rawAddress,
                         FLURRY_GEOCODE_API, (([parameters apiType]==GOOGLE_GEOCODER) ? @"Google" : @"iOS"),
                         nil, nil);
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
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if (status==GEOCODE_ZERO_RESULTS)  {
            NSString *msg = [NSString stringWithFormat:@"Sorry, no valid location found for: '%@'", rawAddress];
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if (status==GEOCODE_OVER_QUERY_LIMIT) {
            // TODO error handling for over query limit  (switch to other geocoder on my server...)
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Error while trying to locate your address.  Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if (status==GEOCODE_REQUEST_DENIED) {
            // TODO error handling for denied, invalid or unknown status (switch to other geocoder on my server...)
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Error while trying to locate your address.  Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else if (status==GEOCODE_NO_NETWORK) {
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:NO_NETWORK_ALERT delegate:nil cancelButtonTitle:OK_BUTTON_TITLE otherButtonTitles:nil];
            [alert show];
        }
        else  { // status==GEOCODE_GENERIC_ERROR
            // Geocoder did not respond with status field
            alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Error while trying to locate your address.  Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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

    // Add the raw address to this location
    [location addRawAddressString:rawAddress];
    
    // Check if an equivalent Location is already in the locations table
    location = [locations consolidateWithMatchingLocations:location keepThisLocation:NO];
    
    // Save db context with the new location object
    saveContext(managedObjectContext);
    
    // Mark and update the tableview and ToFromViewController
    [self markAndUpdateSelectedLocation:location];
}

// Method to process a new incoming location from an IOS directions request
- (void)newDirectionsRequestLocation:(Location *)location
{
    NIMLOG_EVENT1(@"New Directions Request Address: %@", [location formattedAddress]);
    
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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger) supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate {
    return NO;
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

@end
