//
//  FeedBackViewController.h
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/15/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface FeedBackViewController : UIViewController  <AVAudioRecorderDelegate, AVAudioPlayerDelegate>{
    
   	NSURL * recordedTmpFile;
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
}
@property (nonatomic,retain) UIActivityIndicatorView * actSpinner;
-(void)setUpUI;
@end
