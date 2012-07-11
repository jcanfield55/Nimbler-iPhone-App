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
#import "RootMap.h"
#import "TwitterSearch.h"
#import "FeedBackForm.h"
#import "FeedBackReqParam.h"
#import "twitterViewController.h"
#import <RestKit/RKJSONParserJSONKit.h>

@implementation RouteDetailsViewController

@synthesize itinerary;
@synthesize mainTable;
@synthesize feedbackButton;
@synthesize advisoryButton;
@synthesize twitterCount;

int const ROUTE_DETAILS_TABLE_HEIGHT = 370;

#pragma mark lifecycle view
-(void)loadView
{
    [super loadView];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    @try {
        if (self) {
            [[self navigationItem] setTitle:@"Route"];
            UIImage *mapTmg = [UIImage imageNamed:@"map.png"];
            UIButton *mapBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            mapBtn.bounds = CGRectMake(0, 0, mapTmg.size.width, mapTmg.size.height);
            [mapBtn setImage:mapTmg forState:UIControlStateNormal];
            [mapBtn addTarget:self action:@selector(mapOverView) forControlEvents:UIControlEventTouchDown];
            map = [[UIBarButtonItem alloc] initWithCustomView:mapBtn]; 
            self.navigationItem.rightBarButtonItem = map;
            timeFormatter = [[NSDateFormatter alloc] init];
            [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at init RouteDetail: %@", exception);
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    @try {
        // Enforce height of main table
        CGRect rect0 = [mainTable frame];
        rect0.size.height = ROUTE_DETAILS_TABLE_HEIGHT;
        [mainTable setFrame:rect0];
        [mainTable reloadData];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        BOOL isUrgent = [[prefs objectForKey:@"isUrgent"] boolValue];
        int tweetConut = [[prefs objectForKey:@"tweetCount"] intValue];
        [twitterCount removeFromSuperview];
        if (isUrgent) {
            twitterCount = [[CustomBadge alloc] initWithString:[NSString stringWithFormat:@"%d!",tweetConut] withStringColor:[UIColor whiteColor] withInsetColor:[UIColor blueColor] withBadgeFrame:YES withBadgeFrameColor:[UIColor whiteColor]];
            [twitterCount setFrame:CGRectMake(50, 360, twitterCount.frame.size.width, twitterCount.frame.size.height)];
            if (tweetConut == 0) {
                [twitterCount setHidden:YES];
            } else {
                [self.view addSubview:twitterCount];
                [twitterCount setHidden:NO];
            }
        } else {
            twitterCount = [[CustomBadge alloc] init];
            twitterCount = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d",tweetConut]];
            [twitterCount setFrame:CGRectMake(60, 365, twitterCount.frame.size.width, twitterCount.frame.size.height)];        
            if (tweetConut == 0) {
                [twitterCount setHidden:YES];
            } else {
                [self.view addSubview:twitterCount];
                [twitterCount setHidden:NO];
            }
        } 
    }
    @catch (NSException *exception) {
        NSLog(@"exception at viewWillAppear RouteDetail: %@", exception);
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
        if ([[itinerary legs] count] > 0) {
            return [[itinerary legs] count]+2;  // # of legs plus start & end point
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
        }
        [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
        [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:14.0]];
        
        NSString *titleText;
        NSString *subTitle;
        if ([indexPath row] == 0) { // if first row, put in start point
            titleText = [NSString stringWithFormat:@"Start at %@", [[itinerary from] name]];
            [cell.imageView setImage:nil];
        }
        else if ([indexPath row] == [[itinerary sortedLegs] count] + 1) { // if last row, put in end point
            titleText = [NSString stringWithFormat:@"End at %@", [[itinerary to] name]];
            [cell.imageView setImage:nil];
        }
        else {  // otherwise, it is one of the legs
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:([indexPath row]-1)];
            
            titleText = [leg directionsTitleText];
            subTitle = [leg directionsDetailText];
            
            NSLog(@"leg arrival time: %@, leg time: %@", [leg arrivalFlag], [leg arrivalTime]);
            if([leg arrivalTime] > 0) {
                UIImage *imgForArrivalTime = [UIImage alloc];
                if([leg.arrivalFlag intValue] == [ON_TIME intValue]) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_ontime.png"] ;
                }  else if([leg.arrivalFlag intValue] == [DELAYED intValue]) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_delay.png"] ;
                } else if([leg.arrivalFlag intValue] == [EARLY intValue]) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_early.png"] ;
                } else if([leg.arrivalFlag intValue] == [EARLIER intValue]) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_earlier.png"] ;
                } 
                [cell.imageView setImage:imgForArrivalTime];
            }
            else {
                [cell.imageView setImage:nil];
            }
        }
        [[cell textLabel] setText:titleText];
        [[cell detailTextLabel] setLineBreakMode:UILineBreakModeWordWrap];
        [[cell detailTextLabel] setNumberOfLines:0];
        [[cell detailTextLabel] setText:subTitle];
        
        if (subTitle && [subTitle length] > 40) {
            [[cell detailTextLabel] sizeToFit];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception while reload RouteDetailView: %@", exception);
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    @try {
        NSString   *titleText,*patchString;
        CGSize size;
        if ([indexPath row] == 0) { // if first row, put in start point
            titleText = [NSString stringWithFormat:@"Start at %@", [[itinerary from] name]];
            size = [titleText 
                    sizeWithFont:[UIFont systemFontOfSize:14] 
                    constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
        }
        else if ([indexPath row] == [[itinerary sortedLegs] count] + 1) { // if last row, put in end point
            titleText = [NSString stringWithFormat:@"End at %@", [[itinerary to] name]];
            size = [titleText 
                    sizeWithFont:[UIFont systemFontOfSize:14] 
                    constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
        }
        else {    
            Leg *leg = [[itinerary sortedLegs] objectAtIndex:([indexPath row]-1)];
            titleText= [leg directionsDetailText];
            
            // DE:48  Wrapping issue while directionsTitleText & directionsDetailText lenght is small.
            
            if ([[leg directionsTitleText] length] < 20) {
                patchString  = [[leg directionsTitleText] stringByAppendingString:@"adding Patch string for UI" ];
                size = [[titleText stringByAppendingString:patchString] 
                        sizeWithFont:[UIFont systemFontOfSize:14] 
                        constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
            } else {
                size = [[titleText stringByAppendingString:[leg directionsTitleText]] 
                        sizeWithFont:[UIFont systemFontOfSize:14] 
                        constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
            }
        }
        CGFloat height = size.height + 7;
        if (height < 44.0) { // Set a minumum row height
            height = 44.0;
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
    // Initialize the LegMapView Controller
    @try {
        LegMapViewController *legMapVC = [[LegMapViewController alloc] initWithNibName:nil bundle:nil];
        // Initialize the leg VC with the full itinerary and the particular leg object chosen
        [legMapVC setItinerary:itinerary itineraryNumber:[indexPath row]];
        [[self navigationController] pushViewController:legMapVC animated:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at navigating into LegMapView: %@", exception);
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


- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event;
{
    @try {
        FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:FB_SOURCE_ITINERARY uniqueId:[itinerary itinId] date:nil fromAddress:nil toAddress:nil]; 
        FeedBackForm *feedbackvc = [[FeedBackForm alloc] initWithFeedBack:@"FeedBackForm" fbParam:fbParam bundle:nil];
        [[self navigationController] pushViewController:feedbackvc animated:YES];
    }
    @catch (NSException *exception) {
         NSLog(@"Exception at feedback navigation: %@", exception);
    }
}


- (void)mapOverView
{
    @try {
        RootMap *rootMap = [[RootMap alloc] initWithNibName:nil bundle:nil];
        [rootMap setItinerarys:itinerary itineraryNumber:2];
        [[self navigationController] pushViewController:rootMap animated:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception at mapOverview: %@", exception);
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
@end