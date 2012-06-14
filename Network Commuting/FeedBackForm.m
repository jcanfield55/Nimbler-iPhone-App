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

#define RECORD_MSG   @"Recording your feedback \nSpeak ..."
#define SUBMIT_MSG   @"Sending your feedback \nPlease wait ..."
#define PLAY_MSG   @"Playing your recorded file\nPlease wait ..."

@implementation FeedBackForm

@synthesize tpResponse,tpURLResource,alertView,mesg,btnPlayRecording,btnStopRecording,btnPauseRecording,btnRecordRecording;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[self navigationItem] setTitle:@"Feedback Form"];
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
    // Do any additional setup after loading the view from its nib.
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *email = [prefs objectForKey:@"eMailId"];
    txtEmailId.text = email;
    labelCurrentActivityStatus.text = @"";
    txtFeedBack.layer.cornerRadius = 8;
    txtFeedBack.layer.borderWidth = 1.0;
    [txtFeedBack.layer setBorderColor:[[UIColor grayColor] CGColor]];
    
    [btnPlayRecording setEnabled:FALSE];
    [btnPauseRecording setEnabled:FALSE];
    [btnStopRecording setEnabled:FALSE];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}




#pragma mark-Recording functions

-(IBAction)recordRecording:(id)sender{
    
    [btnPlayRecording setEnabled:FALSE];
    [btnPauseRecording setEnabled:FALSE];
    
    
    labelRecTime.text = @"";
    NSLog(@"start recording");
    [txtEmailId resignFirstResponder];
    [txtFeedBack resignFirstResponder];
    labelCurrentActivityStatus.text = @"Start Recording....";

    mesg = RECORD_MSG;
    alertView = [self childAlertViewRec];
     
    secondsLeft = 60;
    secondUsed = 0;
    isRepeat = YES;
    [labelRecTime setHidden:NO];
    timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target:self selector:@selector(updateRecCountdown) userInfo:nil repeats: isRepeat];    
  
    NSArray *tempDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *tempDirPath = [tempDir objectAtIndex:0];
    soundFilePath = [tempDirPath stringByAppendingPathComponent:@"voiceFeedback.caf"];
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    [NSNumber numberWithInt:kAudioFormat], AVFormatIDKey,
                                    [NSNumber numberWithInt:AVAudioQualityMin], AVEncoderAudioQualityKey, 
                                    [NSNumber numberWithInt:16], AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 8], AVLinearPCMBitDepthKey, 
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey, 
                                    [NSNumber numberWithFloat:8000.0], AVSampleRateKey, 
                                    nil];
    
    NSError *error = nil;    
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [audioRecorder prepareToRecord];
    }
    
    if (!audioRecorder.recording)
    {        
        [audioRecorder record];
    }
    
}


-(IBAction)stopRecording:(id)sender
{    
    [btnPlayRecording setEnabled:TRUE];
    [btnPauseRecording setEnabled:FALSE];
    [btnStopRecording setEnabled:FALSE];
    [btnRecordRecording setEnabled:TRUE];
    
    labelCurrentActivityStatus.text = @"Stop Recording....";
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO];  
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    if (audioRecorder.recording)
    {
        [audioRecorder stop];
    } else if (audioPlayer.playing) {
        [audioPlayer stop];
    }    
    NSLog(@"Stop Recording");
    
}

-(void)setActRunStatus{
    labelCurrentActivityStatus.text =@"";
}

-(IBAction)pausRecording:(id)sender
{
    if (audioPlayer.playing) {
        labelCurrentActivityStatus.text = @"Pause Recording....";
        isRepeat = NO;
        [labelRecTime setHidden:YES];
        [timer invalidate];
        timer =  nil;
        timer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO]; 
        
        [audioPlayer pause];
        
        [btnPlayRecording setEnabled:TRUE];
        [btnPauseRecording setEnabled:FALSE];
        [btnRecordRecording setEnabled:TRUE];
        
    }  else {
        labelCurrentActivityStatus.text = @"Recorded file not playing....";
        timer = nil;
        timer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO]; 
    }
    
}
-(IBAction)playRecording:(id)sender
{
    NSLog(@"play Recording");
    labelCurrentActivityStatus.text = @"Play Recording....";
    secondsLeft = 0;
    labelRecTime.text = @"";
    if (!audioRecorder.recording)
    {
        NSError *error;        
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioRecorder.url error:&error];        
        audioPlayer.delegate = self;
        
        if (error) {
            NSLog(@"Error: %@", 
                  [error localizedDescription]);
        } else {
           mesg = PLAY_MSG;
//            alertView = [self WaitPrompt];
            //when recording is being played, record & stop disable, pause is enable  
            
            [btnStopRecording setEnabled:FALSE];
            [btnPlayRecording setEnabled:FALSE];
            [btnRecordRecording setEnabled:FALSE];
            [btnPauseRecording setEnabled:TRUE];
            
            [labelRecTime setHidden:NO];
            timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target:self selector:@selector(updatePlayCountdown) userInfo:nil repeats: YES]; 
            [audioPlayer play];
        }
    }   
}


