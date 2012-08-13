//
//  SettingInfoViewController.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SettingInfoViewController.h"
#import "nc_AppDelegate.h"
#import "UserPreferance.h"
#if FLURRY_ENABLED
#include "Flurry.h"
#endif

#define SETTING_TITLE       @"App Settings"
#define SETTING_ALERT_MSG   @"Updating your settings \n Please wait..."
#define WALK_DISTANCE       @"walkDistance"
#define TRIGGER_AT_HOUR     @"triggerAtHour"
#define PUSH_ENABLE         @"pushEnable"
#define PUSH_NOTIFY_OFF     -1

@implementation SettingInfoViewController

@synthesize sliderMaxWalkDistance;
@synthesize sliderPushNotification;

int pushHour;
bool isPush;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[self navigationItem] setTitle:SETTING_TITLE];
        
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
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [UIColor colorWithRed:98.0/256.0 green:96.0/256.0 blue:96.0/256.0 alpha:1.0], UITextAttributeTextColor,
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
    [self fetchUserSettingData];
#if FLURRY_ENABLED
    [Flurry logEvent: FLURRY_SETTINGS_APPEAR];
#endif
    btnUpdateSetting.layer.cornerRadius = CORNER_RADIUS_SMALL;
}

-(IBAction)UpdateSetting:(id)sender
{
    @try {
        if (!switchPushEnable.on) {
            // set -1 for stop getting push notification
            pushHour = PUSH_NOTIFY_OFF;
            isPush = NO;
        } else {
            isPush = YES;
        }   
        alertView = [self upadetSettings];    
        [alertView show];
        
        // Update in user defaults
        float ss = sliderPushNotification.value;

        UserPreferance *userPrefs = [UserPreferance userPreferance]; // get singleton
        userPrefs.pushEnable = [NSNumber numberWithBool:isPush];
        userPrefs.triggerAtHour = [NSNumber numberWithFloat:ss];
        userPrefs.walkDistance = [NSNumber numberWithFloat:sliderMaxWalkDistance.value];
        [userPrefs saveUpdates];

        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        NSString *token = [prefs objectForKey:DEVICE_TOKEN];
        
        // Update in TPServer DB
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
//        NSString *udid = [UIDevice currentDevice].uniqueIdentifier; 
        
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
                                ALERT_COUNT,[NSNumber numberWithInt:pushHour],
                                DEVICE_TOKEN, token,
                                MAXIMUM_WALK_DISTANCE,[NSNumber numberWithFloat:sliderMaxWalkDistance.value],
                                nil];
        NSString *twitCountReq = [UPDATE_SETTING_REQ appendQueryParams:params];
        NSLog(@" - - -  - - - - - %@", twitCountReq);
        [[RKClient sharedClient]  get:twitCountReq delegate:self];
        
         [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(popOutFromSettingView) userInfo:nil repeats: NO];
    }
    @catch (NSException *exception) {
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        [self.navigationController popViewControllerAnimated:YES];
         NSLog(@"exception at upadting Setting : %@", exception);
    }
}

-(IBAction)sliderWalkDistanceValueChanged:(UISlider *)sender
{
    float walkDistance = sliderMaxWalkDistance.value;
    [sliderMaxWalkDistance setValue:sliderMaxWalkDistance.value];
    [sliderMaxWalkDistance setSelected:YES];
    NSLog(@"walk distance: %f", walkDistance);
}

-(IBAction)sliderPushNotification:(UISlider *)sender
{
    int walkDistance = sliderPushNotification.value;
    [sliderPushNotification setValue:sliderPushNotification.value];
    [sliderPushNotification setSelected:YES];
    pushHour = walkDistance;
    NSLog(@"walk distance: %d", walkDistance);
}

-(void)popOutFromSettingView { 
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    [self.navigationController popViewControllerAnimated:YES]; 
    [self.tabBarController setSelectedIndex:0];
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    @try {
        if ([request isGET]) {
            NSLog(@"response for userUpdateSettings:  %@", [response bodyAsString]);
        }
    }  @catch (NSException *exception) {
        NSLog( @"Exception while getting unique IDs from TP Server response: %@", exception);
    } 
}

-(UIAlertView *) upadetSettings
{    
    UIAlertView *alerts = [[UIAlertView alloc]   
                           initWithTitle:SETTING_ALERT_MSG  
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

-(void)fetchUserSettingData
{
    @try {

        // set stored value for userSettings 
        
        UserPreferance* userPrefs = [UserPreferance userPreferance]; // get singleton
        [sliderMaxWalkDistance setValue:[[userPrefs walkDistance] doubleValue]];
        [sliderPushNotification setValue:[[userPrefs triggerAtHour] doubleValue]];
        pushHour = [[userPrefs triggerAtHour] intValue];
        if ([[userPrefs pushEnable] intValue] == 0) {
            [switchPushEnable setOn:NO];
        } else {
            [switchPushEnable setOn:YES];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at fetch data from core data and set to views: %@",exception);
    }
}

@end