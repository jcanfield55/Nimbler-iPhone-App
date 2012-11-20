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
#import "SettingViewCustomCell.h"

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
    self.tblSetting.delegate = self;
    self.tblSetting.dataSource = self;
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
    [nc_AppDelegate sharedInstance].isSettingView = YES;
    [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = NO;
    [self fetchUserSettingData];
    logEvent(FLURRY_SETTINGS_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);

    btnUpdateSetting.layer.cornerRadius = CORNER_RADIUS_SMALL;
}

- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [nc_AppDelegate sharedInstance].isSettingView = NO;
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
      // US 161 Implementation 
        if(![[[NSUserDefaults standardUserDefaults] objectForKey:PREFS_MAX_WALK_DISTANCE] isEqual:userPrefs.walkDistance]){
            PlanStore *planStrore = [[nc_AppDelegate sharedInstance] planStore];
            [planStrore  clearCache];
        }
        
        [userPrefs saveUpdates];
        
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        NSString *token = [prefs objectForKey:DEVICE_TOKEN];
        NSString * appType;
        if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
            appType = @"1";
        }
        else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:BART_BUNDLE_IDENTIFIER]){
            appType = @"2";
        }
        if([prefs objectForKey:APPLICATION_TYPE]){
            appType = [prefs objectForKey:APPLICATION_TYPE];
        }
        // Update in TPServer DB
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                DEVICE_ID, [prefs objectForKey:DEVICE_CFUUID],
                                ALERT_COUNT,[NSNumber numberWithInt:pushHour],
                                DEVICE_TOKEN, token,
                                MAXIMUM_WALK_DISTANCE,[NSNumber numberWithFloat:sliderMaxWalkDistance.value],ENABLE_URGENTNOTIFICATION_SOUND,[NSNumber numberWithInt:enableUrgentSoundFlag],ENABLE_STANDARDNOTIFICATION_SOUND,[NSNumber numberWithInt:enableStandardSoundFlag],APPLICATION_TYPE,appType,
                                nil];
        NSString *twitCountReq = [UPDATE_SETTING_REQ appendQueryParams:params];
        NIMLOG_EVENT1(@" twitCountReq %@", twitCountReq);
        [nc_AppDelegate sharedInstance].isSettingSavedSuccessfully = NO;
        [[RKClient sharedClient]  get:twitCountReq delegate:self];
        
        logEvent(FLURRY_SETTINGS_SUBMITTED,
                 FLURRY_SETTING_WALK_DISTANCE, [NSString stringWithFormat:@"%f",sliderMaxWalkDistance.value],
                 FLURRY_SETTING_ALERT_COUNT, [NSString stringWithFormat:@"%d",pushHour],
                 nil, nil, nil, nil);
        
        //[NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(popOutFromSettingView) userInfo:nil repeats: NO];
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

