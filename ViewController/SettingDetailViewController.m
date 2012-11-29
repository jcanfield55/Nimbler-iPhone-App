//
//  SettingDetailViewController.m
//  Nimbler Caltrain
//
//  Created by macmini on 21/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SettingDetailViewController.h"


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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        switchUrgentNotification = [[UISwitch alloc] init];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [switchUrgentNotification setOnTintColor:[UIColor lightGrayColor]];
        }
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_URGENTNOTIFICATION_SOUND] intValue] == 1){
            [switchUrgentNotification setOn:YES];
        }
        else{
            [switchUrgentNotification setOn:NO];
        }
        switchStandardNotification = [[UISwitch alloc] init];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [switchStandardNotification setOnTintColor:[UIColor lightGrayColor]];
        }
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_STANDARDNOTIFICATION_SOUND] intValue] == 1){
            [switchStandardNotification setOn:YES];
        }
        else{
            [switchStandardNotification setOn:NO];
        }
        
        
        lblMaximumBikeDistance=[[UILabel alloc] initWithFrame:CGRectMake(DETAIL_SETTING_MAIN_LABEL_XPOS,DETAIL_SETTING_MAIN_LABEL_YPOS, DETAIL_SETTING_MAIN_LABEL_WIDTH, DETAIL_SETTING_MAIN_LABEL_HEIGHT)];
        [lblMaximumBikeDistance setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        lblMaximumBikeDistance.backgroundColor =[UIColor clearColor];
        lblMaximumBikeDistance.adjustsFontSizeToFitWidth=YES;
        lblMaximumBikeDistance.text=MAXIMUM_BIKE_DISTANCE;
        [lblMaximumBikeDistance setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        sliderMaximumBikeDistance = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS,SLIDERS_YPOS,SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderMaximumBikeDistance
             setMinimumTrackTintColor:[UIColor lightGrayColor]];
        }
        [sliderMaximumBikeDistance setMinimumValue:MAX_BIKE_DISTANCE_MIN_VALUE];
        [sliderMaximumBikeDistance setMaximumValue:MAX_BIKE_DISTANCE_MAX_VALUE];
        if([[NSUserDefaults standardUserDefaults] objectForKey:MAX_BIKE_DISTANCE]){
            [sliderMaximumBikeDistance setValue:[[[NSUserDefaults standardUserDefaults] objectForKey:MAX_BIKE_DISTANCE] intValue]];
        }
        else{
            [sliderMaximumBikeDistance setValue:MAX_BIKE_DISTANCE_DEFAULT_VALUE];
        }
        [sliderMaximumBikeDistance addTarget:self action:@selector(maxBikeDistanceValueChanged:) forControlEvents:UIControlEventTouchUpInside];
        
        
        lblPreferenceFastVsSafe=[[UILabel alloc] initWithFrame:CGRectMake(DETAIL_SETTING_MAIN_LABEL_XPOS,DETAIL_SETTING_MAIN_LABEL_YPOS, DETAIL_SETTING_MAIN_LABEL_WIDTH, DETAIL_SETTING_MAIN_LABEL_HEIGHT)];
        [lblPreferenceFastVsSafe setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        lblPreferenceFastVsSafe.backgroundColor =[UIColor clearColor];
        lblPreferenceFastVsSafe.adjustsFontSizeToFitWidth=YES;
        lblPreferenceFastVsSafe.text=PREFERENCE_FAST_VS_SAFE;
        [lblPreferenceFastVsSafe setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        sliderPreferenceFastVsSafe = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS, SLIDERS_YPOS1, SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderPreferenceFastVsSafe
             setMinimumTrackTintColor:[UIColor lightGrayColor]];
        }
        [sliderPreferenceFastVsSafe setMinimumValue:BIKE_PREFERENCE_MIN_VALUE];
        [sliderPreferenceFastVsSafe setMaximumValue:BIKE_PREFERENCE_MAX_VALUE];
        if([[NSUserDefaults standardUserDefaults] objectForKey:PREFERENCE_FAST_VS_SAFE]){
            [sliderPreferenceFastVsSafe setValue:[[[NSUserDefaults standardUserDefaults] objectForKey:PREFERENCE_FAST_VS_SAFE] floatValue]];
        }
        else{
            [sliderPreferenceFastVsSafe setValue:BIKE_PREFERENCE_DEFAULT_VALUE];
        }
        
        lblPreferenceFastVsFlat=[[UILabel alloc] initWithFrame:CGRectMake(DETAIL_SETTING_MAIN_LABEL_XPOS,DETAIL_SETTING_MAIN_LABEL_YPOS, DETAIL_SETTING_MAIN_LABEL_WIDTH, DETAIL_SETTING_MAIN_LABEL_HEIGHT)];
        [lblPreferenceFastVsFlat setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        lblPreferenceFastVsFlat.backgroundColor =[UIColor clearColor];
        lblPreferenceFastVsFlat.adjustsFontSizeToFitWidth=YES;
        lblPreferenceFastVsFlat.text=PREFERENCE_FAST_VS_FLAT;
        [lblPreferenceFastVsFlat setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        sliderPreferenceFastVsFlat = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS, SLIDERS_YPOS1, SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderPreferenceFastVsFlat
             setMinimumTrackTintColor:[UIColor lightGrayColor]];
        }
        [sliderPreferenceFastVsFlat setMinimumValue:BIKE_PREFERENCE_MIN_VALUE];
        [sliderPreferenceFastVsFlat setMaximumValue:BIKE_PREFERENCE_MAX_VALUE];
        if([[NSUserDefaults standardUserDefaults] objectForKey:PREFERENCE_FAST_VS_FLAT]){
            [sliderPreferenceFastVsFlat setValue:[[[NSUserDefaults standardUserDefaults] objectForKey:PREFERENCE_FAST_VS_FLAT] floatValue]];
        }
        else{
            [sliderPreferenceFastVsFlat setValue:BIKE_PREFERENCE_DEFAULT_VALUE];
        }
        lblCurrentBikeDistance = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, LABEL_MAXWALK_Distance_WIDTH, LABEL_MAXWALK_Distance_HEIGHT)] ;
        [lblCurrentBikeDistance setTextColor:[UIColor redColor]];
        [lblCurrentBikeDistance setBackgroundColor:[UIColor clearColor]];
        [lblCurrentBikeDistance setTextAlignment:UITextAlignmentCenter];
        [lblCurrentBikeDistance setFont:[UIFont MEDIUM_FONT]];
        
        lblMinBikeDistance=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_DISTANCE_LABEL_XPOS,BIKE_DISTANCE_LABEL_YPOS, BIKE_DISTANCE_LABEL_WIDTH, BIKE_DISTANCE_LABEL_HEIGHT)];
        [lblMinBikeDistance setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblMinBikeDistance.backgroundColor =[UIColor clearColor];
        lblMinBikeDistance.adjustsFontSizeToFitWidth=YES;
        lblMinBikeDistance.text=[NSString stringWithFormat:@"%d",MAX_BIKE_DISTANCE_MIN_VALUE];
        [lblMinBikeDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblMaxBikeDistance=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_DISTANCE_LABEL_XPOS1,BIKE_DISTANCE_LABEL_YPOS, BIKE_DISTANCE_LABEL_WIDTH, BIKE_DISTANCE_LABEL_HEIGHT)];
        [lblMaxBikeDistance setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblMaxBikeDistance.backgroundColor =[UIColor clearColor];
        lblMaxBikeDistance.adjustsFontSizeToFitWidth=YES;
        lblMaxBikeDistance.text=[NSString stringWithFormat:@"%d",MAX_BIKE_DISTANCE_MAX_VALUE];;
        [lblMaxBikeDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblQuickWithHills=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblQuickWithHills setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblQuickWithHills.backgroundColor =[UIColor clearColor];
        lblQuickWithHills.adjustsFontSizeToFitWidth=YES;
        lblQuickWithHills.text= QUICK_WITH_HILLS;
        [lblQuickWithHills setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblGoAroundHills=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS1,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblGoAroundHills setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblGoAroundHills.backgroundColor =[UIColor clearColor];
        lblGoAroundHills.adjustsFontSizeToFitWidth=YES;
        lblGoAroundHills.text= GO_AROUNG_HILLS;
        [lblGoAroundHills setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblQuickWithAnyStreet=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblQuickWithAnyStreet setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblQuickWithAnyStreet.backgroundColor =[UIColor clearColor];
        lblQuickWithAnyStreet.adjustsFontSizeToFitWidth=YES;
        lblQuickWithAnyStreet.text= QUICK_WITH_ANY_STREET;
        [lblQuickWithAnyStreet setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblBikeFriendlyStreet=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS1,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblBikeFriendlyStreet setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblBikeFriendlyStreet.backgroundColor =[UIColor clearColor];
        lblBikeFriendlyStreet.adjustsFontSizeToFitWidth=YES;
        lblBikeFriendlyStreet.text= BIKE_FRIENDLY_STREET;
        [lblBikeFriendlyStreet setFont:[UIFont SMALL_OBLIQUE_FONT]];
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
    [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
    lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
    [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
    lblNavigationTitle.backgroundColor =[UIColor clearColor];
    lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
    
    if(nSettingRow == 0){
        lblNavigationTitle.text = ADVISORY_CHOICES;
    }
    else if(nSettingRow == 3){
        lblNavigationTitle.text = NOTIFICATION_SOUND;
    }
    else if(nSettingRow == 4){
        lblNavigationTitle.text = NOTIFICATION_TIMING;
    }
    else if(nSettingRow == 5){
        lblNavigationTitle.text = TRANSIT_MODE;
    }
    else if(nSettingRow == 7){
        lblNavigationTitle.text = BIKE_PREFERENCES;
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
    [self.tblDetailSetting setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_background.png"]]];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    isSettingDetail = NO;
    if(nSettingRow == 3){
        if(switchUrgentNotification.isOn){
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:ENABLE_URGENTNOTIFICATION_SOUND];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else{
            [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:ENABLE_URGENTNOTIFICATION_SOUND];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        if(switchStandardNotification.isOn){
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:ENABLE_STANDARDNOTIFICATION_SOUND];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else{
            [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:ENABLE_STANDARDNOTIFICATION_SOUND];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    if(nSettingRow == 7){
        int nBikeDistance = sliderMaximumBikeDistance.value;
        float denominator = 0.5*sliderPreferenceFastVsSafe.value + 0.5*sliderPreferenceFastVsFlat.value + 1;
        float bikeTriangleFlat = sliderPreferenceFastVsSafe.value / denominator;
        float bikeTriangleBikeFriendly = sliderPreferenceFastVsFlat.value / denominator;
        float bikeTriangleQuick = (2 - sliderPreferenceFastVsSafe.value - sliderPreferenceFastVsFlat.value)/(2 * denominator);
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d",nBikeDistance] forKey:MAX_BIKE_DISTANCE];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f",sliderPreferenceFastVsSafe.value] forKey:PREFERENCE_FAST_VS_SAFE];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f",sliderPreferenceFastVsFlat.value] forKey:PREFERENCE_FAST_VS_FLAT];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f",bikeTriangleQuick] forKey:BIKE_TRIANGLE_QUICK];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f",bikeTriangleBikeFriendly] forKey:BIKE_TRIANGLE_BIKE_FRIENDLY];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f",bikeTriangleFlat] forKey:BIKE_TRIANGLE_FLAT];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
       [settingDetailDelegate updateSetting];
}
- (void)popOutToSettings{
    [self.navigationController popViewControllerAnimated:YES];
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
    int nRowCount;
    if(nSettingRow == 0){
        nRowCount = 4;
    }
    else if(nSettingRow == 3){
        nRowCount = 2;
    }
    else if(nSettingRow == 4){
        nRowCount = 5;
    }
    else if(nSettingRow == 5){
        nRowCount = 3;
    }
    else if(nSettingRow == 7){
        nRowCount = 3;
    }
    return nRowCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    int nRowHeight;
    if(nSettingRow == 7){
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
    [cell.textLabel setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
    [cell.textLabel setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
    if(nSettingRow == 0){
        if(indexPath.row == 0){
            cell.textLabel.text = SFMUNI_ADVISORIES;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = BART_ADVISORIES;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 2){
            cell.textLabel.text = ACTRANSIT_ADVISORIES;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 3){
            cell.textLabel.text = CALTRAIN_ADVISORIES;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
    else if(nSettingRow == 3){
        if(indexPath.row == 0){
            cell.textLabel.text = URGENT_NOTIFICATIONS;
            [cell setAccessoryView:switchUrgentNotification];
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = STANDARD_NOTIFICATIONS;
            [cell setAccessoryView:switchStandardNotification];
        }
    }
    else if(nSettingRow == 4){
        if(indexPath.row == 0){
            cell.textLabel.text = WEEKDAY_MORNING;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MORNING] intValue] == 1){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = WEEKDAY_MIDDAY;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MIDDAY] intValue] == 1){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 2){
            cell.textLabel.text = WEEKDAY_EVENING_PEAK;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_EVENING] intValue] == 1){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 3){
            cell.textLabel.text = WEEKDAY_NIGHT;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_NIGHT] intValue] == 1){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 4){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_WEEKEND] intValue] == 1){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            cell.textLabel.text = WEEKENDS;
        }
    }
    else if(nSettingRow == 5){
        if(indexPath.row == 0){
            cell.textLabel.text = TRANSIT_ONLY;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:TRANSIT_MODE_SELECTED] intValue] == 2){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
               cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = BIKE_ONLY;
            if([[[NSUserDefaults standardUserDefaults] objectForKey:TRANSIT_MODE_SELECTED] intValue] == 4){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 2){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:TRANSIT_MODE_SELECTED] intValue] == 5){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            cell.textLabel.text = BIKE_AND_TRANSIT;
        }
    }
    
    else if(nSettingRow == 7){
        if(indexPath.row == 0){
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
        else if(indexPath.row == 1){
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
        else if(indexPath.row == 2){
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
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(nSettingRow == 0){
        if(indexPath.row == 0){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_SFMUNI_ADV] intValue] == 1){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:ENABLE_SFMUNI_ADV];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:ENABLE_SFMUNI_ADV];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        if(indexPath.row == 1){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_BART_ADV] intValue] == 1){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:ENABLE_BART_ADV];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:ENABLE_BART_ADV];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        if(indexPath.row == 2){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_ACTRANSIT_ADV] intValue] == 1){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:ENABLE_ACTRANSIT_ADV];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:ENABLE_ACTRANSIT_ADV];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        if(indexPath.row == 3){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_CALTRAIN_ADV] intValue] == 1){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:ENABLE_CALTRAIN_ADV];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:ENABLE_CALTRAIN_ADV];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        [self.tblDetailSetting reloadData];
    }
    if(nSettingRow == 4){
        if(indexPath.row == 0){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MORNING] intValue] == 1){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:NOTIF_TIMING_MORNING];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:NOTIF_TIMING_MORNING];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        else if(indexPath.row == 1){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_MIDDAY] intValue] == 1){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:NOTIF_TIMING_MIDDAY];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:NOTIF_TIMING_MIDDAY];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        
        else if(indexPath.row == 2){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_EVENING] intValue] == 1){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:NOTIF_TIMING_EVENING];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:NOTIF_TIMING_EVENING];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        else if(indexPath.row == 3){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_NIGHT] intValue] == 1){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:NOTIF_TIMING_NIGHT];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:NOTIF_TIMING_NIGHT];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        else if(indexPath.row == 4){
            if([[[NSUserDefaults standardUserDefaults] objectForKey:NOTIF_TIMING_WEEKEND] intValue] == 1){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:NOTIF_TIMING_WEEKEND];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:NOTIF_TIMING_WEEKEND];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
    if(nSettingRow == 5){
        if(indexPath.row == 0){
            [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:TRANSIT_MODE_SELECTED];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else if(indexPath.row == 1){
            [[NSUserDefaults standardUserDefaults] setObject:@"4" forKey:TRANSIT_MODE_SELECTED];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else if(indexPath.row == 2){
            [[NSUserDefaults standardUserDefaults] setObject:@"5" forKey:TRANSIT_MODE_SELECTED];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    [self.tblDetailSetting reloadData];
    }
}

@end
