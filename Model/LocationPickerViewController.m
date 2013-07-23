//
//  LocationPickerViewController.m
//  Nimbler
//
//  Created by John Canfield on 6/8/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "LocationPickerViewController.h"
#import "FeedBackForm.h"
#import "UtilityFunctions.h"
#import "PreloadedStop.h"


@interface LocationPickerViewController ()
{
    BOOL locationPicked;  // True if a location is picked before returning to ToFromViewController
}
@end

@implementation LocationPickerViewController

@synthesize mainTable;
@synthesize toFromTableVC;
@synthesize locationArray;
@synthesize isFrom;
@synthesize isGeocodeResults;

int const LOCATION_PICKER_TABLE_HEIGHT = 410;
int const LOCATION_PICKER_TABLE_HEIGHT_4INCH = 498;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //[[self navigationItem] setTitle:@"Pick a location"];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO]; 
    logEvent(FLURRY_LOCATION_PICKER_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);

    locationPicked = FALSE;
    
    // Enforce height of main table
    CGRect rect0 = [mainTable frame];
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
       rect0.size.height = LOCATION_PICKER_TABLE_HEIGHT_4INCH;
        rect0.origin.y = 0;
    }
    else{
        rect0.size.height = LOCATION_PICKER_TABLE_HEIGHT;
        rect0.origin.y = 0;
    }
    [mainTable setFrame:rect0];
    mainTable.delegate = self;
    mainTable.dataSource = self;
    [mainTable reloadData];
}

//
// TableView datasource methods
//

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [locationArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"LocationPickerViewCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:@"LocationPickerViewCell"];
        cell.textLabel.numberOfLines= 2;     
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:MEDIUM_LARGE_FONT_SIZE]];
    id tempObject = [locationArray objectAtIndex:[indexPath row]];
    if([tempObject isKindOfClass:[Location class]]){
        Location *loc = (Location *)tempObject;
        [[cell textLabel] setText:loc.shortFormattedAddress];
    }
    else{
        StationListElement *stationListElement = [locationArray objectAtIndex:[indexPath row]];
        int listType = [[nc_AppDelegate sharedInstance].stations returnElementType:stationListElement];
        if(listType == CONTAINS_LIST_TYPE){
            [[cell textLabel] setText:stationListElement.containsList];
        }
        else if(listType == LOCATION_TYPE){
            Location *loc = stationListElement.location;
            [[cell textLabel] setText:[loc shortFormattedAddress]];
        }
        else{
            PreloadedStop *stop = stationListElement.stop;
            [[cell textLabel] setText:stop.formattedAddress];
        }
    }
    cell.textLabel.textColor = [UIColor NIMBLER_RED_FONT_COLOR];
    tableView.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"img_line.png"]];
    cell.contentView.backgroundColor = [UIColor CELL_BACKGROUND_ROUTE_OPTION_VIEW];
    [cell sizeToFit];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:0.3];
    // Send back the picked location and pop the view controller back to ToFromViewController
    id tempObject = [locationArray objectAtIndex:[indexPath row]];
    if([tempObject isKindOfClass:[Location class]]){
        Location *loc = (Location *)tempObject;
        [toFromTableVC setPickedLocation:loc
                           locationArray:locationArray isGeocodedResults:isGeocodeResults];
        locationPicked = TRUE;
        [self popViewController];
        return;
    }
    StationListElement *stationListElement = [locationArray objectAtIndex:[indexPath row]];
    int listType = [[nc_AppDelegate sharedInstance].stations returnElementType:stationListElement];
    if(listType == CONTAINS_LIST_TYPE){
       locationArray = [[nc_AppDelegate sharedInstance].stations fetchStationListByMemberOfListId:stationListElement.containsListId];
        NSMutableArray *arrmemberOfListIds;
        if(![[NSUserDefaults standardUserDefaults] objectForKey:@"memberOfListId"]){
            arrmemberOfListIds = [[NSMutableArray alloc] init];
            [arrmemberOfListIds addObject:stationListElement.memberOfListId];
            [[NSUserDefaults standardUserDefaults] setObject:arrmemberOfListIds forKey:@"memberOfListId"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else{
            arrmemberOfListIds = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"memberOfListId"]];
            [arrmemberOfListIds addObject:stationListElement.memberOfListId];
            [[NSUserDefaults standardUserDefaults] setObject:arrmemberOfListIds forKey:@"memberOfListId"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.3];
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromRight];
        [animation setRemovedOnCompletion:YES];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        [[mainTable layer] addAnimation:animation forKey:nil];
        [mainTable reloadData];
    }
    else if(listType == LOCATION_TYPE){
        Location *loc = stationListElement.location;
        [toFromTableVC setPickedLocation:loc
                           locationArray:locationArray isGeocodedResults:isGeocodeResults];
        locationPicked = TRUE;
        [self popViewController];
    }
    else{
        Location *loc = [[nc_AppDelegate sharedInstance].stations createNewLocationObjectFromGtfsStop:stationListElement.stop :stationListElement];
        stationListElement.location = loc;
        [toFromTableVC setPickedLocation:loc
                           locationArray:locationArray isGeocodedResults:isGeocodeResults];
        locationPicked = TRUE;
        [self popViewController];
    }
}

