//
// FeedBackForm.m
// Nimbler
//
// Created by Sitanshu Joshi on 5/26/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "FeedBackForm.h"
#import "UtilityFunctions.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "nc_AppDelegate.h"
#import "SettingInfoViewController.h"
#import "twitterViewController.h"

#define RECORD_MSG @"Recording your feedback \nSpeak ..."
#define SUBMIT_MSG @"Sending your feedback \nPlease wait ..."
#define FB_TITLE @"Feedback"

#define RECORDING @"Recording...."
#define RECORDING_STOP @"Recording Stopped...."
#define RECORDING_CANCEL @"Recording Canceled...."
#define RECORDING_PAUSE @"Recording Paused...."
#define RECORDING_PLAY @"Record Playing...."
#define VOICE_FB_FILE @"voiceFeedback.caf"
#define PLAY_TIME @"Play Time : %02d"
#define TIME_LEFT @"Time Left : %02d"
#define REC_NOT_PLAY @"Error while playing recording...."
#define PLAY_COMPLETE @"Play complete...."
#define ANIMATION_PARAM @"anim"
#define FB_CONFIRMATION @"Are you sure you want to send feedback?"
#define FB_WHEN_NO_VOICE_OR_TEXT @"Please provide your text or voice feedback, then press Send"
#define ALERT_TRIP @"Trip Planner"

#define BUTTON_DONE @"Done"
#define BUTTON_CANCEL @"Cancel"
#define BUTTON_OK @"OK"

#define BORDER_WIDTH 1.0
#define RECORD_DURATION 60
#define REC_STARTTIME 0
#define BITRATE_KEY 16
#define BITDEPTH_KEY 8
#define CHANNEL_KEY 1
#define SAMPLERATE_KEY 8000.0
#define TIME_INTERVAL 2.0
#define INCREASE_PROGREEVIEW 0.0166
#define UP_DOWN_RATIO 0.3

@implementation FeedBackForm

BOOL isCancelFB = FALSE;
@synthesize tpURLResource,alertView,mesg,btnPlayRecording,btnStopRecording,btnPauseRecording,btnRecordRecording,fbReqParams;
@synthesize txtEmailId,txtFeedBack;
@synthesize buttonsBackgroundView,textViewBackground,textFieldBackground;
@synthesize sentMessageView;
@synthesize navBar,cancelButton;
@synthesize isViewPresented;

