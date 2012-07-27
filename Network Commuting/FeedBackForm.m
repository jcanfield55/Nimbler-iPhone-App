//
//  FeedBackForm.m
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "FeedBackForm.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "nc_AppDelegate.h"

#define RECORD_MSG      @"Recording your feedback \nSpeak ..."
#define SUBMIT_MSG      @"Sending your feedback \nPlease wait ..."
#define FB_TITLE        @"Feedback"

#define RECORDING       @"Recording...."
#define RECORDING_STOP  @"Recording Stopped...."
#define RECORDING_CANCEL @"Recording Canceled...."
#define RECORDING_PAUSE @"Recording Paused...."
#define RECORDING_PLAY  @"Record Playing...."
#define VOICE_FB_FILE   @"voiceFeedback.caf"
#define PLAY_TIME       @"Play Time : %02d"
#define TIME_LEFT       @"Time Left : %02d"
#define REC_NOT_PLAY    @"Error while playing recording...."
#define PLAY_COMPLETE   @"Play complete...."
#define ANIMATION_PARAM @"anim"
#define FB_CONFIRMATION @"Are you sure you want to send feedback?"
#define FB_WHEN_NO_VOICE_OR_TEXT @"for now put the text Please give your feedback and then press Send!"
#define ALERT_TRIP      @"Trip Planner"

#define BUTTON_YES      @"Yes"
#define BUTTON_NO       @"No"
#define BUTTON_DONE     @"Done"
#define BUTTON_CANCEL   @"Cancel"
#define BUTTON_OK       @"OK"

#define BORDER_WIDTH    1.0
#define RECORD_DURATION 60
#define REC_STARTTIME   0
#define BITRATE_KEY     16
#define BITDEPTH_KEY    8
#define CHANNEL_KEY     1
#define SAMPLERATE_KEY  8000.0
#define TIME_INTERVAL   2.0
#define INCREASE_PROGREEVIEW 0.0166
#define UP_DOWN_RATIO   0.3

@implementation FeedBackForm

BOOL isCancelFB = FALSE;
@synthesize tpResponse,tpURLResource,alertView,mesg,btnPlayRecording,btnStopRecording,btnPauseRecording,btnRecordRecording,fbReqParams;
@synthesize txtEmailId,txtFeedBack;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:FB_TITLE];
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

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [UIColor colorWithRed:98.0/255.0 green:96.0/255.0 
                                                                    blue:96.0/255.0 alpha:1.0], UITextAttributeTextColor,
                                                                     nil]];
    
    
    // Do any additional setup after loading the view from its nib.
    }

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    btnSubmitFeedback.layer.cornerRadius = CORNER_RADIUS_SMALL;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    txtEmailId.text = [prefs objectForKey:USER_EMAIL];
    labelCurrentActivityStatus.text = NULL_STRING;
    txtFeedBack.layer.cornerRadius = CORNER_RADIUS_SMALL;
    txtFeedBack.layer.borderWidth = BORDER_WIDTH;
    [txtFeedBack.layer setBorderColor:[[UIColor grayColor] CGColor]];
    
    [btnPlayRecording setEnabled:FALSE];
    [btnPauseRecording setEnabled:FALSE];
    [btnStopRecording setEnabled:FALSE];
    soundFilePath = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
     [super viewWillDisappear:animated];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark-Recording functions
-(IBAction)startRecord:(id)sender
{    
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
//                                    [NSNumber numberWithInt:kAudioFormat], AVFormatIDKey,
                                    [NSNumber numberWithInt:AVAudioQualityMin], AVEncoderAudioQualityKey, 
                                    [NSNumber numberWithInt:BITRATE_KEY], AVEncoderBitRateKey,
                                    [NSNumber numberWithInt:BITDEPTH_KEY], AVLinearPCMBitDepthKey, 
                                    [NSNumber numberWithInt: CHANNEL_KEY], AVNumberOfChannelsKey, 
                                    [NSNumber numberWithFloat:SAMPLERATE_KEY], AVSampleRateKey, 
                                    nil];
    
    NSError *error = nil;  
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];
    if (error) {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [audioRecorder prepareToRecord];
    }
    
    if (!audioRecorder.recording) {        
        [audioRecorder record];
    }
}

-(IBAction)stopRecord:(id)sender {    
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
    if (audioPlayer.playing) {
        labelCurrentActivityStatus.text = RECORDING_PAUSE;
        isRepeat = NO;
        [labelRecTime setHidden:YES];
        [timer invalidate];
        timer =  nil;
        timer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO]; 
        [audioPlayer pause];
        [btnPlayRecording setEnabled:TRUE];
        [btnPauseRecording setEnabled:FALSE];
        [btnRecordRecording setEnabled:TRUE];
    }  else {
        labelCurrentActivityStatus.text = REC_NOT_PLAY;
        timer = nil;
        timer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO]; 
    }
    isFromPause = YES;
}

