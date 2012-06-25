//
//  SettingInfoViewController.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SettingInfoViewController.h"

@implementation SettingInfoViewController
NSString *alertCount;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    arrayTweets = [[NSMutableArray alloc] init];
    [arrayTweets addObject:@"Never"];
    [arrayTweets addObject:@"3"];
    [arrayTweets addObject:@"4"];
    [arrayTweets addObject:@"5"];
    [arrayTweets addObject:@"6"];
    
    PickerTweetCount.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [arrayTweets count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [arrayTweets objectAtIndex:row];   
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSLog(@"select hour: %@", [arrayTweets objectAtIndex:row]);
    if ([[arrayTweets objectAtIndex:row] isEqualToString:@"Never"]) {
        alertCount = @"-1";
    } else {
        alertCount = [arrayTweets objectAtIndex:row];
    }
}


-(IBAction)UpdateSetting:(id)sender
{
    alertView = [self upadetSettings];    
    [alertView show];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *token = [prefs objectForKey:@"DeviceToken"];
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    [RKClient setSharedClient:client];
    NSString *udid = [UIDevice currentDevice].uniqueIdentifier;            
    NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                            @"deviceid", udid,
                            @"alertCount", alertCount,
                            @"deviceToken", token,
                            @"maxDistance", @"4",
                            nil];    
    NSString *twitCountReq = [@"users/preferences/update" appendQueryParams:params];
    
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(popOutFromSettingView) userInfo:nil repeats: NO];
    [[RKClient sharedClient]  get:twitCountReq delegate:self];
}

-(UIAlertView *) upadetSettings
{
    UIAlertView *alerts = [[UIAlertView alloc]   
                           initWithTitle:@"Updating your settings \n Please wait..."  
                           message:nil delegate:nil cancelButtonTitle:nil  
                           otherButtonTitles:nil];  
    
   UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]  
                 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];  
    
    indicator.frame = CGRectMake(135, 70, 20, 20);
    [indicator startAnimating];  
    [alerts addSubview:indicator]; 
    [alerts show];
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];  
    return alerts;
    
}

-(void)popOutFromSettingView { 
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    [self.navigationController popViewControllerAnimated:YES];    
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    @try {
        if ([request isGET]) {
            NSLog(@" %@", [response bodyAsString]);
        }
    }  @catch (NSException *exception) {
        NSLog( @"Exception while getting unique IDs from TP Server response: %@", exception);
    } 
}

@end