NSUserDefaults *prefs;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //[[self navigationItem] setTitle:FB_TITLE];
        prefs = [NSUserDefaults standardUserDefaults];
    }
    return self;
}
-(id)initWithFeedBack:(NSString *)nibNameOrNil fbParam:(FeedBackReqParam *)fbParam bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundle];
    if (self) {
        // Custom initialization
        fbReqParams = fbParam;
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// Part Of DE-318 Fix
// Will resign first responder if textview or textfield become first responder.
- (void)handleSingleTap{
    if([txtFeedBack isFirstResponder]){
        [txtFeedBack resignFirstResponder];
    }
    if([txtEmailId isFirstResponder]){
        [txtEmailId resignFirstResponder];
    }
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setHidden:YES];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    // Part Of DE-318 Fix
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    singleTap.delegate = self;
    [singleTap setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:singleTap];
    
    [btnSubmitFeedback addTarget:self action:@selector(submitFeedBack:) forControlEvents:UIControlEventTouchUpInside];
    
    self.txtFeedBack.delegate = self;
    self.txtEmailId.delegate = self;
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
    }
    UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
    [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
    lblNavigationTitle.text=FEED_BACK_VIEW_TITLE;
    lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
    [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
    lblNavigationTitle.backgroundColor =[UIColor clearColor];
    lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
    [lblNavigationTitle setCenter:navBar.center];
    [navBar addSubview:lblNavigationTitle];
    
    [buttonsBackgroundView.layer setCornerRadius:5.0];
    [textViewBackground.layer setCornerRadius:5.0];
    [textFieldBackground.layer setCornerRadius:5.0];
    
    [txtFeedBack setReturnKeyType:UIReturnKeyNext];
    [txtEmailId setReturnKeyType:UIReturnKeyDone];
    
    if([navBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [navBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [navBar insertSubview:[[UIImageView alloc] initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
    }

}

- (void)viewDidUnload{
    [super viewDidUnload];
    self.txtFeedBack = nil;
    self.txtEmailId = nil;
    self.btnPlayRecording = nil;
    self.btnStopRecording = nil;
    self.btnPauseRecording = nil;
    self.btnRecordRecording = nil;
}

- (void)dealloc{
    self.txtFeedBack = nil;
    self.txtEmailId = nil;
    self.btnPlayRecording = nil;
    self.btnStopRecording = nil;
    self.btnPauseRecording = nil;
    self.btnRecordRecording = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    logEvent(FLURRY_FEEDBACK_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
    [nc_AppDelegate sharedInstance].isFeedBackView = YES;

    btnSubmitFeedback.layer.cornerRadius = CORNER_RADIUS_SMALL;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    txtEmailId.text = [prefs objectForKey:USER_EMAIL];
    labelCurrentActivityStatus.text = NULL_STRING;
    txtFeedBack.layer.cornerRadius = CORNER_RADIUS_SMALL;
    
    [btnPlayRecording setEnabled:FALSE];
    [btnPauseRecording setEnabled:FALSE];
    [btnStopRecording setEnabled:FALSE];
    soundFilePath = nil;
    
    if(isViewPresented){
        UIButton *btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnCancel setBackgroundImage:[UIImage imageNamed:@"img_cancel.png"] forState:UIControlStateNormal];
        [btnCancel setFrame:CGRectMake(250, 7, 62, 30)];
        [btnCancel addTarget:self action:@selector(cancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [navBar addSubview:btnCancel];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [nc_AppDelegate sharedInstance].isFeedBackView = NO;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger) supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark-Recording functions
-(IBAction)startRecord:(id)sender
{
    logEvent(FLURRY_FEEDBACK_RECORD, nil, nil, nil, nil, nil, nil, nil, nil);

    isFromPause = NO;
    isCancelFB = FALSE;
    [btnPlayRecording setEnabled:FALSE];
    [btnPauseRecording setEnabled:FALSE];
    
    labelRecTime.text = NULL_STRING;
    [txtEmailId resignFirstResponder];
    [txtFeedBack resignFirstResponder];
    labelCurrentActivityStatus.text = RECORDING;
    
    mesg = RECORD_MSG;
    alertView = [self childAlertViewRec];
    
    secondsLeft = RECORD_DURATION;
    secondElapsed = REC_STARTTIME;
    isRepeat = YES;
    [labelRecTime setHidden:NO];
    timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(updateRecCountdown) userInfo:nil repeats: isRepeat];
    
    NSArray *tempDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *tempDirPath = [tempDir objectAtIndex:0];
    soundFilePath = [tempDirPath stringByAppendingPathComponent:VOICE_FB_FILE];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    // [NSNumber numberWithInt:kAudioFormat], AVFormatIDKey,
                                    [NSNumber numberWithInt:AVAudioQualityMin], AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:BITRATE_KEY], AVEncoderBitRateKey,
                                    [NSNumber numberWithInt:BITDEPTH_KEY], AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithInt: CHANNEL_KEY], AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:SAMPLERATE_KEY], AVSampleRateKey,
                                    nil];
    
    NSError *error = nil;
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];
    if (error) {
        NIMLOG_ERR1(@"error while Audio Recording: %@", [error localizedDescription]);
    } else {
        [audioRecorder prepareToRecord];
    }
    
    if (!audioRecorder.recording) {
        [audioRecorder record];
    }
}

-(IBAction)stopRecord:(id)sender {
    logEvent(FLURRY_FEEDBACK_STOP, nil, nil, nil, nil, nil, nil, nil, nil);

    [btnPauseRecording setEnabled:FALSE];
    [btnStopRecording setEnabled:FALSE];
    [btnRecordRecording setEnabled:TRUE];
    if (isCancelFB) {
        [btnPlayRecording setEnabled:FALSE];
        labelCurrentActivityStatus.text = RECORDING_CANCEL;
    } else {
        [btnPlayRecording setEnabled:TRUE];
        labelCurrentActivityStatus.text = RECORDING_STOP;
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO];
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    if (audioRecorder.recording)
    {
        [audioRecorder stop];
    } else if (audioPlayer.playing) {
        [audioPlayer stop];
    }
}

-(void)setActRunStatus {
    labelCurrentActivityStatus.text = NULL_STRING;
}

-(IBAction)pauseRecord:(id)sender {
    logEvent(FLURRY_FEEDBACK_PAUSE, nil, nil, nil, nil, nil, nil, nil, nil);

    if (audioPlayer.playing) {
        labelCurrentActivityStatus.text = RECORDING_PAUSE;
        isRepeat = NO;
        [labelRecTime setHidden:YES];
        [timer invalidate];
        timer = nil;
        timer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO];
        [audioPlayer pause];
        [btnPlayRecording setEnabled:TRUE];
        [btnPauseRecording setEnabled:FALSE];
        [btnRecordRecording setEnabled:TRUE];
    } else {
        labelCurrentActivityStatus.text = REC_NOT_PLAY;
        timer = nil;
        timer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO];
    }
    isFromPause = YES;
}

