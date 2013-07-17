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
#import "WebView.h"
#import "SettingInfoViewController.h"
#import "FeedBackForm.h"

#define TWEETERVIEW_MANE        @"Advisories"
#define TABLE_CELL              @"Cell"
#define CALTRAIN_CELL_HEADER    @"Caltrain @Caltrain"
#define TWEET                   @"tweet"
#define TWEET_TIME              @"time"
#define TWEET_SOURCE            @"source"
#define CALTRAIN_IMG            @"caltrain.jpg"

#define MAXLINE_TAG             5
#define CELL_HEIGHT             110
#define REFRESH_HEADER_HEIGHT 52.0f

@implementation twitterViewController
UITableViewCell *cell;
NSUserDefaults *prefs;

@synthesize mainTable,twitterData,dateFormatter,reload,isFromAppDelegate,isTwitterLiveData,noAdvisory,getTweetInProgress,timerForStopProcees,arrayTweet,strAllAdvisories,activityIndicatorView;

@synthesize textPull, textRelease, textLoading, refreshHeaderView, refreshLabel, refreshArrow, refreshSpinner;

@synthesize advisoriesButton,settingsButton,feedBackButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        [self setupStrings];
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
    
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    [self addPullToRefreshHeader];
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
}

- (void)setupStrings{
    textPull = @"Pull down to refresh...";
    textRelease =@"Release to refresh...";
    textLoading = @"Loading...";
}

