//
// RouteOptionsViewController.m
// Nimbler World, Inc.
//
// Created by John Canfield on 1/20/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "RouteOptionsViewController.h"
#import "Leg.h"
#import "UtilityFunctions.h"
#import <math.h>
#import "FeedBackForm.h"
#import "LegMapViewController.h"
#import "twitterViewController.h"
#import "nc_AppDelegate.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "Itinerary.h"
#import "RouteExcludeSettings.h"
#import "RouteExcludeSetting.h"
#import "PlanStore.h"
#import "nc_AppDelegate.h"
#import "RealTimeManager.h"
#import "FeedBackForm.h"
#import "UberMgr.h"

#define TIMER_DEFAULT_VALUE 119

@interface RouteOptionsViewController()
{
    // Variables for internal use
    BOOL setWarningHidden; // True if we should set the warning to be hidden upon viewWillAppear
    NSStringDrawingContext *drawingContext;  // Drawing context for attributed strings
    int routeOptionsTableCellWidth; // Dynamic width used for text wrapping
}

// Attributed strings are only supported on iOS6 or later, so do not call this method on < iOS6
- (NSMutableAttributedString *)detailTextLabelColor:(NSString *)strDetailtextLabel itinerary:(Itinerary *)itinerary;

@end

@implementation RouteOptionsViewController

@synthesize mainTable;
@synthesize noItineraryWarning;
@synthesize modeBtnView;
@synthesize travelByLabel;
@synthesize plan;
@synthesize isReloadRealData;
@synthesize btnGoToNimbler;
@synthesize planRequestParameters;
@synthesize routeDetailsVC;
@synthesize uberDetailsVC;
@synthesize planStore;
@synthesize activityIndicator;
@synthesize timerGettingRealDataByItinerary;
@synthesize timerRealtime;
@synthesize remainingCount;
@synthesize btnFeedBack;

Itinerary * itinerary;
NSString *itinararyId;
UIImage *imageDetailDisclosure;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
        [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
        lblNavigationTitle.text=ROUTE_OPTIONS_VIEW_TITLE;
        lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
        [lblNavigationTitle setTextAlignment:NSTextAlignmentCenter];
        lblNavigationTitle.backgroundColor =[UIColor clearColor];
        lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
        self.navigationItem.titleView=lblNavigationTitle;
        imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
        drawingContext = [[NSStringDrawingContext alloc] init];
        drawingContext.minimumScaleFactor = 0.0;  // Specifies no scaling
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [nc_AppDelegate sharedInstance].isRouteOptionView = false;
    if(self.timerRealtime){
        [self.timerRealtime invalidate];
        self.timerRealtime = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
     [[nc_AppDelegate sharedInstance].twitterCount setHidden:YES];
    [self changeMainTableSettings];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    if(plan){
        self.timerRealtime = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(requestServerForRealTime) userInfo:nil repeats: NO];
    }
    logEvent(FLURRY_ROUTE_OPTIONS_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
    [nc_AppDelegate sharedInstance].isRouteOptionView = true;
    // Enforce height of main table
    mainTable.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"img_line.png"]];
    //[mainTable reloadData];
    [self setFBParameterForPlan];
    [noItineraryWarning setHidden:setWarningHidden];
}

- (void) hideItineraryIfNeeded:(NSArray *)arrItinerary{
    for(int i=0;i<[arrItinerary count];i++){
        Itinerary *itinerary1 = [arrItinerary objectAtIndex:i];
        if(!itinerary1.isRealTimeItinerary)
            continue;
        for(int j=0;j<[arrItinerary count];j++){
            Itinerary *itinerary2 = [arrItinerary objectAtIndex:j];
            if(itinerary2.isRealTimeItinerary || ![itinerary1 isEquivalentModesAndStopsAs:itinerary2])
                continue;
            NSDate *realStartTime = addDateOnlyWithTime(dateOnlyFromDate([NSDate date]), [itinerary1 startTimeOfFirstLeg]);
            NSDate *scheduledStartTime = addDateOnlyWithTime(dateOnlyFromDate([NSDate date]),[itinerary2 startTimeOfFirstLeg]);
            double realTimeInterval = timeIntervalFromDate(realStartTime);
            double scheduledTimeInterval = timeIntervalFromDate(scheduledStartTime);
            if([realStartTime compare:scheduledStartTime] == NSOrderedDescending || realTimeInterval == scheduledTimeInterval){
                itinerary2.hideItinerary = true;
            }
        }
    }
}