-(IBAction)playRecord:(id)sender {
    logEvent(FLURRY_FEEDBACK_PLAY, nil, nil, nil, nil, nil, nil, nil, nil);

    labelCurrentActivityStatus.text = RECORDING_PLAY;
    if(!isFromPause){
        secondsLeft = REC_STARTTIME;
    }
    labelRecTime.text = NULL_STRING;
    
    NSError *err;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    //if([self isPhoneSilent]){
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
    // }
    // else{
    // [session setCategory:AVAudioSessionCategoryPlayback error:&err];
    // }
    [session setActive:YES error:&err];
    
    if (!audioRecorder.recording)
    {
        NSError *error;
        if(audioPlayer == nil){
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioRecorder.url error:&error];
        }
        
        audioPlayer.delegate = self;
        if (error) {
            NIMLOG_ERR1(@"Error While Audio Playing: %@",
                  [error localizedDescription]);
        } else {
            // alertView = [self WaitPrompt];
            //when recording is being played, record & stop disable, pause is enable
            [btnStopRecording setEnabled:FALSE];
            [btnPlayRecording setEnabled:FALSE];
            [btnRecordRecording setEnabled:FALSE];
            [btnPauseRecording setEnabled:TRUE];
            [labelRecTime setHidden:NO];
            timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(updatePlayCountdown) userInfo:nil repeats: YES];
            [audioPlayer play];
        }
    }
}

-(BOOL)isPhoneSilent {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#endif
    CFStringRef state;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
    if(CFStringGetLength(state) > 0)
        return NO;
    else
        return YES;
    
}

#pragma mark Time functionds
-(void) updateRecCountdown {
    int seconds;
    secondsLeft--;
    secondElapsed += INCREASE_PROGREEVIEW;
    [recProgressView setProgress:secondElapsed];
    if(secondsLeft == REC_STARTTIME){
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        isRepeat = NO;
        [labelRecTime setHidden:YES];
        [timer invalidate];
        [self stopRecord:self];
    } else {
        if(![alertView isVisible]){
            isRepeat = NO;
            [labelRecTime setHidden:YES];
            [timer invalidate];
            timer = nil;
            [self stopRecord:self];
        }
        seconds = (secondsLeft %3600) % 60;
        labelRecTime.text = [NSString stringWithFormat:TIME_LEFT, seconds];
    }
}

-(void) updatePlayCountdown {
    secondsLeft++;
    labelRecTime.text = [NSString stringWithFormat:PLAY_TIME, secondsLeft];
}


#pragma mark audio player delegate method
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [btnPlayRecording setEnabled:TRUE];
    [btnRecordRecording setEnabled:TRUE];
    [btnPauseRecording setEnabled:FALSE];
    [btnStopRecording setEnabled:FALSE];
    
    labelCurrentActivityStatus.text = PLAY_COMPLETE;
    secondsLeft = REC_STARTTIME;
    isRepeat = NO;
    [labelRecTime setHidden:YES];
    [timer invalidate];
    timer = nil;
    labelRecTime.text = NULL_STRING;
    timer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO];
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NIMLOG_ERR1(@"Decoder Error occurred =%@",error);
}

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NIMLOG_PERF1(@"SuccessFully Recording");
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NIMLOG_ERR1(@"Encoder Error occurred = %@",error);
}