- (void)addPullToRefreshHeader {
    refreshHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, 285, REFRESH_HEADER_HEIGHT)];
    refreshHeaderView.backgroundColor = [UIColor clearColor];
    
    refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 285, REFRESH_HEADER_HEIGHT)];
    refreshLabel.backgroundColor = [UIColor clearColor];
    refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    refreshLabel.textAlignment = NSTextAlignmentCenter;
    
    refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow.png"]];
    refreshArrow.frame = CGRectMake(floorf((REFRESH_HEADER_HEIGHT - 27) / 2),
                                    (floorf(REFRESH_HEADER_HEIGHT - 44) / 2),
                                    27, 44);
    
    refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT - 20) / 2), floorf((REFRESH_HEADER_HEIGHT - 20) / 2), 20, 20);
    refreshSpinner.hidesWhenStopped = YES;
    
    [refreshHeaderView addSubview:refreshLabel];
    [refreshHeaderView addSubview:refreshArrow];
    [refreshHeaderView addSubview:refreshSpinner];
    [mainTable addSubview:refreshHeaderView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (isLoading) return;
    isDragging = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (isLoading) {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
            mainTable.contentInset = UIEdgeInsetsZero;
        else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
            mainTable.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (isDragging && scrollView.contentOffset.y < 0) {
        // Update the arrow direction and label
        [UIView animateWithDuration:0.25 animations:^{
            if (scrollView.contentOffset.y < -REFRESH_HEADER_HEIGHT) {
                // User is scrolling above the header
                refreshLabel.text = self.textRelease;
                [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
            } else {
                // User is scrolling somewhere within the header
                refreshLabel.text = self.textPull;
                [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
            }
        }];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (isLoading) return;
    isDragging = NO;
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT) {
        // Released above the header
        [self startLoading];
    }
}

- (void)startLoading {
    isLoading = YES;
    
    // Show the header
    [UIView animateWithDuration:0.3 animations:^{
        mainTable.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
        refreshLabel.text = self.textLoading;
        refreshArrow.hidden = YES;
        [refreshSpinner startAnimating];
    }];
    
    // Refresh action!
    [self refresh];
}

- (void)stopLoading {
    isLoading = NO;
    
    // Hide the header
    [UIView animateWithDuration:0.3 animations:^{
        mainTable.contentInset = UIEdgeInsetsZero;
        [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    }
                     completion:^(BOOL finished) {
                         [self performSelector:@selector(stopLoadingComplete)];
                     }];
}

- (void)stopLoadingComplete {
    // Reset the header
    refreshLabel.text = self.textPull;
    refreshArrow.hidden = NO;
    [refreshSpinner stopAnimating];
}

- (void)refresh {
    // This is just a demo. Override this method with your custom reload action.
    // Don't forget to call stopLoading at the end.
    [self getLatestTweets];
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
    
   [self startProcessForGettingTweets]; 
    mainTable.delegate = self;
    mainTable.dataSource = self;
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
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
    @try {
        NSString *cellIdentifier = TABLE_CELL;
        UILabel *labelTime;
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if(cell==nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        
        if ([cell.contentView subviews]){
            for (UIView *subview in [cell.contentView subviews]) {
                [subview removeFromSuperview];
            }
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        id key = [arrayTweet objectAtIndex:indexPath.row];
        NSString *tweetDetail = [(NSDictionary*)key objectForKey:TWEET];
        NSArray *tempArray = [tweetDetail componentsSeparatedByString:@":"];
        
        NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
        NSTimeInterval seconds = [tweetTime doubleValue]/1000;
        NSDate *epochNSDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
        NSDateFormatter *detailsTimeFormatter = [[NSDateFormatter alloc] init];
        [detailsTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        UILabel *lblTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 10, 300, 30)];
        [lblTextLabel setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]];
        [lblTextLabel setText:[tempArray objectAtIndex:0]];
        [lblTextLabel setTextColor:[UIColor colorWithRed:252.0/255.0 green:103.0/255.0 blue:88.0/255.0 alpha:1.0]];
        [lblTextLabel setBackgroundColor:[UIColor clearColor]];
        [cell.contentView addSubview:lblTextLabel];
        
        NSMutableString *strTweet = [[NSMutableString alloc] init];
        for(int i = 1; i < [tempArray count]; i++){
            NSString *tweetText = [[NSString alloc] initWithString:[tempArray objectAtIndex:i]];
            if ([tweetText rangeOfString:@"http"].location != NSNotFound) {
                tweetText = [NSString stringWithFormat:@"%@:",tweetText];
            }
            [strTweet appendString:tweetText];
        }
        CGSize stringSize = [strTweet sizeWithFont:[UIFont systemFontOfSize:16.0] constrainedToSize:CGSizeMake(220, 9999) lineBreakMode:UILineBreakModeWordWrap];
        UITextView *uiTextView=[[UITextView alloc] initWithFrame:CGRectMake(55, 28, 220, stringSize.height + 40)];
        uiTextView.font = [UIFont systemFontOfSize:15.0];
        uiTextView.text = strTweet;
        uiTextView.textColor = [UIColor colorWithRed:98.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0];
        uiTextView.editable = NO;
        uiTextView.dataDetectorTypes = UIDataDetectorTypeLink;
        uiTextView.scrollEnabled = NO;
        uiTextView.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:uiTextView];
        
        cell.textLabel.textColor = [UIColor colorWithRed:252.0/255.0 green:103.0/255.0 blue:88.0/255.0 alpha:1.0];
        cell.detailTextLabel.numberOfLines= MAXLINE_TAG;
        cell.detailTextLabel.textColor = [UIColor colorWithRed:98.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0];
        
        labelTime = (UILabel *)[cell viewWithTag:MAXLINE_TAG];
        CGRect   lbl3Frame = CGRectMake(210,3, 73, 25);
        labelTime = [[UILabel alloc] initWithFrame:lbl3Frame];
        labelTime.tag = MAXLINE_TAG;
        labelTime.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:labelTime];
        labelTime.text = [[detailsTimeFormatter stringFromDate:epochNSDate] lowercaseString];
        [labelTime setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]];
        
        // DE-270 Fixed
        UIImage *image = getAgencyIcon([key objectForKey:TWEET_SOURCE]);
        if(image)
            cell.imageView.image =image;
        else
            cell.imageView.image = [UIImage imageNamed:CALTRAIN_IMG];
        cell.imageView.layer.cornerRadius = CORNER_RADIUS_MEDIUM;
        cell.imageView.layer.masksToBounds = YES;
        return cell;
    }
    @catch (NSException *exception) {
        logException(@"twitterViewController -> cellForRowAtIndexPath", @"", exception);
    }
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([arrayTweet count] > indexPath.row){
        id key = [arrayTweet objectAtIndex:indexPath.row];
        NSString *tweetDetail = [(NSDictionary*)key objectForKey:TWEET];
        UIFont *cellFont = [UIFont systemFontOfSize:16.0];
        CGSize constraintSize = CGSizeMake(220.0f, MAXFLOAT);
        CGSize labelSize = [tweetDetail sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
        return labelSize.height + 40;
    }
    return 50;
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
        client.cachePolicy = RKRequestCachePolicyNone;
        [RKClient setSharedClient:client];
        if([arrayTweet count] > 0){
            id key = [arrayTweet objectAtIndex:0];
            NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
            
            if (tweetTime == NULL) {
                tweetTime = latestTweetTime;
            }
            NSString *strAgencyIDs = [[nc_AppDelegate sharedInstance] getAgencyIdsString];
            if(strAgencyIDs.length > 0){
                NSDictionary *dict = [NSDictionary dictionaryWithKeysAndObjects:
                                      LAST_TWEET_TIME,tweetTime,
                                      DEVICE_TOKEN, [[nc_AppDelegate sharedInstance] deviceTokenString],APPLICATION_TYPE,[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],AGENCY_IDS,strAgencyIDs,APPLICATION_VERSION,[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                      nil];
                NSString *req = [LATEST_TWEETS_REQ appendQueryParams:dict];
                [[RKClient sharedClient]  get:req delegate:self];
                [[nc_AppDelegate sharedInstance] updateBadge:0];
            }
            else{
                [arrayTweet removeAllObjects];
                [mainTable reloadData];
                //[[nc_AppDelegate sharedInstance] updateBadge:0];
            }
           
        }
    }
    else{
        if([arrayTweet count] != 0){
            logEvent(FLURRY_ALERT_NO_NETWORK, FLURRY_ALERT_LOCATION, @"twitterViewController -> getLatestTweets", nil, nil, nil, nil, nil, nil);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_TITLE message:NO_NETWORK_ALERT delegate:self cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil];
            [alert show];
        }
        else{
            [self stopLoading];
            noAdvisory.text = @"No advisories available.  Unable to connect to server.  Please try again when you have network connectivity";
        }
    }
}
      
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
    NSString *strResourcePath = request.resourcePath;
    RKJSONParserJSONKit* rkTwitDataParser = [RKJSONParserJSONKit new];
    @try {
        if ([request isGET]) {
            if ([strResourcePath isEqualToString:strAllAdvisories]) {
                isTwitterLiveData = false;
                NIMLOG_TWITTER1(@"Twitter response %@", [response bodyAsString]);
                id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];
                if(!res)
                    [noAdvisory setHidden:NO];
                [self setTwitterLiveData:res];
                [[nc_AppDelegate sharedInstance].twitterCount setHidden:YES];
            } else {
                NIMLOG_TWITTER1(@"latest tweets: %@", [response bodyAsString]);
                id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];
                NSNumber *respCode = [(NSDictionary*)res objectForKey:ERROR_CODE];
                int tc = [[(NSDictionary*)res objectForKey:TWIT_COUNT] intValue];
                if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                    if(tc > 0){
                        NSMutableArray *arrayLatestTweet = [(NSDictionary*)res objectForKey:TWEET]; 
                        NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:arrayTweet];
                        [arrayTweet removeAllObjects];
                        [arrayTweet addObjectsFromArray:arrayLatestTweet];
                        [arrayTweet addObjectsFromArray:tempArray];
                        [self stopLoading];
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
            client.cachePolicy = RKRequestCachePolicyNone;
            [RKClient setSharedClient:client];
            isTwitterLiveData = TRUE;
            NSString *strAgencyIDs = [[nc_AppDelegate sharedInstance] getAgencyIdsString];
            if(strAgencyIDs.length > 0){
                NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                                        DEVICE_TOKEN, [[nc_AppDelegate sharedInstance] deviceTokenString],APPLICATION_TYPE,[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],AGENCY_IDS,strAgencyIDs,APPLICATION_VERSION,[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                        nil];
                NSString *allAdvisories = [ALL_TWEETS_REQ appendQueryParams:params];
                strAllAdvisories = allAdvisories;
                [[RKClient sharedClient]  get:allAdvisories delegate:self];
            }
            else{
                [arrayTweet removeAllObjects];
                [mainTable reloadData];
                //[[nc_AppDelegate sharedInstance] updateBadge:0];
            }
        }
        @catch (NSException *exception) {
            logException(@"twitterViewController -> getAdvisoryData", @"", exception);
        }
    }
    else{
        if([arrayTweet count] != 0){
            logEvent(FLURRY_ALERT_NO_NETWORK, FLURRY_ALERT_LOCATION, @"twitterViewController -> getAdvisoryData", nil, nil, nil, nil, nil, nil);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_TITLE message:NO_NETWORK_ALERT delegate:self cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil];
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
    [self stopLoading];
}
-(void)timerAction
{
    timerForStopProcees = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(stopProcessForGettingTweets) userInfo:nil repeats:NO];
}

