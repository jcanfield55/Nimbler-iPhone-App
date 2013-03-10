//
//  RouteOptionsViewController.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "RouteOptionsViewController.h"
#import "Leg.h"
#import "UtilityFunctions.h"
#import <math.h>
#import "FeedBackForm.h"
#import "LegMapViewController.h"
#import "twitterViewController.h"
#import "nc_AppDelegate.h"
#import "LocalConstants.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "Itinerary.h"
#import "RouteExcludeSettings.h"
#import "RouteExcludeSetting.h"
#import "PlanStore.h"

#define IDENTIFIER_CELL         @"UIRouteOptionsViewCell"

@interface RouteOptionsViewController()
{
    // Variables for internal use
    NSArray* arrRouteSettings;  // Array returned from RouteExcludeSettings with exclude button state
    BOOL setWarningHidden;   // True if we should set the warning to be hidden upon viewWillAppear
}

// Attributed strings are only supported on iOS6 or later, so do not call this method on < iOS6
- (NSMutableAttributedString *)detailTextLabelColor:(NSString *)strDetailtextLabel itinerary:(Itinerary *)itinerary;

@end

@implementation RouteOptionsViewController

@synthesize mainTable;
@synthesize noItineraryWarning;
@synthesize plan;
@synthesize isReloadRealData;
@synthesize btnGoToNimbler;
@synthesize planRequestParameters;
@synthesize routeDetailsVC;
@synthesize planStore;

Itinerary * itinerary;
NSString *itinararyId;
UIImage *imageDetailDisclosure;

int const ROUTE_OPTIONS_TABLE_HEIGHT = 366;
int const ROUTE_OPTIONS_TABLE_HEIGHT_IPHONE5 = 450;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
        [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
        lblNavigationTitle.text=ROUTE_OPTIONS_VIEW_TITLE;
        lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
        [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
        lblNavigationTitle.backgroundColor =[UIColor clearColor];
        lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
        self.navigationItem.titleView=lblNavigationTitle;
        imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    logEvent(FLURRY_ROUTE_OPTIONS_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
    
    // Enforce height of main table
    mainTable.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"img_line.png"]];
    [self changeMainTableSettings];
    [self setFBParameterForPlan];
    [noItineraryWarning setHidden:setWarningHidden];
}

// Method used to set the plan 
-(void)newPlanAvailable:(Plan *)newPlan
             fromObject:(id)referringObject
                 status:(PlanRequestStatus)status
       RequestParameter:(PlanRequestParameters *)requestParameter
{
    planRequestParameters = requestParameter;
    if ([referringObject isKindOfClass:[ToFromViewController class]]) {
        plan = newPlan;
        arrRouteSettings = [[RouteExcludeSettings latestUserSettings] excludeSettingsForPlan:plan
                                                                              withParameters:planRequestParameters];
        // no need to update changeMainTableSettings since this happens in viewWillAppear
    }
    else { // not referral by toFromViewController (i.e. an update to existing view)
        if (plan != newPlan) {
            logError(@"RouteOptionsViewController -> newPlanAvailable", @"newPlan != plan for a refresh");
            return;  // This update is not relevant, so return
        }
        arrRouteSettings = [[RouteExcludeSettings latestUserSettings] excludeSettingsForPlan:plan
                                                                              withParameters:planRequestParameters];
        [self changeMainTableSettings];
    }
    if (status == PLAN_STATUS_OK) {
        [noItineraryWarning setHidden:YES];
        setWarningHidden = true;
    } else if (status == PLAN_EXCLUDED_TO_ZERO_RESULTS) {
        [noItineraryWarning setHidden:NO]; // show warning
        setWarningHidden = false;
    } 
}

