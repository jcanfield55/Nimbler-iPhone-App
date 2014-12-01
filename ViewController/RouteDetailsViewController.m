//
// RouteDetailsViewController.m
// Nimbler World, Inc.
//
// Created by John Canfield on 2/25/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
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
#import "KeyObjectStore.h"
#import "WebView.h"
#import "BikeStepsViewController.h"
#import "TEXTConstant.h"

#define MAXIMUM_SCROLL_POINT 338
#define MAXIMUM_SCROLL_POINT_4_INCH 425
#define MINIMUM_SCROLL_POINT 15
#define LABEL__NEXT_REALTIME_Y_BUFFER 17
#define MAIN_TABLE_Y_BUFFER 30
#define PREFS_IS_LABEL_HIDDEN @"labelHidden"
#define TIMER_DEFAULT_VALUE 119


@interface RouteDetailsViewController()
{
    UIBarButtonItem *forwardButton;
    UIBarButtonItem *backButton;
    NSArray* bbiArray;
    int routeDetailsTableCellWidth;  // DE408 fix.  Make this variable a instance variable (rather than local to a method) and use the value from the heightForRowAtIndex method when within the cellForRowAtIndex method.  Previously the first cells would not have the full width of the table.  
    
    NSMutableDictionary *imageDictionary; // Dictionary to hold pre-loaded table images
}
@end

@implementation RouteDetailsViewController

@synthesize itinerary;
@synthesize mainTable;
@synthesize legMapVC;
@synthesize mapView;
@synthesize itineraryNumber;
@synthesize btnBackItem,btnForwardItem,btnGoToItinerary;
@synthesize timer;
@synthesize count;
@synthesize lblNextRealtime;
@synthesize handleControl;
@synthesize mapToTableRatioConstraint;
@synthesize handleVerticalConstraint;
@synthesize mapHeight;
@synthesize tableHeight;
@synthesize activityIndicatorView;

NSUserDefaults *prefs;

#pragma mark lifecycle view
-(void)loadView
{
    [super loadView];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    if([[[UIDevice currentDevice] systemVersion] intValue] >= 7){
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.mainTable.delegate = self;
    self.mainTable.dataSource = self;
    
    // Set up the MKMapView and LegMapViewController
    if (!legMapVC) {
        mapView.layer.borderWidth = 3.0;
        mapView.layer.borderColor = [UIColor whiteColor].CGColor;
        legMapVC = [[LegMapViewController alloc] initWithMapView:mapView];
        [mapView setDelegate:legMapVC];
    }
    
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
                [self.navigationController.navigationBar setBackgroundImage:returnNavigationBarBackgroundImage() forBarMetrics:UIBarMetricsDefault];
            }
            else {
                [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:returnNavigationBarBackgroundImage()] aboveSubview:self.navigationController.navigationBar];
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
            
            [self.view bringSubviewToFront:handleControl];
            
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
            
            // forwardButton = [[UIBarButtonItem alloc] initWithCustomView:btnForwardItem];
            
            [view addSubview:btnBackItem];
            [view addSubview:btnForwardItem];
            backButton = [[UIBarButtonItem alloc] initWithCustomView:view];
            // Accessibility Label For UI Automation.
            backButton.accessibilityLabel = BACK_BUTTON;
            // forwardButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(navigateForward:)];
            // bbiArray = [NSArray arrayWithObject:backButton];
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
        mapHeight = mapView.frame.size.height;
        tableHeight = mainTable.frame.size.height;
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
    [lblNextRealtime setText:[NSString stringWithFormat:@"%@: %@ ",TIME_TO_NEXT_REFRESH,[self returnFormattedStringFromSeconds:count]]];
    if(count < 0){
        if(timer){
            [timer invalidate];
            timer = nil;
        }
        [lblNextRealtime setText:NO_REALTIME_UPDATES];
    }
}

