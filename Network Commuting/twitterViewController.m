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

@implementation twitterViewController
NSMutableArray *arrayTweet;


@synthesize mainTable,twitterData,dateFormattr;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"Nimbler Caltrain"];
        dateFormattr = [[NSDateFormatter alloc] init];
        [dateFormattr setDateStyle:NSDateFormatterFullStyle];
        
       UIBarButtonItem *relod = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(getLatestTweets)]; 
        self.navigationItem.rightBarButtonItem = relod;
    }
    return self;
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell =     [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle                                       reuseIdentifier:CellIdentifier] ;
    }
    
    id key = [arrayTweet objectAtIndex:indexPath.row];                
    NSString *tweetDetail = [(NSDictionary*)key objectForKey:@"tweet"];
    NSString *tweetTime =  [(NSDictionary*)key objectForKey:@"time"];
       
    NSTimeInterval seconds = [tweetTime doubleValue]/1000;
    NSDate *epochNSDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
    NSDate *currentDate = [NSDate date];
    NSString *tweetAt = [self stringForTimeIntervalSinceCreated:currentDate serverTime:epochNSDate];
        
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]]; 
    cell.textLabel.text = @"caltrain @Caltrain";
    cell.detailTextLabel.text = tweetDetail;
    cell.detailTextLabel.numberOfLines= 3;
    
    UILabel *labelTime = (UILabel *)[cell viewWithTag:3];
    CGRect lbl3Frame = CGRectMake(280, 0, 30, 20);
    labelTime = [[UILabel alloc] initWithFrame:lbl3Frame];
    labelTime.tag = 3;
    labelTime.textColor = [UIColor blackColor];
    [cell.contentView addSubview:labelTime];
    labelTime.text = tweetAt;
    [labelTime setFont:[UIFont boldSystemFontOfSize:12.0]];
    
    UIImage *img = [UIImage imageNamed:@"caltrain.jpg"];
    [cell.imageView setImage:img];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    id key = [arrayTweet objectAtIndex:indexPath.row];                
//    NSString *tweetDetail = [(NSDictionary*)key objectForKey:@"tweet"];
//   CGSize size = [tweetDetail 
//            sizeWithFont:[UIFont systemFontOfSize:14] 
//            constrainedToSize:CGSizeMake(320, CGFLOAT_MAX)];
    
    return 75; // all other rows are 40px high 
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

#pragma mark reloadNewTweets request Response

-(void)getLatestTweets 
{
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    [RKClient setSharedClient:client];
    id key = [arrayTweet objectAtIndex:0];                
    NSString *tweetTime =  [(NSDictionary*)key objectForKey:@"time"];
    NSDictionary *dict = [NSDictionary dictionaryWithKeysAndObjects:
                          @"tweetTime",tweetTime,
                          nil];
    NSString *req = [@"advisories/latest" appendQueryParams:dict];
    [[RKClient sharedClient]  get:req delegate:self];  
}


- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    RKJSONParserJSONKit* rkTwitDataParser = [RKJSONParserJSONKit new];
        if ([request isGET]) {
            NSLog(@"latest tweets: %@", [response bodyAsString]);
                       
            id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];
            NSNumber *respCode = [(NSDictionary*)res objectForKey:@"errCode"];
            
            @try {
                if ([respCode intValue] == 105) {
                    NSMutableArray *arrayLatestTweet = [(NSDictionary*)res objectForKey:@"tweet"]; 
                    NSLog(@"size of new array: %d", arrayLatestTweet.count);
                                        
                    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:arrayLatestTweet.count];
                    [tempArray addObjectsFromArray:arrayLatestTweet];
                    [tempArray addObjectsFromArray:arrayTweet];
                    
                    arrayTweet = [[NSMutableArray alloc]initWithCapacity:arrayLatestTweet.count];
                    [arrayTweet addObjectsFromArray:tempArray];
                    NSLog(@"exception %d", [tempArray count]);
                    
                    [mainTable reloadData];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"exceptions: %@", exception);
            }
        }
}

-(void)setTwitterLiveData:(id)twitData
{
    twitterData = twitData;
    NSNumber *respCode = [(NSDictionary*)twitterData objectForKey:@"errCode"];
    
    if ([respCode intValue] == 105) {
        arrayTweet = [(NSDictionary*)twitterData objectForKey:@"tweet"]; 
        [mainTable reloadData];
    }
}

@end