- (void) changeMainTableSettings{
    UIView *bgView = [self.view viewWithTag:1000];
    if(bgView){
        [bgView removeFromSuperview];
        bgView = nil;
    }
    CGRect rect0 = [mainTable frame];
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
        rect0.size.height = ROUTE_OPTIONS_TABLE_HEIGHT_IPHONE5;
        rect0.origin.y = 55;  // TODO Replace with automatic code
    }
    else{
        rect0.size.height = ROUTE_OPTIONS_TABLE_HEIGHT;
        rect0.origin.y = 55;
    }
    int mainTableYPOS = [self calculateTotalHeightOfButtonView];
    if(mainTableYPOS > 0){
        rect0.origin.y = 0;
        rect0.origin.y = mainTableYPOS;
        rect0.size.height = rect0.size.height - mainTableYPOS;
        [self createViewWithButtons:mainTableYPOS];
    }
    [mainTable setFrame:rect0];
    [mainTable reloadData];
}
- (void) reloadData:(Plan *)newPlan{
    self.isReloadRealData = true;
    [mainTable reloadData];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)popOutToNimbler{
    
    for(int i=0;i<[[plan itineraries] count];i++){
        Itinerary *iti = [[[plan itineraries] allObjects]  objectAtIndex:i];
        iti.itinArrivalFlag = nil;
        iti.hideItinerary = false;
        if(iti.isRealTimeItinerary){
            for(int j=0;j<[[iti sortedLegs] count];j++){
                Leg *leg = [[iti sortedLegs] objectAtIndex:j];
                leg.predictions = nil;
                leg.arrivalFlag = nil;
                leg.timeDiffInMins = nil;
            }
            [plan deleteItinerary:iti];
        }
    }
    
    for(int i=0;i<[[plan requestChunks] count];i++){
        PlanRequestChunk *reqChunks = [[[plan requestChunks] allObjects] objectAtIndex:i];
        if(reqChunks.type == [NSNumber numberWithInt:2]){
            [[nc_AppDelegate sharedInstance].managedObjectContext deleteObject:reqChunks];
        }
    }
    saveContext([nc_AppDelegate sharedInstance].managedObjectContext);
    
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    [[self navigationController] popViewControllerAnimated:NO];
}

-(void) toggleExcludeButton:(id)sender{
    UIButton *btn = (UIButton *)sender;
    IncludeExcludeSetting newSettingValue;
    if([[RouteExcludeSettings latestUserSettings] settingForKey:btn.titleLabel.text] == SETTING_EXCLUDE_ROUTE){
        [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_INCLUDE_ROUTE forKey:btn.titleLabel.text];
        [btn setBackgroundImage:[UIImage imageNamed:@"pressed1.png"] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor NIMBLER_RED_FONT_COLOR] forState:UIControlStateNormal];
        newSettingValue = SETTING_INCLUDE_ROUTE;
    }
    else{
        [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:btn.titleLabel.text];
        [btn setBackgroundImage:nil forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor GRAY_FONT_COLOR] forState:UIControlStateNormal];
        newSettingValue = SETTING_EXCLUDE_ROUTE;
    }

    // Update sorted itineraries with new exclusions
    if (!planRequestParameters) {
        logError(@"RouteOptionsViewController -> toggleExcludeButton",
                 @"planRequestParameters = nil, skipping excludeButton updates");
        return;
    }
    arrRouteSettings = [[RouteExcludeSettings latestUserSettings] excludeSettingsForPlan:plan
                                                                          withParameters:planRequestParameters];
    logEvent(FLURRY_EXCLUDE_SETTING_CHANGED,
             FLURRY_CHANGED_EXCLUDE_SETTING, btn.titleLabel.text,
             FLURRY_NEW_EXCLUDE_SETTINGS, [RouteExcludeSettings stringFromSettingArray:arrRouteSettings],
             nil, nil, nil, nil);
    
    PlanRequestParameters* newParameters = [PlanRequestParameters copyOfPlanRequestParameters:planRequestParameters];
    newParameters.thisRequestTripDate = newParameters.originalTripDate;
    newParameters.serverCallsSoFar = 0;
    [plan prepareSortedItinerariesWithMatchesForDate:newParameters.originalTripDate
                                      departOrArrive:newParameters.departOrArrive
                                routeExcludeSettings:[RouteExcludeSettings latestUserSettings]
                             generateGtfsItineraries:YES
                               removeNonOptimalItins:YES];
    [planStore requestMoreItinerariesIfNeeded:self.plan parameters:newParameters];
    [mainTable reloadData];
}


#pragma mark - UITableViewDelegate methods
// Table view management methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[plan sortedItineraries] count];
}

