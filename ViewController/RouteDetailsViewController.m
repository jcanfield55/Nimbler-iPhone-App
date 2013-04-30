//
//  RouteDetailsViewController.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/25/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "RouteDetailsViewController.h"
#import "Leg.h"
#import "LegMapViewController.h"
#import "FeedBackForm.h"
#import "FeedBackReqParam.h"
#import "twitterViewController.h"
#import "UtilityFunctions.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "ToFromViewController.h"
#import "nc_AppDelegate.h"
#import "RealTimeManager.h"

@interface RouteDetailsViewController()
{
    UIBarButtonItem *forwardButton;
    UIBarButtonItem *backButton;
    NSArray* bbiArray;
    
    NSMutableDictionary *imageDictionary; // Dictionary to hold pre-loaded table images
}
@end

@implementation RouteDetailsViewController

@synthesize itinerary;
@synthesize mainTable;
@synthesize legMapVC;
@synthesize mapView;
@synthesize itineraryNumber;
@synthesize mainTableTotalHeight;
@synthesize btnBackItem,btnForwardItem,btnGoToItinerary;
@synthesize timer;
@synthesize count;
@synthesize lblNextRealtime;
@synthesize realTimeImageView;

NSUserDefaults *prefs;

#pragma mark lifecycle view
-(void)loadView
{
    [super loadView];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    self.mainTable.delegate = self;
    self.mainTable.dataSource = self;
    
    // Accessibility Label For UI Automation.
    self.mainTable.accessibilityLabel =ROUTE_DETAILS_TABLE_VIEW;
    
    
    UIImage* btnImage = [UIImage imageNamed:@"img_itineraryNavigation.png"];
    btnGoToItinerary = [[UIButton alloc] initWithFrame:CGRectMake(0,0,76, 34)];
    [btnGoToItinerary addTarget:self action:@selector(popOutToItinerary) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToItinerary setBackgroundImage:btnImage forState:UIControlStateNormal];
    
    // Accessibility Label For UI Automation.
    btnGoToItinerary.accessibilityLabel =GO_TO_ITINERARY_BUTTON;
    
    UIBarButtonItem *backToItinerary = [[UIBarButtonItem alloc] initWithCustomView:btnGoToItinerary];
    self.navigationItem.leftBarButtonItem = backToItinerary;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    @try {
        if (self) {
            if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
                [self.navigationController.navigationBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
            }
            else {
                [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
            }
            
            UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
            [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
            lblNavigationTitle.text=ROUTE_DETAIL_VIEW_TITLE;
            lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
            [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
            lblNavigationTitle.backgroundColor =[UIColor clearColor];
            lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
            self.navigationItem.titleView=lblNavigationTitle;
            
            //[[self navigationItem] setTitle:ROUTE_TITLE_MSG];
            
            // Set up the MKMapView and LegMapViewController
            mapView = [[MKMapView alloc] init];
            mapView.layer.borderWidth = 3.0;
            mapView.layer.borderColor = [UIColor whiteColor].CGColor;
            CGRect mapFrame = CGRectMake(ROUTE_LEGMAP_X_ORIGIN, ROUTE_LEGMAP_Y_ORIGIN,
                                         ROUTE_LEGMAP_WIDTH,  ROUTE_LEGMAP_MIN_HEIGHT_4INCH);
            
            [mapView setFrame:mapFrame];
            [[self view] addSubview:mapView];
            legMapVC = [[LegMapViewController alloc] initWithMapView:mapView];
            [mapView setDelegate:legMapVC];
            
            UIImage* backImage = [UIImage imageNamed:@"img_backSelect.png"];
            UIImage* forwardImage = [UIImage imageNamed:@"img_forwardSelect.png"];
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0,
                                                                    (forwardImage.size.width+backImage.size.width),forwardImage.size.height)];
            // Set up the forward and back button
            btnBackItem = [[UIButton alloc] initWithFrame:CGRectMake(0,0,backImage.size.width,backImage.size.height)];
            [btnBackItem addTarget:self action:@selector(navigateBack:) forControlEvents:UIControlEventTouchUpInside];
            [btnBackItem setBackgroundImage:backImage forState:UIControlStateNormal];
            
            // Accessibility Label For UI Automation.
            btnBackItem.accessibilityLabel = BACKWARD_BUTTON;
                        
            btnForwardItem = [[UIButton alloc] initWithFrame:CGRectMake(backImage.size.width,0,
                                                                        forwardImage.size.width,
                                                                        forwardImage.size.height)];
            [btnForwardItem addTarget:self action:@selector(navigateForward:) forControlEvents:UIControlEventTouchUpInside];
            [btnForwardItem setBackgroundImage:forwardImage forState:UIControlStateNormal];
            // Accessibility Label For UI Automation.
            btnForwardItem.accessibilityLabel =FORWARD_BUTTON;
            
//            forwardButton = [[UIBarButtonItem alloc] initWithCustomView:btnForwardItem]; 
            
            [view addSubview:btnBackItem];
            [view addSubview:btnForwardItem];
             backButton = [[UIBarButtonItem alloc] initWithCustomView:view];
            // Accessibility Label For UI Automation.
            backButton.accessibilityLabel = BACK_BUTTON;
//            forwardButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(navigateForward:)]; 
//            bbiArray = [NSArray arrayWithObject:backButton];
            self.navigationItem.rightBarButtonItem = backButton;
            
            timeFormatter = [[NSDateFormatter alloc] init];
            [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
            
            // Preload the image files for table icons and put into a dictionary
            NSArray* imageNameArray = [NSArray arrayWithObjects:
                                       @"img_legPoint", @"img_legPointSelect",
                                       @"img_legTrain", @"img_legTrainSelect",
                                       @"img_legHeavyTrain", @"img_legHeavyTrainSelect",
                                       @"img_legBus", @"img_legBusSelect",
                                       @"img_legWalk", @"img_legWalkSelect",
                                       @"img_backSelect", @"img_backUnSelect",
                                       @"img_forwardSelect", @"img_forwardUnSelect",@"img_bicycle", @"img_bicycleSelect",@"img_legFerry",@"img_legFerrySelect", nil];
            imageDictionary = [[NSMutableDictionary alloc] initWithCapacity:[imageNameArray count]];
            for (NSString* filename in imageNameArray) {
                [imageDictionary setObject:[UIImage imageNamed:filename] forKey:filename];
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"RouteDetailsViewController->initWithNibName", @"", exception);
    }
    return self;
}

- (void) viewDidUnload{
    [super viewDidUnload];
    self.mainTable = nil;
}

- (void) dealloc{
    self.mainTable = nil;
}
-(void)newItineraryAvailable:(Itinerary *)newItinerary
                      status:(ItineraryStatus)status ItineraryNumber:(int)itiNumber{
    if(status == ITINERARY_STATUS_OK){
        [self setItinerary:newItinerary];
        [self setItineraryNumber:itiNumber];
        [mainTable reloadData];
    }
    
}

-(void) progressViewProgress {
    count--;
    [lblNextRealtime setText:[NSString stringWithFormat:@"Time to next refresh: %@ ",[self returnFormattedStringFromSeconds:count]]];
    UIImage *realtime1 = [UIImage imageNamed:@"realtime1.png"];
    UIImage *realtime2 = [UIImage imageNamed:@"realtime2.png"];
    [realTimeImageView setAnimationImages:[NSArray arrayWithObjects:realtime1,realtime2, nil]];
    [realTimeImageView setAnimationDuration:1.0];
    [realTimeImageView startAnimating];
    
    if(count == 0){
        if(timer){
            [timer invalidate];
            timer = nil;
        }
        [lblNextRealtime setText:@"No Realtime Updates"];
        [realTimeImageView setHidden:YES];
    }
}

- (void)setItinerary:(Itinerary *)i0
{
    @try {
        count = 119;
        itinerary = i0;
        if(itinerary.isRealTimeItinerary){
            [lblNextRealtime setHidden:NO];
            [lblNextRealtime setText:[NSString stringWithFormat:@"Time to next refresh: %@ ",[self returnFormattedStringFromSeconds:count]]];
            [realTimeImageView setHidden:NO];
            UIImage *realtime1 = [UIImage imageNamed:@"realtime1.png"];
            UIImage *realtime2 = [UIImage imageNamed:@"realtime2.png"];
            
            [realTimeImageView setAnimationImages:[NSArray arrayWithObjects:realtime1,realtime2, nil]];
            [realTimeImageView setAnimationDuration:1.0];
            [realTimeImageView startAnimating];
            
            if(timer){
                [timer invalidate];
                timer = nil;
            }
            timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(progressViewProgress) userInfo:nil repeats:YES];
        }
        else{
            [lblNextRealtime setHidden:YES];
            [realTimeImageView setHidden:YES];
        }
        // DE-183 Fixed
        [self setItineraryNumber:0];  // Initially start on the first row of itinerary
        [legMapVC setItinerary:i0];
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
    @catch (NSException *exception) {
        logException(@"RouteDetailsViewController->setItinerary", @"", exception);
    }
}

// Override method to set to a new itinerary number (whether from the navigation forward back buttons or by selecting a new row on the table)
- (void)setItineraryNumber:(int)iNumber0
{
    logEvent(FLURRY_ROUTE_DETAILS_NEWITINERARY_NUMBER,
             FLURRY_SELECTED_ROW_NUMBER, [NSString stringWithFormat:@"%d", iNumber0],
             nil, nil, nil, nil, nil, nil);
                                                                                               
    itineraryNumber = iNumber0;
    [mainTable reloadData]; // reload the table to highlight the new itinerary number
    
    // Scrolls the table to the new area.  If it is not
    [mainTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:itineraryNumber inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle]; 
    
    // Activates or de-activates the backward and forward as needed
    if(itineraryNumber == 0){
        [btnBackItem setEnabled:FALSE];
        [btnBackItem setBackgroundImage:[imageDictionary objectForKey:@"img_backUnSelect"] forState:UIControlStateNormal];
    } else {
        [btnBackItem setEnabled:TRUE];
        [btnBackItem setBackgroundImage:[imageDictionary objectForKey:@"img_backSelect"] forState:UIControlStateNormal];
    }
    if(itineraryNumber == [itinerary itineraryRowCount] - 1){       
        [btnForwardItem setEnabled:FALSE];
        [btnForwardItem setBackgroundImage:[imageDictionary objectForKey:@"img_forwardUnSelect"] forState:UIControlStateNormal];
    } else {
        [btnForwardItem setEnabled:TRUE];
        [btnForwardItem setBackgroundImage:[imageDictionary objectForKey:@"img_forwardSelect"] forState:UIControlStateNormal];
    }
    [legMapVC setItineraryNumber:itineraryNumber];
    // Updates legMapVC itinerary number (changing the region for the map
}

- (void) intermediateStopTimesReceived:(NSArray *)stopTimes Leg:(Leg *)leg{
    [nc_AppDelegate sharedInstance].isNeedToLoadRealData = true;
    [mainTable reloadData];
    [legMapVC addIntermediateStops:stopTimes Leg:leg];
}

- (void) setViewFrames{
    // Enforce height of main table
    CGRect tableFrame = [mainTable frame];
    CGRect mapFrame = [mapView frame];
    CGRect nextRealtimeFrame = [lblNextRealtime frame];
    CGRect realTimeImageFrame = [realTimeImageView frame];
    mainTable.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"img_line.png"]];
    // If we have a small itinerary, reduce the table size so it just fits it, and increase the map size
    CGFloat newMainTableHeight;
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
        newMainTableHeight = fmin(ROUTE_DETAILS_TABLE_MAX_HEIGHT_4INCH, mainTableTotalHeight);
    }
    else{
        newMainTableHeight = fmin(ROUTE_DETAILS_TABLE_MAX_HEIGHT, mainTableTotalHeight);
    }
    //if (tableFrame.size.height != newMainTableHeight) { // if something is changing...
    CGFloat combinedHeight;
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
        combinedHeight = ROUTE_DETAILS_TABLE_MAX_HEIGHT_4INCH + ROUTE_LEGMAP_MIN_HEIGHT_4INCH+1;
    }
    else{
        combinedHeight = ROUTE_DETAILS_TABLE_MAX_HEIGHT + ROUTE_LEGMAP_MIN_HEIGHT+1;
    }
    if(lblNextRealtime.isHidden){
        tableFrame.size.height = newMainTableHeight;
        tableFrame.origin.y = combinedHeight - newMainTableHeight + 10;
        mapFrame.size.height = combinedHeight - newMainTableHeight - 1;
    }
    else{
        mapFrame.size.height = combinedHeight - newMainTableHeight - 1;
        realTimeImageFrame.origin.y = mapFrame.origin.y + mapFrame.size.height+5;
        nextRealtimeFrame.origin.y = mapFrame.origin.y + mapFrame.size.height+5;
        tableFrame.size.height = newMainTableHeight - (10 +nextRealtimeFrame.size.height);
        tableFrame.origin.y = combinedHeight - newMainTableHeight + 15 +nextRealtimeFrame.size.height;
    }
    [mainTable setFrame:tableFrame];
    [mapView setFrame:mapFrame];
    [lblNextRealtime setFrame:nextRealtimeFrame];
    [realTimeImageView setFrame:realTimeImageFrame];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    @try {
        logEvent(FLURRY_ROUTE_DETAILS_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
        [self setViewFrames];
        [mainTable reloadData];
        
        // Scrolls the table to the new area and selects the row
        if (itineraryNumber != 0) {
            [mainTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:itineraryNumber inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];   
        }
        [self.view bringSubviewToFront:self.mainTable];
    }
    @catch (NSException *exception) {
        logException(@"RouteDetailsViewController->viewWillAppear", @"", exception);
    }
    [self setFBParamater:0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [mainTable flashScrollIndicators];   
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
        logException(@"RouteDetailsViewController->tableView: numberOfRowsInSection", @"", exception);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UIRouteDetailsViewCell"];
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
            [[cell detailTextLabel] setTextColor:[UIColor GRAY_FONT_COLOR]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.contentView.backgroundColor = [UIColor CELL_BACKGROUND_ROUTE_OPTION_VIEW];
        }
        
        // Find the right image filename
        NSMutableString* imgFileName = [NSMutableString stringWithCapacity:40];
        Leg *leg = [[itinerary legDescriptionToLegMapArray] objectAtIndex:[indexPath row]];
        if ([leg isEqual:[NSNull null]]) { // Start or finish point
            [imgFileName appendString:@"img_legPoint"];
        } else {
            if([leg isWalk]){
                [imgFileName appendString:@"img_legWalk"];
            } else if([leg isBus]){
                [imgFileName appendString:@"img_legBus"];
            } else if ([leg isHeavyTrain]){
                [imgFileName appendString:@"img_legHeavyTrain"];
            } else if([leg isTrain]){                        
                [imgFileName appendString:@"img_legTrain"];
            }
            else if([leg isBike]){
                [imgFileName appendString:@"img_bicycle"];
            }
            else if([leg isFerry]){
                [imgFileName appendString:@"img_legFerry"];
            }
        }
 
        // if this is the selected row, make red
        if (itineraryNumber == [indexPath row]) { 
            [cell.textLabel setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
            [imgFileName appendString:@"Select"];
        } else {
            [cell.textLabel setTextColor:[UIColor GRAY_FONT_COLOR]];
        }
        
        // Add text
        [[cell textLabel] setText:[[itinerary legDescriptionTitleSortedArray] objectAtIndex:[indexPath row]]];
        [[cell detailTextLabel] setText:[[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]]];

        // Add icon if there is one
        if ([imgFileName length] == 0) {
            cell.imageView.image = nil;
        } else {
            cell.imageView.image = [imageDictionary objectForKey:imgFileName];
        }
    }
    @catch (NSException *exception) {
        logException(@"RouteDetailsViewController->cellForRowAtIndexPath", @"", exception);
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
        logException(@"RouteDetailsViewController->heightForRowAtIndexPath", @"", exception);
        NIMLOG_ERR1(@"RouteDetailsViewController->heightForRowAtIndexPath:%@",exception);
    }
}

// If selected, show the LegMapViewController
- (void) tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self setItineraryNumber:[indexPath row]];
    [self setFBParamater:[indexPath row]];
}

