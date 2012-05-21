//
//  FeedBackViewController.h
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/15/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import "TPResponse.h"

@interface FeedBackViewController : UIViewController  <AVAudioRecorderDelegate, AVAudioPlayerDelegate,RKObjectLoaderDelegate>{
    
   	NSURL * recordedTmpFile;
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
}
@property (nonatomic,retain) UIActivityIndicatorView * actSpinner;
@property(nonatomic,retain) UITextField *textFieldRounded;
@property(nonatomic,retain) UILabel *label;
//@property (strong, nonatomic) RKObjectManager *rkTPResponse; 
@property (strong, nonatomic) TPResponse *tpResponse; 

@property(nonatomic,retain) NSString *tpURLResource;
- (void)setRkTPResponse:(RKObjectManager *)rkTPResponse0;
-(void)setUpUI;
@end