#pragma mark GestureRecognizer delegate method
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // Allow Tap gesture recognizer to only view not to buttons and textfields
    if(touch.view == self.view || touch.view == buttonsBackgroundView || touch.view == textViewBackground || touch.view == textFieldBackground){
        return YES;
    }
    return NO;
}

#pragma mark Restful request
-(IBAction)submitFeedBack:(id)sender
{
    // DE- 195 Fixed
    if([[nc_AppDelegate sharedInstance] isNetworkConnectionLive]){
        // Fixed DE-338
        // Removing the white space character from feedback text and then check the length
        NSString *feedBackText = [txtFeedBack.text stringByReplacingOccurrencesOfString:@"Type message here" withString:@""];
        if((soundFilePath == nil) && ([feedBackText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0)) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FB_TITLE_MSG message:FB_WHEN_NO_VOICE_OR_TEXT delegate:self cancelButtonTitle:BUTTON_OK otherButtonTitles:nil, nil];
            [alert show];
        } else {
            mesg = SUBMIT_MSG;
            [self sendFeedbackToServer];
        }
    }
    else{
        logEvent(FLURRY_ALERT_NO_NETWORK, FLURRY_ALERT_LOCATION, @"FeedBackForm -> submitFeedBack", nil, nil, nil, nil, nil, nil);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_TITLE message:NO_NETWORK_ALERT delegate:self cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil];
        [alert show];
    }
}

// Hide the sent message view after 3 seconds
- (void) hideMessageView{
    if(isViewPresented){
        [self dismissModalViewControllerAnimated:YES];
    }
    else{
        [self.navigationController.navigationBar setHidden:NO];
        [sentMessageView setHidden:YES];
        [[nc_AppDelegate sharedInstance].toFromViewController revealtoggle];
    }
}
#pragma mark Restful Response
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
    if ([request isGET]) {
        // if any getRequest
        
    } else if ([request isPOST]) {
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        if ([response isOK]) {
            // Success! Let's take a look at the data
            txtFeedBack.text = NULL_STRING;
            // Resign First responder of both textfield and textview when feedback sent success received from server
            if([txtFeedBack becomeFirstResponder]){
               [txtFeedBack resignFirstResponder];  
            }
            if([txtEmailId becomeFirstResponder]){
               [txtEmailId resignFirstResponder];  
            }
            RKJSONParserJSONKit* parser1 = [RKJSONParserJSONKit new];
            NSDictionary *fbParser = [parser1 objectFromString:[response bodyAsString] error:nil];
            NSString *msg;
            for (id key in fbParser) {
                NIMLOG_EVENT1(@"key: %@, value: %@", key, [fbParser objectForKey:key]);
                if ([key isEqualToString:FB_RESPONSE_MSG]) {
                    if ([[fbParser objectForKey:FB_RESPONCE_CODE] intValue] == RESPONSE_SUCCESSFULL) {
                        //msg = FB_RESPONSE_SUCCEES;
                        [self.navigationController.navigationBar setHidden:YES];
                        [sentMessageView setHidden:NO];
                        [self performSelector:@selector(hideMessageView) withObject:nil afterDelay:3.0];
                        return;
                    } else {
                        msg = FB_RESPONSE_FAIL ;
                    }
                }
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FB_TITLE_MSG message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
    }
}

#pragma mark Close keybord at return
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Any additional checks to ensure you have the correct textField here.
    if(textField == txtEmailId) {
        [txtEmailId resignFirstResponder];
        return NO;
    }
    return YES;
}

