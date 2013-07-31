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
#import "GeocodeRequestParameters.h"
#import "nc_AppDelegate.h"
#import "StationListElement.h"
#import "Stations.h"
#import <MapKit/MapKit.h>
#import "LocationFromLocalSearch.h"


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
@synthesize stations;
@synthesize isDeleteMode;
@synthesize isRearrangeMode;
@synthesize isRenameMode;
@synthesize btnEdit;

NSString *strBART1 = @" bart";
NSString *strBART2 = @"bart ";
NSString *strCaltrain1 = @" caltrain";
NSString *strCaltrain2 = @"caltrain ";
NSString *strAirBart1 = @" airbart";
NSString *strAirBart2 = @"airbart ";
NSString *strStreet1 = @" street";
NSString *strStreet2 = @"street ";

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
        [txtField setReturnKeyType:UIReturnKeyDone];  // DE275 fix
        [txtField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        txtField.delegate = self;
        [txtField addTarget:self action:@selector(toFromTyping:forEvent:) forControlEvents:UIControlEventEditingChanged];
        [txtField addTarget:self action:@selector(textSubmitted:forEvent:) forControlEvents:(UIControlEventEditingDidEndOnExit)];
        [txtField setBackgroundColor:[UIColor whiteColor]];
        
        // Accessibility Label For UI Automation.
        txtField.accessibilityLabel = TEXTFIELD_TOFROMTABLEVIEW;
        
        imageDetailDisclosure = [UIImage imageNamed:@"img_locListArrow.png"];
        
        btnEdit = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnEdit setFrame:CGRectMake(280,8,40,10)];
        [btnEdit setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        btnEdit.titleLabel.font = [UIFont systemFontOfSize:14];
        [btnEdit setTitle:@"Edit" forState:UIControlStateNormal];
        [btnEdit setTitle:@"Done" forState:UIControlStateSelected];
        [btnEdit addTarget:self action:@selector(editButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
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
        return ([locations numberOfLocations:isFrom]); // matching rows + 1 for "Enter New Address" Row
    }
    else {
        return [locations numberOfLocations:isFrom];  // matching rows only
    }
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(isDeleteMode){
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if(isRearrangeMode){
        return YES;
    }
    return NO;
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    NSInteger sourceRow = sourceIndexPath.row;
    NSInteger destRow = destinationIndexPath.row;
    
    if(toFromVC.editMode == FROM_EDIT){
        NSMutableArray *sortedlocations = [[NSMutableArray alloc] initWithArray:locations.sortedMatchingFromLocations];
        id object = [sortedlocations objectAtIndex:sourceRow];
        [sortedlocations removeObjectAtIndex:sourceRow];
        [sortedlocations insertObject:object atIndex:destRow];
        locations.sortedMatchingFromLocations = sortedlocations;
    }
    else if(toFromVC.editMode == TO_EDIT){
        NSMutableArray *sortedlocations = [[NSMutableArray alloc] initWithArray:locations.sortedMatchingToLocations];
        id object = [sortedlocations objectAtIndex:sourceRow];
        [sortedlocations removeObjectAtIndex:sourceRow];
        [sortedlocations insertObject:object atIndex:destRow];
        locations.sortedMatchingToLocations = sortedlocations;
    }
    
    Location *locationMoved =  [locations locationAtIndex:[self adjustedForEnterNewAddressFor:destRow]
                                                   isFrom:isFrom];
    Location *nextLocation = nil;
    Location *previousLocation = nil;
    if([locations.sortedMatchingFromLocations count] > destRow+1){
        nextLocation = [locations locationAtIndex:[self adjustedForEnterNewAddressFor:destRow+1]
                                           isFrom:isFrom];
    }
    if( destRow-1 >= 0 && [locations.sortedMatchingFromLocations count] > destRow-1){
        previousLocation = [locations locationAtIndex:[self adjustedForEnterNewAddressFor:destRow-1]
                                               isFrom:isFrom];
    }
    BOOL isMovedLocationFavorite = false;
    BOOL isNextLocationFavorite = false;
    BOOL isPreviousLocationFavorite = false;
    
    if((locationMoved.fromFrequencyFloat >= 100000 && locationMoved.toFrequencyFloat >= 100000)){
        isMovedLocationFavorite = true;
    }
    if(previousLocation && (previousLocation.fromFrequencyFloat >= 100000 && previousLocation.toFrequencyFloat >= 100000)){
        isPreviousLocationFavorite = true;
    }
    if(nextLocation && (nextLocation.fromFrequencyFloat >= 100000 && nextLocation.toFrequencyFloat >= 100000)){
        isNextLocationFavorite = true;
    }
    if(isPreviousLocationFavorite && isNextLocationFavorite){
        double avgFromFrequency = ([previousLocation fromFrequencyFloat] + [nextLocation fromFrequencyFloat])/2.0;
        double avgToFrequency = ([previousLocation toFrequencyFloat] + [nextLocation toFrequencyFloat])/2.0;
        [locationMoved setFromFrequencyFloat:avgFromFrequency];
        [locationMoved setToFrequencyFloat:avgToFrequency];
    }
    else if(!isPreviousLocationFavorite && !isNextLocationFavorite){
        if(isMovedLocationFavorite && !nextLocation){
            [locationMoved setFromFrequencyFloat:([previousLocation fromFrequencyFloat]- 1)];
            [locationMoved setToFrequencyFloat:([previousLocation toFrequencyFloat]-1)];
        }
        else{
            double avgFromFrequency = ([previousLocation fromFrequencyFloat] + [nextLocation fromFrequencyFloat])/2.0;
            double avgToFrequency = ([previousLocation toFrequencyFloat] + [nextLocation toFrequencyFloat])/2.0;
            [locationMoved setFromFrequencyFloat:avgFromFrequency];
            [locationMoved setToFrequencyFloat:avgToFrequency];
        }
    }
    else if(!isPreviousLocationFavorite && isNextLocationFavorite){
        [locationMoved setFromFrequencyFloat:([nextLocation fromFrequencyFloat]+1)];
        [locationMoved setToFrequencyFloat:([nextLocation toFrequencyFloat]+1)];
    }
    else if(isPreviousLocationFavorite && !isNextLocationFavorite){
        if(isMovedLocationFavorite){
            [locationMoved setFromFrequencyFloat:([previousLocation fromFrequencyFloat]-1)];
            [locationMoved setToFrequencyFloat:([previousLocation toFrequencyFloat]-1)];
        }
        else{
            [locationMoved setFromFrequencyFloat:([nextLocation fromFrequencyFloat]+1)];
            [locationMoved setToFrequencyFloat:([nextLocation toFrequencyFloat]+1)];
        }
    }
    saveContext(managedObjectContext);
    NSSortDescriptor *sdFrom = [NSSortDescriptor sortDescriptorWithKey:@"fromFrequency"
                                                             ascending:NO];
    locations.sortedMatchingFromLocations = [[locations sortedMatchingFromLocations] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sdFrom]];
    
    NSSortDescriptor *sdTo = [NSSortDescriptor sortDescriptorWithKey:@"toFrequency"
                                                           ascending:NO];
    locations.sortedMatchingToLocations = [[locations sortedMatchingToLocations] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sdTo]];
    
    [myTableView reloadData];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if(toFromVC.editMode == FROM_EDIT){
            NSMutableArray *sortedLocations = [[NSMutableArray alloc] initWithArray:locations.sortedMatchingFromLocations];
            Location *location = [locations.sortedMatchingFromLocations objectAtIndex:[indexPath row]];
            location.fromFrequency = [NSNumber numberWithDouble:0.5];
            location.toFrequency = [NSNumber numberWithDouble:0.5];
            saveContext(managedObjectContext);
            [sortedLocations removeObjectAtIndex:[indexPath row]];
            locations.sortedMatchingFromLocations = sortedLocations;
            locations.matchingFromRowCount = locations.matchingFromRowCount - 1;
        }
        else if(toFromVC.editMode == TO_EDIT){
            NSMutableArray *sortedLocations = [[NSMutableArray alloc] initWithArray:locations.sortedMatchingToLocations];
            Location *location = [locations.sortedMatchingFromLocations objectAtIndex:[indexPath row]];
            location.fromFrequency = [NSNumber numberWithDouble:0.5];
            location.toFrequency = [NSNumber numberWithDouble:0.5];
            saveContext(managedObjectContext);
            [sortedLocations removeObjectAtIndex:[indexPath row]];
            locations.sortedMatchingToLocations = sortedLocations;
            locations.matchingToRowCount = locations.matchingToRowCount - 1;
        }
        [myTableView reloadData];
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(isRenameMode){
        [tableView beginUpdates];
        [myTableView setFrame:CGRectMake(myTableView.frame.origin.x, myTableView.frame.origin.y, myTableView.frame.size.width, TOFROM_HEIGHT_EDIT_MODE)];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UITextView *txtView = [[UITextView alloc] initWithFrame:CGRectMake(1,2,300,50)];
        txtView.delegate = self;
        [txtView setBackgroundColor:[UIColor whiteColor]];
        Location *location;
        if(toFromVC.editMode == FROM_EDIT){
          location = [locations.sortedMatchingFromLocations objectAtIndex:[indexPath row]];  
        }
        else if(toFromVC.editMode == TO_EDIT){
           location = [locations.sortedMatchingToLocations objectAtIndex:[indexPath row]];
        }
        if(location.locationName){
            NSString *address = [NSString stringWithFormat:@"%@?%@",location.locationName,[location shortFormattedAddress]];
            address = [address stringByReplacingOccurrencesOfString:@"?" withString:@"\n"];
            txtView.text = address;
        }
        else{
            NSString *address = [NSString stringWithFormat:@"?%@",[location shortFormattedAddress]];
            address = [address stringByReplacingOccurrencesOfString:@"?" withString:@"\n"];
            txtView.text = address;
        }
        [txtView setFont:cell.textLabel.font];
        [txtView setTag:[indexPath row]+10000];
        [cell addSubview:txtView];
        [txtView becomeFirstResponder];
        
        NSArray *views = [tableView subviews];
        for(int i=0;i<[views count];i++){
            UIView *subView = [views objectAtIndex:i];
            NSArray *subViews = [subView subviews];
            for(int j=0;j<[subViews count];j++){
                UIView *tempSubView = [subViews objectAtIndex:j];
                if([tempSubView isKindOfClass:[UITextView class]] && ![tempSubView isEqual:txtView]){
                    [tempSubView removeFromSuperview];
                }
            }
        }
        [tableView endUpdates];
    }
    else{
        NIMLOG_EVENT1(@"Select Row: isFrom=%d, section=%d, row=%d", isFrom, [indexPath section], [indexPath row]);
        [toFromVC.navigationController setNavigationBarHidden:NO animated:NO];
        
            locations.isLocationSelected = true;
            Location *loc = [locations
                             locationAtIndex:[self adjustedForEnterNewAddressFor:[indexPath row]]
                             isFrom:isFrom];  //selected Location
            if([loc isKindOfClass:[LocationFromLocalSearch class]])
            {
                LocationFromLocalSearch *locationFromLocalSearch = (LocationFromLocalSearch *)loc;
                NSArray *matchingLocations = [locations locationsWithFormattedAddress:locationFromLocalSearch.formattedAddress];
                if ([matchingLocations count] > 0) {
                    loc = [matchingLocations objectAtIndex:0];  // Get the first matching location
                }
                else{
                    loc = [locations selectedLocationOfLocalSearchWithLocation:locationFromLocalSearch IsFrom:isFrom error:nil];
                }
            }
            // If user tapped the selected location, then go into Edit Mode if not there already
            if ([toFromVC editMode] == NO_EDIT && loc == selectedLocation) {
                locations.isLocationSelected = false;
                [toFromVC setEditMode:NO_EDIT];
            }
            else {
                // Have toFromVC end the edit mode (DE96 fix)
                
                NSString* isFromString = (isFrom ? @"fromTable" : @"toTable");
                
                if ([[loc locationType] isEqualToString:TOFROM_LIST_TYPE]) { // If a list (like 'Caltrain Station List')
                    [toFromVC setEditMode:NO_EDIT];
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
                    NSArray *list = [stations fetchStationListByMemberOfListId:ALL_STATION];
                    if(!list || [list count] == 0){
                        list = [locations locationsMembersOfList:[loc memberOfList]];
                    }
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
                    [toFromVC setEditMode:NO_EDIT]; 
                }
            }
        }
    saveContext(managedObjectContext);
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([toFromVC editMode]==NO_EDIT &&
        [self adjustedForEnterNewAddressFor:[indexPath row]] == -1) {
        return 50;
    }
    else{
        Location *loc = [locations locationAtIndex:[self adjustedForEnterNewAddressFor:[indexPath row]]
                                            isFrom:isFrom];
        if([loc.formattedAddress rangeOfString:@"\n"].location != NSNotFound){
            return 50;
        }
    }
    return 50;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If not the 'Enter new address row', show the appropriate location cell
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"ToFromTableLocationRow"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"ToFromTableLocationRow"];
        if(isRearrangeMode){
            cell.showsReorderControl = YES;
        }
    }
     cell.textLabel.numberOfLines = 2;
    // DE176 fix 4 of 4.  Check if we need firstResponderSetting set, and if so, set it
    if (([toFromVC editMode]==FROM_EDIT && [self isFrom] && ![[self txtField] isFirstResponder]) ||
        ([toFromVC editMode]==TO_EDIT && ![self isFrom] && ![[self txtField] isFirstResponder])) {
    }
    
    // Prepare the cell settings
    Location *loc = [locations locationAtIndex:[self adjustedForEnterNewAddressFor:[indexPath row]]
                                        isFrom:isFrom];
    // if There is PlaceName available for location
    if([loc isKindOfClass:[LocationFromLocalSearch class ]]){
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        if(loc.locationName){
            cell.textLabel.text = loc.locationName;
            cell.detailTextLabel.text = loc.shortFormattedAddress;
        }
        else{
            cell.textLabel.text = loc.shortFormattedAddress;
            cell.detailTextLabel.text = nil;
            cell.textLabel.numberOfLines = 2;
        }
        [[cell textLabel] setFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE]];
        cell.textLabel.textColor = [UIColor GRAY_FONT_COLOR_CELLTEXT];
        cell.detailTextLabel.textColor = [UIColor GRAY_FONT_COLOR_CELLDETAILTEXT];
        [cell setAccessoryView:nil];
    }
    else{
        if(loc.locationName){
            cell.textLabel.text = loc.locationName;
            cell.detailTextLabel.text = loc.shortFormattedAddress;
        }
        else{
            cell.textLabel.text = loc.shortFormattedAddress;
            cell.detailTextLabel.text = nil;
            cell.textLabel.numberOfLines = 2;
        }
        UIButton *btnFavorite = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnFavorite setTag:indexPath.row];
        [btnFavorite setFrame:CGRectMake(0, 0, 16, 16)];
        [btnFavorite setImage:[UIImage imageNamed:@"img_inActiveStar.png"] forState:UIControlStateNormal];
        [btnFavorite addTarget:self action:@selector(btnFavoriteClicked:) forControlEvents:UIControlEventTouchUpInside];
        if ([[loc locationType] isEqualToString:TOFROM_LIST_TYPE]) {
            // Bold italic if a list header
            [[cell textLabel] setFont:[UIFont MEDIUM_LARGE_OBLIQUE_FONT]];
            cell.textLabel.textColor = [UIColor GRAY_FONT_COLOR];
            [cell setEditing:NO];
            UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 11, 18)];
            [imgViewDetailDisclosure setImage:imageDetailDisclosure];
            [cell setAccessoryView:imgViewDetailDisclosure];
            
        }
        else if (loc == selectedLocation) {
            [[cell textLabel] setFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE]];
            cell.textLabel.textColor = [UIColor GRAY_FONT_COLOR];
            if([[loc fromFrequency] doubleValue]>=100000.0){
                [btnFavorite setSelected:YES];
                [btnFavorite setImage:[UIImage imageNamed:@"img_activeStar.png"] forState:UIControlStateNormal];
            }
            [cell setAccessoryView:btnFavorite];
        } else {
            // just bold for normal cell
            [[cell textLabel] setFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE]];
            cell.textLabel.textColor = [UIColor GRAY_FONT_COLOR];
            if([[loc fromFrequency] doubleValue]>=100000.0){
                [btnFavorite setSelected:YES];
                [btnFavorite setImage:[UIImage imageNamed:@"img_activeStar.png"] forState:UIControlStateNormal];
            }
            [cell setAccessoryView:btnFavorite];
        }
        
    }
    cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
    
    // In the future, we can support Nicknames by putting formatted address into subtitle, as shown below
    /* if ([loc nickName]) {   // if there is a nickname, put that in the top row
     [[cell textLabel] setText:[loc nickName]];
     NSLog(@"Subtitle formatted address: %@", [loc formattedAddress]);
     [[cell detailTextLabel] setText:[loc formattedAddress]];
     } else {  // if no nickname, just show one row with the formatted address */

}

