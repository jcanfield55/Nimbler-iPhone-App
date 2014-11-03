//
// FeedBackForm.h
// Nimbler
//
// Created by Sitanshu Joshi on 5/26/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import "Plan.h"
#import "FeedBackReqParam.h"

@interface FeedBackForm : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, RKRequestDelegate, UIAlertViewDelegate,UITextViewDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate,UIApplicationDelegate>{
    
    NSString *soundFilePath;
    NSString *tpURLResource;
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    UIProgressView *recProgressView;
    
    IBOutlet UITextView *txtFeedBack;
    IBOutlet UILabel *labelRecTime;
    IBOutlet UILabel *labelCurrentActivityStatus;
    
    /* these buttons removed 10/27/14
    IBOutlet UIButton * btnPlayRecording;
    IBOutlet UIButton * btnStopRecording;
    IBOutlet UIButton * btnPauseRecording;
    IBOutlet UIButton * btnRecordRecording;
     */
    
    IBOutlet UIButton *btnSubmitFeedback;
    IBOutlet UIButton *btnAppFeedback;
    IBOutlet UITextField *txtEmailId;
    int secondsLeft;
    float secondElapsed;
    BOOL isRepeat;
    NSTimer *timer;
    BOOL isFromPause;
    UIActivityIndicatorView *busyIndicator;
    
    FeedBackReqParam *fbReqParams;
    UIButton *advisoriesButton;
    UIButton *settingsButton;
    UIButton *feedBackButton;
    
    UIView *buttonsBackgroundView;
    UIView *textViewBackground;
    UIView *textFieldBackground;
    
    UIView *sentMessageView;
    
}

@property (strong, nonatomic) IBOutlet UITextView *txtFeedBack;
@property (strong, nonatomic) IBOutlet UITextField *txtEmailId;
@property(nonatomic,retain) NSString *tpURLResource;
@property(nonatomic,retain) NSString *mesg;
@property (strong, nonatomic) UIAlertView * alertView;
/* @property (strong, nonatomic) IBOutlet UIButton *btnPlayRecording,*btnStopRecording,*btnPauseRecording,*btnRecordRecording; */
@property (strong, nonatomic) IBOutlet UIView *buttonsBackgroundView;
@property (strong, nonatomic) IBOutlet UIView *textViewBackground;
@property (strong, nonatomic) IBOutlet UIView *textFieldBackground;
@property (strong, nonatomic) IBOutlet UIView *sentMessageView;

@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic) BOOL isViewPresented;

@property (strong, nonatomic) UILabel *lblNavigationTitle;
/*  These buttons were removed 10/27
-(IBAction)startRecord:(id)sender;
-(IBAction)stopRecord:(id)sender;
-(IBAction)pauseRecord:(id)sender;
-(IBAction)playRecord:(id)sender; 
 */
-(IBAction)appFeedbackClicked:(id)sender;
-(IBAction)submitFeedBack:(id)sender;
-(IBAction)cancelButtonClicked:(id)sender;

@property (strong, nonatomic) FeedBackReqParam *fbReqParams;;

-(UIAlertView *) childAlertViewRec ;
-(UIAlertView *) feedbackConfirmAlert ;

-(void)sendFeedbackToServer;

-(id)initWithFeedBack:(NSString *)nibNameOrNil fbParam:(FeedBackReqParam *)fbParam bundle:(NSBundle *)nibBundle;
-(BOOL)isPhoneSilent;
- (void) hideTabBar;

@end