-(void)sendFeedbackToServer
{
    
    alertView = [self feedbackConfirmAlert];
    // NSString *udid = [UIDevice currentDevice].uniqueIdentifier;
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    client.cachePolicy = RKRequestCachePolicyNone;
    RKParams *rkp = [RKParams params];
    [RKClient setSharedClient:client];
    
    if (soundFilePath != nil) {
        NSString *myFile =soundFilePath;
        RKParamsAttachment* attachment = [rkp setFile:myFile forParam:FB_FILE_MARKER];
        attachment.MIMEType = FB_FILE_TYPE;
        attachment.fileName = FB_FILE_NAME;
        [rkp setValue:[NSNumber numberWithInt:FEEDBACK_AUDIO] forParam:FB_FILE_FORMAT_TYPE];
    }
    if (txtFeedBack.text != nil){
        [rkp setValue:txtFeedBack.text forParam:FB_TEXT];
        [rkp setValue:[NSNumber numberWithInt:FEEDBACK_TEXT] forParam:FB_FILE_FORMAT_TYPE];
    }
    if (txtEmailId.text != nil) {
        [rkp setValue:txtEmailId.text forParam:EMAIL_ID];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:txtEmailId.text forKey:USER_EMAIL];
    }
    if(soundFilePath != nil && txtFeedBack.text != nil) {
        [rkp setValue:[NSNumber numberWithInt:FEEDBACK_TEXT_AUDIO] forParam:FB_FILE_FORMAT_TYPE];
    }

    logEvent(FLURRY_FEEDBACK_SUBMIT,
             FLURRY_FEEDBACK_TEXT, txtFeedBack.text,
             FLURRY_USER_EMAIL, txtEmailId.text, nil, nil, nil, nil);
    
    [rkp setValue:[prefs objectForKey:DEVICE_CFUUID] forParam:DEVICE_ID];
        [rkp setValue:[nc_AppDelegate sharedInstance].FBSource forParam:FEEDBACK_SOURCE];
    [rkp setValue:@"3.5" forParam:FEEDBACK_RATING];
    
    NIMLOG_EVENT1(@"Shared Instance Feedback Source: %@",[nc_AppDelegate sharedInstance].FBSource);
    if([nc_AppDelegate sharedInstance].FBSource == [NSNumber numberWithInt:FB_SOURCE_GENERAL]){
        [rkp setValue:[nc_AppDelegate sharedInstance].FBSFromAdd forParam:FB_FORMATTEDADDR_FROM];
        [rkp setValue:[nc_AppDelegate sharedInstance].FBToAdd forParam:FB_FORMATTEDADDR_TO];
        [rkp setValue:[nc_AppDelegate sharedInstance].FBDate forParam:FB_DATE];
    } else {
        //[rkp setValue:@"" forParam:FB_UNIQUEID]; // temporary fix
//         JC Temporarily commenting this out because we need to send "" as uniqueID no matter what
        if([nc_AppDelegate sharedInstance].FBUniqueId == nil){
            [rkp setValue:@"" forParam:FB_UNIQUEID];
        }
        else{
            [rkp setValue:[nc_AppDelegate sharedInstance].FBUniqueId forParam:FB_UNIQUEID];
        } 
    }
    [rkp setValue:[[nc_AppDelegate sharedInstance] deviceTokenString]  forParam:DEVICE_TOKEN];
    [rkp setValue:[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId] forParam:APPLICATION_TYPE];
    [rkp setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"] forParam:APPLICATION_VERSION];
    
    [[RKClient sharedClient] post:FB_REQUEST params:rkp delegate:self];
}

#pragma mark UIAlertView utility
-(UIAlertView *) feedbackConfirmAlert
{
    UIAlertView *alerts = [[UIAlertView alloc]
                           initWithTitle:mesg
                           message:nil delegate:nil cancelButtonTitle:nil
                           otherButtonTitles:nil];
    busyIndicator = [[UIActivityIndicatorView alloc]
                     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    busyIndicator.frame = CGRectMake(135, 80, 20, 20);
    [busyIndicator startAnimating];
    [alerts addSubview:busyIndicator];
    [alerts show];
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
    return alerts;
}

-(UIAlertView *) childAlertViewRec
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:mesg
                          message:nil delegate:self cancelButtonTitle:BUTTON_DONE
                          otherButtonTitles:BUTTON_CANCEL,nil];
    [alert show];
    recProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    recProgressView.center = CGPointMake(alert.bounds.size.width / 2, alert.bounds.size.height - 67);
    [alert addSubview:recProgressView];
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
    return alert;
}

