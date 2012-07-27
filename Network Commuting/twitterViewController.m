//
//  twitterViewController.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/21/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "twitterViewController.h"
#import "UtilityFunctions.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "QuartzCore/QuartzCore.h"
#if FLURRY_ENABLED
#include "Flurry.h"
#endif

#define TWEETERVIEW_MANE        @"Advisories"
#define TABLE_CELL              @"Cell"
#define CALTRAIN_CELL_HEADER    @"Caltrain @Caltrain"
#define TWEET                   @"tweet"
#define TWEET_TIME              @"time"
#define CALTRAIN_IMG            @"caltrain.jpg"

#define MAXLINE_TAG             3
#define CELL_HEIGHT             80

@implementation twitterViewController

NSMutableArray *arrayTweet;

@synthesize mainTable,twitterData,dateFormatter,reload,isFromAppDelegate,isTwitterLiveData,noAdvisory;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:TWEETERVIEW_MANE];               
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
        
      UIButton *btnReload = [[UIButton alloc] initWithFrame:CGRectMake(0,0,48,34)];
        [btnReload addTarget:self action:@selector(getLatestTweets) forControlEvents:UIControlEventTouchUpInside];
        [btnReload setBackgroundImage:[UIImage imageNamed:@"img_reload.png"] forState:UIControlStateNormal];
        
        reload = [[UIBarButtonItem alloc] initWithCustomView:btnReload]; 
        self.navigationItem.rightBarButtonItem = reload;

    }
    return self;
}

-(void)hideUnUsedTableViewCell{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor clearColor];
    [mainTable setTableFooterView:view];
}
-(void)popOut
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self hideUnUsedTableViewCell];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0], UITextAttributeTextColor,
                                                                     nil]];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#if FLURRY_ENABLED
    [Flurry logEvent:FLURRY_ADVISORIES_APPEAR];
#endif
    [self getAdvisoryData];
    
    mainTable.delegate = self;
    mainTable.dataSource = self;
    [mainTable reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([arrayTweet count] == 0) {
        [noAdvisory setHidden:NO];
    } else {
        [noAdvisory setHidden:YES];
    }
    
    return [arrayTweet count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = TABLE_CELL;
    
    UITableViewCell *cell =     [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell = nil;
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    id key = [arrayTweet objectAtIndex:indexPath.row];                
    NSString *tweetDetail = [(NSDictionary*)key objectForKey:TWEET];
    NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
    
    NSTimeInterval seconds = [tweetTime doubleValue]/1000;
    NSDate *epochNSDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
    NSDate *currentDate = [NSDate date];
    NSString *tweetTimeDiff = [self stringForTimeIntervalSinceCreated:currentDate serverTime:epochNSDate];
    
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]]; 
    cell.textLabel.text = CALTRAIN_CELL_HEADER;
    cell.textLabel.textColor = [UIColor colorWithRed:252.0/255.0 green:103.0/255.0 blue:88.0/255.0 alpha:1.0];    
    cell.detailTextLabel.text = tweetDetail;
    cell.detailTextLabel.numberOfLines= MAXLINE_TAG;
    cell.detailTextLabel.textColor = [UIColor colorWithRed:98.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0];
    
    UILabel *labelTime = (UILabel *)[cell viewWithTag:MAXLINE_TAG];
   
    CGRect lbl3Frame = CGRectMake(280, 5, 35, 25);
    labelTime = [[UILabel alloc] initWithFrame:lbl3Frame];
    labelTime.tag = MAXLINE_TAG;
    labelTime.backgroundColor = [UIColor clearColor];
    [labelTime setTextAlignment:UITextAlignmentRight];
    [cell.contentView addSubview:labelTime];
    labelTime.text = tweetTimeDiff;
    cell.detailTextLabel.textColor = [UIColor colorWithRed:98.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0];
    
    UIImage *img = [UIImage imageNamed:CALTRAIN_IMG];    
    cell.imageView.layer.cornerRadius = CORNER_RADIUS_MEDIUM;
    cell.imageView.layer.masksToBounds = YES;
    [cell.imageView setImage:img];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
       return CELL_HEIGHT;  
}