- (void) backToTwitterView{
     CATransition *animation = [CATransition animation];
     [animation setDuration:0.3];
     [animation setType:kCATransitionPush];
     [animation setSubtype:kCATransitionFromLeft];
     [animation setRemovedOnCompletion:YES];
     [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
     [[self.navigationController.view layer] addAnimation:animation forKey:nil];
     [[self navigationController] popViewControllerAnimated:NO];
}

- (void)openUrl:(NSURL *)url {
    UIViewController *webViewController = [[UIViewController alloc] init];
    UIButton * btnGoToNimbler = [[UIButton alloc] initWithFrame:CGRectMake(0,0,65,34)];
    [btnGoToNimbler addTarget:self action:@selector(backToTwitterView) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToNimbler setBackgroundImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    
    UIBarButtonItem *backTonimbler = [[UIBarButtonItem alloc] initWithCustomView:btnGoToNimbler];
    webViewController.navigationItem.leftBarButtonItem = backTonimbler;
    [webViewController.view addSubview:[WebView instance]];
    if ([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT) {
        [WebView instance].frame = CGRectMake(0, 0, 285, 479);
    } else {
        [WebView instance].frame = CGRectMake(0, 0, 285, 415);
    }
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [[WebView instance] loadRequest:request];
    [WebView instance].delegate = self;
    if([[[UIDevice currentDevice] systemVersion] intValue] < 5.0){
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.3];
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromRight];
        [animation setRemovedOnCompletion:YES];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        [[self.navigationController.view layer] addAnimation:animation forKey:nil];
        [[self navigationController] pushViewController:webViewController animated:NO];
    } else {
        [[self navigationController] pushViewController:webViewController animated:YES];
    }
}


-(void)webViewDidStartLoad:(UIWebView *)webView{
    if(!activityIndicatorView){
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(145, 168, 37, 37)];
        [activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        [webView addSubview:activityIndicatorView];
    }
    [activityIndicatorView startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [activityIndicatorView stopAnimating];
}

-(IBAction)advisoriesButtonClicked:(id)sender{
    
}
-(IBAction)settingsButtonClicked:(id)sender{
    SettingInfoViewController *secondView = [[SettingInfoViewController alloc] initWithNibName:@"SettingViewController_SF" bundle:nil];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    [animation setType:kCATransition];
    [animation setSubtype:kCATransitionFromTop];
    [[self.navigationController.view layer] addAnimation:animation forKey:@"SwitchToView1"];
    [self.navigationController pushViewController:secondView animated:NO];
}
-(IBAction)feedBackButtonClicked:(id)sender{
    FeedBackForm *secondView = [[FeedBackForm alloc] initWithNibName:@"FeedBackForm" bundle:nil];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    [animation setType:kCATransition];
    [animation setSubtype:kCATransitionFromTop];
    [[self.navigationController.view layer] addAnimation:animation forKey:@"SwitchToView1"];
    [self.navigationController pushViewController:secondView animated:NO];
}


@end