- (void)deleteButtonClicked:(id)sender{
    isDeleteMode = true;
    isRearrangeMode = true;
    isRenameMode = true;
    [myTableView setEditing:YES animated:YES];
    [myTableView setAllowsSelectionDuringEditing:YES];
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    textView.selectedRange = NSMakeRange(0, 0);
}

- (void) saveContext{
    saveContext(toFromVC.managedObjectContext);
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if([text isEqualToString:@"\n"]){
        int row = [textView tag] - 10000;
        if(toFromVC.editMode == FROM_EDIT){
            [toFromVC.fromTable setFrame:CGRectMake(toFromVC.fromTable.frame.origin.x, toFromVC.fromTable.frame.origin.y, toFromVC.fromTable.frame.size.width, TOFROM_HEIGHT_LOCATION_EDIT_MODE)];
            NSMutableArray *sortedLocations = [[NSMutableArray alloc] initWithArray:locations.sortedMatchingFromLocations];
            Location *location = [sortedLocations objectAtIndex:row];
            NSString *textViewText = textView.text;
            if([textViewText rangeOfString:@"\n"].location != NSNotFound){
                NSArray *array = [textViewText componentsSeparatedByString:@"\n"];
                NSString *locationName = [array objectAtIndex:0];
                location.locationName = locationName;
            }
            location.userUpdatedLocation = [NSNumber numberWithBool:true];
            [sortedLocations replaceObjectAtIndex:row withObject:location];
            locations.sortedMatchingFromLocations = sortedLocations;
            [textView removeFromSuperview];
            [textView resignFirstResponder];
            if([location.shortFormattedAddress isEqualToString:locations.selectedFromLocation.shortFormattedAddress]){
                locations.selectedFromLocation = location;
            }
            if([location.shortFormattedAddress isEqualToString:locations.selectedToLocation.shortFormattedAddress]){
                locations.selectedToLocation = location;
            }
            [self performSelector:@selector(saveContext) withObject:nil afterDelay:0.5];
            
        }
        else if(toFromVC.editMode == TO_EDIT){
             [toFromVC.toTable setFrame:CGRectMake(toFromVC.toTable.frame.origin.x, toFromVC.toTable.frame.origin.y, toFromVC.toTable.frame.size.width, TOFROM_HEIGHT_LOCATION_EDIT_MODE)];
            NSMutableArray *sortedLocations = [[NSMutableArray alloc] initWithArray:locations.sortedMatchingToLocations];
            Location *location = [sortedLocations objectAtIndex:row];
            NSString *textViewText = textView.text;
            if([textViewText rangeOfString:@"\n"].location != NSNotFound){
                NSArray *array = [textViewText componentsSeparatedByString:@"\n"];
                NSString *locationName = [array objectAtIndex:0];
                location.locationName = locationName;
            }
            location.userUpdatedLocation = [NSNumber numberWithBool:true];
            [sortedLocations replaceObjectAtIndex:row withObject:location];
            locations.sortedMatchingToLocations = sortedLocations;
            [textView removeFromSuperview];
            [textView resignFirstResponder];
            if([location.shortFormattedAddress isEqualToString:locations.selectedFromLocation.shortFormattedAddress]){
                locations.selectedFromLocation = location;
            }
            if([location.shortFormattedAddress isEqualToString:locations.selectedToLocation.shortFormattedAddress]){
                locations.selectedToLocation = location;
            }
            [self performSelector:@selector(saveContext) withObject:nil afterDelay:0.0];
        }
        [myTableView reloadData];
    }
    return YES;
}