-(IBAction)playRecord:(id)sender {
    labelCurrentActivityStatus.text = RECORDING_PLAY;
    if(!isFromPause){
        secondsLeft = REC_STARTTIME;
    }
    labelRecTime.text = NULL_STRING;
    if (!audioRecorder.recording)
    {
        NSError *error;
        if(audioPlayer == nil){
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioRecorder.url error:&error];
        }
        audioPlayer.delegate = self;
        if (error) {
            NSLog(@"Error: %@", 
                  [error localizedDescription]);
        } else {
//            alertView = [self WaitPrompt];
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
            timer =  nil;
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
    timer =  nil;
    labelRecTime.text = NULL_STRING;
    timer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO]; 
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decoder Error occurred");
}

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"SuccessFully Recording");
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Encoder Error occurred");
}


#pragma mark Restful request
-(IBAction)submitFeedBack:(id)sender
{
    if((soundFilePath == nil) && ([txtFeedBack.text isEqualToString:NULL_STRING])) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FB_TITLE_MSG message:FB_WHEN_NO_VOICE_OR_TEXT delegate:self cancelButtonTitle:BUTTON_OK otherButtonTitles:nil, nil];
        [alert show];
    } else {
        mesg = SUBMIT_MSG;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FB_TITLE_MSG message:FB_CONFIRMATION delegate:self cancelButtonTitle:BUTTON_YES otherButtonTitles:BUTTON_NO, nil];
        [alert show];
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
            RKJSONParserJSONKit* parser1 = [RKJSONParserJSONKit new];
            NSDictionary  *fbParser = [parser1 objectFromString:[response bodyAsString] error:nil];
            NSString *msg;
            for (id key in fbParser) {
                NSLog(@"key: %@, value: %@", key, [fbParser objectForKey:key]);
                if ([key isEqualToString:FB_RESPONSE_MSG]) {
                    if ([[fbParser objectForKey:FB_RESPONCE_CODE] intValue] == RESPONSE_SUCCESSFULL) {
                        msg = FB_RESPONSE_SUCCEES;
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
    
    NSString *udid = [UIDevice currentDevice].uniqueIdentifier;    
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    RKParams *rkp = [RKParams params];
    [RKClient setSharedClient:client];
    
    if (soundFilePath != nil) {
        NSString *myFile =soundFilePath;
        RKParamsAttachment* attachment = [rkp setFile:myFile forParam:FILE];
        attachment.MIMEType = FILE_TYPE;
        attachment.fileName = FILE_NAME;
        [rkp setValue:[NSNumber numberWithInt:FEEDBACK_AUDIO] forParam:FILE_FORMATE_TYPE];
    } 
    if (txtFeedBack.text != nil){
        [rkp setValue:txtFeedBack.text forParam:FB_TEXT];
        [rkp setValue:[NSNumber numberWithInt:FEEDBACK_TEXT] forParam:FILE_FORMATE_TYPE];
    } 
    if (txtEmailId.text != nil) {
        [rkp setValue:txtEmailId.text forParam:EMAIL_ID];
         NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:txtEmailId.text forKey:USER_EMAIL];
    }
    if(soundFilePath != nil && txtFeedBack.text != nil) {
        [rkp setValue:[NSNumber numberWithInt:FEEDBACK_TEXT_AUDIO] forParam:FILE_FORMATE_TYPE]; 
    }
    
    [rkp setValue:udid forParam:DEVICE_ID]; 
    [rkp setValue:[nc_AppDelegate sharedInstance].FBSource forParam:FEEDBACK_SOURCE]; 
    [rkp setValue:@"3.5" forParam:FEEDBACK_RATING];
    
    if([nc_AppDelegate sharedInstance].FBSource == [NSNumber numberWithInt:FB_SOURCE_GENERAL]){     
        [rkp setValue:[nc_AppDelegate sharedInstance].FBSFromAdd forParam:FB_FORMATTEDADDR_FROM];
        [rkp setValue:[nc_AppDelegate sharedInstance].FBToAdd forParam:FB_FORMATTEDADDR_TO];
        [rkp setValue:[nc_AppDelegate sharedInstance].FBDate forParam:FB_DATE];
    } else {
        [rkp setValue:[nc_AppDelegate sharedInstance].FBUniqueId forParam:FB_UNIQUEID]; 
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(popOut) userInfo:nil repeats: NO];
    [[RKClient sharedClient]  post:FB_REQUEST params:rkp delegate:self];
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
    recProgressView.center = CGPointMake(alert.bounds.size.width / 2,  alert.bounds.size.height - 67);
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
    } else if ([btnName isEqualToString:BUTTON_YES]) {
        [self sendFeedbackToServer];
    } 
}

-(void)popOut
{
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
    [self.tabBarController setSelectedIndex:0];
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
    [self animateTextField: textField up: YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self animateTextField: textField up: NO];
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
    [self animateTextView: textView up: YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    [self animateTextView: textView up: NO];
}
@end