-(void)setFBParamater:(int)ss
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
        logException(@"RouteDetailsViewController->test", @"Setting FB parameters for leg/itinerary", exception);
        [self setFBParameterForItinerary];
    }
}

#pragma mark - Map navigation callbacks

// Callback for when user presses the navigate back button on the right navbar
- (IBAction)navigateBack:(id)sender {
    if ([self itineraryNumber] > 0) {
        [self setItineraryNumber:([self itineraryNumber] - 1)];
         [self setFBParamater:itineraryNumber];
        [legMapVC refreshLegOverlay:itineraryNumber];
    }
}

// Callback for when user presses the navigate forward button on the right navbar
- (IBAction)navigateForward:(id)sender {
    if ([self itineraryNumber] < [itinerary itineraryRowCount] - 1) {
        [self setItineraryNumber:([self itineraryNumber] + 1)];
        [self setFBParamater:itineraryNumber];
        [legMapVC refreshLegOverlay:itineraryNumber];
    }
    
}


-(void)ReloadLegWithNewData
{
    @try {
        [mainTable reloadData];
    }
    @catch (NSException *exception) {
        logException(@"RouteDetailsViewController->ReloadLegWithNewData", @"", exception);
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
        logException(@"RouteDetailsViewController->didLoadResponse", @"Loading Twitter Data", exception);

    }
}