- (void)editButtonClicked:(id)sender{
    UIButton *editButton = (UIButton *)sender;
    if(editButton.selected==YES){
        [editButton setSelected:NO];
        isDeleteMode = false;
        isRearrangeMode = false;
        isRenameMode = false;
        [myTableView setEditing:NO animated:NO];
    }
    else{
        [editButton setSelected:YES];
        [self deleteButtonClicked:nil];
    }
}

- (void) btnFavoriteClicked:(id)sender{
    UIButton *favoriteButton = (UIButton *)sender;
    Location *loc = [locations locationAtIndex:[self adjustedForEnterNewAddressFor:[sender tag]]
                                        isFrom:isFrom];
    if(favoriteButton.selected==YES){
        [favoriteButton setSelected:NO];
        [favoriteButton setImage:[UIImage imageNamed:@"img_inActiveStar.png"] forState:UIControlStateNormal];
        [loc setFromFrequencyFloat:([loc fromFrequencyFloat]-100000)];
        [loc setToFrequencyFloat:([loc toFrequencyFloat]-100000)];
    }
    else{
        [favoriteButton setSelected:YES];
        [favoriteButton setImage:[UIImage imageNamed:@"img_activeStar.png"] forState:UIControlStateNormal];
        [loc setFromFrequencyFloat:([loc fromFrequencyFloat]+ 100000)];
        [loc setToFrequencyFloat:([loc toFrequencyFloat]+100000)];
    }
    saveContext(managedObjectContext);
    NSSortDescriptor *sdFrom = [NSSortDescriptor sortDescriptorWithKey:@"fromFrequency"
                                                             ascending:NO];
    locations.sortedMatchingFromLocations = [[locations sortedMatchingFromLocations] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sdFrom]];
    
    NSSortDescriptor *sdTo = [NSSortDescriptor sortDescriptorWithKey:@"toFrequency"
                                                             ascending:NO];
    locations.sortedMatchingToLocations = [[locations sortedMatchingToLocations] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sdTo]];
    [myTableView reloadData];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 25.0;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,320, 25)];
    UIImageView *imgViewHeader = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 320, 25)];
    [imgViewHeader setImage:[UIImage imageNamed:@"img_searchEditBG.png"]];
    [headerView addSubview:imgViewHeader];
    UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(4, 7, 12, 12)];
    [imgView setImage:[UIImage imageNamed:@"img_search.png"]];
    UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(18, 0, 200, 25)];
    [lbl setBackgroundColor:[UIColor clearColor]];
    [lbl setFont:[UIFont systemFontOfSize:14]];
    lbl.text = @"Searching Locations";
    lbl.textColor = [UIColor lightGrayColor];
    if(toFromVC.editMode == FROM_EDIT){
      if([[toFromVC.txtFromView text] length]>0){
        [headerView addSubview:imgView];
        [headerView addSubview:lbl];
        return headerView;
      }
    }
    else if(toFromVC.editMode == TO_EDIT){
        if([[toFromVC.txtToView text] length]>0){
            [headerView addSubview:imgView];
            [headerView addSubview:lbl];
            return headerView;
        }
    }
    [headerView addSubview:btnEdit];
    return headerView;
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
        return (rawIndexRow);
    }
}

