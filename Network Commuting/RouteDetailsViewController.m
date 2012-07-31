//
//  RouteDetailsViewController.m
//  Network Commuting
//
//  Created by John Canfield on 2/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RouteDetailsViewController.h"
#import "Leg.h"
#import "LegMapViewController.h"
#import "TwitterSearch.h"
#import "FeedBackForm.h"
#import "FeedBackReqParam.h"
#import "twitterViewController.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "ToFromViewController.h"
#import "nc_AppDelegate.h"
#if FLURRY_ENABLED
#include "Flurry.h"
#endif

@interface RouteDetailsViewController()
{
    UIBarButtonItem *forwardButton;
    UIBarButtonItem *backButton;
    NSArray* bbiArray;
}
@end

@implementation RouteDetailsViewController

@synthesize itinerary;
@synthesize mainTable;
@synthesize feedbackButton;
@synthesize advisoryButton;
@synthesize legMapVC;
@synthesize mapView;
@synthesize itineraryNumber;
@synthesize mainTableTotalHeight;
@synthesize btnBackItem,btnForwardItem,btnGoToItinerary;

NSUserDefaults *prefs;

#pragma mark lifecycle view
-(void)loadView
{
    [super loadView];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    btnGoToItinerary = [[UIButton alloc] initWithFrame:CGRectMake(0,0,92,34)];
    [btnGoToItinerary addTarget:self action:@selector(popOutToItinerary) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToItinerary setBackgroundImage:[UIImage imageNamed:@"img_itineraryNavigation.png"] forState:UIControlStateNormal];
    
    UIBarButtonItem *backToItinerary = [[UIBarButtonItem alloc] initWithCustomView:btnGoToItinerary];
    self.navigationItem.leftBarButtonItem = backToItinerary;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    @try {
        if (self) {
            [[self navigationItem] setTitle:ROUTE_TITLE_MSG];
            [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
            [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                             [UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0], UITextAttributeTextColor,
                                                                             nil]];
            
            // Set up the MKMapView and LegMapViewController
            mapView = [[MKMapView alloc] init];
            mapView.layer.borderWidth = 3.0;
            mapView.layer.borderColor = [UIColor whiteColor].CGColor;
            CGRect mapFrame = CGRectMake(ROUTE_LEGMAP_X_ORIGIN, ROUTE_LEGMAP_Y_ORIGIN,
                                         ROUTE_LEGMAP_WIDTH,  ROUTE_LEGMAP_MIN_HEIGHT);      
            
            [mapView setFrame:mapFrame];
            [[self view] addSubview:mapView];
            legMapVC = [[LegMapViewController alloc] initWithMapView:mapView];
            [mapView setDelegate:legMapVC];
            
             UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0,130,34)];
            // Set up the forward and back button
            btnBackItem = [[UIButton alloc] initWithFrame:CGRectMake(20,0,52,34)];
            [btnBackItem addTarget:self action:@selector(navigateBack:) forControlEvents:UIControlEventTouchUpInside];
            [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backSelect.png"] forState:UIControlStateNormal];
                        
            btnForwardItem = [[UIButton alloc] initWithFrame:CGRectMake(72,0,52,34)];
            [btnForwardItem addTarget:self action:@selector(navigateForward:) forControlEvents:UIControlEventTouchUpInside];
            [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardSelect.png"] forState:UIControlStateNormal];
            
//            forwardButton = [[UIBarButtonItem alloc] initWithCustomView:btnForwardItem]; 
            
            [view addSubview:btnBackItem];
            [view addSubview:btnForwardItem];
             backButton = [[UIBarButtonItem alloc] initWithCustomView:view];
//            forwardButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(navigateForward:)]; 
//            bbiArray = [NSArray arrayWithObject:backButton];
            self.navigationItem.rightBarButtonItem = backButton;
            
            timeFormatter = [[NSDateFormatter alloc] init];
            [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at init RouteDetail: %@", exception);
    }
    return self;
}

- (void)setItinerary:(Itinerary *)i0
{
    itinerary = i0;
    [legMapVC setItinerary:i0];
    [self setItineraryNumber:0];  // Initially start on the first row of itinerary
    [btnBackItem setEnabled:FALSE];
        
    //set FbParameterForItinerary
    [self setFBParameterForItinerary];
    
    // Compute the mainTableTotalHeight by calling the height of each row
    mainTableTotalHeight = 0.0;
    for (int i=0; i<[self tableView:mainTable numberOfRowsInSection:0]; i++) {
        mainTableTotalHeight += [self tableView:mainTable 
                        heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
}

// Override method to set to a new itinerary number (whether from the navigation forward back buttons or by selecting a new row on the table)
- (void)setItineraryNumber:(int)iNumber0
{
#if FLURRY_ENABLED
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys: FLURRY_SELECTED_ROW_NUMBER, 
                        [NSString stringWithFormat:@"%d", iNumber0], nil];
    [Flurry logEvent:FLURRY_ROUTE_DETAILS_NEWITINERARY_NUMBER withParameters:params];
#endif
                                                                                                
    itineraryNumber = iNumber0;
    
    // Scrolls the table to the new area.  If it is not
    [mainTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:itineraryNumber inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle]; 

    /*
     Implemetation Red colour highlighted at selacted Leg.
     */
    NSInteger cellCount = [mainTable numberOfRowsInSection:0];
    int i;
    for(i = 0; i<cellCount ;i++){
        UITableViewCell *cell = [mainTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        Leg *leg = [[itinerary legDescriptionToLegMapArray] objectAtIndex:i];
        if(itineraryNumber == i){
            [cell.textLabel setTextColor:[UIColor redColor]];
            if (![leg isEqual:[NSNull null]]) {
                if([leg isWalk]){
                    cell.imageView.image = [UIImage imageNamed:@"img_legWalkSelect"];
                } else if([leg isBus]){
                    cell.imageView.image = [UIImage imageNamed:@"img_legPointSelect"];
                } else if([leg isTrain]){                        
                    cell.imageView.image = [UIImage imageNamed:@"img_legTrainSelect"];
                } 
            } else {
                cell.imageView.image = [UIImage imageNamed:@"img_legPointSelect"];
            }
        }
        else{
            [cell.textLabel setTextColor:[UIColor blackColor]];
            if (![leg isEqual:[NSNull null]]) {
                if([leg isWalk]){
                    cell.imageView.image = [UIImage imageNamed:@"img_legWalk"];
                } else if([leg isBus]){
                    cell.imageView.image = [UIImage imageNamed:@"img_legPoint"];
                } else if([leg isTrain]){                        
                    cell.imageView.image = [UIImage imageNamed:@"img_legTrain"];
                } 
            } else {
                cell.imageView.image = [UIImage imageNamed:@"img_legPoint"];
            }
        }
    }
    
    // Activates or de-activates the backward and forward as needed
    if(itineraryNumber == 0){
        [btnBackItem setEnabled:FALSE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnBackItem setEnabled:TRUE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backSelect.png"] forState:UIControlStateNormal];
    }
    if(itineraryNumber == [itinerary itineraryRowCount] - 1){       
        [btnForwardItem setEnabled:FALSE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnForwardItem setEnabled:TRUE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardSelect.png"] forState:UIControlStateNormal];
    }
    // Updates legMapVC itinerary number (changing the region for the map
    [legMapVC setItineraryNumber:itineraryNumber];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    @try {
#if FLURRY_ENABLED
        [Flurry logEvent: FLURRY_ROUTE_DETAILS_APPEAR];
#endif
        // Enforce height of main table
        CGRect tableFrame = [mainTable frame];
        CGRect mapFrame = [mapView frame];
        mainTable.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"img_line.png"]];
        // If we have a small itinerary, reduce the table size so it just fits it, and increase the map size
        CGFloat newMainTableHeight = fmin(ROUTE_DETAILS_TABLE_MAX_HEIGHT, mainTableTotalHeight);
        if (tableFrame.size.height != newMainTableHeight) { // if something is changing...
            CGFloat combinedHeight = ROUTE_DETAILS_TABLE_MAX_HEIGHT + ROUTE_LEGMAP_MIN_HEIGHT+1;
            tableFrame.size.height = newMainTableHeight;
            tableFrame.origin.y = combinedHeight - newMainTableHeight + 10;
            mapFrame.size.height = combinedHeight - newMainTableHeight - 1;
            
            [mainTable setFrame:tableFrame];
            [mapView setFrame:mapFrame];
        }
        [mainTable reloadData];
        
        // Scrolls the table to the new area and selects the row
        if (itineraryNumber != 0) {
            [mainTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:itineraryNumber inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];   
        }
    
    }
    @catch (NSException *exception) {
        NSLog(@"exception at viewWillAppear RouteDetail: %@", exception);
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [mainTable flashScrollIndicators];   
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// Table view management methods
#pragma mark - UITableViewDelegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    @try {
        if ([itinerary itineraryRowCount] > 0) {
            return [itinerary itineraryRowCount];  
        }
        else {
            return 0;  // TODO come up with better handling for no legs in this itinerary
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception at cell count: %@",exception);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UIRouteDetailsViewCell"];
    @try {
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                          reuseIdentifier:@"UIRouteDetailsViewCell"];
            [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:STANDARD_FONT_SIZE]];
            [[cell textLabel] setLineBreakMode:UILineBreakModeWordWrap];
            [[cell textLabel] setNumberOfLines:0];
            [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:STANDARD_FONT_SIZE]];
            [[cell detailTextLabel] setLineBreakMode:UILineBreakModeWordWrap];
            [[cell detailTextLabel] setNumberOfLines:0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [[cell textLabel] setText:[[itinerary legDescriptionTitleSortedArray] objectAtIndex:[indexPath row]]];
        
        [[cell detailTextLabel] setText:[[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]]];
        cell.contentView.backgroundColor = [UIColor colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:0.07];
    }
    @catch (NSException *exception) {
        NSLog(@"exception while reload RouteDetailView: %@", exception);
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    @try {
        // NSString *patchString;
        
        NSString* titleText = [[itinerary legDescriptionTitleSortedArray] objectAtIndex:[indexPath row]];
        NSString* subtitleText = [[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]];
        CGSize titleSize = [titleText sizeWithFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE] 
              constrainedToSize:CGSizeMake(ROUTE_DETAILS_TABLE_CELL_TEXT_WIDTH, CGFLOAT_MAX)];
        CGSize subtitleSize = [subtitleText sizeWithFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE]
                 constrainedToSize:CGSizeMake(ROUTE_DETAILS_TABLE_CELL_TEXT_WIDTH, CGFLOAT_MAX)];

        CGFloat height = titleSize.height + subtitleSize.height + VARIABLE_TABLE_CELL_HEIGHT_BUFFER;
        if (height < STANDARD_TABLE_CELL_MINIMUM_HEIGHT) { // Set a minumum row height
            height = STANDARD_TABLE_CELL_MINIMUM_HEIGHT;
        }
        
        return height;
    }
    @catch (NSException *exception) {
        NSLog(@"exception at set dynamic height for RouteDetailViewTable Cell: %@", exception);
    }
}

// If selected, show the LegMapViewController
- (void) tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self setItineraryNumber:[indexPath row]];
    [self test:[indexPath row]];
}