-(void)setFBParameterForItinerary
{
    NIMLOG_PERF1(@"Itinerary.....");
    [nc_AppDelegate sharedInstance].FBSource = [NSNumber numberWithInt:FB_SOURCE_ITINERARY];
    [nc_AppDelegate sharedInstance].FBDate = nil;
    [nc_AppDelegate sharedInstance].FBToAdd = nil;
    [nc_AppDelegate sharedInstance].FBSFromAdd = nil;
    [nc_AppDelegate sharedInstance].FBUniqueId = [itinerary itinId];
}

-(void)setFBParameterForLeg:(NSString *)legId
{
    NIMLOG_PERF1(@"leg.....");
    [nc_AppDelegate sharedInstance].FBSource = [NSNumber numberWithInt:FB_SOURCE_LEG];
    [nc_AppDelegate sharedInstance].FBDate = nil;
    [nc_AppDelegate sharedInstance].FBToAdd = nil;
    [nc_AppDelegate sharedInstance].FBSFromAdd = nil;
    [nc_AppDelegate sharedInstance].FBUniqueId = legId;
}

-(void)popOutToItinerary
{
    if(timer){
        [timer invalidate];
        timer = nil;
    }
    
    if(legMapVC.timerVehiclePosition){
        [legMapVC.timerVehiclePosition invalidate];
        legMapVC.timerVehiclePosition = nil;
    }
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    [[self navigationController] popViewControllerAnimated:NO];
}

- (NSString *) returnFormattedStringFromSeconds:(int) seconds{
    NSString *timeString;
    if(seconds > 59){
        if(seconds-60 < 10){
            timeString = [NSString stringWithFormat:@"01:0%d",seconds-60];
        }
        else{
            timeString = [NSString stringWithFormat:@"01:%d",seconds-60];
        }
    }
    else{
        if(seconds < 10){
            timeString = [NSString stringWithFormat:@"00:0%d",seconds];
        }
        else{
            timeString = [NSString stringWithFormat:@"00:%d",seconds];
        }
    }
    return timeString;
}
@end