//
//  SettingInfoViewController.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/25/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "SettingInfoViewController.h"
#import "nc_AppDelegate.h"
#import "UserPreferance.h"
#import "UtilityFunctions.h"

#define SETTING_TITLE       @"App Settings"
#define SETTING_ALERT_MSG   @"Updating your settings \n Please wait..."
#define WALK_DISTANCE       @"walkDistance"
#define TRIGGER_AT_HOUR     @"triggerAtHour"
#define PUSH_ENABLE         @"pushEnable"

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
@synthesize pushHour;
@synthesize isPush;
@synthesize tblSetting;
@synthesize scrollView;
@synthesize switchPushNotification;
@synthesize sliderPushNotificationFrequency;
@synthesize lblFrequencyOfPush;
@synthesize lblMaximumWalkDistance;
@synthesize sliderMaximumWalkDistance;
@synthesize lblFrequently;
@synthesize lblRarely;
@synthesize lblMinWalkDistance;
@synthesize lblMaxWalkDistance;
@synthesize lblCurrentMaxWalkDistance;
@synthesize settingDetailViewController;

UIImage *imageDetailDisclosure;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
        
        switchPushNotification = [[UISwitch alloc] init];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [switchPushNotification setOnTintColor:[UIColor lightGrayColor]];
        }
         [switchPushNotification addTarget:self action:@selector(switchValueChanged) forControlEvents:UIControlEventValueChanged];
        lblFrequently=[[UILabel alloc] initWithFrame:CGRectMake(LABEL_FREQUENTLY_XPOS,LABEL_FREQUENTLY_YPOS, LABEL_FREQUENTLY_WIDTH, LABEL_FREQUENTLY_HEIGHT)];
        [lblFrequently setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblFrequently.backgroundColor =[UIColor clearColor];
        lblFrequently.adjustsFontSizeToFitWidth=YES;
        lblFrequently.text= LABEL_FREQUENTLY;
        [lblFrequently setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblRarely=[[UILabel alloc] initWithFrame:CGRectMake(LABEL_RARELY_XPOS,LABEL_RARELY_YPOS,LABEL_RARELY_WIDTH,LABEL_RARELY_HEIGHT)];
        [lblRarely setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblRarely.backgroundColor =[UIColor clearColor];
        lblRarely.adjustsFontSizeToFitWidth=YES;
        lblRarely.text= LABEL_RARELY;
        [lblRarely setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        sliderPushNotificationFrequency = [[UISlider alloc] initWithFrame:CGRectMake(SLIDER_PUSH_FREQUENCY_XPOS,SLIDER_PUSH_FREQUENCY_YPOS,SLIDER_PUSH_FREQUENCY_WIDTH,SLIDER_PUSH_FREQUENCY_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderPushNotificationFrequency
             setMinimumTrackTintColor:[UIColor lightGrayColor]];
        }
        [sliderPushNotificationFrequency setMinimumValue:PUSH_FREQUENCY_MIN_VALUE];
        [sliderPushNotificationFrequency setMaximumValue:PUSH_FREQUENCY_MAX_VALUE];
        if([[NSUserDefaults standardUserDefaults] objectForKey:PREFS_PUSH_NOTIFICATION_THRESHOLD]){
            [sliderPushNotificationFrequency setValue:[[[NSUserDefaults standardUserDefaults] objectForKey:PREFS_PUSH_NOTIFICATION_THRESHOLD] floatValue]];
        }
        else{
            [sliderPushNotificationFrequency setValue:PUSH_FREQUENCY_DEFAULT_VALUE];
        }
        
        [sliderPushNotificationFrequency addTarget:self action:@selector(pushNotificationValueChanged:) forControlEvents:UIControlEventTouchUpInside];
        
        
        lblFrequencyOfPush=[[UILabel alloc] initWithFrame:CGRectMake(SETTING_MAIN_LABEL_XPOS,SETTING_MAIN_LABEL_YPOS,SETTING_MAIN_LABEL_WIDTH,SETTING_MAIN_LABEL_HEIGHT)];
        [lblFrequencyOfPush setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        lblFrequencyOfPush.backgroundColor =[UIColor clearColor];
        lblFrequencyOfPush.adjustsFontSizeToFitWidth=YES;
        lblFrequencyOfPush.text=FREQUENCY_OF_PUSH;
        [lblFrequencyOfPush setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        lblMaximumWalkDistance=[[UILabel alloc] initWithFrame:CGRectMake(SETTING_MAIN_LABEL_XPOS,SETTING_MAIN_LABEL_YPOS,SETTING_MAIN_LABEL_WIDTH,SETTING_MAIN_LABEL_HEIGHT)];
        [lblMaximumWalkDistance setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        lblMaximumWalkDistance.backgroundColor =[UIColor clearColor];
        lblMaximumWalkDistance.adjustsFontSizeToFitWidth=YES;
        lblMaximumWalkDistance.text=MAXIMUM_WALK_DISTANCE_LABEL;
        [lblMaximumWalkDistance setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        lblMinWalkDistance=[[UILabel alloc] initWithFrame:CGRectMake(SETTING_SUB_LABEL_XPOS,SETTING_SUB_LABEL_YPOS,SETTING_SUB_LABEL_WIDTH,SETTING_SUB_LABEL_HEIGHT)];
        [lblMinWalkDistance setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblMinWalkDistance.backgroundColor =[UIColor clearColor];
        lblMinWalkDistance.adjustsFontSizeToFitWidth=YES;
        lblMinWalkDistance.text= [NSString stringWithFormat:@"%0.2f",MAX_WALK_DISTANCE_MIN_VALUE];
        [lblMinWalkDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblMaxWalkDistance=[[UILabel alloc] initWithFrame:CGRectMake(SETTING_SUB_LABEL_XPOS1,SETTING_SUB_LABEL_YPOS,SETTING_SUB_LABEL_WIDTH,SETTING_SUB_LABEL_HEIGHT)];
        [lblMaxWalkDistance setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblMaxWalkDistance.backgroundColor =[UIColor clearColor];
        lblMaxWalkDistance.adjustsFontSizeToFitWidth=YES;
        lblMaxWalkDistance.text= [NSString stringWithFormat:@"%0.2f",MAX_WALK_DISTANCE_MAX_VALUE];
        [lblMaxWalkDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        sliderMaximumWalkDistance = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS,SLIDERS_YPOS, SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderMaximumWalkDistance
             setMinimumTrackTintColor:[UIColor lightGrayColor]];
        }
        [sliderMaximumWalkDistance setMinimumValue:MAX_WALK_DISTANCE_MIN_VALUE];
        [sliderMaximumWalkDistance setMaximumValue:MAX_WALK_DISTANCE_MAX_VALUE];
        if([[NSUserDefaults standardUserDefaults] objectForKey:PREFS_MAX_WALK_DISTANCE]){
            [sliderMaximumWalkDistance setValue:[[[NSUserDefaults standardUserDefaults] objectForKey:PREFS_MAX_WALK_DISTANCE] floatValue]];
        }
        else{
            [sliderMaximumWalkDistance setValue:MAX_WALK_DISTANCE_DEFAULT_VALUE];
        }
        [sliderMaximumWalkDistance addTarget:self action:@selector(sliderWalkDistance:) forControlEvents:UIControlEventValueChanged];
        
        lblCurrentMaxWalkDistance = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, LABEL_MAXWALK_Distance_WIDTH, LABEL_MAXWALK_Distance_HEIGHT)] ;
        [lblCurrentMaxWalkDistance setTextColor:[UIColor redColor]];
        [lblCurrentMaxWalkDistance setBackgroundColor:[UIColor clearColor]];
        [lblCurrentMaxWalkDistance setTextAlignment:UITextAlignmentCenter];
        [lblCurrentMaxWalkDistance setFont:[UIFont MEDIUM_FONT]];
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
    self.tblSetting.delegate = self;
    self.tblSetting.dataSource = self;
    [self.tblSetting setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_background.png"]]];
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
    }
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
    if([[[NSUserDefaults standardUserDefaults] objectForKey:PREFS_IS_PUSH_ENABLE] intValue] == 1){
        [switchPushNotification setOn:YES];
    }
    else{
        [switchPushNotification setOn:NO];
    }
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
    //[scrollView setFrame:CGRectMake(0,0,320,480)];
    [scrollView setContentSize:CGSizeMake(320,1075)];
    [nc_AppDelegate sharedInstance].isSettingView = YES;
    [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = NO;
    [self fetchUserSettingData];
    logEvent(FLURRY_SETTINGS_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
    
    btnUpdateSetting.layer.cornerRadius = CORNER_RADIUS_SMALL;
}

- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [nc_AppDelegate sharedInstance].isSettingView = NO;
    if(!settingDetailViewController.isSettingDetail){
        [self saveSetting];
    }
    
}

- (void) saveSetting{
    @try {
//        if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
//            if (!switchPushEnable.on) {
//                // set -1 for stop getting push notification
//                pushHour = PUSH_NOTIFY_OFF;
//                isPush = NO;
//            } else {
//                isPush = YES;
//            }
//            if(self.switchEnableUrgentSound.on){
//                enableUrgentSoundFlag = 1;
//            }
//            else{
//                enableUrgentSoundFlag = 2;
//            }
//            if(self.switchEnableStandardSound.on){
//                enableStandardSoundFlag = 1;
//            }
//            else{
//                enableStandardSoundFlag = 2;
//            }
//            [[NSUserDefaults standardUserDefaults] setInteger:enableUrgentSoundFlag forKey:ENABLE_URGENTNOTIFICATION_SOUND];
//            [[NSUserDefaults standardUserDefaults] setInteger:enableStandardSoundFlag forKey:ENABLE_STANDARDNOTIFICATION_SOUND];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//            // alertView = [self upadetSettings];
//            //[alertView show];
//            
//            // Update in user defaults
//            float ss = sliderPushNotification.value;
//            int alertFrequencyIntValue = ss;
//            
//            UserPreferance *userPrefs = [UserPreferance userPreferance]; // get singleton
//            userPrefs.pushEnable = [NSNumber numberWithBool:isPush];
//            userPrefs.triggerAtHour = [NSNumber numberWithInt:alertFrequencyIntValue];
//            userPrefs.walkDistance = [NSNumber numberWithFloat:sliderMaxWalkDistance.value];
//            // US 161 Implementation
//            if(![[[NSUserDefaults standardUserDefaults] objectForKey:PREFS_MAX_WALK_DISTANCE] isEqual:userPrefs.walkDistance]){
//                PlanStore *planStrore = [[nc_AppDelegate sharedInstance] planStore];
//                [planStrore  clearCache];
//            }
//            
//            [userPrefs saveUpdates];
//            
//            NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
//            NSString *token = [prefs objectForKey:DEVICE_TOKEN];
//            // Update in TPServer DB
//            RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
//            [RKClient setSharedClient:client];
//            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
//                                    DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
//                                    ALERT_COUNT,[NSNumber numberWithInt:pushHour],
//                                    DEVICE_TOKEN, token,
//                                    MAXIMUM_WALK_DISTANCE,[NSNumber numberWithFloat:sliderMaxWalkDistance.value],ENABLE_URGENTNOTIFICATION_SOUND,[NSNumber numberWithInt:enableUrgentSoundFlag],ENABLE_STANDARDNOTIFICATION_SOUND,[NSNumber numberWithInt:enableStandardSoundFlag],APPLICATION_TYPE,[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],
//                                    nil];
//            NSString *twitCountReq = [UPDATE_SETTING_REQ appendQueryParams:params];
//            NIMLOG_EVENT1(@" twitCountReq %@", twitCountReq);
//            [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = NO;
//            [[RKClient sharedClient]  get:twitCountReq delegate:self];
//            
//            logEvent(FLURRY_SETTINGS_SUBMITTED,
//                     FLURRY_SETTING_WALK_DISTANCE, [NSString stringWithFormat:@"%f",sliderMaxWalkDistance.value],
//                     FLURRY_SETTING_ALERT_COUNT, [NSString stringWithFormat:@"%d",pushHour],
//                     nil, nil, nil, nil);
//        }
//        else{
            if (!switchPushNotification.on) {
                // set -1 for stop getting push notification
                pushHour = PUSH_NOTIFY_OFF;
                isPush = NO;
            } else {
                isPush = YES;
            }
            float ss = sliderPushNotificationFrequency.value;
            int alertFrequencyIntValue = ss;
            UserPreferance *userPrefs = [UserPreferance userPreferance]; // get singleton
            userPrefs.pushEnable = [NSNumber numberWithBool:isPush];
            userPrefs.triggerAtHour = [NSNumber numberWithInt:alertFrequencyIntValue];
            userPrefs.walkDistance = [NSNumber numberWithFloat:sliderMaximumWalkDistance.value];
            // US 161 Implementation
            if(![[[NSUserDefaults standardUserDefaults] objectForKey:PREFS_MAX_WALK_DISTANCE] isEqual:userPrefs.walkDistance]){
                PlanStore *planStrore = [[nc_AppDelegate sharedInstance] planStore];
                [planStrore  clearCache];
            }
            
            [userPrefs saveUpdates];
            NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
            NSString *token = [prefs objectForKey:DEVICE_TOKEN];
            // Update in TPServer DB
            RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
            [RKClient setSharedClient:client];
//            NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
//                                    DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
//                                    ALERT_COUNT,[NSNumber numberWithInt:pushHour],
//                                    DEVICE_TOKEN, token,
//                                    MAXIMUM_WALK_DISTANCE,[NSNumber numberWithFloat:sliderMaximumWalkDistance.value],ENABLE_URGENTNOTIFICATION_SOUND,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_URGENTNOTIFICATION_SOUND],ENABLE_STANDARDNOTIFICATION_SOUND,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_STANDARDNOTIFICATION_SOUND],ENABLE_SFMUNI_ADV,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV],ENABLE_BART_ADV,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV],ENABLE_ACTRANSIT_ADV,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV],ENABLE_CALTRAIN_ADV,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV],NOTIF_TIMING_MORNING,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MORNING],NOTIF_TIMING_MIDDAY,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MIDDAY],NOTIF_TIMING_EVENING,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_EVENING],NOTIF_TIMING_NIGHT,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_NIGHT],NOTIF_TIMING_WEEKEND,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_WEEKEND],TRANSIT_MODE_SELECTED,[[NSUserDefaults standardUserDefaults] objectForKey:TRANSIT_MODE_SELECTED],MAX_BIKE_DISTANCE,[[NSUserDefaults standardUserDefaults] objectForKey:MAX_BIKE_DISTANCE],BIKE_TRIANGLE_FLAT,[[NSUserDefaults standardUserDefaults] objectForKey:BIKE_TRIANGLE_FLAT],BIKE_TRIANGLE_BIKE_FRIENDLY,[[NSUserDefaults standardUserDefaults] objectForKey:BIKE_TRIANGLE_BIKE_FRIENDLY],BIKE_TRIANGLE_QUICK,[[NSUserDefaults standardUserDefaults] objectForKey:BIKE_TRIANGLE_QUICK],APPLICATION_TYPE,[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],
//                                    nil];
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                                DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
                                ALERT_COUNT,[NSNumber numberWithInt:pushHour],
                                DEVICE_TOKEN, token,
                                MAXIMUM_WALK_DISTANCE,[NSNumber numberWithFloat:sliderMaximumWalkDistance.value],ENABLE_URGENTNOTIFICATION_SOUND,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_URGENTNOTIFICATION_SOUND],ENABLE_STANDARDNOTIFICATION_SOUND,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_STANDARDNOTIFICATION_SOUND],ENABLE_SFMUNI_ADV,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV],ENABLE_BART_ADV,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV],ENABLE_ACTRANSIT_ADV,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV],ENABLE_CALTRAIN_ADV,[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV],NOTIF_TIMING_MORNING,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MORNING],NOTIF_TIMING_MIDDAY,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MIDDAY],NOTIF_TIMING_EVENING,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_EVENING],NOTIF_TIMING_NIGHT,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_NIGHT],NOTIF_TIMING_WEEKEND,[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_WEEKEND],
                                APPLICATION_TYPE,[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],
                                nil];
            NSString *twitCountReq = [UPDATE_SETTING_REQ appendQueryParams:params];
            NIMLOG_EVENT1(@" twitCountReq %@", twitCountReq);
            [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = NO;
            [[RKClient sharedClient]  get:twitCountReq delegate:self];
            
            logEvent(FLURRY_SETTINGS_SUBMITTED,
                     FLURRY_SETTING_WALK_DISTANCE, [NSString stringWithFormat:@"%f",sliderMaxWalkDistance.value],
                     FLURRY_SETTING_ALERT_COUNT, [NSString stringWithFormat:@"%d",pushHour],
                     nil, nil, nil, nil);
            
        //}
    }
    @catch (NSException *exception) {
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        [self.navigationController popViewControllerAnimated:YES];
        logException(@"SettingInfoViewController->saveSetting", @"", exception);
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
    // Fixed DE-209
    lblSliderMaxWalkDistanceValue.center = CGPointMake(sliderXPOS, -10);
    lblSliderMaxWalkDistanceValue.text = [NSString stringWithFormat:@"%0.2f", sliderMaxWalkDistance.value];
}