- (void) decrementCounter{
    if(remainingCount == 0){
        [self requestServerForRealTime];
        if(self.timerGettingRealDataByItinerary){
            [self.timerGettingRealDataByItinerary invalidate];
            self.timerGettingRealDataByItinerary = nil;
        }
        remainingCount = TIMER_DEFAULT_VALUE;
        self.timerGettingRealDataByItinerary = [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(decrementCounter) userInfo:nil repeats: YES];
    }
    remainingCount = remainingCount - 1;
}
// Method used to set the plan
-(void)newPlanAvailable:(Plan *)newPlan
             fromObject:(id)referringObject
                 status:(PlanRequestStatus)status
       RequestParameter:(PlanRequestParameters *)requestParameter
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    if (status == PLAN_GENERIC_EXCEPTION || status == PLAN_NOT_AVAILABLE_THAT_TIME) {
        if (plan && [[plan sortedItineraries] count] == 0) {
            // if no itineraries showing, then show warning
            [noItineraryWarning setHidden:NO];
            setWarningHidden = false;
        }
        return;
    }
    NIMLOG_US202(@"newPlanAvailable, status=%d, sortedItins=%d", status, newPlan.sortedItineraries.count);
    planRequestParameters = requestParameter;
    if ([referringObject isKindOfClass:[ToFromViewController class]]) {
        plan = newPlan;
        // no need to update changeMainTableSettings since this happens in viewWillAppear
    }
    else { // not referral by toFromViewController (i.e. an update to existing view)
        if (plan != newPlan) {
            logError(@"RouteOptionsViewController -> newPlanAvailable", @"newPlan != plan for a refresh");
            return; // This update is not relevant, so return
        }
        [self changeMainTableSettings];
    }
    if (status == PLAN_STATUS_OK) {
        [noItineraryWarning setHidden:YES];
        setWarningHidden = true;
    }
    // Fixed DE-322
    else if (status == PLAN_EXCLUDED_TO_ZERO_RESULTS && [[plan sortedItineraries] count] == 0) {
        [noItineraryWarning setHidden:NO]; // show warning
        setWarningHidden = false;
    } else {
        logError(@"RouteOptionsViewController -> newPlanAvailable",
                 [NSString stringWithFormat:@"Unexpected status = %d", status]);
    }
    if (planRequestParameters.needToRequestRealtime || planRequestParameters.serverCallsSoFar >= PLAN_MAX_SERVER_CALLS_PER_REQUEST) {
        if(self.timerGettingRealDataByItinerary != nil){
            [self.timerGettingRealDataByItinerary invalidate];
            self.timerGettingRealDataByItinerary = nil;
        }
        if(self.timerRealtime){
            [self.timerRealtime invalidate];
            self.timerRealtime = nil;
        }
        remainingCount = TIMER_DEFAULT_VALUE;
        self.timerRealtime = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(requestServerForRealTime) userInfo:nil repeats: NO];
        self.timerGettingRealDataByItinerary = [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(decrementCounter) userInfo:nil repeats: YES];
    }
}