// Only usable for >= iOS6.  Returns NSMutableAttributedString with Caltrain train #s emphasized.  
- (NSMutableAttributedString *)detailTextLabelColor:(NSString *)strDetailtextLabel itinerary:(Itinerary *)itinerary{
    if([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0){
        logError(@"RouteOptionsViewController -> detailTextLabelColor",
                 [NSString stringWithFormat:@"Attempt to use NSMutableAttributedString with iOS version: %f",
                  [[[UIDevice currentDevice] systemVersion] floatValue]]);
        return nil;
    }
    NSString *strFullTrainNumber;
    NSMutableAttributedString *strMutableDetailTextLabel = [[NSMutableAttributedString alloc] initWithString:strDetailtextLabel];
    for(int i=0;i<[[itinerary sortedLegs] count];i++){
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:i];
        if([[leg agencyId] isEqualToString:CALTRAIN_AGENCY_ID]){
            NSString *strTrainNumber;
            NSRange range;
            NSString *strHeadSign = [leg headSign];
            NSArray *headSignComponent = [strHeadSign componentsSeparatedByString:@"Train"];
            strTrainNumber = [headSignComponent objectAtIndex:1];
            if([strTrainNumber rangeOfString:@")" options:NSCaseInsensitiveSearch].location != NSNotFound){
                range = [strTrainNumber rangeOfString:@")"];
                strTrainNumber = [strTrainNumber substringToIndex:range.location];
                NSString * strTempTrainNumber = [strTrainNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                strFullTrainNumber = [NSString stringWithFormat:@"#%@",strTempTrainNumber];
            }
            if([strDetailtextLabel rangeOfString:strFullTrainNumber options:NSCaseInsensitiveSearch].location != NSNotFound){
                range = [strDetailtextLabel rangeOfString:strFullTrainNumber];
                if([[leg routeLongName] isEqualToString:@"Local"]){
                    [strMutableDetailTextLabel addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:range];
                }
                // DE-227 Fixed
                // Changed the red Color to Nimbler Red and changed limited train to italic
                if([[leg routeLongName] isEqualToString:@"Limited"]){
                    [strMutableDetailTextLabel addAttribute:NSFontAttributeName value:[UIFont MEDIUM_OBLIQUE_FONT] range:range];
                }
                if([[leg routeLongName] isEqualToString:@"Bullet"]){
                    [strMutableDetailTextLabel addAttribute:NSFontAttributeName value:[UIFont MEDIUM_OBLIQUE_FONT] range:range];
                    [strMutableDetailTextLabel addAttribute:NSForegroundColorAttributeName value:[UIColor NIMBLER_RED_FONT_COLOR] range:range];
                }
            }
        }
    }
    return strMutableDetailTextLabel;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:IDENTIFIER_CELL];
    @try {
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                          reuseIdentifier:IDENTIFIER_CELL];
            [cell.imageView setImage:nil];
        }
        UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithImage:imageDetailDisclosure];
        [cell setAccessoryView:imgViewDetailDisclosure];
         cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.numberOfLines = 2;
        // Get the requested itinerary
        Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
        
        // Set title
        [[cell textLabel] setFont:[UIFont MEDIUM_BOLD_FONT]];
        //Part Of DE-229 Implementation
        NSString *timeDiffFirstLeg;
        NSString *timeDiffLastLeg;
        NSString *titleText;
        Leg *firstLeg;
        if([itin.sortedLegs count] > 0){
            firstLeg = [itin.sortedLegs objectAtIndex:0];
            timeDiffFirstLeg = firstLeg.timeDiffInMins;
        }
        Leg *lastLeg = [[itin sortedLegs] lastObject];
        timeDiffLastLeg = lastLeg.timeDiffInMins;
        UIView *viewCellBackground = [[UIView alloc] init];
        [viewCellBackground setBackgroundColor:[UIColor CELL_BACKGROUND_ROUTE_OPTION_VIEW]];
        cell.backgroundView = viewCellBackground;
        NSString* durationStr = durationString(1000.0 * [[itin endTimeOfLastLeg]
                                                         timeIntervalSinceDate:[itin startTimeOfFirstLeg]]);
        titleText = [NSString stringWithFormat:@"%@ - %@ (%@)",
                     superShortTimeStringForDate([itin startTimeOfFirstLeg]),
                     superShortTimeStringForDate([itin endTimeOfLastLeg]),
                     durationStr];
        cell.textLabel.text = titleText;
        // notify with TEXT for LEG timimg
        if (isReloadRealData) {
            if([itin itinArrivalFlag] >= 0) {
                if([itin.itinArrivalFlag intValue] == ON_TIME) {
                    titleText = [NSString stringWithFormat:@"%@ %@",titleText,@"On Time"];
                }  else if([itin.itinArrivalFlag intValue] == DELAYED) {
                    NSDate *realStartTime;
                    NSDate *realEndTime;
                    if(timeDiffFirstLeg)
                        realStartTime = [[itin startTimeOfFirstLeg]
                                               dateByAddingTimeInterval:[timeDiffFirstLeg floatValue]*60.0];
                    else
                        realStartTime = [itin startTimeOfFirstLeg]
                        ;
                    
                    if(timeDiffLastLeg)
                        realEndTime = [[itin endTimeOfLastLeg]
                                         dateByAddingTimeInterval:[timeDiffLastLeg floatValue]*60.0];
                    else
                        realEndTime = [itin endTimeOfLastLeg]
                        ;
                    
                        
                    NSString* durationStr = durationString(1000.0 * [realEndTime
                                                                     timeIntervalSinceDate:realStartTime]);
                    titleText = [NSString stringWithFormat:@"%@ - %@ (%@)",
                                 superShortTimeStringForDate(realStartTime),
                                           superShortTimeStringForDate(realEndTime),
                                           durationStr];
                    cell.textLabel.text = titleText;
                    titleText = [NSString stringWithFormat:@"%@ %@",titleText,@"Delayed"];
                } else if([itin.itinArrivalFlag intValue] == EARLY) {
                     NSDate* realTimeArrivalTime;
                    if(timeDiffFirstLeg){
                        realTimeArrivalTime = [[itin startTimeOfFirstLeg]
                                               dateByAddingTimeInterval:[timeDiffFirstLeg floatValue]*60.0];
                    }
                    else{
                        realTimeArrivalTime = [itin startTimeOfFirstLeg]
                        ;
                    }
                    NSString* durationStr = durationString(1000.0 * [[itin endTimeOfLastLeg]
                                                                     timeIntervalSinceDate:realTimeArrivalTime]);
                    titleText = [NSString stringWithFormat:@"%@ - %@ (%@)",
                                           superShortTimeStringForDate(realTimeArrivalTime),
                                           superShortTimeStringForDate([itin endTimeOfLastLeg]),
                                           durationStr];
                    titleText = [NSString stringWithFormat:@"%@ %@",titleText,@"Early"];
                } else if([itin.itinArrivalFlag intValue] == EARLIER) {
                   titleText = [NSString stringWithFormat:@"%@ %@",titleText,@"Earlier"];
                } else if ([itin.itinArrivalFlag intValue] == ITINERARY_TIME_SLIPPAGE ) {
                     titleText = [NSString stringWithFormat:@"%@ %@",titleText,@"Updated"];
                }
                 [[cell textLabel] setText:titleText];
            }
        }         
        cell.textLabel.textColor = [UIColor NIMBLER_RED_FONT_COLOR];
        [[cell detailTextLabel] setFont:[UIFont MEDIUM_FONT]];
        cell.detailTextLabel.textColor = [UIColor GRAY_FONT_COLOR];
        
        // DE-228 Fixed
        // Applied The color only if the ios version is 6.0 or greater.
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 6){
            NSString *strDetailtextLabel = [itin itinerarySummaryStringForWidth:ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH
                                                                           Font:cell.detailTextLabel.font];
            NSMutableAttributedString *strMutableDetailTextLabel = [self detailTextLabelColor:strDetailtextLabel itinerary:itin];
            [cell detailTextLabel].attributedText = strMutableDetailTextLabel;
        }
        else{
            cell.detailTextLabel.text = [itin itinerarySummaryStringForWidth:ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH
                                                                        Font:cell.detailTextLabel.font];
        }
        [[cell detailTextLabel] setNumberOfLines:0];  // Allow for multi-lines
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->cellForRowAtIndexPath", @"", exception);
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    @try {
    Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
    
    NSString* durationStr = durationString(1000.0 * [[itin endTimeOfLastLeg]
                                                     timeIntervalSinceDate:[itin startTimeOfFirstLeg]]);
    
    // TODO -- make sure not text wrapping on first line
    NSString *titleText = [NSString stringWithFormat:@"%@ - %@ (%@)",
                           superShortTimeStringForDate([itin startTimeOfFirstLeg]),
                           superShortTimeStringForDate([itin endTimeOfLastLeg]),
                           durationStr];
    NSString* subtitleText = [itin itinerarySummaryStringForWidth:(CGFloat)ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH
                                                             Font:(UIFont *)[UIFont MEDIUM_FONT]];
    
    CGSize titleSize = [titleText sizeWithFont:[UIFont MEDIUM_BOLD_FONT]
                             constrainedToSize:CGSizeMake(ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH, CGFLOAT_MAX)];

    CGSize subtitleSize = [subtitleText sizeWithFont:[UIFont MEDIUM_FONT]
                                   constrainedToSize:CGSizeMake(ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH, CGFLOAT_MAX)];
    
    CGFloat height = titleSize.height + subtitleSize.height + ROUTE_OPTIONS_VARIABLE_TABLE_CELL_HEIGHT_BUFFER;
    if (height < ROUTE_OPTIONS_TABLE_CELL_MINIMUM_HEIGHT) { // Set a minumum row height
        height = ROUTE_OPTIONS_TABLE_CELL_MINIMUM_HEIGHT;
    }
    
    return height;
    }
   @catch (NSException *exception) {
       logException(@"RouteOptionsViewController->heightForRowAtIndexPath", @"", exception);
       return ROUTE_OPTIONS_TABLE_CELL_MINIMUM_HEIGHT;
   }
}