-(IBAction)sliderWalkDistance:(UISlider *)sender
{
    [sliderMaximumWalkDistance setValue:sliderMaximumWalkDistance.value];
    [sliderMaximumWalkDistance setSelected:YES];
    float sliderXPOS = [self xPositionFromSliderValue:sliderMaximumWalkDistance];
    // Fixed DE-209
    lblCurrentMaxWalkDistance.center = CGPointMake(sliderXPOS, -10);
    lblCurrentMaxWalkDistance.text = [NSString stringWithFormat:@"%0.2f", sliderMaximumWalkDistance.value];
}

-(IBAction)sliderPushNotification:(UISlider *)sender
{
    int pushNotificationThreshold = lroundf(sliderPushNotification.value);
    [sliderPushNotification setValue:pushNotificationThreshold];
    [sliderPushNotification setSelected:YES];
    pushHour = pushNotificationThreshold;
    NIMLOG_EVENT1(@"walk distance: %d", pushNotificationThreshold);
}

-(IBAction)pushNotificationValueChanged:(UISlider *)sender
{
    int pushNotificationThreshold = lroundf(sliderPushNotificationFrequency.value);
    [sliderPushNotificationFrequency setValue:pushNotificationThreshold];
    [sliderPushNotificationFrequency setSelected:YES];
    pushHour = pushNotificationThreshold;
    NIMLOG_EVENT1(@"walk distance: %d", pushNotificationThreshold);
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
            NSNumber *respCode = [(NSDictionary*)res objectForKey:RESPONSE_CODE];
            if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = YES;
            }
            else{
                [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = NO;
            }
            NIMLOG_EVENT1(@"response for userUpdateSettings:  %@", [response bodyAsString]);
        }
    }  @catch (NSException *exception) {
        logException(@"SettingInfoViewController->didLoadResponse", @"while getting unique IDs from TP Server response", exception);
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
        logException(@"SettingInfoViewController->fetchUserSettingData", @"", exception);
    }
}

