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
#import <RestKit/RKJSONParserJSONKit.h>

#define IDENTIFIER_CELL         @"UIRouteOptionsViewCell"

@interface RouteOptionsViewController()
{
    // Variables for internal use
    
    RouteDetailsViewController* routeDetailsVC;
    RouteMapViewController* routeMapVC;
}

@end

@implementation RouteOptionsViewController

@synthesize mainTable;
@synthesize plan;
@synthesize isReloadRealData;
@synthesize liveData,btnGoToNimbler;
@synthesize btnMap;

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
      
        // nav map button [CG]
        btnMap = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(tapMapButton)];
        self.navigationItem.rightBarButtonItem = btnMap;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    logEvent(FLURRY_ROUTE_OPTIONS_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
    
    // Enforce height of main table
    mainTable.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"img_line.png"]];
    CGRect rect0 = [mainTable frame];
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
        rect0.size.height = ROUTE_OPTIONS_TABLE_HEIGHT_IPHONE5;
        rect0.origin.y = 0;
    }
    else{
        rect0.size.height = ROUTE_OPTIONS_TABLE_HEIGHT;
        rect0.origin.y = 0;
    }
    [mainTable setFrame:rect0];
    [mainTable reloadData];
    [self setFBParameterForPlan];
}

// Call-back from PlanStore requestPlanFromLocation:... method when it has a plan
-(void)newPlanAvailable:(Plan *)newPlan status:(PlanRequestStatus)status
{
    if (status == PLAN_STATUS_OK) {
        [mainTable reloadData];
    }
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)popOutToNimbler{
    NSLog(@"Begin popOutToNimbler");    
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    NSLog(@"Will popViewControllerAnimated");
    [[self navigationController] popViewControllerAnimated:NO];
}

// push the map view [CG]
- (void)tapMapButton
{
  NSLog(@"** tapMapButton");
  
  if (!routeMapVC) {
    routeMapVC = [[RouteMapViewController alloc] initWithNibName:@"RouteMapViewController" bundle:nil];
  }

  routeMapVC.plan = self.plan;
  
  //itinerary = [plan.sortedItineraries objectAtIndex:[indexPath row]];
  //itinararyId =[itinerary itinId];
  
  //[routeDetailsVC setItinerary:itinerary];
  if([[[UIDevice currentDevice] systemVersion] intValue] < 5.0){
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromRight];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    [[self navigationController] pushViewController:routeMapVC animated:NO];
  }
  else{
    [[self navigationController] pushViewController:routeMapVC animated:YES];
  }

  
}