- (void) changeMainTableSettings{
    int mainTableYPOS = [self calculateTotalHeightOfButtonView];
    if(mainTableYPOS > 0){
        [self createViewWithButtons:mainTableYPOS];
    }
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
        Itinerary *iti = [[[plan itineraries] allObjects] objectAtIndex:i];
        if(iti.isRealTimeItinerary){
            [plan deleteItinerary:iti];
        }
        if(iti.hideItinerary){
            iti.hideItinerary = false;
        }
    }
    for(PlanRequestChunk *reqChunks in [plan requestChunks]){
        if(reqChunks.type == [NSNumber numberWithInt:2]){
            [[nc_AppDelegate sharedInstance].managedObjectContext deleteObject:reqChunks];
        }
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


-(void) toggleExcludeButton:(id)sender{
    @try {
        if(self.timerRealtime){
            [self.timerRealtime invalidate];
            self.timerRealtime = nil;
        }
        self.timerRealtime = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(requestServerForRealTime) userInfo:nil repeats: NO];
        NIMLOG_PERF2(@"toggleExcludeButton started");
        [activityIndicator startAnimating];
        // DE-293 Fixed
        [noItineraryWarning setHidden:YES];
        setWarningHidden = true;
        UIButton *btn = (UIButton *)sender;
        RouteExcludeSetting* toggledSetting;
        for (RouteExcludeSetting *setting in [plan excludeSettingsArray]) {
            if ([setting.key isEqualToString:btn.titleLabel.text]) {
                toggledSetting = setting; // Getting the setting we are going to toggle in the settingArray
                break;
            }
        }
        if([[RouteExcludeSettings latestUserSettings] settingForKey:btn.titleLabel.text] == SETTING_EXCLUDE_ROUTE){
            
            NSArray *subViews = [modeBtnView subviews];
            if([btn.titleLabel.text isEqualToString:returnBikeButtonTitle()]){
                [[NSUserDefaults standardUserDefaults] setObject:MODE_ENABLE forKey:DEFAULT_BIKE_MODE];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:BIKE_SHARE];
                for(int i=0;i<[subViews count];i++){
                    UIButton *button = [subViews objectAtIndex:i];
                    if([button isKindOfClass:[UIButton class]] && [button.titleLabel.text isEqualToString:BIKE_SHARE]){
                        [[NSUserDefaults standardUserDefaults] setObject:MODE_DISABLE forKey:DEFAULT_SHARE_MODE];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [button setBackgroundImage:[UIImage imageNamed:@"excludeUnSelected@2x.png"] forState:UIControlStateNormal];
                        [button setTitleColor:[UIColor LIGHT_GRAY_FONT_COLOR] forState:UIControlStateNormal];
                        break;
                    }
                }
            }
            else if([btn.titleLabel.text isEqualToString:BIKE_SHARE]){
                [[NSUserDefaults standardUserDefaults] setObject:MODE_ENABLE forKey:DEFAULT_SHARE_MODE];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:returnBikeButtonTitle()];
                for(int i=0;i<[subViews count];i++){
                    UIButton *button = [subViews objectAtIndex:i];
                    if([button isKindOfClass:[UIButton class]] && [button.titleLabel.text isEqualToString:returnBikeButtonTitle()]){
                        [[NSUserDefaults standardUserDefaults] setObject:MODE_DISABLE forKey:DEFAULT_BIKE_MODE];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [button setBackgroundImage:[UIImage imageNamed:@"excludeUnSelected@2x.png"] forState:UIControlStateNormal];
                        [button setTitleColor:[UIColor LIGHT_GRAY_FONT_COLOR] forState:UIControlStateNormal];
                        break;
                    }
                }
            }
            else if([btn.titleLabel.text isEqualToString:UBER_EXCLUDE_BUTTON_DISPLAY_NAME]) {
                [[NSUserDefaults standardUserDefaults] setObject:MODE_ENABLE forKey:DEFAULT_CAR_MODE];
            }
            else{
                [[NSUserDefaults standardUserDefaults] setObject:MODE_ENABLE forKey:DEFAULT_TRANSIT_MODE];
            } 
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_INCLUDE_ROUTE forKey:btn.titleLabel.text];
            toggledSetting.setting = SETTING_INCLUDE_ROUTE;
            [btn setBackgroundImage:[UIImage imageNamed:@"excludeSelected@2x.png"] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor NIMBLER_RED_FONT_COLOR] forState:UIControlStateNormal];
        }
        else{
            
            [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:btn.titleLabel.text];
            toggledSetting.setting = SETTING_EXCLUDE_ROUTE;
            [btn setBackgroundImage:[UIImage imageNamed:@"excludeUnSelected@2x.png"] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor LIGHT_GRAY_FONT_COLOR] forState:UIControlStateNormal];
            
            if([btn.titleLabel.text isEqualToString:returnBikeButtonTitle()]){
                [[NSUserDefaults standardUserDefaults] setObject:MODE_DISABLE forKey:DEFAULT_BIKE_MODE];
            }
            else if([btn.titleLabel.text isEqualToString:BIKE_SHARE]){
                [[NSUserDefaults standardUserDefaults] setObject:MODE_DISABLE forKey:DEFAULT_SHARE_MODE];
            }
            else if([btn.titleLabel.text isEqualToString:UBER_EXCLUDE_BUTTON_DISPLAY_NAME]){
                [[NSUserDefaults standardUserDefaults] setObject:MODE_DISABLE forKey:DEFAULT_CAR_MODE];
            }
            else{
                BOOL isTransitModeExcluded = false;
                for(int i=0;i<[[plan excludeSettingsArray] count];i++){
                    RouteExcludeSetting *routeExcludeSetting = [[plan excludeSettingsArray] objectAtIndex:i];
                    NSString *key = routeExcludeSetting.key;
                    if(![key isEqualToString:returnBikeButtonTitle()] && ![key isEqualToString:BIKE_SHARE]){
                        if([[RouteExcludeSettings latestUserSettings] settingForKey:key] == SETTING_INCLUDE_ROUTE){
                            isTransitModeExcluded = true;
                            break;
                        }
                    }
                }
                if(!isTransitModeExcluded){
                  [[NSUserDefaults standardUserDefaults] setObject:MODE_DISABLE forKey:DEFAULT_TRANSIT_MODE];
                }
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        // Update sorted itineraries with new exclusions
        if (!planRequestParameters) {
            logError(@"RouteOptionsViewController -> toggleExcludeButton",
                     @"planRequestParameters = nil, skipping excludeButton updates");
            return;
        }
        NIMLOG_PERF2(@"Finished setting button");
        logEvent(FLURRY_EXCLUDE_SETTING_CHANGED,
                 FLURRY_CHANGED_EXCLUDE_SETTING, btn.titleLabel.text,
                 FLURRY_NEW_EXCLUDE_SETTINGS, [RouteExcludeSettings stringFromSettingArray:[plan excludeSettingsArray]],
                 nil, nil, nil, nil);
        
        PlanRequestParameters* newParameters = [PlanRequestParameters copyOfPlanRequestParameters:planRequestParameters];
        newParameters.thisRequestTripDate = newParameters.originalTripDate;
        newParameters.serverCallsSoFar = 0;
        NIMLOG_PERF2(@"preparing sortedItineraries");
        [plan prepareSortedItinerariesWithMatchesForDate:newParameters.originalTripDate
                                          departOrArrive:newParameters.departOrArrive
                                    routeExcludeSettings:[RouteExcludeSettings latestUserSettings]
                                 generateGtfsItineraries:NO
                                   removeNonOptimalItins:YES];
        if (!setWarningHidden && [[plan sortedItineraries] count] > 0) { // if we now have itineraries, hide warning
            [noItineraryWarning setHidden:YES];
            setWarningHidden = true;
        }
        NIMLOG_PERF2(@"done preparing sortedItineraries");
        MoreItineraryStatus reqStatus = [planStore requestMoreItinerariesIfNeeded:self.plan parameters:newParameters];
        if (reqStatus == NO_MORE_ITINERARIES_REQUESTED && [[plan sortedItineraries] count] == 0) {
            // if no itineraries showing and no more requests made, show warning
            [noItineraryWarning setHidden:NO];
            setWarningHidden = false;
        }
        //[activityIndicator stopAnimating];
        [mainTable reloadData];
        NIMLOG_PERF2(@"done toggleExcludeButton");
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->toggleExcludeButton", @"", exception);
    }
}

