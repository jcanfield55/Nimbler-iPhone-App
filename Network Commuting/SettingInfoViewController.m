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
@synthesize switchEnableUrgentSound;
@synthesize switchEnableStandardSound;
@synthesize enableUrgentSoundFlag;
@synthesize enableStandardSoundFlag;
@synthesize switchPushEnable;
@synthesize btnUpdateSetting;
@synthesize lblSliderMaxWalkDistanceValue;

int pushHour;
bool isPush;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //[[self navigationItem] setTitle:SETTING_TITLE];
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
//    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
//        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
//    }
//    else {
//        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_navigationbar.png"]] aboveSubview:self.navigationController.navigationBar];
//    }
    UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
    [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
    lblNavigationTitle.text=SETTING_VIEW_TITLE;
    lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
    [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
    lblNavigationTitle.backgroundColor =[UIColor clearColor];
    lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
    self.navigationItem.titleView=lblNavigationTitle;
    
    lblSliderMaxWalkDistanceValue = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, LABEL_MAXWALK_Distance_WIDTH, LABEL_MAXWALK_Distance_HEIGHT)] ;
    [lblSliderMaxWalkDistanceValue setTextColor:[UIColor redColor]];
    [lblSliderMaxWalkDistanceValue setBackgroundColor:[UIColor clearColor]];
    [lblSliderMaxWalkDistanceValue setTextAlignment:UITextAlignmentCenter];
    [self.sliderMaxWalkDistance addSubview:lblSliderMaxWalkDistanceValue];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.sliderMaxWalkDistance = nil;
    self.switchPushEnable = nil;
    self.btnUpdateSetting = nil;
    self.sliderPushNotification = nil;
    self.switchEnableUrgentSound = nil;
    self.switchEnableStandardSound = nil;
}

- (void)dealloc{
    self.sliderMaxWalkDistance = nil;
    self.switchPushEnable = nil;
    self.btnUpdateSetting = nil;
    self.sliderPushNotification = nil;
    self.switchEnableUrgentSound = nil;
    self.switchEnableStandardSound = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self fetchUserSettingData];
#if FLURRY_ENABLED
    [Flurry logEvent: FLURRY_SETTINGS_APPEAR];
#endif
    btnUpdateSetting.layer.cornerRadius = CORNER_RADIUS_SMALL;
}

- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [self saveSetting];
}

- (void) saveSetting{
    @try {
        if (!switchPushEnable.on) {
            // set -1 for stop getting push notification
            pushHour = PUSH_NOTIFY_OFF;
            isPush = NO;
        } else {
            isPush = YES;
        }   
        if(self.switchEnableUrgentSound.on){
            enableUrgentSoundFlag = 1;
        }
        else{
            enableUrgentSoundFlag = 2;
        }
        if(self.switchEnableStandardSound.on){
            enableStandardSoundFlag = 1;
        }
        else{
            enableStandardSoundFlag = 2;
        }
        [[NSUserDefaults standardUserDefaults] setInteger:enableUrgentSoundFlag forKey:ENABLE_URGENTNOTIFICATION_SOUND];
        [[NSUserDefaults standardUserDefaults] setInteger:enableStandardSoundFlag forKey:ENABLE_STANDARDNOTIFICATION_SOUND];
        [[NSUserDefaults standardUserDefaults] synchronize];
       // alertView = [self upadetSettings];    
        //[alertView show];
        
        // Update in user defaults
        float ss = sliderPushNotification.value;
        int alertFrequencyIntValue = ss;
        
        UserPreferance *userPrefs = [UserPreferance userPreferance]; // get singleton
        userPrefs.pushEnable = [NSNumber numberWithBool:isPush];
        userPrefs.triggerAtHour = [NSNumber numberWithInt:alertFrequencyIntValue];
        userPrefs.walkDistance = [NSNumber numberWithFloat:sliderMaxWalkDistance.value];
        [userPrefs saveUpdates];
        
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        NSString *token = [prefs objectForKey:DEVICE_TOKEN];
       
        // Update in TPServer DB
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
                                ALERT_COUNT,[NSNumber numberWithInt:pushHour],
                                DEVICE_TOKEN, token,
                                MAXIMUM_WALK_DISTANCE,[NSNumber numberWithFloat:sliderMaxWalkDistance.value],ENABLE_URGENTNOTIFICATION_SOUND,[NSNumber numberWithInt:enableUrgentSoundFlag],ENABLE_STANDARDNOTIFICATION_SOUND,[NSNumber numberWithInt:enableStandardSoundFlag],
                                nil];
        NSString *twitCountReq = [UPDATE_SETTING_REQ appendQueryParams:params];
        NSLog(@" - - -  - - - - - %@", twitCountReq);
        [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = NO;
        [[RKClient sharedClient]  get:twitCountReq delegate:self];
        
#if FLURRY_ENABLED
        NSDictionary *flurryParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                      FLURRY_SETTING_WALK_DISTANCE,
                                      [NSString stringWithFormat:@"%f",sliderMaxWalkDistance.value],
                                      FLURRY_SETTING_ALERT_COUNT,
                                      [NSString stringWithFormat:@"%d",pushHour],
                                      nil];
        [Flurry logEvent: FLURRY_ROUTE_REQUESTED withParameters:flurryParams];
#endif
        
        //[NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(popOutFromSettingView) userInfo:nil repeats: NO];
    }
    @catch (NSException *exception) {
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        [self.navigationController popViewControllerAnimated:YES];
        NSLog(@"exception at upadting Setting : %@", exception);
    }
}


