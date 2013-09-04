//
//  twitterViewController.h
//  Nimbler
//
//  Created by JaY Kumbhani on 6/21/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RestKit/RestKit.h"
#import "Foundation/foundation.h"

@interface twitterViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,RKRequestDelegate,UIWebViewDelegate,UIApplicationDelegate>{
    NSMutableArray *arrayTweet;
    NSString *strAllAdvisories;
    UIActivityIndicatorView *activityIndicatorView;
    
    // Pull To Refresh variables
    UIView *refreshHeaderView;
    UILabel *refreshLabel;
    UIImageView *refreshArrow;
    UIActivityIndicatorView *refreshSpinner;
    BOOL isDragging;
    BOOL isLoading;
    NSString *textPull;
    NSString *textRelease;
    NSString *textLoading;
    
    UIButton *advisoriesButton;
    UIButton *settingsButton;
    UIButton *feedBackButton;
}

@property (strong, nonatomic) IBOutlet UITableView* mainTable;
@property (nonatomic, strong) id twitterData;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIBarButtonItem *reload;
@property (nonatomic) BOOL isFromAppDelegate;
@property (nonatomic) BOOL isTwitterLiveData;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *getTweetInProgress;
@property (strong, nonatomic) IBOutlet UILabel *noAdvisory; 
@property (strong, nonatomic) NSTimer *timerForStopProcees;
@property (strong, nonatomic) NSMutableArray *arrayTweet;
@property (strong, nonatomic) NSString *strAllAdvisories;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

// Pull To Refresh properties and methods
@property (nonatomic, retain) UIView *refreshHeaderView;
@property (nonatomic, retain) UILabel *refreshLabel;
@property (nonatomic, retain) UIImageView *refreshArrow;
@property (nonatomic, retain) UIActivityIndicatorView *refreshSpinner;
@property (nonatomic, copy) NSString *textPull;
@property (nonatomic, copy) NSString *textRelease;
@property (nonatomic, copy) NSString *textLoading;

- (void)setupStrings;
- (void)addPullToRefreshHeader;
- (void)startLoading;
- (void)stopLoading;
- (void)refresh;

-(void)setTwitterLiveData:(id)tweetData;

-(NSString *)stringForTimeIntervalSinceCreated:(NSDate *)dateTime serverTime:(NSDate *)serverDateTime;
-(void)popOut;
-(void)getAdvisoryData;
-(void)stopProcessForGettingTweets;
-(void)startProcessForGettingTweets;
-(void)timerAction;
- (void)openUrl:(NSURL *)url;

- (void) hideTabBar;

@end