#pragma mark - UITableViewDelegate methods
// Table view management methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    @try {
        return [[plan sortedItineraries] count];
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->numberOfRowsInSection", @"", exception);
    }
}


// Only usable for >= iOS6. Returns NSMutableAttributedString with Caltrain train #s emphasized.
- (NSMutableAttributedString *)detailTextLabelColor:(NSString *)strDetailtextLabel itinerary:(Itinerary *)itinerary{
    if([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0){
        logError(@"RouteOptionsViewController -> detailTextLabelColor",
                 [NSString stringWithFormat:@"Attempt to use NSMutableAttributedString with iOS version: %f",
                  [[[UIDevice currentDevice] systemVersion] floatValue]]);
        return nil;
    }
    NSMutableAttributedString *strMutableDetailTextLabel = [[NSMutableAttributedString alloc] initWithString:strDetailtextLabel];
    for(int i=0;i<[[itinerary sortedLegs] count];i++){
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:i];
        if([[leg agencyId] isEqualToString:CALTRAIN_AGENCY_ID]){
            NSString *strFullTrainNumber = nil;
            NSString *strTrainNumber = nil;
            NSRange range;
            NSString *strHeadSign = [leg headSign];
            NSArray *headSignComponent = [strHeadSign componentsSeparatedByString:@"Train"];
            if ([headSignComponent count] > 1) {
                strTrainNumber = [headSignComponent objectAtIndex:1];
            } else if (leg.tripShortName && leg.tripShortName.length > 0) {
                strTrainNumber = leg.tripShortName;
                strFullTrainNumber = leg.tripShortName;
            }
            if (strTrainNumber &&
                [strTrainNumber rangeOfString:@")" options:NSCaseInsensitiveSearch].location != NSNotFound){
                range = [strTrainNumber rangeOfString:@")"];
                strTrainNumber = [strTrainNumber substringToIndex:range.location];
                NSString * strTempTrainNumber = [strTrainNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                strFullTrainNumber = [NSString stringWithFormat:@"#%@",strTempTrainNumber];
            }
            if(strFullTrainNumber &&
               [strDetailtextLabel rangeOfString:strFullTrainNumber options:NSCaseInsensitiveSearch].location != NSNotFound){
                range = [strDetailtextLabel rangeOfString:strFullTrainNumber];
                if([[leg routeLongName] isEqualToString:@"Local"]){
                    [strMutableDetailTextLabel addAttribute:NSForegroundColorAttributeName value:[UIColor GRAY_FONT_COLOR] range:range];
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
    routeOptionsTableCellWidth = tableView.frame.size.width - ROUTE_OPTIONS_TABLE_CELL_TEXT_BORDER;
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UIRouteOptionsViewCell"];
    @try {
        int mostRecentCellWidth = cell.frame.size.width - ROUTE_OPTIONS_TABLE_CELL_TEXT_BORDER;
        if (!cell || mostRecentCellWidth != routeOptionsTableCellWidth) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:@"UIRouteOptionsViewCell"];
            [cell.imageView setImage:nil];
            UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithImage:imageDetailDisclosure];
            [cell setAccessoryView:imgViewDetailDisclosure];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 2;
            [cell setBackgroundColor:[UIColor clearColor]];
            
            [[cell textLabel] setFont:[UIFont MEDIUM_BOLD_FONT]];
            cell.textLabel.textColor = [UIColor NIMBLER_RED_FONT_COLOR];
            [[cell detailTextLabel] setFont:[UIFont MEDIUM_FONT]];
            cell.detailTextLabel.textColor = [UIColor GRAY_FONT_COLOR];
        }
        
        // Get the requested itinerary
        Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
        
        // Handle Uber itinerary case first
        NIMLOG_UBER(@"TableCell row:%d, isUber:%d",[indexPath row], itin.isUberItinerary);
        if (itin.isUberItinerary) {
            ItineraryFromUber *uberItin = (ItineraryFromUber *)itin;
            cell.textLabel.textColor = [UIColor NIMBLER_RED_FONT_COLOR];
            [[cell detailTextLabel] setFont:[UIFont MEDIUM_FONT]];
            cell.detailTextLabel.textColor = [UIColor GRAY_FONT_COLOR];
            
            [[cell textLabel] setText:@"Uber"];
            
            NSMutableString* pricelabel = [NSMutableString stringWithCapacity:40];
            if (uberItin.uberTimeEstimateSeconds) {
                [pricelabel appendFormat:@"In %d min", uberItin.uberTimeEstimateMinutes];
            }
            if (uberItin.uberPriceEstimate) {
                [pricelabel appendFormat:@" \u2013 %@",uberItin.uberPriceEstimate];
            }
            if (uberItin.uberSurgeMultiplier.floatValue > 1.00000001) {
                [pricelabel appendString:@" (surge)"];
            }
            [[cell detailTextLabel] setText:pricelabel];
            return cell;
        }
        
        // ... else not an uber itinerary

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
//        UIView *viewCellBackground = [[UIView alloc] init];
//        [viewCellBackground setBackgroundColor:[UIColor CELL_BACKGROUND_ROUTE_OPTION_VIEW]];
//        cell.backgroundView = viewCellBackground;
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
                } else if([itin.itinArrivalFlag intValue] == DELAYED) {
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
        
        // DE-228 Fixed
        // Applied The color only if the ios version is 6.0 or greater.
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 6){
            NSString *strDetailtextLabel = [itin itinerarySummaryStringForWidth:routeOptionsTableCellWidth
                                                                           Font:cell.detailTextLabel.font];
            NSMutableAttributedString *strMutableDetailTextLabel = [self detailTextLabelColor:strDetailtextLabel itinerary:itin];
            [cell detailTextLabel].attributedText = strMutableDetailTextLabel;
        }
        else{
            cell.detailTextLabel.text = [itin itinerarySummaryStringForWidth:routeOptionsTableCellWidth
                                                                        Font:cell.detailTextLabel.font];
        }
        [[cell detailTextLabel] setNumberOfLines:0]; // Allow for multi-lines
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->cellForRowAtIndexPath", @"", exception);
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        routeOptionsTableCellWidth = aTableView.frame.size.width - ROUTE_OPTIONS_TABLE_CELL_TEXT_BORDER;
        Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
        
        NSString *titleText;
        NSString *subtitleText;
        // Uber case
        if (itin.isUberItinerary) {
            ItineraryFromUber *uberItin = (ItineraryFromUber *)itin;
            titleText =  @"Uber";
            subtitleText = uberItin.uberPriceEstimate;
        }
        
        else {  // non-Uber case
            NSString* durationStr = durationString(1000.0 * [[itin endTimeOfLastLeg]
                                                             timeIntervalSinceDate:[itin startTimeOfFirstLeg]]);
            // TODO -- make sure not text wrapping on first line
            titleText = [NSString stringWithFormat:@"%@ - %@ (%@)",
                         superShortTimeStringForDate([itin startTimeOfFirstLeg]),
                         superShortTimeStringForDate([itin endTimeOfLastLeg]),
                         durationStr];
            subtitleText = [itin itinerarySummaryStringForWidth:(CGFloat)routeOptionsTableCellWidth
                                                           Font:(UIFont *)[UIFont MEDIUM_FONT]];
        }
        CGRect titleRect = [titleText
                                boundingRectWithSize:CGSizeMake(routeOptionsTableCellWidth, CGFLOAT_MAX)
                                options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                attributes:[NSDictionary dictionaryWithObject:[UIFont MEDIUM_BOLD_FONT] forKey:NSFontAttributeName]
                                context:drawingContext];
        CGRect subtitleRect = [subtitleText
                                boundingRectWithSize:CGSizeMake(routeOptionsTableCellWidth, CGFLOAT_MAX)
                                options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                attributes:[NSDictionary dictionaryWithObject:[UIFont MEDIUM_FONT] forKey:NSFontAttributeName]
                                context:drawingContext];
        
        CGFloat height = ceil(titleRect.size.height) + ceil(subtitleRect.size.height) + ROUTE_OPTIONS_VARIABLE_TABLE_CELL_HEIGHT_BUFFER;
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
        itinerary = [[plan sortedItineraries] objectAtIndex:[indexPath row]];

        // Handle Uber itinerary use case first
        // Send to UberDetailViewController instead of RouteDetailsViewController
        if (itinerary.isUberItinerary) {
            ItineraryFromUber* uberItin = (ItineraryFromUber *) itinerary;
            if (!uberDetailsVC) {
                uberDetailsVC = [[UberDetailViewController alloc]
                                 initWithNibName:@"UberDetailViewController" bundle:nil];
            }
            
            // Make sure Uber controller is not already pushed...
            BOOL isAlreadyPushed = NO;
            for(UIViewController *controller in self.navigationController.viewControllers){
                if([controller isKindOfClass:[UberDetailViewController class]]){
                    isAlreadyPushed = YES;
                }
            }
            if(!isAlreadyPushed){
                [uberDetailsVC setUberItin:uberItin];
                [uberDetailsVC setPlan:plan];
                [[self navigationController] pushViewController:uberDetailsVC animated:YES];
            }
            
            return;
        }
        
        /*UITableViewCell *cell = [atableView cellForRowAtIndexPath:indexPath];
        UIView *viewCellBackground = [[UIView alloc] init];
        [viewCellBackground setBackgroundColor:[UIColor CELL_BACKGROUND_ROUTE_OPTION_VIEW]];
        cell.backgroundView = viewCellBackground;*/
        if (!routeDetailsVC) {
            routeDetailsVC = [[RouteDetailsViewController alloc] initWithNibName:@"RouteDetailsViewController" bundle:nil];
        }
        if(itinerary.isRealTimeItinerary){
            NIMLOG_PERF2(@"Realtime itinerary");
        }
        for(int i=0;i<[[itinerary sortedLegs] count];i++){
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:i];
            if([leg isScheduled]){
                NIMLOG_PERF2(@"legId->%@",leg.legId);
                NIMLOG_PERF2(@"routeId->%@, routeshortName->%@, fromStop->%@, toStop->%@, fromStopId->%@, toStopId->%@, tripId->%@, headSign->%@, legMode->%@, ScheduledTripId->%@",leg.routeId,leg.routeShortName,leg.from.name,leg.to.name,leg.from.stopId,leg.to.stopId,leg.realTripId,leg.headSign,leg.mode,leg.tripId);
            }
        }
        itinararyId =[itinerary itinId];
        
        logEvent(FLURRY_ROUTE_SELECTED,
                 FLURRY_SELECTED_ROW_NUMBER, [NSString stringWithFormat:@"%d", [indexPath row]],
                 FLURRY_SELECTED_DEPARTURE_TIME, [NSString stringWithFormat:@"%@", [itinerary startTimeOfFirstLeg]],
                 nil, nil, nil, nil);
        
        // DE-309 Fixed
        // Added Error Handling such that RouteDetailViewController is pushed only once even if user select the row multiple times.
        BOOL isAlreadyPushed = NO;
        for(UIViewController *controller in self.navigationController.viewControllers){
            if([controller isKindOfClass:[RouteDetailsViewController class]]){
                isAlreadyPushed = YES;
            }
        }
        if(!isAlreadyPushed){
            routeDetailsVC.count = remainingCount;
            [routeDetailsVC setItinerary:itinerary];
            [[self navigationController] pushViewController:routeDetailsVC animated:YES];
        }
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->didSelectRowAtIndexPath", @"", exception);
    }
}