#pragma mark - UITableViewDelegate methods
// Table view management methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[plan sortedItineraries] count];
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
        NSString* durationStr = durationString(1000.0 * [[itin endTimeOfLastLeg]
                                                   timeIntervalSinceDate:[itin startTimeOfFirstLeg]]);
        NSString *titleText = [NSString stringWithFormat:@"%@ - %@ (%@)",
                               superShortTimeStringForDate([itin startTimeOfFirstLeg]),
                               superShortTimeStringForDate([itin endTimeOfLastLeg]),
                               durationStr];
        [[cell textLabel] setText:titleText];
        UIView *viewCellBackground = [[UIView alloc] init];
        [viewCellBackground setBackgroundColor:[UIColor CELL_BACKGROUND_ROUTE_OPTION_VIEW]];
        cell.backgroundView = viewCellBackground;
        
        // notify with TEXT for LEG timimg
        if (isReloadRealData) {
            if([itin itinArrivalFlag] >= 0) {
                if([itin.itinArrivalFlag intValue] == ON_TIME) {
                    titleText = [NSString stringWithFormat:@"%@ %@",titleText,@"On Time"];
                }  else if([itin.itinArrivalFlag intValue] == DELAYED) {
                    titleText = [NSString stringWithFormat:@"%@ %@",titleText,@"Delayed"];
                } else if([itin.itinArrivalFlag intValue] == EARLY) {
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

        [[cell detailTextLabel] setText:[itin itinerarySummaryStringForWidth:ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH
                                                                        Font:cell.detailTextLabel.font]];
            
        [[cell detailTextLabel] setNumberOfLines:0];  // Allow for multi-lines
        [cell.detailTextLabel setTextColor:[itin detailTextLabelColor]];
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->cellForRowAtIndexPath", @"", exception);
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
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
        
        itinerary = [plan.sortedItineraries objectAtIndex:[indexPath row]];
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

#pragma mark realTime data updates
-(void)setLiveFeed:(id)liveFees
{
    @try {
        liveData = liveFees;
        //        NSString *itinId = [(NSDictionary*)liveFeed objectForKey:@"itineraryId"];
        NSNumber *respCode = [(NSDictionary*)liveData objectForKey:@"errCode"];
        
        if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
            //It means there are live feeds in response
            NSArray *itineraryLiveFees = [(NSDictionary*)liveData objectForKey:@"itinLiveFeeds"]; 
            if ([itineraryLiveFees count] > 0) {
                for (int j=0; j<itineraryLiveFees.count; j++) {                    
                    id key = [itineraryLiveFees objectAtIndex:j];                
                    NSString *itinTimeFalg = [(NSDictionary*)key objectForKey:@"arrivalTimeFlag"];
                    NSString *ititId = [(NSDictionary*)key objectForKey:@"itineraryId"];
                    NSArray *legLiveFees = [(NSDictionary*)key objectForKey:@"legLiveFeeds"]; 
                    if ([legLiveFees count] > 0) {
                        for (int i=0; i<legLiveFees.count; i++) {                
                            NSString *arrivalTime = [[legLiveFees objectAtIndex:i] valueForKey:@"departureTime"];
                            NSString *arrivalTimeFlag = [[legLiveFees objectAtIndex:i] valueForKey:@"arrivalTimeFlag"];
                            NSString *timeDiff = [[legLiveFees objectAtIndex:i] valueForKey:@"timeDiffInMins"];
                            NSString *legId = [[[legLiveFees objectAtIndex:i] valueForKey:@"leg"] valueForKey:@"id"];                 
                            
                            [self setRealtimeData:legId arrivalTime:arrivalTime arrivalFlag:arrivalTimeFlag itineraryId:ititId itineraryArrivalFlag:itinTimeFalg legDiffMins:timeDiff];
                        }      
                    }
                }
                isReloadRealData = true;
                [mainTable reloadData]; 
                [routeDetailsVC ReloadLegWithNewData];
            }            
        } else {
            //thereare no live feeds available. 
            isReloadRealData = FALSE;
            NIMLOG_PERF1(@"thereare no live feeds available for current route");
        }
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->liveFees", @"", exception);
    }
}

- (void) setRealtimeData:(NSString *)legId arrivalTime:(NSString *)arrivalTime arrivalFlag:(NSString *)arrivalFlag itineraryId:(NSString *)ititId itineraryArrivalFlag:(NSString *)itinArrivalflag legDiffMins:(NSString *)timeDiff
{
    @try {
        NSArray *ities = [plan sortedItineraries];
        for (int i=0; i <ities.count ; i++) {
            if ([[[ities objectAtIndex:i] itinId] isEqualToString:ititId]) {
                [[ities objectAtIndex:i] setItinArrivalFlag:itinArrivalflag];
            }
            Itinerary *it = [ities objectAtIndex:i];
            NSArray *legs =  [it sortedLegs];
            for (int i=0;i<legs.count;i++) {
                if ([[[legs objectAtIndex:i] legId] isEqualToString:legId]) {
                    [[legs objectAtIndex:i] setArrivalFlag:arrivalFlag];
                    [[legs objectAtIndex:i] setArrivalTime:arrivalTime];
                    [[legs objectAtIndex:i] setTimeDiffInMins:timeDiff];
                }
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"RouteOptionsViewController->setRealtimeData", @"", exception);
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
@end