//
//  SettingViewCustomCell.h
//  Nimbler Caltrain
//
//  Created by macmini on 20/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingViewCustomCell : UITableViewCell{
    
    // Section1 Components
    UILabel  *lblSFMuniAdvisories;
    UISwitch *switchSFMuniAdvisories;
    UILabel  *lblBartAdvisories;
    UISwitch *switchBartAdvisories;
    UILabel  *lblACTransitAdvisories;
    UISwitch *switchACTransitAdvisories;
    UILabel  *lblCaltrainAdvisories;
    UISwitch *switchCaltrainAdvisories;
    
    // Section2 Components
    UILabel  *lblPushNotification;
    UISwitch *switchPushNotification;
    UILabel  *lblPushNotificationFrequency;
    UISlider *sliderPushNotificationFrequency;
    UILabel  *lblNotificationSound;
    UILabel  *lblUrgentNotifications;
    UISwitch *switchUrgentNotifications;
    UILabel  *lblStandardNotifications;
    UISwitch *switchStandardNotifications;
    UILabel  *lblNotificationTiming;
    UILabel  *lblWeekDayMorning;
    UILabel  *lblWeekDayMidDay;
    UILabel  *lblWeekDayEveningPeak;
    UILabel  *lblWeekDayNight;
    UILabel  *lblWeekends;
    
    // Section3 Components
    UILabel   *lblTransitOnly;
    UILabel   *lblBikeOnly;
    UILabel   *lblBikeAndTransit;
    
    // Section4 Components
    UILabel  *lblMaximumWalkDistance;
    UISlider *sliderMaximumWalkDistance;
    
    // Section5 Components
    UILabel  *lblMaximumBikeDistance;
    UISlider *sliderMaximumBikeDistance;
    UILabel  *lblPreferenceFastVsSafe;
    UISwitch *switchPreferenceFastVsSafe;
    UILabel  *lblPreferenceFastVsFlat;
    UISwitch *switchPreferenceFastVsFlat;
}
// Section1 Components
@property (nonatomic, strong) UILabel  *lblSFMuniAdvisories;
@property (nonatomic, strong) UISwitch *switchSFMuniAdvisories;
@property (nonatomic, strong) UILabel  *lblBartAdvisories;
@property (nonatomic, strong) UISwitch *switchBartAdvisories;
@property (nonatomic, strong) UILabel  *lblACTransitAdvisories;
@property (nonatomic, strong) UISwitch *switchACTransitAdvisories;
@property (nonatomic, strong) UILabel  *lblCaltrainAdvisories;
@property (nonatomic, strong) UISwitch *switchCaltrainAdvisories;

// Section2 Components
@property (nonatomic, strong) UILabel  *lblPushNotification;
@property (nonatomic, strong) UISwitch *switchPushNotification;
@property (nonatomic, strong) UILabel  *lblPushNotificationFrequency;
@property (nonatomic, strong) UISlider *sliderPushNotificationFrequency;
@property (nonatomic, strong) UILabel  *lblNotificationSound;
@property (nonatomic, strong) UILabel  *lblUrgentNotifications;
@property (nonatomic, strong) UISwitch *switchUrgentNotifications;
@property (nonatomic, strong) UILabel  *lblStandardNotifications;
@property (nonatomic, strong) UISwitch *switchStandardNotifications;
@property (nonatomic, strong) UILabel  *lblNotificationTiming;
@property (nonatomic, strong) UILabel  *lblWeekDayMorning;
@property (nonatomic, strong) UILabel  *lblWeekDayMidDay;
@property (nonatomic, strong) UILabel  *lblWeekDayEveningPeak;
@property (nonatomic, strong) UILabel  *lblWeekDayNight;
@property (nonatomic, strong) UILabel  *lblWeekends;

// Section3 Components
@property (nonatomic, strong) UILabel   *lblTransitOnly;
@property (nonatomic, strong) UILabel   *lblBikeOnly;
@property (nonatomic, strong) UILabel   *lblBikeAndTransit;

// Section4 Components
@property (nonatomic, strong) UILabel  *lblMaximumWalkDistance;
@property (nonatomic, strong) UISlider *sliderMaximumWalkDistance;

// Section5 Components
@property (nonatomic, strong) UILabel  *lblMaximumBikeDistance;
@property (nonatomic, strong) UISlider *sliderMaximumBikeDistance;
@property (nonatomic, strong) UILabel  *lblPreferenceFastVsSafe;
@property (nonatomic, strong) UISwitch *switchPreferenceFastVsSafe;
@property (nonatomic, strong) UILabel  *lblPreferenceFastVsFlat;
@property (nonatomic, strong) UISwitch *switchPreferenceFastVsFlat;
@end
