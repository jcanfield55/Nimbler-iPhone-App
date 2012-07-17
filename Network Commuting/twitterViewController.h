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
@property (nonatomic, strong) NSDateFormatter *dateFormattr;
@property (nonatomic, strong) UIBarButtonItem *relod;
@property (nonatomic) BOOL isFromAppDelegate;
@property (nonatomic) BOOL isTwitterLivaData;

-(void)setTwitterLiveData:(id)twitData;

-(NSString *)stringForTimeIntervalSinceCreated:(NSDate *)dateTime serverTime:(NSDate *)serverDateTime;
-(void)popOut;
-(void)refreshTweetCount;
@end