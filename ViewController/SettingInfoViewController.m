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
#define PUSH_ENABLE         @"pushEnable"

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
        [sliderPushNotificationFrequency setValue:[userPrefs pushNotificationThreshold]];
        
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
        [sliderMaximumWalkDistance setValue:[userPrefs walkDistance]];

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
    UserPreferance* userPrefs = [UserPreferance userPreferance];
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
    
    [switchPushEnable setOn:userPrefs.pushEnable];
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
    [UserPreferance userPreferance].isSettingSavedSuccessfully = NO;
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

        float ss = sliderPushNotificationFrequency.value;
        int alertFrequencyIntValue = ss;
        UserPreferance *userPrefs = [UserPreferance userPreferance]; // get singleton
        
        // US 161 Implementation -- clear cache if max walk distance has been modified
        if(sliderMaximumWalkDistance.value != userPrefs.walkDistance) {
            PlanStore *planStore = [[nc_AppDelegate sharedInstance] planStore];
            [planStore  clearCache];
        }
        
        // Update preferences 
        userPrefs.pushEnable = switchPushNotification.on;
        userPrefs.pushNotificationThreshold = alertFrequencyIntValue;
        userPrefs.walkDistance = sliderMaximumWalkDistance.value;
        
        // Store changes to server
        [userPrefs saveToServer];
        
        logEvent(FLURRY_SETTINGS_SUBMITTED,
                 FLURRY_SETTING_WALK_DISTANCE, [NSString stringWithFormat:@"%f",sliderMaxWalkDistance.value],
                 FLURRY_SETTING_ALERT_COUNT, [NSString stringWithFormat:@"%d",pushHour],
                 nil, nil, nil, nil);
        
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
    NIMLOG_EVENT1(@"walk distance: %d", pushNotificationThreshold);
}

-(IBAction)pushNotificationValueChanged:(UISlider *)sender
{
    int pushNotificationThreshold = lroundf(sliderPushNotificationFrequency.value);
    [sliderPushNotificationFrequency setValue:pushNotificationThreshold];
    [sliderPushNotificationFrequency setSelected:YES];
    NIMLOG_EVENT1(@"walk distance: %d", pushNotificationThreshold);
}

-(void)popOutFromSettingView {
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    // Code Added to select Trip Planner Tab
    RXCustomTabBar *rxCustomTabBar = (RXCustomTabBar *)self.tabBarController;
    [rxCustomTabBar selectTab:0];
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
    if(indexPath.section == 0){
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
            int agencyCount;
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
    else if(indexPath.section == 1){
        if(indexPath.row == 3){
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
                [strMutableTextLabel appendString:LABEL_WKKDAY];
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
    UserPreferance* userPrefs = [UserPreferance userPreferance];
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
        else if(indexPath.row == 3){
            cell.textLabel.text = NOTIFICATION_TIMING;
            cell.detailTextLabel.text = [self detailtextLabelString:indexPath];
        }
    }
    else if(indexPath.section == 2){
//        if(indexPath.row == 0){
//            cell.textLabel.text = TRANSIT_MODE;
//            if (userPrefs.transitMode == TRANSIT_MODE_TRANSIT_ONLY){
//                cell.detailTextLabel.text = TRANSIT_ONLY;
//            }
//            if (userPrefs.transitMode == TRANSIT_MODE_BIKE_ONLY) {
//                cell.detailTextLabel.text = BIKE_ONLY;
//            }
//            if (userPrefs.transitMode == TRANSIT_MODE_BIKE_AND_TRANSIT) {
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