- (void) backToRouteOptionsView {
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    [[self navigationController] popViewControllerAnimated:NO];
}

#pragma mark - View lifecycle

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    if([[[UIDevice currentDevice] systemVersion] intValue] >= 7){
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Accessibility Label For UI Automation.
    self.mainTable.accessibilityLabel =ROUTE_OPTIONS_TABLE_VIEW;
    
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:returnNavigationBarBackgroundImage() forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:returnNavigationBarBackgroundImage()] aboveSubview:self.navigationController.navigationBar];
    }
    btnGoToNimbler = [[UIButton alloc] initWithFrame:CGRectMake(0,0,65,34)];
    [btnGoToNimbler addTarget:self action:@selector(popOutToNimbler) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToNimbler setBackgroundImage:[UIImage imageNamed:@"img_nimblerNavigation.png"] forState:UIControlStateNormal];
    
    // Accessibility Label For UI Automation.
    btnGoToNimbler.accessibilityLabel =BACK_TO_NIMBLER_BUTTON;
    
    UIBarButtonItem *backTonimbler = [[UIBarButtonItem alloc] initWithCustomView:btnGoToNimbler];
    
    self.navigationItem.leftBarButtonItem = backTonimbler;
    
    [travelByLabel setFont:[UIFont fontWithName:@"Helvetica" size:13.0]];
    [travelByLabel setTextColor:[UIColor lightGrayColor]];
    travelByLabel.text = MODE_BUTTON_TRAVEL_BY_TEXT;
    
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
            id res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
            twitterViewController *twit = [[twitterViewController alloc] init];
            [twit setTwitterLiveData:res];
            [[self navigationController] pushViewController:twit animated:YES];
        }
        
    } @catch (NSException *exception) {
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
    @try {
        
        int xPos = 70;
        int yPos = 5;
        int btnHeight = EXCLUDE_BUTTON_HEIGHT;
        int width = EXCLUDE_BUTTON_WIDTH;
        
        // Remove previous buttonViews from previous routes, DE407 fix
        for (UIView *subview in [modeBtnView subviews]) {
            if ([subview isKindOfClass:[UIButton class]]) {
                [subview removeFromSuperview];
            }
        }
        
        // Update the height constraint for modeBtnView if needed
        for (NSLayoutConstraint *constraint in [modeBtnView constraints]) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                if (constraint.constant != height) {  // If not set to the right heigh
                    NSLayoutConstraint* newConstr = [NSLayoutConstraint constraintWithItem:modeBtnView
                                                                                 attribute:NSLayoutAttributeHeight
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:nil
                                                                                 attribute:0
                                                                                multiplier:1.0
                                                                                  constant:height];
                    [modeBtnView removeConstraint:constraint];
                    [modeBtnView addConstraint:newConstr];
                }
                break;
            }
        }
        BOOL transitMode = [[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_TRANSIT_MODE] boolValue];
        if(!transitMode){
            for(int i=0;i<[[plan excludeSettingsArray] count];i++){
                RouteExcludeSetting *routeExcludeSetting = [[plan excludeSettingsArray] objectAtIndex:i];
                UIButton *btnAgency = [UIButton buttonWithType:UIButtonTypeCustom];
                if(xPos+width > 300){
                    yPos = yPos + btnHeight + 5;
                    xPos = 5;
                }
                [btnAgency setFrame:CGRectMake(xPos,yPos,width, btnHeight)];
                xPos = xPos+width;
                [btnAgency setTitle:routeExcludeSetting.key forState:UIControlStateNormal];
                [btnAgency.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12.0]];
                if([routeExcludeSetting.key isEqualToString:returnBikeButtonTitle()] || [routeExcludeSetting.key isEqualToString:BIKE_SHARE]){
                    if([[RouteExcludeSettings latestUserSettings] settingForKey:routeExcludeSetting.key] == SETTING_EXCLUDE_ROUTE){
                        [btnAgency setBackgroundImage:[UIImage imageNamed:@"excludeUnSelected@2x.png"] forState:UIControlStateNormal];
                        [btnAgency setTitleColor:[UIColor LIGHT_GRAY_FONT_COLOR] forState:UIControlStateNormal];
                    }
                    else{
                        [btnAgency setBackgroundImage:[UIImage imageNamed:@"excludeSelected@2x.png"] forState:UIControlStateNormal];
                        [btnAgency setTitleColor:[UIColor NIMBLER_RED_FONT_COLOR] forState:UIControlStateNormal];
                    }
                }
                else{
                    [btnAgency setBackgroundImage:[UIImage imageNamed:@"excludeUnSelected@2x.png"] forState:UIControlStateNormal];
                    [btnAgency setTitleColor:[UIColor LIGHT_GRAY_FONT_COLOR] forState:UIControlStateNormal];
                }
                [btnAgency addTarget:self action:@selector(toggleExcludeButton:) forControlEvents:UIControlEventTouchUpInside];
                [modeBtnView addSubview:btnAgency];
            }
        }
        else{
            for(int i=0;i<[[plan excludeSettingsArray] count];i++){
                RouteExcludeSetting *routeExcludeSetting = [[plan excludeSettingsArray] objectAtIndex:i];
                UIButton *btnAgency = [UIButton buttonWithType:UIButtonTypeCustom];
                if(xPos+width > 300){
                    yPos = yPos + btnHeight + 5;
                    xPos = 5;
                }
                [btnAgency setFrame:CGRectMake(xPos,yPos,width, btnHeight)];
                xPos = xPos+width;
                [btnAgency setTitle:routeExcludeSetting.key forState:UIControlStateNormal];
                [btnAgency.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12.0]];
                if([[RouteExcludeSettings latestUserSettings] settingForKey:routeExcludeSetting.key] == SETTING_EXCLUDE_ROUTE){
                    [btnAgency setBackgroundImage:[UIImage imageNamed:@"excludeUnSelected@2x.png"] forState:UIControlStateNormal];
                    [btnAgency setTitleColor:[UIColor LIGHT_GRAY_FONT_COLOR] forState:UIControlStateNormal];
                }
                else{
                    [btnAgency setBackgroundImage:[UIImage imageNamed:@"excludeSelected@2x.png"] forState:UIControlStateNormal];
                    [btnAgency setTitleColor:[UIColor NIMBLER_RED_FONT_COLOR] forState:UIControlStateNormal];
                }
                [btnAgency addTarget:self action:@selector(toggleExcludeButton:) forControlEvents:UIControlEventTouchUpInside];
                [modeBtnView addSubview:btnAgency];
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->createViewWithButtons", @"", exception);
    }
}

