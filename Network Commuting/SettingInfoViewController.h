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
    IBOutlet UIStepper *steperPushHour;
    IBOutlet UILabel *lblPushTrigger;
    IBOutlet UISlider *sliderMaxWalkDistance;
    IBOutlet UISwitch *switchPushEnable;
}

@property (nonatomic, strong) IBOutlet UIStepper *steperPushHour;
@property (nonatomic, strong) IBOutlet UISlider *sliderMaxWalkDistance;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

-(IBAction)UpdateSetting:(id)sender;
-(IBAction)stepperValueChanged:(UIStepper *)sender;
-(IBAction)sliderWalkDistanceValueChanged:(UISlider *)sender;

-(UIAlertView *) upadetSettings;
-(void)popOutFromSettingView;
-(void)fetchData;
@end