-(void)hideUnUsedTableViewCell
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor clearColor];
    [mainTable setTableFooterView:view];
}

// If selected, show the RouteDetailsViewController
- (void) tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        UITableViewCell *cell = [atableView cellForRowAtIndexPath:indexPath];
        UIView *viewCellBackground = [[UIView alloc] init];
        [viewCellBackground setBackgroundColor:[UIColor CELL_BACKGROUND_ROUTE_OPTION_VIEW]];
        cell.backgroundView = viewCellBackground;
        if (!routeDetailsVC) {
            routeDetailsVC = [[RouteDetailsViewController alloc] initWithNibName:@"RouteDetailsViewController" bundle:nil];
        }
        itinerary = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
        itinararyId =[itinerary itinId];

        logEvent(FLURRY_ROUTE_SELECTED,
                 FLURRY_SELECTED_ROW_NUMBER, [NSString stringWithFormat:@"%d", [indexPath row]],
                 FLURRY_SELECTED_DEPARTURE_TIME, [NSString stringWithFormat:@"%@", [itinerary startTimeOfFirstLeg]],
                 nil, nil, nil, nil);
        
        [routeDetailsVC setItinerary:itinerary];
        if([[[UIDevice currentDevice] systemVersion] intValue] < 5.0){
            CATransition *animation = [CATransition animation];
            [animation setDuration:0.3];
            [animation setType:kCATransitionPush];
            [animation setSubtype:kCATransitionFromRight];
            [animation setRemovedOnCompletion:YES];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [[self.navigationController.view layer] addAnimation:animation forKey:nil];
            [[self navigationController] pushViewController:routeDetailsVC animated:NO];
        }
        else{
            [[self navigationController] pushViewController:routeDetailsVC animated:YES];
        } 
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->didSelectRowAtIndexPath", @"", exception);
    }
}