- (NSString *)detailtextLabelString:(NSIndexPath *)indexPath{
    NSString *strDetailTextLabel = @"";
    if(indexPath.section == 0){
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
            strDetailTextLabel = LABEL_ALL;
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 2 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 2 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 2 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 2){
            strDetailTextLabel = LABEL_NONE;
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@ + %@",LABEL_SFMUNI,LABEL_BART,LABEL_ACTRANSIT];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@ + %@",LABEL_SFMUNI,LABEL_BART,LABEL_CALTRAIN];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@ + %@",LABEL_SFMUNI,LABEL_ACTRANSIT,LABEL_CALTRAIN];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@ + %@",LABEL_BART,LABEL_ACTRANSIT,LABEL_CALTRAIN];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@",LABEL_SFMUNI,LABEL_BART];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@",LABEL_SFMUNI,LABEL_ACTRANSIT];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@",LABEL_SFMUNI,LABEL_CALTRAIN];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@",LABEL_BART,LABEL_ACTRANSIT];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@",LABEL_BART,LABEL_CALTRAIN];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1 && [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ + %@",LABEL_ACTRANSIT,LABEL_CALTRAIN];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ Only",LABEL_SFMUNI];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ Only",LABEL_BART];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ Only",LABEL_ACTRANSIT];
        }
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
            strDetailTextLabel = [NSString stringWithFormat:@"%@ Only",LABEL_CALTRAIN];
        }
    }
    else if(indexPath.section == 1){
        if(indexPath.row == 3){
            NSString *strTimeMorning = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MORNING];
            NSString *strTimeMidday = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MIDDAY];
            NSString *strTimeEvening = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_EVENING];
            NSString *strTimeNight = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_NIGHT];
            NSString *strTimeWeekdends = [[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_WEEKEND];
            if([ strTimeMorning intValue] == 1 && [strTimeMidday intValue] == 1 && [strTimeEvening intValue] == 1 && [strTimeNight intValue] == 1 && [strTimeWeekdends intValue] == 1){
                strDetailTextLabel = LABEL_ALL;
            }
            else if([ strTimeMorning intValue] == 2 && [strTimeMidday intValue] == 2 && [strTimeEvening intValue] == 2 && [strTimeNight intValue] == 2 && [strTimeWeekdends intValue] == 2){
                strDetailTextLabel = LABEL_NO_NOTIFICATIONS;
            }
            else if([strTimeMorning intValue] == 1 && [strTimeMidday intValue] == 1 && [strTimeEvening intValue] == 1 && [strTimeNight intValue] == 1){
                strDetailTextLabel = LABEL_WKDAY_ALL;
            }
            else if([strTimeMorning intValue] != 1 && [strTimeMidday intValue] != 1 && [strTimeEvening intValue] != 1 && [strTimeNight intValue] != 1 && [strTimeWeekdends intValue] == 1){
                strDetailTextLabel = LABEL_WEEKENDS;
            }
            else{
                NSArray *arrayFlags = [NSArray arrayWithObjects:strTimeMorning,strTimeMidday,strTimeEvening,strTimeNight,strTimeWeekdends, nil];
                NSArray *arrayStringToAppend = [NSArray arrayWithObjects:LABEL_MORNING,LABEL_MIDDAY,LABEL_EVENING,LABEL_NIGHT,LABEL_WKENDS, nil];
                NSMutableString *strMutableTextLabel = [[NSMutableString alloc] init];
                [strMutableTextLabel appendString:LABEL_WKKDAY];
                for(int i = 0;i < [arrayFlags count]; i++){
                    if([[arrayFlags objectAtIndex:i] intValue] == 1){
                        [strMutableTextLabel appendFormat:@" %@,",[arrayStringToAppend objectAtIndex:i]];
                    }
                }
                int nLength = [strMutableTextLabel length];
                strDetailTextLabel = [strMutableTextLabel substringToIndex:nLength-1];
            }
        }
    }
    return strDetailTextLabel;
}

