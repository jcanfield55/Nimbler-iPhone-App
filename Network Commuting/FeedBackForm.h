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
#import "FeedBackReqParam.h"

@interface FeedBackForm : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, RKRequestDelegate, UIAlertViewDelegate>{
    
   	NSString *soundFilePath;
    NSString *tpURLResource;
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    TPResponse *tpResponse;
    UIProgressView *recProgressView;

    IBOutlet UITextView *txtFeedBack;
    IBOutlet UILabel *labelRecTime;
    IBOutlet UILabel *labelCurrentActivityStatus;
       
    IBOutlet UIButton * btnPlayRecording;
    IBOutlet UIButton * btnStopRecording;
    IBOutlet UIButton * btnPauseRecording;
    IBOutlet UIButton * btnRecordRecording;
        
    IBOutlet UIButton * btnSubmitFeedback;
    IBOutlet UITextField *txtEmailId;
    int secondsLeft;
    float secondElapsed;
    BOOL isRepeat;
    NSTimer *timer;
    BOOL isFromPause;
    UIActivityIndicatorView *busyIndicator;
    
    FeedBackReqParam *fbReqParams;
    
    
}

@property (strong, nonatomic) IBOutlet UITextView *txtFeedBack;
@property (strong, nonatomic) IBOutlet UITextField *txtEmailId;
@property (strong, nonatomic) TPResponse *tpResponse; 
@property(nonatomic,retain) NSString *tpURLResource;
@property(nonatomic,retain) NSString *mesg;
@property (strong, nonatomic) UIAlertView * alertView;
@property (strong, nonatomic) IBOutlet UIButton *btnPlayRecording,*btnStopRecording,*btnPauseRecording,*btnRecordRecording;


-(IBAction)startRecord:(id)sender;
-(IBAction)stopRecord:(id)sender;
-(IBAction)pauseRecord:(id)sender;
-(IBAction)playRecord:(id)sender;
-(IBAction)submitFeedBack:(id)sender;

@property (strong, nonatomic) FeedBackReqParam *fbReqParams;; 

-(UIAlertView *) childAlertViewRec ;
-(UIAlertView *) feedbackConfirmAlert ;

-(void)sendFeedbackToServer;

-(id)initWithFeedBack:(NSString *)nibNameOrNil fbParam:(FeedBackReqParam *)fbParam bundle:(NSBundle *)nibBundle;
-(BOOL)isPhoneSilent;

@end

