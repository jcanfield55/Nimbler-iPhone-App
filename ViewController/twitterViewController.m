//
//  twitterViewController.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/21/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "twitterViewController.h"
#import "UtilityFunctions.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "nc_AppDelegate.h"
#import "QuartzCore/QuartzCore.h"

#define TWEETERVIEW_MANE        @"Advisories"
#define TABLE_CELL              @"Cell"
#define CALTRAIN_CELL_HEADER    @"Caltrain @Caltrain"
#define TWEET                   @"tweet"
#define TWEET_TIME              @"time"
#define CALTRAIN_IMG            @"caltrain.jpg"

#define MAXLINE_TAG             5
#define CELL_HEIGHT             110

@implementation twitterViewController
UITableViewCell *cell;
NSUserDefaults *prefs;

@synthesize mainTable,twitterData,dateFormatter,reload,isFromAppDelegate,isTwitterLiveData,noAdvisory,getTweetInProgress,timerForStopProcees,arrayTweet;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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
    
    // Accessibility Label For UI Automation.
    self.mainTable.accessibilityLabel = TWITTER_TABLE_VIEW;
    
    arrayTweet = [[NSMutableArray alloc] init];
    [self hideUnUsedTableViewCell];
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
    }
    UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
    [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
    lblNavigationTitle.text=TWITTER_VIEW_TITLE;
    lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
    [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
    lblNavigationTitle.backgroundColor =[UIColor clearColor];
    lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
    self.navigationItem.titleView=lblNavigationTitle;              
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    prefs = [NSUserDefaults standardUserDefaults];
    UIButton *btnReload = [[UIButton alloc] initWithFrame:CGRectMake(0,0,48,34)];
    [btnReload addTarget:self action:@selector(getLatestTweets) forControlEvents:UIControlEventTouchUpInside];
    [btnReload setBackgroundImage:[UIImage imageNamed:@"img_reload.png"] forState:UIControlStateNormal];
    
    reload = [[UIBarButtonItem alloc] initWithCustomView:btnReload];
    
    // Accessibility Label For UI Automation.
    reload.accessibilityLabel = RELOAD_BUTTON;
    
    self.navigationItem.rightBarButtonItem = reload;

    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload{
    [super viewDidUnload];
    self.mainTable = nil;
    self.getTweetInProgress = nil;
    self.noAdvisory = nil;
}

- (void)dealloc{
    self.mainTable = nil;
    self.getTweetInProgress = nil;
    self.noAdvisory = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    logEvent(FLURRY_ADVISORIES_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
    
    [nc_AppDelegate sharedInstance].isTwitterView = YES;
   [self startProcessForGettingTweets]; 
    mainTable.delegate = self;
    mainTable.dataSource = self;
    
    [self getAdvisoryData];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [nc_AppDelegate sharedInstance].isTwitterView = NO;
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [arrayTweet count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = TABLE_CELL;
    UILabel *labelTime;
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell = nil;
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    id key = [arrayTweet objectAtIndex:indexPath.row];                
    NSString *tweetDetail = [(NSDictionary*)key objectForKey:TWEET];
    NSArray *tempArray = [tweetDetail componentsSeparatedByString:@":"];
    
    NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
    NSTimeInterval seconds = [tweetTime doubleValue]/1000;
    NSDate *epochNSDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
    NSDateFormatter *detailsTimeFormatter = [[NSDateFormatter alloc] init];
    [detailsTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    
//    NSDate *currentDate = [NSDate date];
//    NSString *tweetTimeDiff = [self stringForTimeIntervalSinceCreated:currentDate serverTime:epochNSDate];
    
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]]; 
    cell.textLabel.text = [tempArray objectAtIndex:0];
    NSMutableString *strTweet = [[NSMutableString alloc] init];
    for(int i=1;i<[tempArray count];i++){
        [strTweet appendString:[tempArray objectAtIndex:i]];
    }
    cell.detailTextLabel.text = strTweet;
    cell.textLabel.textColor = [UIColor colorWithRed:252.0/255.0 green:103.0/255.0 blue:88.0/255.0 alpha:1.0];    
    cell.detailTextLabel.numberOfLines= MAXLINE_TAG;
    cell.detailTextLabel.textColor = [UIColor colorWithRed:98.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0];
    
    labelTime = (UILabel *)[cell viewWithTag:MAXLINE_TAG];
     CGRect   lbl3Frame = CGRectMake(245,3, 120, 25);
    labelTime = [[UILabel alloc] initWithFrame:lbl3Frame];
    labelTime.tag = MAXLINE_TAG;
    labelTime.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:labelTime];
    labelTime.text = [[detailsTimeFormatter stringFromDate:epochNSDate] lowercaseString];
    [labelTime setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]]; 
    
    UIImage *img = [UIImage imageNamed:CALTRAIN_IMG];    
    cell.imageView.layer.cornerRadius = CORNER_RADIUS_MEDIUM;
    cell.imageView.layer.masksToBounds = YES;
    [cell.imageView setImage:img];
    return cell;
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{      
    id key = [arrayTweet objectAtIndex:indexPath.row]; 
    NSString *tweetDetail = [(NSDictionary*)key objectForKey:TWEET];
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:15];
    CGSize constraintSize = CGSizeMake(320.0f, MAXFLOAT);
    CGSize labelSize = [tweetDetail sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
    return labelSize.height + 50;  
}

#pragma mark reloadNewTweets request Response
-(void)getLatestTweets 
{
    // DE-196 Fixed
    if([[nc_AppDelegate sharedInstance] isNetworkConnectionLive]){
        noAdvisory.text = @"There are no advisories at this time. Everything appears to be running normally.";
        [self startProcessForGettingTweets];
        NSString *latestTweetTime = @"0";
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        if([arrayTweet count] > 0){
            id key = [arrayTweet objectAtIndex:0];
            NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
            
            if (tweetTime == NULL) {
                tweetTime = latestTweetTime;
            }
            NSDictionary *dict = [NSDictionary dictionaryWithKeysAndObjects:
                                  LAST_TWEET_TIME,tweetTime,
                                  DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
                                  nil];
            NSString *req = [LATEST_TWEETS_REQ appendQueryParams:dict];
            [[RKClient sharedClient]  get:req delegate:self];
            [[nc_AppDelegate sharedInstance] updateBadge:0];
        }
    }
    else{
        if([arrayTweet count] != 0){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler Caltrain" message:NO_NETWORK_ALERT delegate:self cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil];
            [alert show];
        }
        else{
            noAdvisory.text = @"No advisories available.  Unable to connect to server.  Please try again when you have network connectivity";
        }
    }
}
      
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    RKJSONParserJSONKit* rkTwitDataParser = [RKJSONParserJSONKit new];
    @try {
        if ([request isGET]) {
            if (isTwitterLiveData) {
                isTwitterLiveData = false;
                NIMLOG_TWITTER1(@"Twitter response %@", [response bodyAsString]);
                id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];                
                [self setTwitterLiveData:res];
            } else {
                NIMLOG_TWITTER1(@"latest tweets: %@", [response bodyAsString]);
                id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];
                NSNumber *respCode = [(NSDictionary*)res objectForKey:ERROR_CODE];
                int tc = [[(NSDictionary*)res objectForKey:TWIT_COUNT] intValue];
                if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                    if(tc > 0){
                        NSMutableArray *arrayLatestTweet = [(NSDictionary*)res objectForKey:TWEET]; 
                        //NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:arrayLatestTweet.count];
                        [arrayTweet removeAllObjects];
                        [arrayTweet addObjectsFromArray:arrayLatestTweet];
                        [mainTable reloadData]; 
                    }
                }
                else {
                    [mainTable reloadData];
                }
             [self stopProcessForGettingTweets];
            }
            
        }

    }
    @catch (NSException *exception) {
        logException(@"twitterViewController -> didLoadResponse", @"", exception);
    }

}

