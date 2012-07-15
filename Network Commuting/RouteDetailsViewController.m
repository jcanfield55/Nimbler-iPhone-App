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
#import "ToFromViewController.h"

@implementation RouteDetailsViewController

@synthesize itinerary;
@synthesize mainTable;
@synthesize feedbackButton;
@synthesize advisoryButton;
@synthesize twitterCount;

int const ROUTE_DETAILS_TABLE_HEIGHT = 370;
NSUserDefaults *prefs;

#pragma mark lifecycle view
-(void)loadView
{
    [super loadView];
}

-(void)viewDidLoad{
    [super viewDidLoad];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    @try {
        if (self) {
            [[self navigationItem] setTitle:ROUTE_TITLE_MSG];
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
        prefs = [NSUserDefaults standardUserDefaults];
        int tweetConut = [[prefs objectForKey:TWEET_COUNT] intValue];
        [twitterCount removeFromSuperview];
        twitterCount = [[CustomBadge alloc] init];
        twitterCount = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d",tweetConut]];
        [twitterCount setFrame:CGRectMake(60, 372, twitterCount.frame.size.width, twitterCount.frame.size.height)];        
        if (tweetConut == 0) {
            [twitterCount setHidden:YES];
        } else {
            [self.view addSubview:twitterCount];
            [twitterCount setHidden:NO];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at viewWillAppear RouteDetail: %@", exception);
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
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
        if ([[itinerary legDescriptionTitleSortedArray] count] > 0) {
            return [[itinerary legDescriptionTitleSortedArray] count];  
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
            [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]];
            [[cell textLabel] setLineBreakMode:UILineBreakModeWordWrap];
            [[cell textLabel] setNumberOfLines:0];
            [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE]];
            [[cell detailTextLabel] setLineBreakMode:UILineBreakModeWordWrap];
            [[cell detailTextLabel] setNumberOfLines:0];
        }
        
        [[cell textLabel] setText:[[itinerary legDescriptionTitleSortedArray] objectAtIndex:[indexPath row]]];
        [[cell detailTextLabel] setText:[[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]]];

        if ([[itinerary legDescriptionToLegMapArray] objectAtIndex:[indexPath row]] == [NSNull null]) {
            [cell.imageView setImage:nil];
        }
        else {
            Leg *leg = [[itinerary legDescriptionToLegMapArray] objectAtIndex:[indexPath row]];
            
            NSLog(@"leg arrival time: %@, leg time: %@", [leg arrivalFlag], [leg arrivalTime]);
            if([leg arrivalTime] > 0) {
                UIImage *imgForArrivalTime = [UIImage alloc];
                if([leg.arrivalFlag intValue] == ON_TIME) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_ontime.png"] ;
                }  else if([leg.arrivalFlag intValue] == DELAYED) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_delay.png"] ;
                } else if([leg.arrivalFlag intValue] == EARLY) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_early.png"] ;
                } else if([leg.arrivalFlag intValue] == EARLIER) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_earlier.png"] ;
                } 
                [cell.imageView setImage:imgForArrivalTime];
            }
            else {
                [cell.imageView setImage:nil];
            }
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
        // NSString *patchString;
        NSString* titleText = [[itinerary legDescriptionTitleSortedArray] objectAtIndex:[indexPath row]];
        NSString* subtitleText = [[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:[indexPath row]];
        CGSize titleSize = [titleText sizeWithFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE] 
              constrainedToSize:CGSizeMake(ROUTE_DETAILS_TABLE_CELL_WIDTH, CGFLOAT_MAX)];
        CGSize subtitleSize = [subtitleText sizeWithFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE]
                 constrainedToSize:CGSizeMake(ROUTE_DETAILS_TABLE_CELL_WIDTH, CGFLOAT_MAX)];
        
        /*
        // DE:48  Wrapping issue while directionsTitleText & directionsDetailText lenght is small.        
        if ([[leg directionsTitleText] length] < 20) {
            patchString  = [[leg directionsTitleText] stringByAppendingString:@"adding Patch string for UI" ];
            size = [[titleText stringByAppendingString:patchString] 
                    sizeWithFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE] 
                    constrainedToSize:CGSizeMake(ROUTE_DETAILS_TABLE_CELL_WIDTH, CGFLOAT_MAX)];
        } else {
            size = [[titleText stringByAppendingString:[leg directionsTitleText]] 
                    sizeWithFont:[UIFont systemFontOfSize:MEDIUM_FONT_SIZE] 
                    constrainedToSize:CGSizeMake(ROUTE_DETAILS_TABLE_CELL_WIDTH, CGFLOAT_MAX)];
        } */
        
        CGFloat height = titleSize.height + subtitleSize.height + VARIABLE_TABLE_CELL_HEIGHT_BUFFER;
        if (height < STANDARD_TABLE_CELL_MINIMUM_HEIGHT) { // Set a minumum row height
            height = STANDARD_TABLE_CELL_MINIMUM_HEIGHT;
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
        LegMapViewController *legMapVC = [[LegMapViewController alloc] initWithNibName:@"LegMapViewController" bundle:nil];
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


- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
        FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:[NSNumber numberWithInt:FB_SOURCE_ITINERARY] uniqueId:[itinerary itinId] date:nil fromAddress:nil toAddress:nil]; 
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