//DE:21 dynamic cell height 
#pragma mark - UIDynamic cell heght methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellText;
    id tempObject = [locationArray objectAtIndex:[indexPath row]];
    if([tempObject isKindOfClass:[Location class]]){
        Location *loc = (Location *)tempObject;
        cellText = loc.shortFormattedAddress;
    }
    else{
        StationListElement *stationListElement = [locationArray objectAtIndex:[indexPath row]];
        int listType = [[nc_AppDelegate sharedInstance].stations returnElementType:stationListElement];
        if(listType == CONTAINS_LIST_TYPE){
            cellText = stationListElement.containsList;
        }
        else if(listType == LOCATION_TYPE){
            Location *loc = stationListElement.location;
            cellText = loc.shortFormattedAddress;
        }
        else{
            PreloadedStop *stop = stationListElement.stop;
            cellText = stop.formattedAddress;
        }
 
    }
    CGSize size = [cellText 
                sizeWithFont:[UIFont systemFontOfSize:MEDIUM_LARGE_FONT_SIZE] 
                constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
    
    CGFloat height = size.height + VARIABLE_TABLE_CELL_HEIGHT_BUFFER;
    if (height < STANDARD_TABLE_CELL_MINIMUM_HEIGHT) { // Set a minumum row height
        height = STANDARD_TABLE_CELL_MINIMUM_HEIGHT;
    }
    // static height for better UI
    return height;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (locationPicked == FALSE) {   // If user just returning back to main page...
        for (id locationElement in locationArray) {
            if ([locationElement isKindOfClass:[StationListElement class]]) {
                // Do nothing... No need to remove locations that are part of stationLists
            }
            else if ([locationElement isKindOfClass:[Location class]]) {
                Location* loc = (Location *)locationElement;
                // remove all the locations from Core Data if they have frequency = 0
                if ([loc fromFrequencyFloat]<TINY_FLOAT && [loc toFrequencyFloat]<TINY_FLOAT) {
                    [[toFromTableVC locations] removeLocation:loc];
                }
            }
        }
        
        // return to the appropriate edit mode so users can continue editing
        if (isFrom) {
            [[toFromTableVC toFromVC] setEditMode:FROM_EDIT];
        }
        else {
            [[toFromTableVC toFromVC] setEditMode:TO_EDIT];
        }
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    //Accessibility Label for UIAutomation.
    self.mainTable.accessibilityLabel = LOCATION_PICKER_TABLE_VIEW;
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
    }
    // Do any additional setup after loading the view from its nib.
    UIButton *btnGoToNimbler = [[UIButton alloc] initWithFrame:CGRectMake(0,0,65,34)];
    [btnGoToNimbler addTarget:self action:@selector(popOutToNimbler) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToNimbler setBackgroundImage:[UIImage imageNamed:@"img_nimblerNavigation.png"] forState:UIControlStateNormal];
    
    UIBarButtonItem *backTonimbler = [[UIBarButtonItem alloc] initWithCustomView:btnGoToNimbler];
    self.navigationItem.leftBarButtonItem = backTonimbler;
    
    UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
    [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
    lblNavigationTitle.text = LOCATION_PICKER_VIEW_TITLE;
    lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
    [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
    lblNavigationTitle.backgroundColor =[UIColor clearColor];
    lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
    self.navigationItem.titleView=lblNavigationTitle;
}

- (void)viewDidUnload{
    [super viewDidUnload];
    self.mainTable = nil;
}

- (void)dealloc{
    self.mainTable = nil;
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

-(void)popViewController
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"memberOfListId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [toFromTableVC textSubmitted:nil forEvent:nil];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    [[self navigationController] popViewControllerAnimated:NO];
}

-(void)popOutToNimbler
{
     NSMutableArray *arrMemberOfListIds = [[NSMutableArray alloc]initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"memberOfListId"]];
    if([arrMemberOfListIds count] > 0){
        [toFromTableVC textSubmitted:nil forEvent:nil];
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.3];
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromLeft];
        [animation setRemovedOnCompletion:YES];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        locationArray = [[nc_AppDelegate sharedInstance].stations fetchStationListByMemberOfListId:[arrMemberOfListIds lastObject]];
        [[mainTable layer] addAnimation:animation forKey:nil];
        [arrMemberOfListIds removeLastObject];
        [[NSUserDefaults standardUserDefaults] setObject:arrMemberOfListIds forKey:@"memberOfListId"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [mainTable reloadData];
        [self.navigationController setNavigationBarHidden:NO animated:NO]; 
    }
    else{
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.3];
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromLeft];
        [animation setRemovedOnCompletion:YES];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        [[self.navigationController.view layer] addAnimation:animation forKey:nil];
        [[self navigationController] popViewControllerAnimated:NO];
    }
}

@end