#pragma mark - View lifecycle

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Accessibility Label For UI Automation.
    self.mainTable.accessibilityLabel =ROUTE_OPTIONS_TABLE_VIEW;
    
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
    }
    btnGoToNimbler = [[UIButton alloc] initWithFrame:CGRectMake(0,0,65,34)];
    [btnGoToNimbler addTarget:self action:@selector(popOutToNimbler) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToNimbler setBackgroundImage:[UIImage imageNamed:@"img_nimblerNavigation.png"] forState:UIControlStateNormal];
    
    // Accessibility Label For UI Automation.
    btnGoToNimbler.accessibilityLabel =BACK_TO_NIMBLER_BUTTON;
    
    UIBarButtonItem *backTonimbler = [[UIBarButtonItem alloc] initWithCustomView:btnGoToNimbler];
    self.navigationItem.leftBarButtonItem = backTonimbler;
    
    [self hideUnUsedTableViewCell];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NIMLOG_PERF1(@"RouteOptions did appear");
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
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
        logException(@"RouteOptionsViewController->didLoadResponse", @"Exception while getting unique IDs from TP Server response: %@", exception);
    }
}


-(void)setFBParameterForPlan
{
    [nc_AppDelegate sharedInstance].FBSource = [NSNumber numberWithInt:FB_SOURCE_PLAN];
    [nc_AppDelegate sharedInstance].FBDate = nil;
    [nc_AppDelegate sharedInstance].FBToAdd = nil;
    [nc_AppDelegate sharedInstance].FBSFromAdd = nil;
    [nc_AppDelegate sharedInstance].FBUniqueId = [plan planId];
}

