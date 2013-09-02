//
//  SettingDetailViewController.m
//  Nimbler Caltrain
//
//  Created by macmini on 21/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SettingDetailViewController.h"
#import "UserPreferance.h"
#import "nc_AppDelegate.h"
#import "UtilityFunctions.h"
#import "RouteExcludeSettings.h"
#import "RouteExcludeSetting.h"
#import "twitterViewController.h"
#import "FeedBackForm.h"

@implementation SettingDetailViewController

@synthesize tblDetailSetting;
@synthesize nSettingRow;
@synthesize switchUrgentNotification;
@synthesize switchStandardNotification;
@synthesize lblMaximumBikeDistance;
@synthesize sliderMaximumBikeDistance;
@synthesize lblPreferenceFastVsSafe;
@synthesize sliderPreferenceFastVsSafe;
@synthesize lblPreferenceFastVsFlat;
@synthesize sliderPreferenceFastVsFlat;
@synthesize lblCurrentBikeDistance;
@synthesize lblMinBikeDistance;
@synthesize lblMaxBikeDistance;
@synthesize lblQuickWithHills;
@synthesize lblGoAroundHills;
@synthesize lblQuickWithAnyStreet;
@synthesize lblBikeFriendlyStreet;
@synthesize isSettingDetail;
@synthesize settingDetailDelegate;
@synthesize imgViewCheckMark;

