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

@implementation RouteOptionsViewController

@synthesize plan;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        [[self navigationItem] setTitle:@"Itineraries"];
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];

    
       feedback = [[UIBarButtonItem alloc] initWithTitle:@"F" style:UIBarButtonItemStylePlain target:self action:@selector(feedBackSubmit)];

        self.navigationItem.rightBarButtonItem = feedback;
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[self tableView] reloadData];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

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


#pragma mark - UITableViewDelegate methods

// If selected, show the RouteDetailsViewController
- (void) tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        
        RouteDetailsViewController *routeDetailsVC = [[RouteDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
        //    [self sendRequestForTimingDelay];
        [routeDetailsVC setItinerary:[[plan sortedItineraries] objectAtIndex:[indexPath row]]];
        [[self navigationController] pushViewController:routeDetailsVC animated:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"exceptions %@", exception);
    }
    
}

#pragma mark - View lifecycle

/*
 Implement loadView to create a view hierarchy programmatically, without using a nib.
*/
 - (void)loadView
{
    [super loadView];
    
}


-(void)feedBackSubmit
{
    
     FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:FB_SOURCE_PLAN uniqueId:[plan planId] date:nil fromAddress:nil toAddress:nil];
    
    FeedBackForm *feedbackFormVc = [[FeedBackForm alloc] initWithFeedBack:@"FeedBackForm" fbParam:fbParam bundle:nil];
    
    [[self navigationController] pushViewController:feedbackFormVc animated:YES]; 
}

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

-(void)sendRequestForTimingDelay
{
//    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//    NSString *ititId =    [prefs objectForKey:@"itinararyid"];    

    
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    [RKClient setSharedClient:client];
    
    
    NSDictionary *dict = [NSDictionary dictionaryWithKeysAndObjects:
                          @"itineraryid",@"4fd6d0def2f3ae0f17fd702a" ,
                          nil];
    NSString *req = [@"livefeeds/itinerary" appendQueryParams:dict];
    
    [[RKClient sharedClient]  get:req  delegate:self];
    
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    
    NSLog(@"response %@", [response bodyAsString]);
    id res = (id)[response bodyAsJSON];
    
    
    NSLog(@"got the response ");
    if([res isKindOfClass:[NSDictionary class]]){
       
//        if([[(NSDictionary*)res objectForKey:@"itinaryid"] isEqualToString:ititId]){
             NSLog(@"yes dictionary.. %@", [(NSDictionary*)res objectForKey:@"itineraryId"]);
            NSLog(@"yes dictionary.. %@", [(NSDictionary*)res objectForKey:@"errCode"]);
      
            NSArray *legLiveFees = [(NSDictionary*)res objectForKey:@"legLiveFeeds"];
            NSLog(@"led live feeds %@", legLiveFees);

            [[legLiveFees objectAtIndex:0] valueForKey:@"leg"];
            [[[legLiveFees objectAtIndex:0] valueForKey:@"leg"] valueForKey:@"id"];
            NSLog(@" id %@", [[[legLiveFees objectAtIndex:0] valueForKey:@"leg"] valueForKey:@"id"]);
        NSLog(@"testing .. %@", [[legLiveFees objectAtIndex:0] valueForKey:@"leg"]);
//        }
    } else {
        
    }
}


-(void)sendRequestForFeedback:(RKParams*)para
{
    RKParams *param = [RKParams alloc];
    param = para;
    
    
}
#pragma Rest Request for TPServer

@end