- (void) createViewWithButtons:(int)height{
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, height)];
    [bgView setTag:1000];
    [bgView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:bgView];
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, height)];
    [imgView setImage:[UIImage imageNamed:@"img_travel.png"]];
    [bgView addSubview:imgView];
    
    UILabel *lblChoose = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 80, 25)];
    [lblChoose setText:@"Travel By:"];
    [lblChoose setBackgroundColor:[UIColor clearColor]];
    [lblChoose setFont:[UIFont fontWithName:@"Helvetica-Bold" size:13.0]];
    [lblChoose setTextAlignment:UITextAlignmentCenter];
    [lblChoose setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
    [bgView addSubview:lblChoose];
    
    int xPos = 80;
    int yPos = 5;
    int width = 80;
    int btnHeight = 25;
    
    for(int i=0;i<[arrRouteSettings count];i++){
        RouteExcludeSetting *routeExcludeSetting = [arrRouteSettings objectAtIndex:i];
        UIButton *btnAgency = [UIButton buttonWithType:UIButtonTypeCustom];
        if(xPos+width > 320){
            yPos = yPos + 25 + 5;
            xPos = 0;
        }
        [btnAgency setFrame:CGRectMake(xPos,yPos, width, btnHeight)];
        xPos = xPos + width;
        [btnAgency setTitle:routeExcludeSetting.key forState:UIControlStateNormal];
        [btnAgency.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12.0]];
        if([[RouteExcludeSettings latestUserSettings] settingForKey:routeExcludeSetting.key] == SETTING_EXCLUDE_ROUTE){
            [btnAgency setBackgroundImage:nil forState:UIControlStateNormal];
            [btnAgency setTitleColor:[UIColor GRAY_FONT_COLOR] forState:UIControlStateNormal];
        }
        else{
            [btnAgency setBackgroundImage:[UIImage imageNamed:@"pressed1.png"] forState:UIControlStateNormal];
            [btnAgency setTitleColor:[UIColor NIMBLER_RED_FONT_COLOR] forState:UIControlStateNormal];
        }
        [btnAgency addTarget:self action:@selector(toggleExcludeButton:) forControlEvents:UIControlEventTouchUpInside];
        [bgView addSubview:btnAgency];
    }
}

- (int) calculateTotalHeightOfButtonView{
    int tempButtonCounts;
    if([arrRouteSettings count] > 3)
       tempButtonCounts = [arrRouteSettings count] - 3;
    else
        tempButtonCounts = 0;
    
    int tempDivision = tempButtonCounts/4;
    int tempModulo = tempButtonCounts%4;
    int nAdditionalRows;
    if(tempModulo > 0)
      nAdditionalRows = tempDivision + 1;
    else
        nAdditionalRows = tempDivision;
    
    int totalRows = nAdditionalRows + 1;
    int buffer = 0;
    if(totalRows > 0)
      buffer = (totalRows+1) * 5;
    return totalRows * 25 + buffer;
}
@end