-(void)setTwitterLiveData:(id)tweetData
{
    twitterData = tweetData;
    NSNumber *respCode = [(NSDictionary*)twitterData objectForKey:ERROR_CODE];
    
    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
        // DE-173 Fixed
        [arrayTweet removeAllObjects];
        [arrayTweet addObjectsFromArray:[(NSDictionary*)twitterData objectForKey:TWEET]]; 
        [mainTable reloadData];
    } else if ([respCode intValue] == RESPONSE_DATA_NOT_EXIST) {
      [arrayTweet removeAllObjects]; 
        [mainTable reloadData];
    }
    [self stopProcessForGettingTweets];
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
    // DE-196 Fixed
    if([[nc_AppDelegate sharedInstance] isNetworkConnectionLive]){
        @try {
            noAdvisory.text = @"There are no advisories at this time. Everything appears to be running normally.";
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
            [[nc_AppDelegate sharedInstance] updateBadge:0];
            RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
            [RKClient setSharedClient:client];
            isTwitterLiveData = TRUE;
            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                                    DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
                                    nil];
            NSString *allAdvisories = [ALL_TWEETS_REQ appendQueryParams:params];
            [[RKClient sharedClient]  get:allAdvisories delegate:self];
        }
        @catch (NSException *exception) {
            logException(@"twitterViewController -> getAdvisoryData", @"", exception);
        }
    }
    else{
        if([arrayTweet count] != 0){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler Caltrain" message:NO_NETWORK_ALERT delegate:self cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil];
            [alert show];
        }
        else{
            noAdvisory.text = @"No advisories available.  Unable to connect to server.  Please try again when you have network connectivity";
        }
    }
}

#pragma mark UIUpdation
// after and before request these methods will be called 
-(void)startProcessForGettingTweets
{
    [noAdvisory setHidden:YES];
    [getTweetInProgress startAnimating]; 
    [self timerAction];
}
-(void)stopProcessForGettingTweets
{
    if ([arrayTweet count] == 0) {
        [noAdvisory setHidden:NO];
    } else {
        [noAdvisory setHidden:YES];
    }
    [getTweetInProgress stopAnimating];
    [getTweetInProgress setHidesWhenStopped:TRUE];
}
-(void)timerAction
{
    timerForStopProcees = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(stopProcessForGettingTweets) userInfo:nil repeats:NO];
}

@end