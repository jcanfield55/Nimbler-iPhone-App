//
//  SettingInfoViewController.h
//  Nimbler
//
//  Created by JaY Kumbhani on 6/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Restkit/RestKit.h>
#import "Foundation/foundation.h"

@interface SettingInfoViewController : UIViewController <UIPickerViewDelegate,UIPickerViewDataSource,RKRequestDelegate>{
    
    IBOutlet UIPickerView *PickerTweetCount;
    NSMutableArray *arrayTweets;
    UIAlertView *alertView;
    IBOutlet UITextField *txtMaxWalkDistance;
}


-(IBAction)UpdateSetting:(id)sender;

-(UIAlertView *) upadetSettings;
-(void)popOutFromSettingView;
@end