@synthesize backButton;
@synthesize titleLabel;
@synthesize titleLabelString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UserPreferance* userPrefs = [UserPreferance userPreferance];
        switchUrgentNotification = [[UISwitch alloc] init];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [switchUrgentNotification setOnTintColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        }
        [switchUrgentNotification setOn:[userPrefs urgentNotificationSound]];
        [switchUrgentNotification addTarget:self action:@selector(switchUrgentNotificationChanged) forControlEvents:UIControlEventValueChanged];

        switchStandardNotification = [[UISwitch alloc] init];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [switchStandardNotification setOnTintColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        }
        [switchStandardNotification setOn:[userPrefs standardNotificationSound]];
        [switchStandardNotification addTarget:self action:@selector(switchStandardNotificationChanged) forControlEvents:UIControlEventValueChanged];
        
        lblMaximumBikeDistance=[[UILabel alloc] initWithFrame:CGRectMake(DETAIL_SETTING_MAIN_LABEL_XPOS,DETAIL_SETTING_MAIN_LABEL_YPOS, DETAIL_SETTING_MAIN_LABEL_WIDTH, DETAIL_SETTING_MAIN_LABEL_HEIGHT)];
        [lblMaximumBikeDistance setTextColor:[UIColor whiteColor]];
        lblMaximumBikeDistance.backgroundColor =[UIColor clearColor];
        lblMaximumBikeDistance.adjustsFontSizeToFitWidth=YES;
        lblMaximumBikeDistance.text=MAXIMUM_BIKE_DISTANCE;
        [lblMaximumBikeDistance setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        sliderMaximumBikeDistance = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS,SLIDERS_YPOS,SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderMaximumBikeDistance setMinimumTrackImage:[UIImage imageNamed:@"redSlider.png"] forState:UIControlStateNormal];
            [sliderMaximumBikeDistance setMaximumTrackImage:[UIImage imageNamed:@"whiteSlider.png"] forState:UIControlStateNormal];
            [sliderMaximumBikeDistance setThumbImage:[UIImage imageNamed:@"thumbSlider.png"] forState:UIControlStateNormal];
        }
        [sliderMaximumBikeDistance setMinimumValue:MAX_BIKE_DISTANCE_MIN_VALUE];
        [sliderMaximumBikeDistance setMaximumValue:MAX_BIKE_DISTANCE_MAX_VALUE];
        [sliderMaximumBikeDistance setValue:[userPrefs bikeDistance]];

        [sliderMaximumBikeDistance addTarget:self action:@selector(maxBikeDistanceValueChanged:) forControlEvents:UIControlEventTouchUpInside];
        
        
        lblPreferenceFastVsSafe=[[UILabel alloc] initWithFrame:CGRectMake(DETAIL_SETTING_MAIN_LABEL_XPOS,DETAIL_SETTING_MAIN_LABEL_YPOS, DETAIL_SETTING_MAIN_LABEL_WIDTH, DETAIL_SETTING_MAIN_LABEL_HEIGHT)];
        [lblPreferenceFastVsSafe setTextColor:[UIColor whiteColor]];
        lblPreferenceFastVsSafe.backgroundColor =[UIColor clearColor];
        lblPreferenceFastVsSafe.adjustsFontSizeToFitWidth=YES;
        lblPreferenceFastVsSafe.text=PREFERENCE_FAST_VS_SAFE;
        [lblPreferenceFastVsSafe setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        sliderPreferenceFastVsSafe = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS, SLIDERS_YPOS1, SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderPreferenceFastVsSafe setMinimumTrackImage:[UIImage imageNamed:@"redSlider.png"] forState:UIControlStateNormal];
            [sliderPreferenceFastVsSafe setMaximumTrackImage:[UIImage imageNamed:@"whiteSlider.png"] forState:UIControlStateNormal];
            [sliderPreferenceFastVsSafe setThumbImage:[UIImage imageNamed:@"thumbSlider.png"] forState:UIControlStateNormal];
        }
        [sliderPreferenceFastVsSafe setMinimumValue:BIKE_PREFERENCE_MIN_VALUE];
        [sliderPreferenceFastVsSafe setMaximumValue:BIKE_PREFERENCE_MAX_VALUE];
        [sliderPreferenceFastVsSafe setValue:[userPrefs fastVsSafe]];
        
        lblPreferenceFastVsFlat=[[UILabel alloc] initWithFrame:CGRectMake(DETAIL_SETTING_MAIN_LABEL_XPOS,DETAIL_SETTING_MAIN_LABEL_YPOS, DETAIL_SETTING_MAIN_LABEL_WIDTH, DETAIL_SETTING_MAIN_LABEL_HEIGHT)];
        [lblPreferenceFastVsFlat setTextColor:[UIColor whiteColor]];
        lblPreferenceFastVsFlat.backgroundColor =[UIColor clearColor];
        lblPreferenceFastVsFlat.adjustsFontSizeToFitWidth=YES;
        lblPreferenceFastVsFlat.text=PREFERENCE_FAST_VS_FLAT;
        [lblPreferenceFastVsFlat setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        sliderPreferenceFastVsFlat = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS, SLIDERS_YPOS1, SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderPreferenceFastVsFlat setMinimumTrackImage:[UIImage imageNamed:@"redSlider.png"] forState:UIControlStateNormal];
            [sliderPreferenceFastVsFlat setMaximumTrackImage:[UIImage imageNamed:@"whiteSlider.png"] forState:UIControlStateNormal];
            [sliderPreferenceFastVsFlat setThumbImage:[UIImage imageNamed:@"thumbSlider.png"] forState:UIControlStateNormal];
        }
        [sliderPreferenceFastVsFlat setMinimumValue:BIKE_PREFERENCE_MIN_VALUE];
        [sliderPreferenceFastVsFlat setMaximumValue:BIKE_PREFERENCE_MAX_VALUE];
        [sliderPreferenceFastVsFlat setValue:[userPrefs fastVsFlat]];

        lblCurrentBikeDistance = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, LABEL_MAXWALK_Distance_WIDTH, LABEL_MAXWALK_Distance_HEIGHT)] ;
        [lblCurrentBikeDistance setTextColor:[UIColor whiteColor]];
        [lblCurrentBikeDistance setBackgroundColor:[UIColor clearColor]];
        [lblCurrentBikeDistance setTextAlignment:UITextAlignmentCenter];
        [lblCurrentBikeDistance setFont:[UIFont MEDIUM_FONT]];
        
        lblMinBikeDistance=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_DISTANCE_LABEL_XPOS,BIKE_DISTANCE_LABEL_YPOS, BIKE_DISTANCE_LABEL_WIDTH, BIKE_DISTANCE_LABEL_HEIGHT)];
        [lblMinBikeDistance setTextColor:[UIColor whiteColor]];
        lblMinBikeDistance.backgroundColor =[UIColor clearColor];
        lblMinBikeDistance.adjustsFontSizeToFitWidth=YES;
        lblMinBikeDistance.text=[NSString stringWithFormat:@"%d",MAX_BIKE_DISTANCE_MIN_VALUE];
        [lblMinBikeDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblMaxBikeDistance=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_DISTANCE_LABEL_XPOS1,BIKE_DISTANCE_LABEL_YPOS, BIKE_DISTANCE_LABEL_WIDTH, BIKE_DISTANCE_LABEL_HEIGHT)];
        [lblMaxBikeDistance setTextColor:[UIColor whiteColor]];
        lblMaxBikeDistance.backgroundColor =[UIColor clearColor];
        lblMaxBikeDistance.adjustsFontSizeToFitWidth=YES;
        lblMaxBikeDistance.text=[NSString stringWithFormat:@"%d",MAX_BIKE_DISTANCE_MAX_VALUE];;
        [lblMaxBikeDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblQuickWithHills=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblQuickWithHills setTextColor:[UIColor whiteColor]];
        lblQuickWithHills.backgroundColor =[UIColor clearColor];
        lblQuickWithHills.adjustsFontSizeToFitWidth=YES;
        lblQuickWithHills.text= QUICK_WITH_HILLS;
        [lblQuickWithHills setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblGoAroundHills=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS1,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblGoAroundHills setTextColor:[UIColor whiteColor]];
        lblGoAroundHills.backgroundColor =[UIColor clearColor];
        lblGoAroundHills.adjustsFontSizeToFitWidth=YES;
        lblGoAroundHills.text= GO_AROUNG_HILLS;
        [lblGoAroundHills setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblQuickWithAnyStreet=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblQuickWithAnyStreet setTextColor:[UIColor whiteColor]];
        lblQuickWithAnyStreet.backgroundColor =[UIColor clearColor];
        lblQuickWithAnyStreet.adjustsFontSizeToFitWidth=YES;
        lblQuickWithAnyStreet.text= QUICK_WITH_ANY_STREET;
        [lblQuickWithAnyStreet setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblBikeFriendlyStreet=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS1,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblBikeFriendlyStreet setTextColor:[UIColor whiteColor]];
        lblBikeFriendlyStreet.backgroundColor =[UIColor clearColor];
        lblBikeFriendlyStreet.adjustsFontSizeToFitWidth=YES;
        lblBikeFriendlyStreet.text= BIKE_FRIENDLY_STREET;
        [lblBikeFriendlyStreet setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        imgViewCheckMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if([[[UIDevice currentDevice] systemVersion] intValue] < 5) {
        [tblDetailSetting setBackgroundColor:[UIColor colorWithRed:128.0/255.0 green:128.0/255.0 blue:128.0/255.0 alpha:1.0]];
    }
    UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
    [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
    lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
    [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
    lblNavigationTitle.backgroundColor =[UIColor clearColor];
    lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
    
    if(nSettingRow == N_SETTINGS_ROW_ADVISORY){
        titleLabel.text = ADVISORY_CHOICES;
    }
    else if(nSettingRow == N_SETTINGS_ROW_PUSH_SOUND){
        titleLabel.text = NOTIFICATION_SOUND;
    }
    else if(nSettingRow == N_SETTINGS_ROW_PUSH_TIMING){
        titleLabel.text = NOTIFICATION_TIMING;
    }
    else if(nSettingRow == N_SETTINGS_ROW_TRANSIT_MODE){
        titleLabel.text = TRANSIT_MODE;
    }
    else if(nSettingRow == N_SETTINGS_ROW_BIKE_PREF){
        titleLabel.text = BIKE_PREFERENCES;
    }
    self.navigationItem.titleView=lblNavigationTitle;
    UIImage* btnImage = [UIImage imageNamed:@"img_Settings.png"];
    UIButton * btnGoToItinerary = [[UIButton alloc] initWithFrame:CGRectMake(0,0,65, 34)];
    [btnGoToItinerary addTarget:self action:@selector(popOutToSettings) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToItinerary setBackgroundImage:btnImage forState:UIControlStateNormal];
    UIBarButtonItem *backToItinerary = [[UIBarButtonItem alloc] initWithCustomView:btnGoToItinerary];
    self.navigationItem.leftBarButtonItem = backToItinerary;
    
    self.tblDetailSetting.delegate = self;
    self.tblDetailSetting.dataSource = self;
    //[self.tblDetailSetting setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_background.png"]]];
}
- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if([[[UIDevice currentDevice] systemVersion] intValue] >= 7){
        [backButton setFrame:CGRectMake(backButton.frame.origin.x,backButton.frame.origin.y+20, backButton.frame.size.width, backButton.frame.size.height)];
        [titleLabel setFrame:CGRectMake(titleLabel.frame.origin.x,titleLabel.frame.origin.y+20, titleLabel.frame.size.width, titleLabel.frame.size.height)];
    }
    [nc_AppDelegate sharedInstance].isSettingDetailView = YES;
}
// Clear cache and update latest settings to server
- (void) clearCacheAndSaveSettingsToServer{
    if(sliderMaximumBikeDistance.value !=  [[[NSUserDefaults standardUserDefaults] objectForKey:PREFS_MAX_BIKE_DISTANCE] floatValue] || sliderPreferenceFastVsSafe.value != [[[NSUserDefaults standardUserDefaults] objectForKey:PREFS_BIKE_FAST_VS_SAFE] floatValue] || sliderPreferenceFastVsFlat.value != [[[NSUserDefaults standardUserDefaults] objectForKey:PREFS_BIKE_FAST_VS_FLAT] floatValue]){
        RouteExcludeSettings *excludesettings = [RouteExcludeSettings latestUserSettings];
        IncludeExcludeSetting setting = [excludesettings settingForKey:BIKE_BUTTON];
        // Fixed DE-351
        IncludeExcludeSetting bikeShareSetting = [excludesettings settingForKey:BIKE_SHARE];
        if(setting == SETTING_INCLUDE_ROUTE || bikeShareSetting == SETTING_INCLUDE_ROUTE){
            ToFromViewController *toFromVc = [nc_AppDelegate sharedInstance].toFromViewController;
            if(![nc_AppDelegate sharedInstance].isToFromView){
                [toFromVc.navigationController popToRootViewControllerAnimated:YES];
            }
        }
        PlanStore *planStore = [[nc_AppDelegate sharedInstance] planStore];
        [planStore  performSelector:@selector(clearCacheForBikePref) withObject:nil afterDelay:0.5];
    }
    
    [nc_AppDelegate sharedInstance].isSettingDetailView = NO;
    isSettingDetail = NO;
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    if(nSettingRow == N_SETTINGS_ROW_BIKE_PREF){
        userPrefs.bikeDistance = sliderMaximumBikeDistance.value;
        userPrefs.fastVsSafe = sliderPreferenceFastVsSafe.value;
        userPrefs.fastVsFlat = sliderPreferenceFastVsFlat.value;
    }
    
    [settingDetailDelegate updateSetting];
    // if(![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
    if(!userPrefs.sfMuniAdvisories && !userPrefs.bartAdvisories && !userPrefs.acTransitAdvisories && !userPrefs.caltrainAdvisories) {
        [[nc_AppDelegate sharedInstance] updateBadge:0];
        // }
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if([[[UIDevice currentDevice] systemVersion] intValue] >= 7){
        [backButton setFrame:CGRectMake(backButton.frame.origin.x,backButton.frame.origin.y-20, backButton.frame.size.width, backButton.frame.size.height)];
        [titleLabel setFrame:CGRectMake(titleLabel.frame.origin.x,titleLabel.frame.origin.y-20, titleLabel.frame.size.width, titleLabel.frame.size.height)];
    }
    [self clearCacheAndSaveSettingsToServer];
}
- (void)popOutToSettings{
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

-(IBAction)maxBikeDistanceValueChanged:(UISlider *)sender
{
    [sliderMaximumBikeDistance setValue:sliderMaximumBikeDistance.value];
    [sliderMaximumBikeDistance setSelected:YES];
    float sliderXPOS = [self xPositionFromSliderValue:sliderMaximumBikeDistance];
    lblCurrentBikeDistance.center = CGPointMake(sliderXPOS, -10);
    lblCurrentBikeDistance.text = [NSString stringWithFormat:@"%0.0f", sliderMaximumBikeDistance.value];
}

//------------------------------------------------------------------------

#pragma mark
#pragma mark UITableView delegate and datasource methods

//-------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int nRowCount = 4;
    if(nSettingRow == N_SETTINGS_ROW_ADVISORY){
        if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
            nRowCount = WMATA_SETTINGS_ADVISORIES_ROWS;
        }
        else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:PORTLAND_BUNDLE_IDENTIFIER]){
            nRowCount = TRIMET_SETTINGS_ADVISORIES_ROWS;
        }else{
            nRowCount = N_SETTINGS_ADVISORY_ROWS;
        }
    }
    else if(nSettingRow == N_SETTINGS_ROW_PUSH_SOUND){
        nRowCount = N_SETTINGS_PUSH_SOUND_ROWS;
    }
    else if(nSettingRow == N_SETTINGS_ROW_PUSH_TIMING){
        nRowCount = N_SETTINGS_PUSH_TIMING_ROWS;
    }
    else if(nSettingRow == N_SETTINGS_ROW_TRANSIT_MODE){
        nRowCount = N_SETTINGS_TRANSIT_MODE_ROWS;
    }
    else if(nSettingRow == N_SETTINGS_ROW_BIKE_PREF){
        nRowCount = N_SETTINGS_BIKE_PREF_ROWS;
    } else {
        logError(@"SettingDetailViewController->numberOfRowsInSection",
                 [NSString stringWithFormat:@"Unknown nSettingRow: %d", nSettingRow]);
    }
    return nRowCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    int nRowHeight;
    if(nSettingRow == N_SETTINGS_ROW_BIKE_PREF){
        nRowHeight = 80;
    }
    else{
        nRowHeight = 40;
    }
    return nRowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d",indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell = nil;
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.textLabel setFont:[UIFont SMALL_FONT]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    if(nSettingRow == N_SETTINGS_ROW_ADVISORY){
        if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
            cell.textLabel.text = WMATA_ADVISORIES;
            cell.accessoryView = (userPrefs.wMataAdvisories ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
        }
        else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:PORTLAND_BUNDLE_IDENTIFIER]){
            cell.textLabel.text = TRIMET_ADVISORIES;
            cell.accessoryView = (userPrefs.trimetAdvisories ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
        }
        else{
            if(indexPath.row == SETTINGS_ADVISORY_SFMUNI_ROW){
                cell.textLabel.text = SFMUNI_ADVISORIES;
                cell.accessoryView = (userPrefs.sfMuniAdvisories ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
            }
            else if(indexPath.row == SETTINGS_ADVISORY_BART_ROW){
                cell.textLabel.text = BART_ADVISORIES;
                cell.accessoryView = (userPrefs.bartAdvisories ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
            }
            else if(indexPath.row == SETTINGS_ADVISORY_ACTRANSIT_ROW){
                cell.textLabel.text = ACTRANSIT_ADVISORIES;
                cell.accessoryView = (userPrefs.acTransitAdvisories ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
            }
            else if(indexPath.row == SETTINGS_ADVISORY_CALTRAIN_ROW){
                cell.textLabel.text = CALTRAIN_ADVISORIES;
                cell.accessoryView = (userPrefs.caltrainAdvisories ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
            }
        }
    }
    else if(nSettingRow == N_SETTINGS_ROW_PUSH_SOUND){
        if(indexPath.row == SETTINGS_SOUNDS_URGENT_ROW){
            cell.textLabel.text = URGENT_NOTIFICATIONS;
            [cell setAccessoryView:switchUrgentNotification];
        }
        else if(indexPath.row == SETTINGS_SOUNDS_STANDARD_ROW){
            cell.textLabel.text = STANDARD_NOTIFICATIONS;
            [cell setAccessoryView:switchStandardNotification];
        }
    }
    else if(nSettingRow == N_SETTINGS_ROW_PUSH_TIMING){
        if(indexPath.row == SETTINGS_TIMING_WEEKDAY_MORNING_ROW){
            cell.textLabel.text = WEEKDAY_MORNING;
            cell.accessoryView = (userPrefs.notificationMorning ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
        }
        else if(indexPath.row == SETTINGS_TIMING_WEEKDAY_MIDDAY_ROW){
            cell.textLabel.text = WEEKDAY_MIDDAY;
            cell.accessoryView = (userPrefs.notificationMidday ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
        }
        else if(indexPath.row == SETTINGS_TIMING_WEEKDAY_EVENING_ROW){
            cell.textLabel.text = WEEKDAY_EVENING_PEAK;
            cell.accessoryView = (userPrefs.notificationEvening ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
        }
        else if(indexPath.row == SETTINGS_TIMING_WEEKDAY_NIGHT_ROW){
            cell.textLabel.text = WEEKDAY_NIGHT;
            cell.accessoryView = (userPrefs.notificationNight ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
        }
        else if(indexPath.row == SETTINGS_TIMING_WEEKEND_ROW){
            cell.textLabel.text = WEEKENDS;
            cell.accessoryView = (userPrefs.notificationWeekend ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]] : nil);
        }
    }
    else if(nSettingRow == N_SETTINGS_ROW_TRANSIT_MODE){
        if(indexPath.row == 0){
            cell.textLabel.text = TRANSIT_ONLY;
            if(userPrefs.transitMode == TRANSIT_MODE_TRANSIT_ONLY){
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
            }
            else{
                cell.accessoryView = nil;
            }
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = BIKE_ONLY;
            if(userPrefs.transitMode == TRANSIT_MODE_BIKE_ONLY){
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
            }
            else{
                cell.accessoryView = nil;
            }
        }
        else if(indexPath.row == 2){
            cell.textLabel.text = BIKE_AND_TRANSIT;
            if(userPrefs.transitMode == TRANSIT_MODE_BIKE_AND_TRANSIT){
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
            }
            else{
                cell.accessoryView = nil;
            }
        }
    }
    
    else if(nSettingRow == N_SETTINGS_ROW_BIKE_PREF){
        if(indexPath.row == SETTINGS_BIKE_MAX_DISTANCE_ROW){
            cell.textLabel.text = nil;
            [cell setAccessoryView:nil];
            UIView* cellView = [cell contentView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:sliderMaximumBikeDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:sliderMaximumBikeDistance];
                [sliderMaximumBikeDistance addSubview:lblCurrentBikeDistance];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblMaximumBikeDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblMaximumBikeDistance];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblMinBikeDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblMinBikeDistance];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblMaxBikeDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblMaxBikeDistance];
            }
        }
        else if(indexPath.row == SETTINGS_FAST_VS_SAFE_ROW){
            cell.textLabel.text = nil;
            [cell setAccessoryView:nil];
            UIView* cellView = [cell contentView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:sliderPreferenceFastVsSafe] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:sliderPreferenceFastVsSafe];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblPreferenceFastVsSafe] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblPreferenceFastVsSafe];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblQuickWithAnyStreet] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblQuickWithAnyStreet];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblBikeFriendlyStreet] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblBikeFriendlyStreet];
            }
        }
        else if(indexPath.row == SETTINGS_FAST_VS_FLAT_ROW){
            cell.textLabel.text = nil;
            [cell setAccessoryView:nil];
            UIView* cellView = [cell contentView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:sliderPreferenceFastVsFlat] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:sliderPreferenceFastVsFlat];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblPreferenceFastVsFlat] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblPreferenceFastVsFlat];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblQuickWithHills] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblQuickWithHills];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblGoAroundHills] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblGoAroundHills];
            }
        }
    }
    [cell setBackgroundColor:[UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    if(nSettingRow == N_SETTINGS_ROW_ADVISORY){
        if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
            if(indexPath.row == SETTINGS_ADVISORY_WMATA_ROW){
                if(userPrefs.wMataAdvisories){
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = nil;
                    userPrefs.wMataAdvisories = false;
                }
                else{
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                    userPrefs.wMataAdvisories = true;
                }
            }
        }
        else if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:PORTLAND_BUNDLE_IDENTIFIER]){
            if(indexPath.row == SETTINGS_ADVISORY_TRIMET_ROW){
                if(userPrefs.trimetAdvisories){
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                   cell.accessoryView = nil;
                    userPrefs.trimetAdvisories = false;
                }
                else{
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                    userPrefs.trimetAdvisories = true;
                }
            }
        }
        else{
            if(indexPath.row == SETTINGS_ADVISORY_SFMUNI_ROW){
                if(userPrefs.sfMuniAdvisories){
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = nil;
                    userPrefs.sfMuniAdvisories = false;
                }
                else{
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                    userPrefs.sfMuniAdvisories = true;
                }
            }
            if(indexPath.row == SETTINGS_ADVISORY_BART_ROW){
                if(userPrefs.bartAdvisories){
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = nil;
                    userPrefs.bartAdvisories = false;
                }
                else{
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                    userPrefs.bartAdvisories = true;
                }
            }
            if(indexPath.row == SETTINGS_ADVISORY_ACTRANSIT_ROW){
                if(userPrefs.acTransitAdvisories){
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = nil;
                    userPrefs.acTransitAdvisories = false;
                }
                else{
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                    userPrefs.acTransitAdvisories = true;
                }
            }
            if(indexPath.row == SETTINGS_ADVISORY_CALTRAIN_ROW){
                if(userPrefs.caltrainAdvisories){
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = nil;
                    userPrefs.caltrainAdvisories = false;
                }
                else{
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                    userPrefs.caltrainAdvisories = true;
                }
            } 
        }
        [self.tblDetailSetting reloadData];
    }
    if(nSettingRow == N_SETTINGS_ROW_PUSH_TIMING){
        if(indexPath.row == SETTINGS_TIMING_WEEKDAY_MORNING_ROW){
            if(userPrefs.notificationMorning){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryView = nil;
                userPrefs.notificationMorning = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                userPrefs.notificationMorning = true;
            }
        }
        else if(indexPath.row == SETTINGS_TIMING_WEEKDAY_MIDDAY_ROW){
            if(userPrefs.notificationMidday){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
               cell.accessoryView = nil;
                userPrefs.notificationMidday = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                userPrefs.notificationMidday = true;
            }
        }
        
        else if(indexPath.row == SETTINGS_TIMING_WEEKDAY_EVENING_ROW){
            if(userPrefs.notificationEvening){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryView = nil;
                userPrefs.notificationEvening = false; 
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                userPrefs.notificationEvening = true;
            }
        }
        else if(indexPath.row == SETTINGS_TIMING_WEEKDAY_NIGHT_ROW){
            if(userPrefs.notificationNight){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryView = nil;
                userPrefs.notificationNight = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                userPrefs.notificationNight = true; 
            }
        }
        else if(indexPath.row == SETTINGS_TIMING_WEEKEND_ROW){
            if(userPrefs.notificationWeekend){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryView = nil;
                userPrefs.notificationWeekend = false; 
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkMark.png"]];
                userPrefs.notificationWeekend = true;
            }
        }
    }
    if(nSettingRow == N_SETTINGS_ROW_TRANSIT_MODE){
        if(indexPath.row == 0){
            userPrefs.transitMode = TRANSIT_MODE_TRANSIT_ONLY;
        }
        else if(indexPath.row == 1){
            userPrefs.transitMode = TRANSIT_MODE_BIKE_ONLY;
        }
        else if(indexPath.row == 2){
            userPrefs.transitMode = TRANSIT_MODE_BIKE_AND_TRANSIT;
        }
         [self.tblDetailSetting reloadData];
    }
}


-(void)switchUrgentNotificationChanged {
    [UserPreferance userPreferance].urgentNotificationSound = switchUrgentNotification.isOn;

}

-(void)switchStandardNotificationChanged {
    [UserPreferance userPreferance].standardNotificationSound = switchStandardNotification.isOn;
}

-(IBAction)popOutToSettings:(id)sender{
  [self.navigationController popViewControllerAnimated:YES];  
}

@end
