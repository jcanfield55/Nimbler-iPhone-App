//
//  SettingInfoViewController.h
//  Nimbler
//
//  Created by JaY Kumbhani on 6/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>
#import "Foundation/foundation.h"

@interface SettingInfoViewController : UIViewController <RKRequestDelegate>{
    
    UIAlertView *alertView;
    IBOutlet UISlider *sliderMaxWalkDistance;
    IBOutlet UISwitch *switchPushEnable;
    IBOutlet UIButton *btnUpdateSetting;
    IBOutlet UISlider *sliderPushNotification;
             UISwitch *switchEnableUrgentSound;
             UISwitch *switchEnableStandardSound;
             UILabel *lblSliderValue;
    int      enableUrgentSoundFlag;
    int      enableStandardSoundFlag;
   
}

@property (nonatomic, strong) IBOutlet UISwitch *switchPushEnable;
@property (nonatomic, strong) IBOutlet UIButton *btnUpdateSetting;
@property (nonatomic, strong) IBOutlet UISlider *sliderMaxWalkDistance;
@property (nonatomic, strong) IBOutlet UISlider *sliderPushNotification;
@property (nonatomic, strong) IBOutlet UILabel *lblSliderValue;
@property (nonatomic, strong) IBOutlet UISwitch *switchEnableUrgentSound;
@property (nonatomic, strong) IBOutlet UISwitch *switchEnableStandardSound;
@property (nonatomic)   int      enableUrgentSoundFlag;
@property (nonatomic)   int      enableStandardSoundFlag;

-(IBAction)UpdateSetting:(id)sender;
-(IBAction)sliderWalkDistanceValueChanged:(UISlider *)sender;
-(IBAction)sliderPushNotification:(UISlider *)sender;

-(UIAlertView *) upadetSettings;
-(void)popOutFromSettingView;
-(void)fetchUserSettingData;
- (void) saveSetting;
@end