#pragma mark Time functionds

-(void) updateRecCountdown {
    
    int seconds;
    secondsLeft--;
    secondUsed += 0.0166;
    [recProgressView setProgress:secondUsed];
    if(secondsLeft == 0){
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        
        NSLog(@"timer finish");
        isRepeat = NO;
        [labelRecTime setHidden:YES];
        [timer invalidate];
        [self stopRecording:self];
    } else {
        if(![alertView isVisible]){
            NSLog(@"not");
            isRepeat = NO;
            [labelRecTime setHidden:YES];
            [timer invalidate];
            timer =  nil;
            [self stopRecording:self];
        }
        seconds = (secondsLeft %3600) % 60;
        labelRecTime.text = [NSString stringWithFormat:@"Time Left : %02d", seconds];
    }
    
}


-(void) updatePlayCountdown {
    
    secondsLeft++;   
    labelRecTime.text = [NSString stringWithFormat:@"Play Time : %02d", secondsLeft];
}


#pragma mark audio player delegate method

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"SuccessFully Played");
    [btnPlayRecording setEnabled:TRUE];
    [btnRecordRecording setEnabled:TRUE];
    [btnPauseRecording setEnabled:FALSE];
    [btnStopRecording setEnabled:FALSE];
    
    labelCurrentActivityStatus.text = @"Play complete....";
    isRepeat = NO;
    [labelRecTime setHidden:YES];
    [timer invalidate];
    timer =  nil;
    labelRecTime.text = @"";
    timer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO]; 
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
    mesg = SUBMIT_MSG;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler Feedback" message:@"Are you sure to send feedback" delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No", nil];
    [alert show];
}