// For TextFieldEditing Delegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    locations.isLocationSelected = false;
//    if([toFromVC editMode] == NO_EDIT){
//        [toFromVC.navigationController setNavigationBarHidden:YES animated:NO];
//    }
//    else{
//        [toFromVC.navigationController setNavigationBarHidden:NO animated:NO];
//    }
    return YES;
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
            if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= IOS_LOCALSEARCH_VER) {
                [locations setTypedFromStringForLocalSearch:[txtField text]];
            }
        } else {
             [locations setTypedToString:[txtField text]];
            if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= IOS_LOCALSEARCH_VER) {
                [locations setTypedToStringForLocalSearch:[txtField text]];
            }
        }
    if ([locations areMatchingLocationsChanged]) {  //if typing has changed matrix, reload the array
        [myTableView reloadData];
    }
    
}

-(void)reloadLocationWithLocalSearch
{
    if ([locations areMatchingLocationsChanged]) {  //if typing has changed matrix, reload the array
        [myTableView reloadData];
    }
}

- (BOOL) contains:(NSArray *)array String:(NSString *)string{
    for(int i=0;i<[array count];i++){
        StationListElement *stationListElement = [array objectAtIndex:i];
        if([stationListElement.stop.formattedAddress isEqualToString:string]){
            return true;
        }
    }
    return false;
}
// DE-207 Implementation
// Delegate for when complete text entered into the UITextField
- (void)textSubmitted:(NSString *)strRowAddress forEvent:(UIEvent *)event
{
    //[toFromVC.navigationController setNavigationBarHidden:YES animated:NO];
    locations.isLocationSelected = true; 
    rawAddress = strRowAddress;
    
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
            @try {
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
            NSString *msg = [NSString stringWithFormat:@"Did not find the address: '%@' %@", rawAddress,NEWGEOCODE_RESULT_MSG];
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
        if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= IOS_LOCALSEARCH_VER) {
            if (isFrom) {
                [locations setTypedFromString:@""];
                [locations setTypedFromStringForLocalSearch:@""];
            } else {
                [locations setTypedToString:@""];
                [locations setTypedToStringForLocalSearch:@""];
            }
            
        } else {
            if (isFrom) {
                [locations setTypedFromString:@""];
            } else {
                [locations setTypedToString:@""];
            }
        }
        
        
      //  [toFromVC setEditMode:NO_EDIT];
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
    //[toFromVC setEditMode:NO_EDIT];
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