-(IBAction)UpdateSetting:(id)sender
{
}

// Methods Added to Get The Position of Thumb
- (float)mapValueInIntervalInPercents: (float)value min: (float)minimum max: (float)maximum{
    return (100 / (maximum - minimum)) * value -
    (100 * minimum)/(maximum - minimum);
}

- (float)xPositionFromSliderValue:(UISlider *)aSlider{
    float percent = [self mapValueInIntervalInPercents: aSlider.value
                                                   min: aSlider.minimumValue
                                                   max: aSlider.maximumValue] / 100.0;
    
    return percent * aSlider.frame.size.width -
    percent * aSlider.currentThumbImage.size.width +
    aSlider.currentThumbImage.size.width / 2;
}


-(IBAction)sliderWalkDistanceValueChanged:(UISlider *)sender
{
    [sliderMaxWalkDistance setValue:sliderMaxWalkDistance.value];
    [sliderMaxWalkDistance setSelected:YES];
    float sliderXPOS = [self xPositionFromSliderValue:sliderMaxWalkDistance];
    lblSliderMaxWalkDistanceValue.center = CGPointMake(sliderXPOS, 30);
    lblSliderMaxWalkDistanceValue.text = [NSString stringWithFormat:@"%0.2f", sliderMaxWalkDistance.value];
}

-(IBAction)sliderPushNotification:(UISlider *)sender
{
    int walkDistance = lroundf(sliderPushNotification.value);
    [sliderPushNotification setValue:walkDistance];
    [sliderPushNotification setSelected:YES];
    pushHour = walkDistance;
    NSLog(@"walk distance: %d", walkDistance);
}

-(void)popOutFromSettingView { 
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    // Code Added to select Trip Planner Tab
    RXCustomTabBar *rxCustomTabBar = (RXCustomTabBar *)self.tabBarController;
    [rxCustomTabBar selectTab:0];
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response { 
    RKJSONParserJSONKit* rkTwitDataParser = [RKJSONParserJSONKit new];
    @try {
        if ([request isGET]) {
            id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];
            NSNumber *respCode = [(NSDictionary*)res objectForKey:CODE];
            if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = YES;
            }
            else{
                [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = NO;
            }
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
        
        if([[NSUserDefaults standardUserDefaults] integerForKey:ENABLE_URGENTNOTIFICATION_SOUND] == 1){
            [switchEnableUrgentSound setOn:YES];
        }
        else if([[NSUserDefaults standardUserDefaults] integerForKey:ENABLE_URGENTNOTIFICATION_SOUND] == 0){
            [switchEnableUrgentSound setOn:YES];
        }
        else{
           [switchEnableUrgentSound setOn:NO]; 
        }
        
        if([[NSUserDefaults standardUserDefaults] integerForKey:ENABLE_STANDARDNOTIFICATION_SOUND] == 1){
            [switchEnableStandardSound setOn:YES];
        }
        else if([[NSUserDefaults standardUserDefaults] integerForKey:ENABLE_STANDARDNOTIFICATION_SOUND] == 0){
            [switchEnableStandardSound setOn:NO];
        }
        else{
            [switchEnableStandardSound setOn:NO]; 
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at fetch data from core data and set to views: %@",exception);
    }
}

@end