#pragma mark Restful Response

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    if ([request isGET]) {
        // Handling GET /foo.xml
        
    } else if ([request isPOST]) {  
        NSLog(@"Got aresponse back from TPResponse! %@", [response bodyAsString]);
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        
        if ([response isOK]) {
            // Success! Let's take a look at the data
            txtFeedBack.text = @"";
            RKJSONParserJSONKit* parser1 = [RKJSONParserJSONKit new];
            NSDictionary  *p = [parser1 objectFromString:[response bodyAsString] error:nil];
            
            for (id key in p) {
                NSLog(@"key: %@, value: %@", key, [p objectForKey:key]);
                if ([key isEqualToString:@"msg"]) {
                    
                    NSString *msg;
                    if ([[p objectForKey:@"code"] isEqualToString:@"105"]) {
                        msg = FB_RESPOSE_SUCCEES;
                    } else {
                        msg = FB_RESPONSE_FAIL ;
                    }
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FB_TITLE_MSG message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//                    [alert show];
                                                           
                }
                
            }
            
        }
    } 
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{        

    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    if ([[objectLoader resourcePath] isEqualToString:tpURLResource]) 
    {   
        NSInteger statusCode = [[objectLoader response] statusCode];
        NSLog(@"Planning HTTP status code = %d", statusCode);
        
        @try {
            
            if (objects && [objects objectAtIndex:0]) {
                tpResponse = [objects objectAtIndex:0];
                NSLog(@"success ");
            }
        }
        @catch (NSException *exception) {            
            NSLog(@"Error object load==============================: %@", exception);            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Sorry, we are unable to send your feedback to Trip Planner" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];    
          
            return;
        }
        
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Sorry, we are unable to send your feedback to Trip Planner" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];    
    NSLog(@"Error received from RKObjectManager:");
    NSLog(@"%@", error);
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
//    [al autoContentAccessingProxy];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *source = [prefs objectForKey:@"source"];
    NSString *uniqueId = [prefs objectForKey:@"uniqueid"];
    NSString *udid = [UIDevice currentDevice].uniqueIdentifier;
    NSString *fromAddress = [prefs objectForKey:@"fromaddress"];
    NSString *toAddress = [prefs objectForKey:@"toaddress"];
    NSString *date = [prefs objectForKey:@"tripdate"];
    
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    RKParams *rkp = [RKParams params];
    [RKClient setSharedClient:client];
    
    if (soundFilePath != nil) {
        NSString *myFile =soundFilePath;
        RKParamsAttachment* attachment = [rkp setFile:myFile forParam:@"file"];
        attachment.MIMEType = @"audio/caf";
        attachment.fileName = @"FBSound.caf";
        [rkp setValue:FEEDBACK_AUDIO forParam:@"formattype"];
    } 
    if (txtFeedBack.text != nil){
        [rkp setValue:txtFeedBack.text forParam:@"txtfb"];
        [rkp setValue:FEEDBACK_TEXT forParam:@"formattype"];
    } 
    if (txtEmailId.text != nil) {
        [rkp setValue:txtEmailId.text forParam:@"emailid"];
        [prefs setObject:txtEmailId.text forKey:@"eMailId"];
        
    }
    if(soundFilePath != nil && txtFeedBack.text != nil){
        [rkp setValue:FEEDBACK_BOTH forParam:@"formattype"]; 
    }
    
    if([source isEqualToString:@"4"]){
        if ([fromAddress isEqualToString:@"Current Location"]) {
            NSLog(@"loc %@", fromAddress);
            fromAddress = [prefs objectForKey:@"currentLocation"];
        }
        
        [rkp setValue:fromAddress forParam:@"rawAddFrom"];
        [rkp setValue:toAddress forParam:@"rawAddTo"];
        [rkp setValue:date forParam:@"date"];
    }
    
    [rkp setValue:udid forParam:@"deviceid"]; 
    [rkp setValue:source forParam:@"source"]; 
    [rkp setValue:uniqueId forParam:@"uniqueid"]; 
    [rkp setValue:@"3.5" forParam:@"rating"];      
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 3.0 target:self selector:@selector(popOut) userInfo:nil repeats: NO];
    [[RKClient sharedClient]  post:@"feedback/new" params:rkp delegate:self];
    
}

#pragma mark UIAlertView utility

-(UIAlertView *) feedbackConfirmAlert
{
    UIAlertView *alerts = [[UIAlertView alloc]   
                          initWithTitle:mesg  
                          message:nil delegate:nil cancelButtonTitle:nil  
                          otherButtonTitles:nil];  
    
        
   indicator = [[UIActivityIndicatorView alloc]  
                                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];  
     
    indicator.frame = CGRectMake(135, 80, 20, 20);
    [indicator startAnimating];  
    [alerts addSubview:indicator]; 
    
    [alerts show];
    
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];  
    
    return alerts;

}

-(UIAlertView *) childAlertViewRec  
{  
    UIAlertView *alert = [[UIAlertView alloc]   
                          initWithTitle:mesg  
                          message:nil delegate:self cancelButtonTitle:@"Done"  
                          otherButtonTitles: @"Cancel",nil];  
    
    [alert show];  
    
    recProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    recProgressView.center = CGPointMake(alert.bounds.size.width / 2,  alert.bounds.size.height - 67);
    
    
    [alert addSubview:recProgressView];  
    
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];  
    timer = [NSTimer scheduledTimerWithTimeInterval: 20.0 target:self selector:@selector(stopLoadingProcess) userInfo:nil repeats: NO];
    return alert;
}  

-(void)alertView: (UIAlertView *)UIAlertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    NSString *btnName = [UIAlertView buttonTitleAtIndex:buttonIndex];
    
    if ([btnName isEqualToString:@"Cancel"]) {
        soundFilePath = nil;
        audioPlayer = nil;
    } else if ([btnName isEqualToString:@"Done"]) {
        
    } else if ([btnName isEqualToString:@"Yes"]) {
        [self sendFeedbackToServer];
    } 
    
}

-(void)stopLoadingProcess
{
     
    
}

-(void)popOut
{
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark TextField animation at selected

- (void) animateTextField: (UITextField*) textField up: (BOOL) up{
	int txtPosition = (textField.frame.origin.y - 160);
    const int movementDistance = (txtPosition < 0 ? 0 : txtPosition); // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
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
	int txtPosition = (textView.frame.origin.y - 100);
    const int movementDistance = (txtPosition < 0 ? 0 : txtPosition); // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
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
