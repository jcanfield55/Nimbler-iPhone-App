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
}

@property (nonatomic, strong) IBOutlet UISlider *sliderMaxWalkDistance;
@property (nonatomic, strong) IBOutlet UISlider *sliderPushNotification;


-(IBAction)UpdateSetting:(id)sender;
-(IBAction)sliderWalkDistanceValueChanged:(UISlider *)sender;
-(IBAction)sliderPushNotification:(UISlider *)sender;

-(UIAlertView *) upadetSettings;
-(void)popOutFromSettingView;
-(void)fetchUserSettingData;
@end