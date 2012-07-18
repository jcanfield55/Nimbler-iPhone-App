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

#define TWEETERVIEW_MANE        @"Nimbler Caltrain"
#define TABLE_CELL              @"Cell"
#define CALTRAIN_CELL_HEADER    @"Caltrain @Caltrain"
#define TWEET                   @"tweet"
#define TWEET_TIME              @"time"
#define CALTRAIN_IMG            @"caltrain.jpg"

#define MAXLINE_TAG             3
#define CELL_HEIGHT             80

@implementation twitterViewController

NSMutableArray *arrayTweet;

@synthesize mainTable,twitterData,dateFormattr,relod,isFromAppDelegate,isTwitterLivaData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:TWEETERVIEW_MANE];
        self.tabBarItem.title = ADVISORIES_VIEW;
        self.tabBarItem.image = [UIImage imageNamed:@"img_ontime.png"];
        self.tabBarItem.badgeValue = @"3";
        
        dateFormattr = [[NSDateFormatter alloc] init];
        [dateFormattr setDateStyle:NSDateFormatterFullStyle];
        [UIApplication sharedApplication].applicationIconBadgeNumber = BADGE_COUNT_ZERO;

        relod = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(getLatestTweets)]; 
        self.navigationItem.rightBarButtonItem = relod;
        [self refreshTweetCount];
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
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [UIColor blackColor], UITextAttributeTextColor,
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
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        isTwitterLivaData = TRUE;
        NSString *udid = [UIDevice currentDevice].uniqueIdentifier;            
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                DEVICE_ID, udid,
                                nil];    
        NSString *advisoriesAll = [ALL_TWEETS_REQ appendQueryParams:params];
        [[RKClient sharedClient]  get:advisoriesAll delegate:self];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception at advisories button click from ToFromview: %@", exception);
    } 
    
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
    return [arrayTweet count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = TABLE_CELL;
    UITableViewCell *cell =     [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    id key = [arrayTweet objectAtIndex:indexPath.row];                
    NSString *tweetDetail = [(NSDictionary*)key objectForKey:TWEET];
    NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
    
    NSTimeInterval seconds = [tweetTime doubleValue]/1000;
    NSDate *epochNSDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
    NSDate *currentDate = [NSDate date];
    NSString *tweetAt = [self stringForTimeIntervalSinceCreated:currentDate serverTime:epochNSDate];
    
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]]; 
    cell.textLabel.text = CALTRAIN_CELL_HEADER;
    cell.textLabel.textColor = [UIColor redColor];
    cell.detailTextLabel.text = tweetDetail;
    cell.detailTextLabel.numberOfLines= MAXLINE_TAG;
    
    UILabel *labelTime = (UILabel *)[cell viewWithTag:MAXLINE_TAG];
    CGRect lbl3Frame = CGRectMake(280, 5, 30, 25);
    labelTime = [[UILabel alloc] initWithFrame:lbl3Frame];
    labelTime.tag = MAXLINE_TAG;
    labelTime.textColor = [UIColor blackColor];
    [labelTime setTextAlignment:UITextAlignmentRight];
    [cell.contentView addSubview:labelTime];
    labelTime.text = tweetAt;
    [labelTime setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]];
    
    UIImage *img = [UIImage imageNamed:CALTRAIN_IMG];    
    cell.imageView.layer.cornerRadius = CORNER_RADIUS_SMALL;
    cell.imageView.layer.masksToBounds = YES;
    [cell.imageView setImage:img];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    //    id key = [arrayTweet objectAtIndex:indexPath.row];                
    //    NSString *tweetDetail = [(NSDictionary*)key objectForKey:@"tweet"];
    //   CGSize size = [tweetDetail 
    //            sizeWithFont:[UIFont systemFontOfSize:14] 
    //            constrainedToSize:CGSizeMake(320, CGFLOAT_MAX)];
    
    return CELL_HEIGHT;  
}

#pragma mark reloadNewTweets request Response
-(void)getLatestTweets 
{
    if (arrayTweet.count != 0) {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        id key = [arrayTweet objectAtIndex:0];                
        NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
        NSDictionary *dict = [NSDictionary dictionaryWithKeysAndObjects:
                              LAST_TWEET_TIME,tweetTime,
                              DEVICE_ID, [UIDevice currentDevice].uniqueIdentifier,
                              nil];
        NSString *req = [LATEST_TWEETS_REQ appendQueryParams:dict];
        [[RKClient sharedClient]  get:req delegate:self]; 
        [self refreshTweetCount];
    }
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    RKJSONParserJSONKit* rkTwitDataParser = [RKJSONParserJSONKit new];
    if ([request isGET]) {
        if (isTwitterLivaData) {
            isTwitterLivaData = false;
            NSLog(@"response %@", [response bodyAsString]);
            id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];                
            [self setTwitterLiveData:res];
        } else {
            NSLog(@"latest tweets: %@", [response bodyAsString]);
            id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];
            NSNumber *respCode = [(NSDictionary*)res objectForKey:ERROR_CODE];
            @try {
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
            @catch (NSException *exception) {
                NSLog(@"exceptions: %@", exception);
            }

        }
    }
}

-(void)setTwitterLiveData:(id)twitData
{
    twitterData = twitData;
    NSNumber *respCode = [(NSDictionary*)twitterData objectForKey:ERROR_CODE];
    
    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
        arrayTweet = [(NSDictionary*)twitterData objectForKey:TWEET]; 
        [mainTable reloadData];
    } else if ([respCode intValue] == RESPONSE_DATA_NOT_EXIST) {
        arrayTweet = nil; 
        [mainTable reloadData];
    }
}

-(void)refreshTweetCount
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:@"0" forKey:TWEET_COUNT];
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

@end