//------------------------------------------------------------------------

#pragma mark
#pragma mark UITableView delegate and datasource methods

//-------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//    if(section == 0){
//        return ADVISORY_CHOICES;
//    }
//    else if(section == 1){
//        return PUSH_NOTIFICATION;
//    }
//    else{
//        return WALK_BIKE_SETTINGS;
//    }
//    
//}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 0){
        return 1;
    }
    else if(section == 1){
        if(!switchPushNotification.isOn){
            return 1;
        }
        else{
            return 4;
        }
    }
    else{
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if((indexPath.section == 1 && indexPath.row == 1) || (indexPath.section == 2 && indexPath.row == 0)){
        return 80;
    }
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d",indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell = nil;
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if(indexPath.section == 0 || (indexPath.section == 1 && (indexPath.row == 2 || indexPath.row == 3)) || (indexPath.section == 2 && (indexPath.row == 0 || indexPath.row == 2))){
        UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithImage:imageDetailDisclosure];
        [cell setAccessoryView:imgViewDetailDisclosure];
    }
    [cell.textLabel setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
    [cell.textLabel setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
    [cell.detailTextLabel setTextColor:[UIColor GRAY_FONT_COLOR]];
    [cell.detailTextLabel setFont:[UIFont SMALL_OBLIQUE_FONT]];
    if(indexPath.section == 0){
        cell.textLabel.text = ADVISORY_CHOICES;
         cell.detailTextLabel.text = [self detailtextLabelString:indexPath];
    }
    else if(indexPath.section == 1){
        if(indexPath.row == 0){
            cell.textLabel.text = PUSH_NOTIFICATION;
            UIView* cellView = [cell accessoryView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:switchPushNotification] != NSNotFound) {
            }
            else{
                [cell setAccessoryView:switchPushNotification];
            }
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = nil;
            [cell setAccessoryView:nil];
            UIView* cellView = [cell contentView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:sliderPushNotificationFrequency] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:sliderPushNotificationFrequency];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblFrequencyOfPush] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblFrequencyOfPush];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblFrequently] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblFrequently];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblRarely] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblRarely];
            }
        }
        else if(indexPath.row == 2){
            int nUrgentNotification = [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_URGENTNOTIFICATION_SOUND] intValue];
            int nStandardNotification = [[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_STANDARDNOTIFICATION_SOUND] intValue];
            if(nUrgentNotification == 1 && nStandardNotification == 1){
                cell.detailTextLabel.text = URGENT_AND_STANDARD;
            }
            else if(nUrgentNotification == 2 && nStandardNotification == 2){
                cell.detailTextLabel.text = LABEL_NONE;
            }
            else if(nUrgentNotification == 1 && nStandardNotification == 2){
                cell.detailTextLabel.text = URGENT;
            }
            else if(nUrgentNotification == 2 && nStandardNotification == 1){
                cell.detailTextLabel.text = STANDARD;
            }
            cell.textLabel.text = NOTIFICATION_SOUND;
        }
        else if(indexPath.row == 3){
            cell.textLabel.text = NOTIFICATION_TIMING;
            cell.detailTextLabel.text = [self detailtextLabelString:indexPath];
        }
    }
    else if(indexPath.section == 2){
//        if(indexPath.row == 0){
//            NSString *strTransitMode = [[NSUserDefaults standardUserDefaults] objectForKey:TRANSIT_MODE_SELECTED];
//            cell.textLabel.text = TRANSIT_MODE;
//            if([strTransitMode intValue] == 2){
//                cell.detailTextLabel.text = TRANSIT_ONLY;
//            }
//            else if([strTransitMode intValue] == 4){
//                cell.detailTextLabel.text = BIKE_ONLY;
//            }
//            else if([strTransitMode intValue] == 5){
//                cell.detailTextLabel.text = BIKE_AND_TRANSIT;
//            }
//        }
        if(indexPath.row == 0){
            cell.textLabel.text = nil;
            [cell setAccessoryView:nil];
            UIView* cellView = [cell contentView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:sliderMaximumWalkDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:sliderMaximumWalkDistance];
                [sliderMaximumWalkDistance addSubview:lblCurrentMaxWalkDistance];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblMaximumWalkDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblMaximumWalkDistance];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblMinWalkDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblMinWalkDistance];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblMaxWalkDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblMaxWalkDistance];
            }
        }
        else if(indexPath.row == 2){
            cell.textLabel.text = BIKE_PREFERENCES;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 0 || (indexPath.section == 1 && (indexPath.row == 2 || indexPath.row == 3))){
        if([[UIScreen mainScreen] bounds].size.height == 568){
            settingDetailViewController = [[SettingDetailViewController alloc] initWithNibName:@"SettingDetailViewController_568h" bundle:nil];
        }
        else{
            settingDetailViewController = [[SettingDetailViewController alloc] initWithNibName:@"SettingDetailViewController" bundle:nil];
        }
        int nSettingRow;
        if(indexPath.section == 0){
            nSettingRow = 0;
        }
        else if(indexPath.section == 1){
            if(indexPath.row == 2){
                nSettingRow = 3;
            }
            else if(indexPath.row == 3){
                nSettingRow = 4;
            }
        }
        else{
            if(indexPath.row == 0){
                nSettingRow = 5;
            }
            else if(indexPath.row == 2){
                nSettingRow = 7;
            }
        }
        settingDetailViewController.nSettingRow = nSettingRow;
        settingDetailViewController.isSettingDetail = YES;
        settingDetailViewController.settingDetailDelegate = self;
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [self.navigationController pushViewController:settingDetailViewController animated:YES];
        }
        else{
            CATransition *animation = [CATransition animation];
            [animation setDuration:0.3];
            [animation setType:kCATransitionPush];
            [animation setSubtype:kCATransitionFromRight];
            [animation setRemovedOnCompletion:YES];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [[self.navigationController.view layer] addAnimation:animation forKey:nil];
            [[self navigationController] pushViewController:settingDetailViewController animated:NO];
        }
        
    }
}

- (void) updateSetting{
    [self saveSetting];
    [self.tblSetting reloadData];
}

- (void)switchValueChanged{
    [self.tblSetting reloadData];
}
@end