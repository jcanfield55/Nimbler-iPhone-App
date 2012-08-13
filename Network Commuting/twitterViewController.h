//
//  twitterViewController.h
//  Nimbler
//
//  Created by JaY Kumbhani on 6/21/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RestKit/RestKit.h"
#import "Foundation/foundation.h"

@interface twitterViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,RKRequestDelegate>

@property (strong, nonatomic) IBOutlet UITableView* mainTable;
@property (nonatomic, retain) id twitterData;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIBarButtonItem *reload;
@property (nonatomic) BOOL isFromAppDelegate;
@property (nonatomic) BOOL isTwitterLiveData;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *getTweetInProgress;
@property (strong, nonatomic) IBOutlet UILabel *noAdvisory; 
@property (strong, nonatomic) NSTimer *timerForStopProcees;

-(void)setTwitterLiveData:(id)tweetData;

-(NSString *)stringForTimeIntervalSinceCreated:(NSDate *)dateTime serverTime:(NSDate *)serverDateTime;
-(void)popOut;
-(void)getAdvisoryData;
-(void)stopProcessForGettingTweets;
-(void)startProcessForGettingTweets;
-(void)timerAction;
@end