#pragma mark reloadNewTweets request Response
-(void)getLatestTweets 
{
    NSString *latestTweetTime = @"0";
//    if (arrayTweet.count != 0) {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        id key = [arrayTweet objectAtIndex:0];                
        NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
    
    if (tweetTime == NULL) {
        tweetTime = latestTweetTime;
    }
        NSDictionary *dict = [NSDictionary dictionaryWithKeysAndObjects:
                              LAST_TWEET_TIME,tweetTime,
                              DEVICE_ID, [UIDevice currentDevice].uniqueIdentifier,
                              nil];
        NSString *req = [LATEST_TWEETS_REQ appendQueryParams:dict];
        [[RKClient sharedClient]  get:req delegate:self]; 
    [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
//    }
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    RKJSONParserJSONKit* rkTwitDataParser = [RKJSONParserJSONKit new];
    @try {
        if ([request isGET]) {
            if (isTwitterLiveData) {
                isTwitterLiveData = false;
                NSLog(@"response %@", [response bodyAsString]);
                id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];                
                [self setTwitterLiveData:res];
            } else {
                NSLog(@"latest tweets: %@", [response bodyAsString]);
                id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];
                NSNumber *respCode = [(NSDictionary*)res objectForKey:ERROR_CODE];
                
                if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                    NSMutableArray *arrayLatestTweet = [(NSDictionary*)res objectForKey:TWEET]; 
                    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:arrayLatestTweet.count];
                    [tempArray addObjectsFromArray:arrayLatestTweet];
                    [tempArray addObjectsFromArray:arrayTweet];
                    arrayTweet = [[NSMutableArray alloc]initWithCapacity:arrayLatestTweet.count];
                    [arrayTweet addObjectsFromArray:tempArray];
                    [mainTable reloadData];
                }
            }
            
        }

    }
    @catch (NSException *exception) {
        NSLog(@"exceptions: %@", exception);
    }

}

-(void)setTwitterLiveData:(id)tweetData
{
    twitterData = tweetData;
    NSNumber *respCode = [(NSDictionary*)twitterData objectForKey:ERROR_CODE];
    
    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
        arrayTweet = [(NSDictionary*)twitterData objectForKey:TWEET]; 
        [mainTable reloadData];
    } else if ([respCode intValue] == RESPONSE_DATA_NOT_EXIST) {
        arrayTweet = nil; 
        [mainTable reloadData];
    }
}

// convert into twitter calaculate time
-(NSString *)stringForTimeIntervalSinceCreated:(NSDate *)dateTime serverTime:(NSDate *)serverDateTime{
    NSInteger tweetMin;
    NSInteger tweethour;
    NSInteger tweetday;
    NSInteger day;
    NSInteger interval = abs((NSInteger)[dateTime timeIntervalSinceDate:serverDateTime]);
    if(interval >= 86400)
    {
        tweetday  = interval/86400;
        day = interval%86400;
        if(day!=0)
        {
            if(day>=3600){
                //HourInterval=DayModules/3600;
                return [NSString stringWithFormat:@"%id", tweetday];
            }
            else {
                if(day>=60){
                    //MinInterval=DayModules/60;
                    return [NSString stringWithFormat:@"%id", tweetday];
                }
                else {
                    return [NSString stringWithFormat:@"%id", tweetday];
                }
            }
        }
        else 
        {
            return [NSString stringWithFormat:@"%id", tweetday];
        }
    }
    else{
        if(interval>=3600) {
            tweethour= interval/3600;
            return [NSString stringWithFormat:@"%ih", tweethour];
        } else if(interval>=60) {
            tweetMin = interval/60;
            return [NSString stringWithFormat:@"%im", tweetMin];
        }
        else{
            return [NSString stringWithFormat:@"%is", interval];
        }
    }
}

-(void)getAdvisoryData
{
    @try {
        [UIApplication sharedApplication].applicationIconBadgeNumber = BADGE_COUNT_ZERO;
        [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        isTwitterLiveData = TRUE;
        NSString *udid = [UIDevice currentDevice].uniqueIdentifier;            
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                DEVICE_ID, udid,
                                nil];    
        NSString *allAdvisories = [ALL_TWEETS_REQ appendQueryParams:params];
        [[RKClient sharedClient]  get:allAdvisories delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception at advisories button click from ToFromview: %@", exception);
    } 
}

@end