-(void)test:(int)ss
{
    @try {
        Leg *leg = [[itinerary legDescriptionToLegMapArray] objectAtIndex:ss];
        if (![leg isEqual:[NSNull null]]) {
            if([leg isWalk]){
                [self setFBParameterForLeg:[leg legId]];
            } else if([leg isBus]){
                [self setFBParameterForLeg:[leg legId]];
            } else if([leg isTrain]){                        
                [self setFBParameterForLeg:[leg legId]];
            } 
        } else {
            [self setFBParameterForItinerary];
        }
    }
    @catch (NSException *exception) {
        [self setFBParameterForItinerary];
    }
}

#pragma mark - Map navigation callbacks

// Callback for when user presses the navigate back button on the right navbar
- (IBAction)navigateBack:(id)sender {
        
    if ([self itineraryNumber] > 0) {
        [self setItineraryNumber:([self itineraryNumber] - 1)];
         [self test:itineraryNumber];
    }
    
}

// Callback for when user presses the navigate forward button on the right navbar
- (IBAction)navigateForward:(id)sender {
    if ([self itineraryNumber] < [itinerary itineraryRowCount] - 1) {
        [self setItineraryNumber:([self itineraryNumber] + 1)];
        [self test:itineraryNumber];
    }
}


#pragma mark - Button Press methods
- (IBAction)advisoryButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {        
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        [[RKClient sharedClient]  get:@"advisories/all" delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception at requesting advisory data: %@", exception);
    } 
}


- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
        FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:[NSNumber numberWithInt:FB_SOURCE_ITINERARY] uniqueId:[itinerary itinId] date:nil fromAddress:nil toAddress:nil]; 
        FeedBackForm *feedbackvc = [[FeedBackForm alloc] initWithFeedBack:@"FeedBackForm" fbParam:fbParam bundle:nil];
        [[self navigationController] pushViewController:feedbackvc animated:YES];
    }
    @catch (NSException *exception) {
         NSLog(@"Exception at feedback navigation: %@", exception);
    }
}

-(void)ReloadLegWithNewData
{
    @try {
        [mainTable reloadData];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at realoding routeDetailViewTable: %@", exception);
    }
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    @try {
        if ([request isGET]) {       
            RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
            id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];                
            twitterViewController *twit = [[twitterViewController alloc] init];
            [twit setTwitterLiveData:res];
            [[self navigationController] pushViewController:twit animated:YES];     
        } 
    }  @catch (NSException *exception) {
        NSLog( @"Exception while getting twitter Data from TP Server response: %@", exception);
    } 
}

-(void)setFBParameterForItinerary
{
    NSLog(@"Itinerary.....");
    [nc_AppDelegate sharedInstance].FBSource = [NSNumber numberWithInt:FB_SOURCE_ITINERARY];
    [nc_AppDelegate sharedInstance].FBDate = nil;
    [nc_AppDelegate sharedInstance].FBToAdd = nil;
    [nc_AppDelegate sharedInstance].FBSFromAdd = nil;
    [nc_AppDelegate sharedInstance].FBUniqueId = [itinerary itinId];
}

-(void)setFBParameterForLeg:(NSString *)legId
{
    NSLog(@"leg.....");
    [nc_AppDelegate sharedInstance].FBSource = [NSNumber numberWithInt:FB_SOURCE_LEG];
    [nc_AppDelegate sharedInstance].FBDate = nil;
    [nc_AppDelegate sharedInstance].FBToAdd = nil;
    [nc_AppDelegate sharedInstance].FBSFromAdd = nil;
    [nc_AppDelegate sharedInstance].FBUniqueId = legId;
}

-(void)popOutToItinerary
{
    [self.navigationController popViewControllerAnimated:TRUE];
}
@end