- (void)setItinerary:(Itinerary *)i0
{
    @try {
        [[NSUserDefaults standardUserDefaults] setBool:self.lblNextRealtime.isHidden forKey:PREFS_IS_LABEL_HIDDEN];
        [[NSUserDefaults standardUserDefaults] synchronize];
        itinerary = i0;
        if(itinerary.isRealTimeItinerary){
            [lblNextRealtime setHidden:NO];
            [lblNextRealtime setText:[NSString stringWithFormat:@"%@: %@ ",TIME_TO_NEXT_REFRESH,[self returnFormattedStringFromSeconds:count]]];
            if(timer){
                [timer invalidate];
                timer = nil;
            }
            timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(progressViewProgress) userInfo:nil repeats:YES];
        }
        else{
            [lblNextRealtime setHidden:YES];
        }
        // DE-183 Fixed
        [self setItineraryNumber:0]; // Initially start on the first row of itinerary
        [legMapVC setItinerary:i0];
        [btnBackItem setEnabled:FALSE];
        
        //set FbParameterForItinerary
        [self setFBParameterForItinerary];
        
        BOOL previousStatus = [[NSUserDefaults standardUserDefaults] boolForKey:PREFS_IS_LABEL_HIDDEN];
        if(previousStatus && lblNextRealtime.isHidden){
            [mainTable setFrame:CGRectMake(mainTable.frame.origin.x,mainTable.frame.origin.y,mainTable.frame.size.width,mainTable.frame.size.height)];
        }
        else if(!previousStatus && lblNextRealtime.isHidden){
            NSLog(@"mainTableHeight=%f",mainTable.frame.size.height);
            [mainTable setFrame:CGRectMake(mainTable.frame.origin.x,mainTable.frame.origin.y - self.lblNextRealtime.frame.size.height,mainTable.frame.size.width,mainTable.frame.size.height+self.lblNextRealtime.frame.size.height)];
        }
        else if(previousStatus && !lblNextRealtime.isHidden){
            [mainTable setFrame:CGRectMake(mainTable.frame.origin.x,mainTable.frame.origin.y + self.lblNextRealtime.frame.size.height,mainTable.frame.size.width,mainTable.frame.size.height-self.lblNextRealtime.frame.size.height)];
        }
        else{
            NSLog(@"mainTableHeight=%f",mainTable.frame.size.height);
            [mainTable setFrame:CGRectMake(mainTable.frame.origin.x,mainTable.frame.origin.y,mainTable.frame.size.width,mainTable.frame.size.height)];
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
    
    // Scrolls the table to the new area. If it is not
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


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [nc_AppDelegate sharedInstance].isRouteDetailView = true;
    @try {
        logEvent(FLURRY_ROUTE_DETAILS_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
        yPos = handleControl.frame.origin.y;
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
    [nc_AppDelegate sharedInstance].isRouteDetailView = false;
    [[NSUserDefaults standardUserDefaults] setBool:self.lblNextRealtime.isHidden forKey:PREFS_IS_LABEL_HIDDEN];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
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
            return 0; // TODO come up with better handling for no legs in this itinerary
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
        int mostRecentCellWidth = cell.frame.size.width - ROUTE_DETAILS_TABLE_CELL_TEXT_BORDER;
        if (!cell || mostRecentCellWidth != routeDetailsTableCellWidth) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:@"UIRouteDetailsViewCell"];
            [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:STANDARD_FONT_SIZE]];
            [[cell textLabel] setLineBreakMode:NSLineBreakByWordWrapping];
            [[cell textLabel] setNumberOfLines:0];
            [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:STANDARD_FONT_SIZE]];
            [[cell detailTextLabel] setLineBreakMode:NSLineBreakByWordWrapping];
            [[cell detailTextLabel] setNumberOfLines:0];
            [[cell detailTextLabel] setTextColor:[UIColor GRAY_FONT_COLOR]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
           // cell.contentView.backgroundColor = [UIColor CELL_BACKGROUND_ROUTE_OPTION_VIEW];
        }
        
        if ([cell.contentView subviews]){
            for (UIView *subview in [cell.contentView subviews]) {
                [subview removeFromSuperview];
            }
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
        
        if (routeDetailsTableCellWidth <= 0) { // should not happen
            routeDetailsTableCellWidth = tableView.frame.size.width - ROUTE_DETAILS_TABLE_CELL_TEXT_BORDER;
        }
        NIMLOG_AUTOSIZE(@"Cell Row #%d: Width = %d", [indexPath row], routeDetailsTableCellWidth);
        NSString *textString = [[itinerary legDescriptionTitleSortedArray] objectAtIndex:[indexPath row]];
        CGSize attributedLabelSize = [textString sizeWithFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]constrainedToSize:CGSizeMake(routeDetailsTableCellWidth, CGFLOAT_MAX)];
        NSInteger attributedLblYPOS = 0;
        if(![[[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]] length]>0 && attributedLabelSize.height>18){
            attributedLblYPOS =5;
        }
        else if(![[[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]] length]>0){
            attributedLblYPOS =10;
        }
        
        TTTAttributedLabel *attributedLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(40,attributedLblYPOS,routeDetailsTableCellWidth, attributedLabelSize.height)];
        attributedLabel.font=[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE];
        attributedLabel.numberOfLines = 5;
        if (itineraryNumber == [indexPath row]) {
            attributedLabel.textColor = [UIColor NIMBLER_RED_FONT_COLOR];
            [imgFileName appendString:@"Select"];
        } else {
            attributedLabel.textColor = [UIColor GRAY_FONT_COLOR];
        }
        [attributedLabel setText:textString];
        [attributedLabel setBackgroundColor:[UIColor clearColor]];
        attributedLabel.delegate = self;
        NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
        [mutableLinkAttributes setValue:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];
        [mutableLinkAttributes setValue:(__bridge id)[[UIColor colorWithRed:123.0/255.0 green:104.0/255.0 blue:238.0/255.0 alpha:1.0f] CGColor] forKey:(NSString *)kCTForegroundColorAttributeName];
        attributedLabel.linkAttributes = mutableLinkAttributes;
        NSRange range = [textString rangeOfString:@"Capital BikeShare"];
        [attributedLabel addLinkToURL:[NSURL URLWithString:@"Capital BikeShare"] withRange:range];
        [cell.contentView addSubview:attributedLabel];
        
        CGSize subTitleLabelSize = [[[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]] sizeWithFont:[UIFont systemFontOfSize:STANDARD_FONT_SIZE] constrainedToSize:CGSizeMake(routeDetailsTableCellWidth, CGFLOAT_MAX)];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40,attributedLabelSize.height+3,routeDetailsTableCellWidth, subTitleLabelSize.height)];
        label.numberOfLines = 2;
        [label setFont:[UIFont systemFontOfSize:STANDARD_FONT_SIZE]];
        [label setLineBreakMode:NSLineBreakByWordWrapping];
        [label setNumberOfLines:0];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor GRAY_FONT_COLOR]];
        [label setText:[[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]]];
        [cell.contentView addSubview:label];
        
        // Add icon if there is one
        if ([imgFileName length] == 0) {
            cell.imageView.image = nil;
        } else {
            cell.imageView.image = [imageDictionary objectForKey:imgFileName];
        }
        
        if(![leg isEqual:[NSNull null]] && [leg isBike] && [[leg sortedSteps] count] > 0){
           UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_DetailDesclosure.png"]];
            cell.accessoryView = imageView;
        }
        else{
            cell.accessoryView = nil;
        }
    }
    @catch (NSException *exception) {
        logException(@"RouteDetailsViewController->cellForRowAtIndexPath", @"", exception);
    }
    return cell;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.capitalbikeshare.com/pricing"]];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        routeDetailsTableCellWidth = tableView.frame.size.width - ROUTE_DETAILS_TABLE_CELL_TEXT_BORDER;
        NSString* titleText = [[itinerary legDescriptionTitleSortedArray] objectAtIndex:[indexPath row]];
        NSString* subtitleText = [[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]];
        CGSize titleSize = [titleText sizeWithFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE] constrainedToSize:CGSizeMake(routeDetailsTableCellWidth, CGFLOAT_MAX)];
        CGSize subtitleSize = [subtitleText sizeWithFont:[UIFont systemFontOfSize:STANDARD_FONT_SIZE]
                                       constrainedToSize:CGSizeMake(routeDetailsTableCellWidth, CGFLOAT_MAX)];
        CGFloat height = titleSize.height + subtitleSize.height + VARIABLE_TABLE_CELL_HEIGHT_BUFFER;
        if (height < STANDARD_TABLE_CELL_MINIMUM_HEIGHT) { // Set a minumum row height
            height = STANDARD_TABLE_CELL_MINIMUM_HEIGHT;
        }
        NIMLOG_AUTOSIZE(@"row #%d: width = %d, height = %f, titleText = '%@', subtitleText = '%@'", [indexPath row], routeDetailsTableCellWidth, height, titleText, subtitleText);
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
    
     Leg *leg = [[itinerary legDescriptionToLegMapArray] objectAtIndex:[indexPath row]];
    if(![leg isEqual:[NSNull null]] && [leg isBike] && [[leg sortedSteps] count] > 0){
        BikeStepsViewController *bikeStepsView;
        bikeStepsView = [[BikeStepsViewController alloc] initWithNibName:@"BikeStepsViewController" bundle:nil];
        bikeStepsView.yPos = yPos;
        bikeStepsView.steps = [leg sortedSteps];
        [self.navigationController pushViewController:bikeStepsView animated:YES];
    }
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
            id res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
            twitterViewController *twit = [[twitterViewController alloc] init];
            [twit setTwitterLiveData:res];
            [[self navigationController] pushViewController:twit animated:YES];
        }
    } @catch (NSException *exception) {
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

-(void)popOutToItinerary{
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

- (IBAction) imageMoved:(id) sender withEvent:(UIEvent *) event{
    @try {
        for (UITouch *touch in [event allTouches]) {
            CGPoint point = [touch locationInView:self.view];
            NIMLOG_UBER(@"Touch Events: %d, Point (%f, %f)", [[event allTouches] count], point.x, point.y);
            int y = point.y - (handleControl.frame.size.height/2);  // Adjust so finger is positioned at middle of handle
            if (y > self.view.frame.size.height - ROUTE_DETAILS_MINIMUM_TABLE_HEIGHT) {
                y = self.view.frame.size.height - ROUTE_DETAILS_MINIMUM_TABLE_HEIGHT;
            }
            if (y < ROUTE_DETAILS_MINIMUM_MAP_HEIGHT) {
                y = ROUTE_DETAILS_MINIMUM_MAP_HEIGHT;
            }
            
            // Remove mapToTableRatioConstraint if any
            for (NSLayoutConstraint *constraint in [self.view constraints]) {
                if (constraint == mapToTableRatioConstraint) {
                    [self.view removeConstraint:constraint];
                    break;
                }
            }
            
            // Remove handleVerticalConstraint if any
            for (NSLayoutConstraint *constraint in [self.view constraints]) {
                if (constraint == handleVerticalConstraint) {
                    [self.view removeConstraint:constraint];
                    handleVerticalConstraint = nil;
                    break;
                }
            }
            
            // Add a new constraint
            handleVerticalConstraint = [NSLayoutConstraint constraintWithItem:handleControl
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:y];
            [self.view addConstraint:handleVerticalConstraint];
        }
    }
    @catch (NSException *exception) {
        logException(@"RouteDetailsViewController->imageMoved", @"", exception);
    }
}

- (void) backToRouteDetailView{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    [[self navigationController] popViewControllerAnimated:NO];
}

// Part Of DE-318 Fix
// Will resign first responder if textview or textfield become first responder.
- (void)openUrl:(NSURL *)url{
    UIViewController *webViewController = [[UIViewController alloc] init];
    UIButton * btnGoToNimbler = [[UIButton alloc] initWithFrame:CGRectMake(0,0,65,34)];
    [btnGoToNimbler addTarget:self action:@selector(backToRouteDetailView) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToNimbler setBackgroundImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    
    UIBarButtonItem *backTonimbler = [[UIBarButtonItem alloc] initWithCustomView:btnGoToNimbler];
    webViewController.navigationItem.leftBarButtonItem = backTonimbler;
    [webViewController.view addSubview:[WebView instance]];
    
    if([[[UIDevice currentDevice] systemVersion] intValue]>=7){
        webViewController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [[WebView instance] loadRequest:request];
    [[WebView instance] setScalesPageToFit:YES];
    [WebView instance].delegate = self;
    [[self navigationController] pushViewController:webViewController animated:YES];
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    if(!activityIndicatorView){
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(145, 168, 37, 37)];
        [activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        [webView addSubview:activityIndicatorView];
    }
    [activityIndicatorView startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [activityIndicatorView stopAnimating];
}

- (IBAction)feedBackClicked:(id)sender{
    FeedBackForm *feedBackForm;
    feedBackForm = [[FeedBackForm alloc] initWithNibName:@"FeedBackFormPopUp" bundle:nil];
    feedBackForm.isViewPresented = true;
    [self presentViewController:feedBackForm animated:YES completion:nil];
}

@end