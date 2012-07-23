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

#define CELL_HEIGHT             60.0

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
@synthesize liveData;

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
    
    // Enforce height of main table
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
    [tableView dequeueReusableCellWithIdentifier:@"UIRouteOptionsViewCell"];
    @try {
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                          reuseIdentifier:@"UIRouteOptionsViewCell"];
            [cell.imageView setImage:nil];
        }
        // Get the requested itinerary
        Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
        if (isReloadRealData) {
            if([itin itinArrivalFlag] >= 0) {
                UIImage *imgForArrivalTime = [UIImage alloc];
                cell.frame = CGRectMake(100, 2, 20, 20);
                
                if([itin.itinArrivalFlag intValue] == ON_TIME) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_ontime.png"] ;
                }  else if([itin.itinArrivalFlag intValue] == DELAYED) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_delay.png"] ;
                } else if([itin.itinArrivalFlag intValue] == EARLY) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_early.png"] ;
                } else if([itin.itinArrivalFlag intValue] == EARLIER) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_earlier.ong"] ;
                } else if ([itin.itinArrivalFlag intValue] == ITINERARY_TIME_SLIPPAGE ) {
                    imgForArrivalTime = [UIImage imageNamed:@"itin_slipage.png"] ;
                }
                [cell.imageView setImage:imgForArrivalTime];
            }
        } else {
            [cell.imageView setImage:nil];
        }
        /*
         for feedback planId
         */
        
        // Set title
        [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:LARGER_THEN_MEDIUM_FONT_SIZE]];
        NSString *titleText = [NSString stringWithFormat:@"%@ - %@ (%@)", 
                               [timeFormatter stringFromDate:[itin startTime]],
                               [timeFormatter stringFromDate:[itin endTime]],
                               durationString([[itin duration] floatValue])];
        [[cell textLabel] setText:titleText];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.textColor = [UIColor colorWithRed:252.0/256.0 green:103.0/256.0 blue:88.0/256.0 alpha:1.0];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:98.0/256.0 green:96.0/256.0 blue:96.0/256.0 alpha:1.0];
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
        UIImage *unselect = [UIImage imageNamed:@"img_unSelect.png"];
        cell.AccessoryView = [[UIImageView alloc] initWithImage:unselect];

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
        if (!routeDetailsVC) {
            routeDetailsVC = [[RouteDetailsViewController alloc] initWithNibName:@"RouteDetailsViewController" bundle:nil];
        }
        itinararyId =[[[plan sortedItineraries] objectAtIndex:[indexPath row]] itinId];
        itinerary = [plan.sortedItineraries objectAtIndex:[indexPath row]];
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
    [self hideUnUsedTableViewCell];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [UIColor colorWithRed:98.0/256.0 green:96.0/256.0 blue:96.0/256.0 alpha:1.0], UITextAttributeTextColor,
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
            NSLog(@"thereare no live feeds available for current route");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at live itinerary response: %@",exception);
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
    NSLog(@"plan....");
    [nc_AppDelegate sharedInstance].FBSource = [NSNumber numberWithInt:FB_SOURCE_PLAN];
    [nc_AppDelegate sharedInstance].FBDate = nil;
    [nc_AppDelegate sharedInstance].FBToAdd = nil;
    [nc_AppDelegate sharedInstance].FBSFromAdd = nil;
    [nc_AppDelegate sharedInstance].FBUniqueId = [plan planId];
}
@end