-(IBAction)sliderPushNotification:(UISlider *)sender
{
    int pushNotificationThreshold = lroundf(sliderPushNotification.value);
    [sliderPushNotification setValue:pushNotificationThreshold];
    [sliderPushNotification setSelected:YES];
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

//------------------------------------------------------------------------

#pragma mark
#pragma mark UITableView delegate and datasource methods

//-------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *strHeaderTitle;
    if(section == 0){
        strHeaderTitle = ADVISORY_CHOICES;
    }
    else if(section == 1){
        strHeaderTitle = PUSH_NOTIFICATION;
    }
    else if(section == 2){
         strHeaderTitle = TRANSIT_MODE;
    }
    else if(section == 3){
        strHeaderTitle = @"";
    }
    else if(section == 4){
        strHeaderTitle = BIKE_PREFERENCES;
    }
    return strHeaderTitle;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int rowCount;
    if(section == 0){
        rowCount = 4;
    }
    else if(section == 1){
        rowCount = 4;
    }
    else if(section == 2){
        rowCount = 3;
    }
    else if(section == 3){
        rowCount = 1;
    }
    else if(section == 4){
        rowCount = 3;
    }
    return rowCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d",indexPath.row];
    SettingViewCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell){
        cell = [[SettingViewCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if(indexPath.section == 0){
        [cell.lblPushNotification setHidden:YES];
        [cell.switchPushNotification setHidden:YES];
        [cell.lblPushNotificationFrequency setHidden:YES];
        [cell.sliderPushNotificationFrequency setHidden:YES];
        [cell.lblNotificationSound setHidden:YES];
        [cell.lblNotificationTiming setHidden:YES];
        
        [cell.lblMaximumWalkDistance setHidden:YES];
        [cell.sliderMaximumWalkDistance setHidden:YES];
        
        [cell.lblMaximumBikeDistance setHidden:YES];
        [cell.sliderMaximumBikeDistance setHidden:YES];
        [cell.lblPreferenceFastVsSafe setHidden:YES];
        [cell.switchPreferenceFastVsSafe setHidden:YES];
        [cell.lblPreferenceFastVsFlat setHidden:YES];
        [cell.switchPreferenceFastVsFlat setHidden:YES];
        if(indexPath.row == 0){
            [cell.lblSFMuniAdvisories setHidden:NO];
            [cell.switchSFMuniAdvisories setHidden:NO];
        }
        else if(indexPath.row == 1){
            [cell.lblBartAdvisories setHidden:NO];
            [cell.switchBartAdvisories setHidden:NO];
        }
        else if(indexPath.row == 2){
            [cell.lblACTransitAdvisories setHidden:NO];
            [cell.switchACTransitAdvisories setHidden:NO];
        }
        else if(indexPath.row == 3){
            [cell.lblCaltrainAdvisories setHidden:NO];
            [cell.switchCaltrainAdvisories setHidden:NO];
        }
    }
    else if(indexPath.section == 1){
        [cell.lblSFMuniAdvisories setHidden:YES];
        [cell.switchSFMuniAdvisories setHidden:YES];
        [cell.lblBartAdvisories setHidden:YES];
        [cell.switchBartAdvisories setHidden:YES];
        [cell.lblACTransitAdvisories setHidden:YES];
        [cell.switchACTransitAdvisories setHidden:YES];
        [cell.lblCaltrainAdvisories setHidden:YES];
        [cell.switchCaltrainAdvisories setHidden:YES];
        
        [cell.lblMaximumWalkDistance setHidden:YES];
        [cell.sliderMaximumWalkDistance setHidden:YES];
        
        [cell.lblMaximumBikeDistance setHidden:YES];
        [cell.sliderMaximumBikeDistance setHidden:YES];
        [cell.lblPreferenceFastVsSafe setHidden:YES];
        [cell.switchPreferenceFastVsSafe setHidden:YES];
        [cell.lblPreferenceFastVsFlat setHidden:YES];
        [cell.switchPreferenceFastVsFlat setHidden:YES];
        
        if(indexPath.row == 0){
            [cell.lblPushNotification setHidden:NO];
            [cell.switchPushNotification setHidden:NO];
        }
        else if(indexPath.row == 1){
            [cell.lblPushNotificationFrequency setHidden:NO];
            [cell.sliderPushNotificationFrequency setHidden:NO];
        }
        else if(indexPath.row == 2){
           [cell.lblNotificationSound setHidden:NO];  
        }
        else if(indexPath.row == 3){
            [cell.lblNotificationTiming setHidden:NO];
        }
    }
    else if(indexPath.section == 2){
        [cell.lblSFMuniAdvisories setHidden:YES];
        [cell.switchSFMuniAdvisories setHidden:YES];
        [cell.lblBartAdvisories setHidden:YES];
        [cell.switchBartAdvisories setHidden:YES];
        [cell.lblACTransitAdvisories setHidden:YES];
        [cell.switchACTransitAdvisories setHidden:YES];
        [cell.lblCaltrainAdvisories setHidden:YES];
        [cell.switchCaltrainAdvisories setHidden:YES];
        
        [cell.lblPushNotification setHidden:YES];
        [cell.switchPushNotification setHidden:YES];
        [cell.lblPushNotificationFrequency setHidden:YES];
        [cell.sliderPushNotificationFrequency setHidden:YES];
        [cell.lblNotificationSound setHidden:YES];
        [cell.lblNotificationTiming setHidden:YES];
        
        [cell.lblMaximumBikeDistance setHidden:YES];
        [cell.sliderMaximumBikeDistance setHidden:YES];
        [cell.lblPreferenceFastVsSafe setHidden:YES];
        [cell.switchPreferenceFastVsSafe setHidden:YES];
        [cell.lblPreferenceFastVsFlat setHidden:YES];
        [cell.switchPreferenceFastVsFlat setHidden:YES];
        
        [cell.lblMaximumWalkDistance setHidden:YES];
        [cell.sliderMaximumWalkDistance setHidden:YES];
    }
    else if(indexPath.section == 3){
        [cell.lblSFMuniAdvisories setHidden:YES];
        [cell.switchSFMuniAdvisories setHidden:YES];
        [cell.lblBartAdvisories setHidden:YES];
        [cell.switchBartAdvisories setHidden:YES];
        [cell.lblACTransitAdvisories setHidden:YES];
        [cell.switchACTransitAdvisories setHidden:YES];
        [cell.lblCaltrainAdvisories setHidden:YES];
        [cell.switchCaltrainAdvisories setHidden:YES];
        
        [cell.lblPushNotification setHidden:YES];
        [cell.switchPushNotification setHidden:YES];
        [cell.lblPushNotificationFrequency setHidden:YES];
        [cell.sliderPushNotificationFrequency setHidden:YES];
        [cell.lblNotificationSound setHidden:YES];
        [cell.lblNotificationTiming setHidden:YES];
        
        [cell.lblMaximumBikeDistance setHidden:YES];
        [cell.sliderMaximumBikeDistance setHidden:YES];
        [cell.lblPreferenceFastVsSafe setHidden:YES];
        [cell.switchPreferenceFastVsSafe setHidden:YES];
        [cell.lblPreferenceFastVsFlat setHidden:YES];
        [cell.switchPreferenceFastVsFlat setHidden:YES];
        
        [cell.lblMaximumWalkDistance setHidden:NO];
        [cell.sliderMaximumWalkDistance setHidden:NO];
    }
    else if(indexPath.section == 4){
        [cell.lblSFMuniAdvisories setHidden:YES];
        [cell.switchSFMuniAdvisories setHidden:YES];
        [cell.lblBartAdvisories setHidden:YES];
        [cell.switchBartAdvisories setHidden:YES];
        [cell.lblACTransitAdvisories setHidden:YES];
        [cell.switchACTransitAdvisories setHidden:YES];
        [cell.lblCaltrainAdvisories setHidden:YES];
        [cell.switchCaltrainAdvisories setHidden:YES];
        
        [cell.lblPushNotification setHidden:YES];
        [cell.switchPushNotification setHidden:YES];
        [cell.lblPushNotificationFrequency setHidden:YES];
        [cell.sliderPushNotificationFrequency setHidden:YES];
        [cell.lblNotificationSound setHidden:YES];
        [cell.lblNotificationTiming setHidden:YES];
        
        [cell.lblMaximumWalkDistance setHidden:YES];
        [cell.sliderMaximumWalkDistance setHidden:YES];
        
        if(indexPath.row == 0){
            [cell.lblMaximumBikeDistance setHidden:NO];
            [cell.sliderMaximumBikeDistance setHidden:NO];
        }
        else if(indexPath.row == 1){
            [cell.lblPreferenceFastVsSafe setHidden:NO];
            [cell.switchPreferenceFastVsSafe setHidden:NO];
        }
        else if(indexPath.row == 2){
            [cell.lblPreferenceFastVsFlat setHidden:NO];
            [cell.switchPreferenceFastVsFlat setHidden:NO]; 
        }
    }
    return cell;
}

@end