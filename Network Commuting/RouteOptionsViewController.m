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
#import <RestKit/RKJSONParserJSONKit.h>

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
@synthesize tweeterCount;

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
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:@"UIRouteOptionsViewCell"];
    }
    // Get the requested itinerary
    Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
    if (isReloadRealData) {
        if([itin itinArrivalFlag] > 0) {
            UIImage *imgForArrivalTime = [UIImage alloc];
            cell.frame = CGRectMake(100, 2, 20, 20);
            if([itin.itinArrivalFlag intValue] == [ON_TIME intValue]) {
                imgForArrivalTime = [UIImage imageNamed:@"img_ontime.png"] ;
            }  else if([itin.itinArrivalFlag intValue] == [DELAYED intValue]) {
                imgForArrivalTime = [UIImage imageNamed:@"img_delay.png"] ;
            } else if([itin.itinArrivalFlag intValue] == [EARLY intValue]) {
                imgForArrivalTime = [UIImage imageNamed:@"img_early.png"] ;
            } else if([itin.itinArrivalFlag intValue] == [EARLIER intValue]) {
                imgForArrivalTime = [UIImage imageNamed:@"img_earlier"] ;
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
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
    NSString *titleText = [NSString stringWithFormat:@"%@ - %@ (%@)", 
                          [timeFormatter stringFromDate:[itin startTime]],
                          [timeFormatter stringFromDate:[itin endTime]],
                           durationString([[itin duration] floatValue])];
    [[cell textLabel] setText:titleText];
    
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
    
    return cell;
}


// If selected, show the RouteDetailsViewController
- (void) tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        
        if (!routeDetailsVC) {
            routeDetailsVC = [[RouteDetailsViewController alloc] initWithNibName:@"RouteDetailsViewController" bundle:nil];
        }
        itinararyId =[[[plan sortedItineraries] objectAtIndex:[indexPath row]] itinId];
//        [self sendRequestForTimingDelay];
        itinerary = [plan.sortedItineraries objectAtIndex:[indexPath row]];
        [routeDetailsVC setItinerary:itinerary];
        [[self navigationController] pushViewController:routeDetailsVC animated:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"exceptions %@", exception);
    }
}

#pragma mark - Button Event handling

- (IBAction)advisoryButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
//        if (!twitterSearchVC) {
//            twitterSearchVC = [[TwitterSearch alloc] initWithNibName:@"TwitterSearch" bundle:nil];
//        }
//        [[self navigationController] pushViewController:twitterSearchVC animated:YES];
//        [twitterSearchVC loadRequest:CALTRAIN_TWITTER_URL];
        
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        [[RKClient sharedClient]  get:@"advisories/all" delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@" twitter print : %@", exception);
    } 
}

-(void)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:FB_SOURCE_PLAN uniqueId:[plan planId] date:nil fromAddress:nil toAddress:nil];
    FeedBackForm *feedbackFormVc = [[FeedBackForm alloc] initWithFeedBack:@"FeedBackForm" fbParam:fbParam bundle:nil];
    [[self navigationController] pushViewController:feedbackFormVc animated:YES]; 
}



#pragma mark - View lifecycle

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
*/
 - (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"RouteOptions loaded");
    
        
}

- (void)viewDidAppear:(BOOL)animated
{
       
    [super viewDidAppear:animated];
    NSLog(@"RouteOptions did appear");
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    int tweetConut = [[prefs objectForKey:@"tweetCount"] intValue];
    [tweeterCount removeFromSuperview];

    if ([prefs objectForKey:@"isUrgent"]) {
         CustomBadge *c = [[CustomBadge alloc] initWithString:[NSString stringWithFormat:@"%d!",tweetConut] withStringColor:[UIColor whiteColor] withInsetColor:[UIColor blueColor] withBadgeFrame:YES withBadgeFrameColor:[UIColor whiteColor]];
        [c setFrame:CGRectMake(50, 360, c.frame.size.width, c.frame.size.height)];
        [self.view addSubview:c];
    } else {
        tweeterCount = [[CustomBadge alloc] init];
        tweeterCount = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d!",tweetConut]];
        [tweeterCount setFrame:CGRectMake(60, 365, tweeterCount.frame.size.width, tweeterCount.frame.size.height)];        
        if (tweetConut == 0) {
            [tweeterCount setHidden:YES];
        } else {
            [self.view addSubview:tweeterCount];
            [tweeterCount setHidden:NO];
        }
    }
    
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


-(void)sendRequestForFeedback:(RKParams*)para
{
    RKParams *param = [RKParams alloc];
    param = para;
}
#pragma mark realTime data updates

-(void)setLiveFeed:(id)liveFees
{
    @try {
        liveData = liveFees;
        //        NSString *itinId = [(NSDictionary*)liveFeed objectForKey:@"itineraryId"];
        NSNumber *respCode = [(NSDictionary*)liveData objectForKey:@"errCode"];
        
        if ([respCode intValue]== 105) {
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
                            NSString *legId = [[[legLiveFees objectAtIndex:i] valueForKey:@"leg"] valueForKey:@"id"];                 
                        
                            [self setRealtimeData:legId arrivalTime:arrivalTime arrivalFlag:arrivalTimeFlag itineraryId:ititId itineraryArrivalFlag:itinTimeFalg];
                        }      
                    }
                }
                isReloadRealData = true;
                [mainTable reloadData]; 
                LegMapViewController *legMap = [[LegMapViewController alloc] init];
                [legMap ReloadLegMapWithNewData];
                [routeDetailsVC ReloadLegWithNewData];
                
            }            
        } else {
            //thereare no live feeds available.            
            NSLog(@"thereare no live feeds available for current route");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at live itinerary respoce: %@",exception);
    }
}

- (void) setRealtimeData:(NSString *)legId arrivalTime:(NSString *)arrivalTime arrivalFlag:(NSString *)arrivalFlag itineraryId:(NSString *)ititId itineraryArrivalFlag:(NSString *)itinArrivalflag
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
@end