-(void)alertView: (UIAlertView *)UIAlertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *btnName = [UIAlertView buttonTitleAtIndex:buttonIndex];
    if ([btnName isEqualToString:BUTTON_CANCEL]) {
        soundFilePath = nil;
        audioPlayer = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *tempDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *tempDirPath = [tempDir objectAtIndex:0];
        NSString *recordedAudioPath = [tempDirPath stringByAppendingPathComponent:VOICE_FB_FILE];
        if([fileManager fileExistsAtPath:recordedAudioPath]){
            [fileManager removeItemAtPath:recordedAudioPath error:nil];
        }
        isCancelFB = TRUE;
    } else if ([btnName isEqualToString:BUTTON_DONE]) {
        [self.btnPlayRecording setEnabled:TRUE];
    }
}

-(void)popOut
{
    //revealToggle
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    [[nc_AppDelegate sharedInstance].toFromViewController revealtoggle];
}

#pragma mark TextField animation at selected
-(void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    int txtPosition = (textField.frame.origin.y - 160);
    const int movementDistance = (txtPosition < 0 ? 0 : txtPosition); // tweak as needed
    const float movementDuration = UP_DOWN_RATIO; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations:ANIMATION_PARAM context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [UIView beginAnimations:ANIMATION_PARAM context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: 0.5];
    if([UIScreen mainScreen].bounds.size.height == IPHONE5HEIGHT){
       [self.view setFrame:CGRectMake(self.view.frame.origin.x,-90, self.view.frame.size.width, self.view.frame.size.height)];
    }
    else{
       [self.view setFrame:CGRectMake(self.view.frame.origin.x,-160, self.view.frame.size.width, self.view.frame.size.height)]; 
    }
    [UIView commitAnimations];
    
    //[self animateTextField: textField up: YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    //[self animateTextField: textField up: NO];
    [UIView beginAnimations:ANIMATION_PARAM context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: 0.5];
    if(isViewPresented){
      [self.view setFrame:CGRectMake(self.view.frame.origin.x,20, self.view.frame.size.width, self.view.frame.size.height)];
    }
    else{
        [self.view setFrame:CGRectMake(self.view.frame.origin.x,0, self.view.frame.size.width, self.view.frame.size.height)];
    }
    [UIView commitAnimations];
}

#pragma mark TextView animation at selected
- (void) animateTextView: (UITextView*) textView up: (BOOL) up{
    int txtPosition = (textView.frame.origin.y - 140);
    const int movementDistance = (txtPosition < 0 ? 0 : txtPosition); // tweak as needed
    const float movementDuration = UP_DOWN_RATIO; // tweak as needed
    int movement = (up ? -movementDistance : movementDistance);
    [UIView beginAnimations:ANIMATION_PARAM context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    if([textView.text isEqualToString:@"Type message here"]){
        [textView setText:@""];
        [textView setTextColor:[UIColor darkGrayColor]];
    }
    [UIView beginAnimations:ANIMATION_PARAM context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: 0.5];
    [self.view setFrame:CGRectMake(self.view.frame.origin.x,-90, self.view.frame.size.width, self.view.frame.size.height)];
    [UIView commitAnimations];
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if([textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0){
        [textView setText:@"Type message here"];
        [textView setTextColor:[UIColor lightGrayColor]];
    }
    [UIView beginAnimations:ANIMATION_PARAM context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: 0.5];
    [self.view setFrame:CGRectMake(self.view.frame.origin.x,0, self.view.frame.size.width, self.view.frame.size.height)];
    [txtEmailId becomeFirstResponder];
    [UIView commitAnimations];
}

-(IBAction)cancelButtonClicked:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) hideTabBar {
    //[[nc_AppDelegate sharedInstance].twitterCount setHidden:YES];
    for(UIView *view in self.tabBarController.view.subviews)
    {
        CGRect _rect = view.frame;
        if([view isKindOfClass:[UITabBar class]])
        {
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                _rect.origin.y = 0;
            }
            else{
                _rect.origin.y = 0;
            }
            [view setFrame:_rect];
        }
        else if([view isKindOfClass:[UIImageView class]]){
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                _rect.origin.y = 0;
            }
            else{
                _rect.origin.y = 0;
            }
            [view setFrame:_rect];
        }
        else if(![view isKindOfClass:[UIButton class]]){
            if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
                _rect.size.height = 568;
            }
            else{
                _rect.size.height = 480;
            }
            [view setFrame:_rect];
        }
    }
}
@end