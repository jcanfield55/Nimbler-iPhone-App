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
#import "RouteExcludeSettings.h"
#import "RouteExcludeSetting.h"
#import "twitterViewController.h"
#import "FeedBackForm.h"

#define SETTING_TITLE       @"App Settings"
#define SETTING_ALERT_MSG   @"Updating your settings \n Please wait..."
#define WALK_DISTANCE       @"walkDistance"
#define PUSH_ENABLE         @"pushEnable"

@interface SettingInfoViewController() {
    BOOL planCacheNeedsClearing; // True if maxWalkDistance has been updated requiring plan cache to be cleared
}

@end

@implementation SettingInfoViewController

@synthesize sliderMaxWalkDistance;
@synthesize sliderPushNotification;
@synthesize enableUrgentSoundFlag;
@synthesize enableStandardSoundFlag;
@synthesize switchPushEnable;
@synthesize btnUpdateSetting;
@synthesize lblSliderMaxWalkDistanceValue;
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
        UserPreferance* userPrefs = [UserPreferance userPreferance];
        imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
        
        switchPushNotification = [[UISwitch alloc] init];
        switchPushNotification.accessibilityLabel = @"Push Notifications Switch"; 
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [switchPushNotification setOnTintColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        }
        [switchPushNotification addTarget:self action:@selector(switchPushNotificationChanged) forControlEvents:UIControlEventValueChanged];
        lblFrequently=[[UILabel alloc] initWithFrame:CGRectMake(LABEL_FREQUENTLY_XPOS,LABEL_FREQUENTLY_YPOS, LABEL_FREQUENTLY_WIDTH, LABEL_FREQUENTLY_HEIGHT)];
        [lblFrequently setTextColor:[UIColor whiteColor]];
        lblFrequently.backgroundColor =[UIColor clearColor];
        lblFrequently.adjustsFontSizeToFitWidth=YES;
        lblFrequently.text= LABEL_FREQUENTLY;
        [lblFrequently setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblRarely=[[UILabel alloc] initWithFrame:CGRectMake(LABEL_RARELY_XPOS,LABEL_RARELY_YPOS,LABEL_RARELY_WIDTH,LABEL_RARELY_HEIGHT)];
        [lblRarely setTextColor:[UIColor whiteColor]];
        lblRarely.backgroundColor =[UIColor clearColor];
        lblRarely.adjustsFontSizeToFitWidth=YES;
        lblRarely.text= LABEL_RARELY;
        [lblRarely setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        sliderPushNotificationFrequency = [[UISlider alloc] initWithFrame:CGRectMake(SLIDER_PUSH_FREQUENCY_XPOS,SLIDER_PUSH_FREQUENCY_YPOS,SLIDER_PUSH_FREQUENCY_WIDTH,SLIDER_PUSH_FREQUENCY_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderPushNotificationFrequency
             setMinimumTrackTintColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        }
        [sliderPushNotificationFrequency setMinimumValue:PUSH_FREQUENCY_MIN_VALUE];
        [sliderPushNotificationFrequency setMaximumValue:PUSH_FREQUENCY_MAX_VALUE];
        [sliderPushNotificationFrequency setValue:[userPrefs pushNotificationThreshold]];
        
        [sliderPushNotificationFrequency addTarget:self action:@selector(pushNotificationValueChanged:) forControlEvents:UIControlEventTouchUpInside];
        
        
        lblFrequencyOfPush=[[UILabel alloc] initWithFrame:CGRectMake(SETTING_MAIN_LABEL_XPOS,SETTING_MAIN_LABEL_YPOS,SETTING_MAIN_LABEL_WIDTH,SETTING_MAIN_LABEL_HEIGHT)];
        [lblFrequencyOfPush setTextColor:[UIColor whiteColor]];
        lblFrequencyOfPush.backgroundColor =[UIColor clearColor];
        lblFrequencyOfPush.adjustsFontSizeToFitWidth=YES;
        lblFrequencyOfPush.text=FREQUENCY_OF_PUSH;
        [lblFrequencyOfPush setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        lblMaximumWalkDistance=[[UILabel alloc] initWithFrame:CGRectMake(SETTING_MAIN_LABEL_XPOS,SETTING_MAIN_LABEL_YPOS,SETTING_MAIN_LABEL_WIDTH,SETTING_MAIN_LABEL_HEIGHT)];
        [lblMaximumWalkDistance setTextColor:[UIColor whiteColor]];
        lblMaximumWalkDistance.backgroundColor =[UIColor clearColor];
        lblMaximumWalkDistance.adjustsFontSizeToFitWidth=YES;
        lblMaximumWalkDistance.text=MAXIMUM_WALK_DISTANCE_LABEL;
        [lblMaximumWalkDistance setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        lblMinWalkDistance=[[UILabel alloc] initWithFrame:CGRectMake(SETTING_SUB_LABEL_XPOS,SETTING_SUB_LABEL_YPOS,SETTING_SUB_LABEL_WIDTH,SETTING_SUB_LABEL_HEIGHT)];
        [lblMinWalkDistance setTextColor:[UIColor whiteColor]];
        lblMinWalkDistance.backgroundColor =[UIColor clearColor];
        lblMinWalkDistance.adjustsFontSizeToFitWidth=YES;
        lblMinWalkDistance.text= [NSString stringWithFormat:@"%0.2f",MAX_WALK_DISTANCE_MIN_VALUE];
        [lblMinWalkDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblMaxWalkDistance=[[UILabel alloc] initWithFrame:CGRectMake(SETTING_SUB_LABEL_XPOS1,SETTING_SUB_LABEL_YPOS,SETTING_SUB_LABEL_WIDTH,SETTING_SUB_LABEL_HEIGHT)];
        [lblMaxWalkDistance setTextColor:[UIColor whiteColor]];
        lblMaxWalkDistance.backgroundColor =[UIColor clearColor];
        lblMaxWalkDistance.adjustsFontSizeToFitWidth=YES;
        lblMaxWalkDistance.text= [NSString stringWithFormat:@"%0.2f",MAX_WALK_DISTANCE_MAX_VALUE];
        [lblMaxWalkDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        sliderMaximumWalkDistance = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS,SLIDERS_YPOS, SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderMaximumWalkDistance
             setMinimumTrackTintColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        }
        [sliderMaximumWalkDistance setMinimumValue:MAX_WALK_DISTANCE_MIN_VALUE];
        [sliderMaximumWalkDistance setMaximumValue:MAX_WALK_DISTANCE_MAX_VALUE];
        [sliderMaximumWalkDistance setValue:[userPrefs walkDistance]];

        [sliderMaximumWalkDistance addTarget:self action:@selector(sliderWalkDistance:) forControlEvents:UIControlEventValueChanged];
        
        lblCurrentMaxWalkDistance = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, LABEL_MAXWALK_Distance_WIDTH, LABEL_MAXWALK_Distance_HEIGHT)] ;
        [lblCurrentMaxWalkDistance setTextColor:[UIColor whiteColor]];
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
    [self.navigationController.navigationBar setHidden:YES];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    self.tblSetting.delegate = self;
    self.tblSetting.dataSource = self;
    //[self.tblSetting setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_background.png"]]];
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
    
    [switchPushNotification setOn:userPrefs.pushEnable];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.sliderMaxWalkDistance = nil;
    self.switchPushEnable = nil;
    self.btnUpdateSetting = nil;
    self.sliderPushNotification = nil;
}

- (void)dealloc{
    self.sliderMaxWalkDistance = nil;
    self.switchPushEnable = nil;
    self.btnUpdateSetting = nil;
    self.sliderPushNotification = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[scrollView setFrame:CGRectMake(0,0,320,480)];
    [scrollView setContentSize:CGSizeMake(320,1075)];
    [nc_AppDelegate sharedInstance].isSettingView = YES;
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
        UserPreferance *userPrefs = [UserPreferance userPreferance]; // get singleton
        
        // US 161 Implementation -- clear cache if max walk distance has been modified
        if(planCacheNeedsClearing) {
            PlanStore *planStore = [[nc_AppDelegate sharedInstance] planStore];
            [planStore  performSelector:@selector(clearCache) withObject:nil afterDelay:0.5];
            planCacheNeedsClearing = NO;
        }
        
        // Store changes to server if needed
        if ([userPrefs isSaveToServerNeeded]) {
            [userPrefs saveToServer];
        }
        
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

// Slider callback method for original settings page
-(IBAction)sliderWalkDistanceValueChanged:(UISlider *)sender
{
    [sliderMaxWalkDistance setValue:sliderMaxWalkDistance.value];
    [sliderMaxWalkDistance setSelected:YES];
    [UserPreferance userPreferance].walkDistance = sliderMaxWalkDistance.value;
    float sliderXPOS = [self xPositionFromSliderValue:sliderMaxWalkDistance];
    planCacheNeedsClearing = YES;
    // Fixed DE-209
    lblSliderMaxWalkDistanceValue.center = CGPointMake(sliderXPOS, -10);
    lblSliderMaxWalkDistanceValue.text = [NSString stringWithFormat:@"%0.2f", sliderMaxWalkDistance.value];
    [UserPreferance userPreferance].walkDistance = 0;
}

// Slider callback method for new settings page
-(IBAction)sliderWalkDistance:(UISlider *)sender
{
    
    RouteExcludeSettings *excludesettings = [RouteExcludeSettings latestUserSettings];
    IncludeExcludeSetting setting = [excludesettings settingForKey:returnBikeButtonTitle()];
    if(setting == SETTING_EXCLUDE_ROUTE){
        ToFromViewController *toFromVc = [nc_AppDelegate sharedInstance].toFromViewController;
        if(![nc_AppDelegate sharedInstance].isToFromView){
            [toFromVc.navigationController popToRootViewControllerAnimated:YES];
        }
    }
    
    [sliderMaximumWalkDistance setValue:sliderMaximumWalkDistance.value];
    [sliderMaximumWalkDistance setSelected:YES];
    [UserPreferance userPreferance].walkDistance = sliderMaximumWalkDistance.value;
    planCacheNeedsClearing = YES;
    float sliderXPOS = [self xPositionFromSliderValue:sliderMaximumWalkDistance];
    // Fixed DE-209
    lblCurrentMaxWalkDistance.center = CGPointMake(sliderXPOS, -10);
    lblCurrentMaxWalkDistance.text = [NSString stringWithFormat:@"%0.2f", sliderMaximumWalkDistance.value];
}

-(IBAction)sliderPushNotification:(UISlider *)sender
{
    int pushNotificationThreshold = lroundf(sliderPushNotification.value);
    [sliderPushNotification setValue:pushNotificationThreshold];
    [UserPreferance userPreferance].pushNotificationThreshold = pushNotificationThreshold;
    [sliderPushNotification setSelected:YES];
    NIMLOG_EVENT1(@"walk distance: %d", pushNotificationThreshold);
}

// Callback for pushNotificationFrequency slider (in new Settings page)
-(IBAction)pushNotificationValueChanged:(UISlider *)sender
{
    int pushNotificationThreshold = lroundf(sliderPushNotificationFrequency.value);
    [sliderPushNotificationFrequency setValue:pushNotificationThreshold];
    [UserPreferance userPreferance].pushNotificationThreshold = pushNotificationThreshold;
    [sliderPushNotificationFrequency setSelected:YES];
    NIMLOG_EVENT1(@"walk distance: %d", pushNotificationThreshold);
}

-(void)popOutFromSettingView {
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    // Code Added to select Trip Planner Tab
    RXCustomTabBar *rxCustomTabBar = (RXCustomTabBar *)self.tabBarController;
    [rxCustomTabBar selectTab:0];
    [rxCustomTabBar selectTab1:0];
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
        [sliderMaxWalkDistance setValue:[userPrefs walkDistance]];
        [sliderPushNotification setValue:[userPrefs pushNotificationThreshold]];
        [switchPushEnable setOn:[userPrefs pushEnable]];
        
    }
    @catch (NSException *exception) {
        logException(@"SettingInfoViewController->fetchUserSettingData", @"", exception);
    }
}

- (NSString *)detailtextLabelString:(NSIndexPath *)indexPath{
    NSMutableString *strDetailTextLabel = [NSMutableString stringWithCapacity:20];
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    if(indexPath.section == SETTINGS_ADVISORY_SECTION_NUM){
        if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]) {
            if(userPrefs.wMataAdvisories) {
                [strDetailTextLabel appendString:LABEL_WMATA];
            }
            else if (!userPrefs.wMataAdvisories) {
                [strDetailTextLabel appendString:LABEL_NONE];
            }
        }
        else if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:PORTLAND_BUNDLE_IDENTIFIER]) {
            if(userPrefs.trimetAdvisories) {
                [strDetailTextLabel appendString:LABEL_TRIMET];
            }
            else if (!userPrefs.trimetAdvisories) {
                [strDetailTextLabel appendString:LABEL_NONE];
            }
        }
        else{
            if(userPrefs.sfMuniAdvisories &&
               userPrefs.bartAdvisories &&
               userPrefs.acTransitAdvisories &&
               userPrefs.caltrainAdvisories) {
                [strDetailTextLabel appendString:LABEL_ALL];
            }
            else if (!userPrefs.sfMuniAdvisories &&
                     !userPrefs.bartAdvisories &&
                     !userPrefs.acTransitAdvisories &&
                     !userPrefs.caltrainAdvisories) {
                [strDetailTextLabel appendString:LABEL_NONE];
            } else { // Some combination of agencies
                int agencyCount=0;
                if (userPrefs.sfMuniAdvisories) {
                    [strDetailTextLabel appendString:LABEL_SFMUNI];
                    agencyCount++;
                }
                if (userPrefs.bartAdvisories) {
                    if (agencyCount > 0) {
                        [strDetailTextLabel appendFormat:@" + %@",LABEL_BART];
                    } else {
                        [strDetailTextLabel appendFormat:LABEL_BART];
                    }
                    agencyCount++;
                }
                if (userPrefs.acTransitAdvisories) {
                    if (agencyCount > 0) {
                        [strDetailTextLabel appendFormat:@" + %@",LABEL_ACTRANSIT];
                    } else {
                        [strDetailTextLabel appendFormat:LABEL_ACTRANSIT];
                    }
                    agencyCount++;
                }
                if (userPrefs.caltrainAdvisories) {
                    if (agencyCount > 0) {
                        [strDetailTextLabel appendFormat:@" + %@",LABEL_CALTRAIN];
                    } else {
                        [strDetailTextLabel appendFormat:LABEL_CALTRAIN];
                    }
                    agencyCount++;
                }
            }
        }
    }
    else if(indexPath.section == SETTINGS_PUSH_SECTION_NUM){
        if(indexPath.row == SETTINGS_PUSH_TIMING_ROW_NUM){
            if(userPrefs.notificationMorning &&
                userPrefs.notificationMidday &&
                userPrefs.notificationEvening &&
                userPrefs.notificationNight &&
                userPrefs.notificationWeekend) {
                [strDetailTextLabel appendString:LABEL_ALL];
            }
            else if (!userPrefs.notificationMorning &&
                     !userPrefs.notificationMidday &&
                     !userPrefs.notificationEvening &&
                     !userPrefs.notificationNight &&
                     !userPrefs.notificationWeekend) {
                [strDetailTextLabel appendString:LABEL_NO_NOTIFICATIONS];
            }
            else if(userPrefs.notificationMorning &&
               userPrefs.notificationMidday &&
               userPrefs.notificationEvening &&
               userPrefs.notificationNight &&
               !userPrefs.notificationWeekend) {
                [strDetailTextLabel appendString:LABEL_WKDAY_ALL];
            }
            else if (!userPrefs.notificationMorning &&
                     !userPrefs.notificationMidday &&
                     !userPrefs.notificationEvening &&
                     !userPrefs.notificationNight &&
                     userPrefs.notificationWeekend) {
                [strDetailTextLabel appendString:LABEL_WEEKENDS];
            }
            else{
                NSArray *arrayFlags = [NSArray arrayWithObjects:[NSNumber numberWithBool:userPrefs.notificationMorning],
                                       [NSNumber numberWithBool:userPrefs.notificationMidday],
                                       [NSNumber numberWithBool:userPrefs.notificationEvening],
                                       [NSNumber numberWithBool:userPrefs.notificationNight],
                                       [NSNumber numberWithBool:userPrefs.notificationWeekend], nil];
                NSArray *arrayStringToAppend = [NSArray arrayWithObjects:LABEL_MORNING,LABEL_MIDDAY,LABEL_EVENING,LABEL_NIGHT,LABEL_WKENDS, nil];
                NSMutableString *strMutableTextLabel = [NSMutableString stringWithCapacity:25];
                [strMutableTextLabel appendFormat:@"%@ ",LABEL_WKKDAY];
                bool firstOne = true;
                for(int i = 0;i < [arrayFlags count]; i++){
                    if([[arrayFlags objectAtIndex:i] boolValue]) {
                        if (firstOne) {
                            [strMutableTextLabel appendString:[arrayStringToAppend objectAtIndex:i]];
                            firstOne = false;
                        } else {
                            [strMutableTextLabel appendFormat:@", %@",[arrayStringToAppend objectAtIndex:i]];
                        }
                    }
                }
                strDetailTextLabel = [NSString stringWithString:strMutableTextLabel];
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
    return SETTINGS_NUMBER_OF_SECTIONS;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 3;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 3;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == SETTINGS_ADVISORY_SECTION_NUM){
        return SETTINGS_ADVISORY_SECTION_ROWS;
    }
    else if(section == SETTINGS_PUSH_SECTION_NUM){
        if(!switchPushNotification.isOn){
            return 1;
        }
        else{
            return SETTINGS_PUSH_SECTION_ROWS_IF_ON;
        }
    }
    else if (section == SETTINGS_BIKE_WALK_SECTION_NUM) {
        return SETTINGS_BIKE_WALK_SECTION_ROWS;
    }
    else {
        logError(@"SettingInfoViewController->numberOfRowsInSection",
                 [NSString stringWithFormat:@"Unknown Section #: %d", section]);
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if((indexPath.section == SETTINGS_PUSH_SECTION_NUM && indexPath.row == SETTINGS_PUSH_FREQUENCY_ROW_NUM) ||
       (indexPath.section == SETTINGS_BIKE_WALK_SECTION_NUM && indexPath.row == SETTINGS_MAX_WALK_DISTANCE_ROW_NUM)){
        return 80;
    }
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d",indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell = nil;
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if(indexPath.section == SETTINGS_ADVISORY_SECTION_NUM ||
       (indexPath.section == SETTINGS_PUSH_SECTION_NUM &&
        (indexPath.row == SETTINGS_PUSH_SOUND_ROW_NUM || indexPath.row == SETTINGS_PUSH_TIMING_ROW_NUM)) ||
       (indexPath.section == SETTINGS_BIKE_WALK_SECTION_NUM
        && (indexPath.row == SETTINGS_TRANSIT_MODE_ROW_NUM || indexPath.row == SETTINGS_BIKE_PREF_ROW_NUM))){
        UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithImage:imageDetailDisclosure];
        [cell setAccessoryView:imgViewDetailDisclosure];
    }
    [cell setBackgroundColor:[UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0]];
    [cell.textLabel setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
    [cell.detailTextLabel setFont:[UIFont SMALL_OBLIQUE_FONT]];
    if(indexPath.section == SETTINGS_ADVISORY_SECTION_NUM){
        cell.textLabel.text = ADVISORY_CHOICES;
         cell.detailTextLabel.text = [self detailtextLabelString:indexPath];
    }
    else if(indexPath.section == SETTINGS_PUSH_SECTION_NUM){
        if(indexPath.row == SETTINGS_PUSH_ON_OFF_ROW_NUM){
            cell.textLabel.text = PUSH_NOTIFICATION;
            UIView* cellView = [cell accessoryView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:switchPushNotification] != NSNotFound) {
            }
            else{
                [cell setAccessoryView:switchPushNotification];
            }
        }
        else if(indexPath.row == SETTINGS_PUSH_FREQUENCY_ROW_NUM){
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
        else if(indexPath.row == SETTINGS_PUSH_SOUND_ROW_NUM){
            if(userPrefs.standardNotificationSound &&
               userPrefs.urgentNotificationSound) {
                cell.detailTextLabel.text = URGENT_AND_STANDARD;
            }
            else if(!userPrefs.standardNotificationSound &&
                    !userPrefs.urgentNotificationSound) {
                cell.detailTextLabel.text = LABEL_NONE;
            }
            else if(!userPrefs.standardNotificationSound &&
                    userPrefs.urgentNotificationSound) {
                cell.detailTextLabel.text = URGENT;
            }
            else if(userPrefs.standardNotificationSound &&
                    !userPrefs.urgentNotificationSound) {
                cell.detailTextLabel.text = STANDARD;
            }
            cell.textLabel.text = NOTIFICATION_SOUND;
        }
        else if(indexPath.row == SETTINGS_PUSH_TIMING_ROW_NUM){
            cell.textLabel.text = NOTIFICATION_TIMING;
            cell.detailTextLabel.text = [self detailtextLabelString:indexPath];
        }
        else {
            logError(@"SettingInfoViewController->cellForRowAtIndexPath",
                     [NSString stringWithFormat:@"Unknown push row #: %d", indexPath.row]);
        }
    }
    else if(indexPath.section == SETTINGS_BIKE_WALK_SECTION_NUM){
        if(indexPath.row == SETTINGS_TRANSIT_MODE_ROW_NUM){
            cell.textLabel.text = TRANSIT_MODE;
            if (userPrefs.transitMode == TRANSIT_MODE_TRANSIT_ONLY){
                cell.detailTextLabel.text = TRANSIT_ONLY;
            }
            if (userPrefs.transitMode == TRANSIT_MODE_BIKE_ONLY) {
                cell.detailTextLabel.text = BIKE_ONLY;
            }
            if (userPrefs.transitMode == TRANSIT_MODE_BIKE_AND_TRANSIT) {
                cell.detailTextLabel.text = BIKE_AND_TRANSIT;
            }
        }
        else if(indexPath.row == SETTINGS_MAX_WALK_DISTANCE_ROW_NUM){
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
        else if(indexPath.row == SETTINGS_BIKE_PREF_ROW_NUM){
            cell.textLabel.text = BIKE_PREFERENCES;
        }
        else {
            logError(@"SettingInfoViewController->cellForRowAtIndexPath",
                     [NSString stringWithFormat:@"Unknown bike/walk row #: %d", indexPath.row]);
        }
    }
    else {
        logError(@"SettingInfoViewController->cellForRowAtIndexPath",
                 [NSString stringWithFormat:@"Unknown section #: %d", indexPath.section]);
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == SETTINGS_ADVISORY_SECTION_NUM ||
       (indexPath.section == SETTINGS_PUSH_SECTION_NUM &&
        (indexPath.row == SETTINGS_PUSH_SOUND_ROW_NUM || indexPath.row == SETTINGS_PUSH_TIMING_ROW_NUM)) ||
       (indexPath.section == SETTINGS_BIKE_WALK_SECTION_NUM &&
        (indexPath.row == SETTINGS_TRANSIT_MODE_ROW_NUM || indexPath.row == SETTINGS_BIKE_PREF_ROW_NUM))){
        if([[UIScreen mainScreen] bounds].size.height == 568){
            settingDetailViewController = [[SettingDetailViewController alloc] initWithNibName:@"SettingDetailViewController_568h" bundle:nil];
        }
        else{
            settingDetailViewController = [[SettingDetailViewController alloc] initWithNibName:@"SettingDetailViewController" bundle:nil];
        }
        int nSettingRow = 0;
        if(indexPath.section == SETTINGS_ADVISORY_SECTION_NUM){
            nSettingRow = N_SETTINGS_ROW_ADVISORY;
        }
        else if(indexPath.section == SETTINGS_PUSH_SECTION_NUM){
            if(indexPath.row == SETTINGS_PUSH_SOUND_ROW_NUM){
                nSettingRow = N_SETTINGS_ROW_PUSH_SOUND;
            }
            else if(indexPath.row == SETTINGS_PUSH_TIMING_ROW_NUM){
                nSettingRow = N_SETTINGS_ROW_PUSH_TIMING;
            }
        }
        else if (indexPath.section == SETTINGS_BIKE_WALK_SECTION_NUM) {
            if(indexPath.row == SETTINGS_TRANSIT_MODE_ROW_NUM){
                nSettingRow = N_SETTINGS_ROW_TRANSIT_MODE;
            }
            else if(indexPath.row == SETTINGS_BIKE_PREF_ROW_NUM){
                nSettingRow = N_SETTINGS_ROW_BIKE_PREF;
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

- (void)switchPushNotificationChanged{
    if(![[NSUserDefaults standardUserDefaults] objectForKey:DEVICE_TOKEN] && switchPushNotification.on){
        [[UIApplication sharedApplication]
         registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeAlert |
          UIRemoteNotificationTypeBadge |
          UIRemoteNotificationTypeSound)];
    }
    [UserPreferance userPreferance].pushEnable = switchPushNotification.on; // Save setting
    [self.tblSetting reloadData];
}
@end