//
//  SettingInfoViewController.h
//  Nimbler
//
//  Created by JaY Kumbhani on 6/25/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import "Foundation/foundation.h"
#import "SettingDetailViewController.h"

@interface SettingInfoViewController : UIViewController <RKRequestDelegate,UITableViewDataSource,UITableViewDelegate,SettingDetailViewControllerDelegate>{
    
    UIAlertView *alertView;
    IBOutlet UISlider *sliderMaxWalkDistance;
    IBOutlet UISwitch *switchPushEnable;
    IBOutlet UIButton *btnUpdateSetting;
    IBOutlet UISlider *sliderPushNotification;
    UISwitch *switchEnableUrgentSound;
    UISwitch *switchEnableStandardSound;
    int      enableUrgentSoundFlag;
    int      enableStandardSoundFlag;
    UILabel *lblSliderMaxWalkDistanceValue;
    int pushHour;
    BOOL isPush;
    IBOutlet UITableView *tblSetting;
    
    UISwitch *switchPushNotification;
    UISlider *sliderPushNotificationFrequency;
    UILabel  *lblFrequencyOfPush;
    UILabel  *lblMaximumWalkDistance;
    UISlider *sliderMaximumWalkDistance;
    
    UILabel *lblFrequently;
    UILabel *lblRarely;
    UILabel *lblMinWalkDistance;
    UILabel *lblMaxWalkDistance;
    UILabel *lblCurrentMaxWalkDistance;
    SettingDetailViewController *settingDetailViewController;
}

@property (nonatomic, strong) IBOutlet UISwitch *switchPushEnable;
@property (nonatomic, strong) IBOutlet UIButton *btnUpdateSetting;
@property (nonatomic, strong) IBOutlet UISlider *sliderMaxWalkDistance;
@property (nonatomic, strong) IBOutlet UISlider *sliderPushNotification;
@property (nonatomic, strong) IBOutlet UISwitch *switchEnableUrgentSound;
@property (nonatomic, strong) IBOutlet UISwitch *switchEnableStandardSound;
@property (nonatomic, strong) IBOutlet UITableView *tblSetting;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic)   int      enableUrgentSoundFlag;
@property (nonatomic)   int      enableStandardSoundFlag;
@property (nonatomic, strong) UILabel *lblSliderMaxWalkDistanceValue;
@property (nonatomic) int pushHour;
@property (nonatomic) BOOL isPush;

@property (nonatomic, strong) UISwitch *switchPushNotification;
@property (nonatomic, strong) UISlider *sliderPushNotificationFrequency;
@property (nonatomic, strong) UILabel  *lblFrequencyOfPush;
@property (nonatomic, strong) UILabel  *lblMaximumWalkDistance;
@property (nonatomic, strong) UISlider *sliderMaximumWalkDistance;
@property (nonatomic, strong) UILabel *lblFrequently;
@property (nonatomic, strong) UILabel *lblRarely;
@property (nonatomic, strong) UILabel *lblMinWalkDistance;
@property (nonatomic, strong) UILabel *lblMaxWalkDistance;
@property (nonatomic, strong) UILabel *lblCurrentMaxWalkDistance;
@property (nonatomic, strong) SettingDetailViewController *settingDetailViewController;

-(IBAction)UpdateSetting:(id)sender;
-(IBAction)sliderWalkDistance:(UISlider *)sender;
-(IBAction)sliderWalkDistanceValueChanged:(UISlider *)sender;
-(IBAction)sliderPushNotification:(UISlider *)sender;
-(IBAction)pushNotificationValueChanged:(UISlider *)sender;

-(UIAlertView *) upadetSettings;
-(void)popOutFromSettingView;
-(void)fetchUserSettingData;
- (void) saveSetting;
@end