//
//  FeedBackForm.h
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import "TPResponse.h"
#import "Plan.h"


@interface FeedBackForm : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate,RKObjectLoaderDelegate, RKRequestDelegate, UIAlertViewDelegate>{
    
   	NSString *soundFilePath;
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    TPResponse *tpResponse;
    UIProgressView *progress;
    NSString *tpURLResource;
    IBOutlet UITextView *txtFeedBack;
    IBOutlet UILabel *time;
    IBOutlet UILabel *actRunning;
    IBOutlet UITextField *txtEmailId;
    int secondsLeft;
    float secondUse;
    BOOL isRepeat;
    NSTimer *timer;
    UIActivityIndicatorView *indicator;
}

@property (strong, nonatomic) TPResponse *tpResponse; 
@property(nonatomic,retain) NSString *tpURLResource;
@property(nonatomic,retain) NSString *mesg;
@property (strong, nonatomic) UIAlertView * process;

-(IBAction)recordRecording:(id)sender;
-(IBAction)stopRecording:(id)sender;
-(IBAction)pausRecording:(id)sender;
-(IBAction)playRecording:(id)sender;
-(IBAction)submitFeedBack:(id)sender;

-(UIAlertView *) WaitPrompt ;
-(UIAlertView *) waitFb ;
-(void)sendFeedbackToServer;
@end