- (int) calculateTotalHeightOfButtonView{
    int tempButtonCounts;
    if([[plan excludeSettingsArray] count] > 3)
        tempButtonCounts = [[plan excludeSettingsArray] count] - 3;
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
    return totalRows * 38 + buffer;
}
- (bool)waitForNonNullValueOfBlock:(BOOL(^)(void))block
{
    int i;
    for (i=0; i<50; i++) {
        if (block()) {
            return true;
        } else {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        }
    }
    return false;
}


// call the requestRealTimeDataFromServer from RealtimeManager class with plan.
- (void) requestServerForRealTime{
    // TODO:- Comment This both line to run automated test case
#if AUTOMATED_TESTING_SKIP_NCAPPDELEGATE
    return;
#endif
#if SKIP_REAL_TIME_UPDATES
    return;
#endif
    BOOL isRouteOptionView = [nc_AppDelegate sharedInstance].isRouteOptionView;
    BOOL isRouteDetailView = [nc_AppDelegate sharedInstance].isRouteDetailView;
    if(isRouteDetailView || isRouteOptionView){
        RealTimeManager *realtimeManager = [RealTimeManager realTimeManager];
        [realtimeManager requestRealTimeDataFromServerUsingPlan:plan PlanRequestParameters:planRequestParameters];
    }
}

- (IBAction)feedBackClicked:(id)sender{
    FeedBackForm *feedBackForm;
    feedBackForm = [[FeedBackForm alloc] initWithNibName:@"FeedBackFormPopUp" bundle:nil];
    feedBackForm.isViewPresented = true;
    [self presentViewController:feedBackForm animated:YES completion:nil];
}
@end