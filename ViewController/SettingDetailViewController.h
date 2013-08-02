//
//  SettingDetailViewController.h
//  Nimbler Caltrain
//
//  Created by macmini on 21/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingDetailViewControllerDelegate <NSObject>
- (void) updateSetting;
@end
@interface SettingDetailViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>{
    UITableView *tblDetailSetting;
    int nSettingRow;
    UISwitch *switchUrgentNotification;
    UISwitch *switchStandardNotification;
    UILabel  *lblMaximumBikeDistance;
    UISlider *sliderMaximumBikeDistance;
    UILabel  *lblPreferenceFastVsSafe;
    UISlider *sliderPreferenceFastVsSafe;
    UILabel  *lblPreferenceFastVsFlat;
    UISlider *sliderPreferenceFastVsFlat;
    
    UILabel *lblCurrentBikeDistance;
    UILabel *lblMinBikeDistance;
    UILabel *lblMaxBikeDistance;
    
    UILabel *lblQuickWithHills;
    UILabel *lblGoAroundHills;
    UILabel *lblQuickWithAnyStreet;
    UILabel *lblBikeFriendlyStreet;
    BOOL isSettingDetail;
    id<SettingDetailViewControllerDelegate> settingDetailDelegate;
    
    UIButton *advisoriesButton;
    UIButton *setttingsButton;
    UIButton *feedBackButton;
    UIButton *backButton;
    UILabel *titleLabel;
}
@property (nonatomic, strong) IBOutlet UITableView *tblDetailSetting;
@property (nonatomic) int nSettingRow;
@property (nonatomic, strong) UISwitch *switchUrgentNotification;
@property (nonatomic, strong) UISwitch *switchStandardNotification;
@property (nonatomic, strong) UILabel  *lblMaximumBikeDistance;
@property (nonatomic, strong) UISlider *sliderMaximumBikeDistance;
@property (nonatomic, strong) UILabel  *lblPreferenceFastVsSafe;
@property (nonatomic, strong) UISlider *sliderPreferenceFastVsSafe;
@property (nonatomic, strong) UILabel  *lblPreferenceFastVsFlat;
@property (nonatomic, strong) UISlider *sliderPreferenceFastVsFlat;
@property (nonatomic, strong) UILabel  *lblCurrentBikeDistance;
@property (nonatomic, strong) UILabel *lblMinBikeDistance;
@property (nonatomic, strong) UILabel *lblMaxBikeDistance;
@property (nonatomic, strong) UILabel *lblQuickWithHills;
@property (nonatomic, strong) UILabel *lblGoAroundHills;
@property (nonatomic, strong) UILabel *lblQuickWithAnyStreet;
@property (nonatomic, strong) UILabel *lblBikeFriendlyStreet;
@property (nonatomic) BOOL isSettingDetail;
@property (nonatomic, strong) id<SettingDetailViewControllerDelegate> settingDetailDelegate;
@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) NSString *titleLabelString;
@property (nonatomic, strong) UIImageView *imgViewCheckMark;


-(IBAction)popOutToSettings:(id)sender;
-(IBAction)maxBikeDistanceValueChanged:(UISlider *)sender;

-(void)switchUrgentNotificationChanged;
-(void)switchStandardNotificationChanged;
@end
