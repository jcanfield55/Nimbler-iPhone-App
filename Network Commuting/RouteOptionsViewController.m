//
//  RouteOptionsViewController.m
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RouteOptionsViewController.h"
#import "Leg.h"
#import "UtilityFunctions.h"
#import <math.h>
#import "TwitterSearch.h"
#import "FeedBackForm.h"
#import "LegMapViewController.h"
#import "twitterViewController.h"
#import "nc_AppDelegate.h"
#import <RestKit/RKJSONParserJSONKit.h>

#if FLURRY_ENABLED
#include "Flurry.h"
#endif

#define CELL_HEIGHT             60.0
#define IDENTIFIER_CELL         @"UIRouteOptionsViewCell"

@interface RouteOptionsViewController()
{
    // Variables for internal use
    
    TwitterSearch* twitterSearchVC;
    RouteDetailsViewController* routeDetailsVC;
}

@end

@implementation RouteOptionsViewController

@synthesize mainTable;
@synthesize feedbackButton;
@synthesize advisoryButton;
@synthesize plan;
@synthesize isReloadRealData;
@synthesize liveData,btnGoToNimbler;

Itinerary * itinerary;
NSString *itinararyId;

int const ROUTE_OPTIONS_TABLE_HEIGHT = 352;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"Itineraries"];
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#if FLURRY_ENABLED
    [Flurry logEvent:FLURRY_ROUTE_OPTIONS_APPEAR];
#endif
    
    // Enforce height of main table
    mainTable.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"img_line.png"]];
    CGRect rect0 = [mainTable frame];
    rect0.size.height = ROUTE_OPTIONS_TABLE_HEIGHT;
    [mainTable setFrame:rect0];
    [mainTable reloadData];
    [self setFBParameterForPlan];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)popOutToNimbler
{
    [self.navigationController popViewControllerAnimated:TRUE];
}
#pragma mark - UITableViewDelegate methods
// Table view management methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[plan itineraries] count];
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
         cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.numberOfLines = 2;
        // Get the requested itinerary
        Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
        
        // Set title
        [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]];
        NSString *titleText = [NSString stringWithFormat:@"%@ - %@ (%@)", 
                               [timeFormatter stringFromDate:[itin startTime]],
                               [timeFormatter stringFromDate:[itin endTime]],
                               durationString([[itin duration] floatValue])];
        [[cell textLabel] setText:titleText];
        
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
                     titleText = [NSString stringWithFormat:@"%@ %@",titleText,@"Time Slippage"];
                }
                 [[cell textLabel] setText:titleText];
            }
        }         
        cell.textLabel.textColor = [UIColor colorWithRed:252.0/255.0 green:103.0/255.0 blue:88.0/255.0 alpha:1.0];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0];
        // Set sub-title (show each leg's mode and route if available)
        NSMutableString *subTitle = [NSMutableString stringWithCapacity:30];
        NSArray *sortedLegs = [itin sortedLegs];
        for (int i = 0; i < [sortedLegs count]; i++) {
            Leg *leg = [sortedLegs objectAtIndex:i];
            if ([leg mode] && [[leg mode] length] > 0) {
                if (i > 0) {
                    [subTitle appendString:@" -> "];
                }
                [subTitle appendString:[[leg mode] capitalizedString]];
                if ([leg route] && [[leg route] length] > 0) {
                    [subTitle appendString:@" "];
                    [subTitle appendString:[leg route]];
                }
            }
        }
        [[cell detailTextLabel] setText:subTitle];
        cell.contentView.backgroundColor = [UIColor colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:0.04];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at load table: %@", exception);
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    return CELL_HEIGHT;  
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
        cell.contentView.backgroundColor = [UIColor colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:0.3];
        if (!routeDetailsVC) {
            routeDetailsVC = [[RouteDetailsViewController alloc] initWithNibName:@"RouteDetailsViewController" bundle:nil];
        }
        
        itinerary = [plan.sortedItineraries objectAtIndex:[indexPath row]];
        itinararyId =[itinerary itinId];

#if FLURRY_ENABLED         
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:                                 FLURRY_SELECTED_ROW_NUMBER, [NSString stringWithFormat:@"%d", [indexPath row]],                                    FLURRY_SELECTED_DEPARTURE_TIME,[NSString stringWithFormat:@"%@", [itinerary startTime]], nil];                                  [Flurry logEvent:FLURRY_ROUTE_SELECTED withParameters:params];  
#endif
        
        [routeDetailsVC setItinerary:itinerary];
        [[self navigationController] pushViewController:routeDetailsVC animated:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at select itinerary: %@", exception);
    }
}

#pragma mark - Button Event handling

- (IBAction)advisoryButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        [[RKClient sharedClient]  get:@"advisories/all" delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@" Exception at press advisory button from RouteOptionsViewController : %@", exception);
    } 
}

-(void)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
        FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:[NSNumber numberWithInt:FB_SOURCE_PLAN] uniqueId:[plan planId] date:nil fromAddress:nil toAddress:nil];
        FeedBackForm *feedbackFormVc = [[FeedBackForm alloc] initWithFeedBack:@"FeedBackForm" fbParam:fbParam bundle:nil];
        [[self navigationController] pushViewController:feedbackFormVc animated:YES]; 
        
        [nc_AppDelegate sharedInstance].FBSource = [NSNumber numberWithInt:FB_SOURCE_PLAN];
        [nc_AppDelegate sharedInstance].FBDate = nil;
        [nc_AppDelegate sharedInstance].FBToAdd = nil;
        [nc_AppDelegate sharedInstance].FBSFromAdd = nil;
        [nc_AppDelegate sharedInstance].FBUniqueId = [plan planId];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception at press feedback button from RouteOptionsViewController : %@", exception);
    }
}


#pragma mark - View lifecycle

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    btnGoToNimbler = [[UIButton alloc] initWithFrame:CGRectMake(0,0,65,34)];
    [btnGoToNimbler addTarget:self action:@selector(popOutToNimbler) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToNimbler setBackgroundImage:[UIImage imageNamed:@"img_nimblerNavigationSelect.png"] forState:UIControlStateNormal];
    
    UIBarButtonItem *backTonimbler = [[UIBarButtonItem alloc] initWithCustomView:btnGoToNimbler];
    self.navigationItem.leftBarButtonItem = backTonimbler;
    
    [self hideUnUsedTableViewCell];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0], UITextAttributeTextColor,
                                                                     nil]];
    NSLog(@"RouteOptions loaded");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"RouteOptions did appear");
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
            NSLog(@"thereare no live feeds available for current route");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at live feed data response: %@",exception);
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
        NSLog(@"exceptions at set time: %@", exception);
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
        NSLog( @"Exception while getting unique IDs from TP Server response: %@", exception);
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