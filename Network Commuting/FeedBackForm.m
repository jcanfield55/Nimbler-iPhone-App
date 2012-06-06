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

@synthesize tpResponse,tpURLResource,process,mesg;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    actRunning.text = @"";
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


-(void) updateCountdown {
    
    int seconds;
    secondsLeft--;
    secondUse += 0.0166;
     [progress setProgress:secondUse];
    if(secondsLeft == 0){
        [process dismissWithClickedButtonIndex:0 animated:NO];

        NSLog(@"timer finish");
        isRepeat = NO;
        [time setHidden:YES];
        [timer invalidate];
        [self stopRecording:self];
    } else {
        if(![process isVisible]){
            NSLog(@"not");
            isRepeat = NO;
            [time setHidden:YES];
            [timer invalidate];
            timer =  nil;
            [self stopRecording:self];
    }
        seconds = (secondsLeft %3600) % 60;
        time.text = [NSString stringWithFormat:@"Time Left : %02d", seconds];
    }
    
}


-(void) updatePlayCountdown {
    secondsLeft++;
    time.text = [NSString stringWithFormat:@"Play Time : %02d", secondsLeft];
}

#pragma mark-Recording functions

-(IBAction)recordRecording:(id)sender{
    
    NSLog(@"start recording");
    [txtEmailId resignFirstResponder];
    [txtFeedBack resignFirstResponder];
    actRunning.text = @"Start Recording....";

    
    NSArray *tempDirPath;
    NSString *docsDir;
    mesg = RECORD_MSG;
    process = [self WaitPrompt];
     
    secondsLeft = 60;
    secondUse = 0;
    isRepeat = YES;
    [time setHidden:NO];
    timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target:self selector:@selector(updateCountdown) userInfo:nil repeats: isRepeat];    
  
    tempDirPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [tempDirPath objectAtIndex:0];
    soundFilePath = [docsDir stringByAppendingPathComponent:@"voiceFeedback.caf"];
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:AVAudioQualityMin],
                                    AVEncoderAudioQualityKey, [NSNumber numberWithInt:16], AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 2], AVNumberOfChannelsKey, [NSNumber numberWithFloat:44100.0], 
                                    AVSampleRateKey, nil];
    
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
    actRunning.text = @"Stop Recording....";
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO];  
    [process dismissWithClickedButtonIndex:0 animated:NO];
    if (audioRecorder.recording)
    {
        [audioRecorder stop];
    } else if (audioPlayer.playing) {
        [audioPlayer stop];
    }    
    NSLog(@"Stop Recording");
    
}

-(void)setActRunStatus{
    actRunning.text =@"";
}

-(IBAction)pausRecording:(id)sender
{
    if (audioPlayer.playing) {
        actRunning.text = @"Pause Recording....";
        timer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO]; 
        [audioPlayer pause];
    }  else {
        actRunning.text = @"Recording not playing....";
        timer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO]; 
    }
    
}
-(IBAction)playRecording:(id)sender
{
    NSLog(@"play Recording");
    actRunning.text = @"Play Recording....";
    if (!audioRecorder.recording)
    {
        NSError *error;
        
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioRecorder.url error:&error];
        
        audioPlayer.delegate = self;
        
        if (error) {
            NSLog(@"Error: %@", 
                  [error localizedDescription]);
        } else {
//           mesg = PLAY_MSG;
//            process = [self WaitPrompt];
            
            [time setHidden:NO];
            secondsLeft = 0;
            timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target:self selector:@selector(updatePlayCountdown) userInfo:nil repeats: YES]; 
            [audioPlayer play];
        }
    }   
}


#pragma mark audio player delegate method

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"SuccessFully Playing");
    actRunning.text = @"Play complete....";
    isRepeat = NO;
    [time setHidden:YES];
    [timer invalidate];
    timer =  nil;
    time.text = @"";
    timer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target:self selector:@selector(setActRunStatus) userInfo:nil repeats: NO]; 
    [process dismissWithClickedButtonIndex:0 animated:NO];
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
        [process dismissWithClickedButtonIndex:0 animated:NO];
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
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FB_TITLE_MSG message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                    
                    //flush the sent objects
                    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                    [prefs setObject:@"" forKey:@"source"];
                    [prefs setObject:@"" forKey:@"uniqueid"];
                    [prefs setObject:@"" forKey:@"txtfb"];
                                        
                }
                
            }
            
        }
    } 
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{        

    [process dismissWithClickedButtonIndex:0 animated:NO];
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
    [process dismissWithClickedButtonIndex:0 animated:NO];
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
    process = [self waitFb];
//    [al autoContentAccessingProxy];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *source = [prefs objectForKey:@"source"];
    NSString *uniqueId = [prefs objectForKey:@"uniqueid"];
    NSString *udid = [UIDevice currentDevice].uniqueIdentifier;
    
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
    
    [rkp setValue:udid forParam:@"deviceid"]; 
    [rkp setValue:source forParam:@"source"]; 
    [rkp setValue:uniqueId forParam:@"uniqueid"]; 
    [rkp setValue:@"3.5" forParam:@"rating"];
    
    [[RKClient sharedClient]  post:@"feedback/new" params:rkp delegate:self];
}

#pragma mark UIAlertView utility

-(UIAlertView *) waitFb
{
    UIAlertView *alerts = [[UIAlertView alloc]   
                          initWithTitle:mesg  
                          message:nil delegate:nil cancelButtonTitle:nil  
                          otherButtonTitles:nil];  
    
        [alerts show];  
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]  
                                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];  
    
    indicator.center = CGPointMake(alerts.bounds.size.width / 2,   
                                   alerts.bounds.size.height - 50);  
    [indicator startAnimating];  
    [alerts addSubview:indicator]; 
    
    
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];  
    
    return alerts;

}

-(UIAlertView *) WaitPrompt  
{  
    UIAlertView *alert = [[UIAlertView alloc]   
                          initWithTitle:mesg  
                          message:nil delegate:self cancelButtonTitle:@"Done"  
                          otherButtonTitles: @"Cancel",nil];  
    
    [alert show];  
    
    progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progress.center = CGPointMake(alert.bounds.size.width / 2,  alert.bounds.size.height - 67);
    
    
    [alert addSubview:progress];  
    
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];  
    
    return alert;
}  

-(void)alertView: (UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    NSString *btnName = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([btnName isEqualToString:@"Cancel"]) {
        soundFilePath = nil;
        audioPlayer = nil;
    } else if ([btnName isEqualToString:@"Done"]) {
        
    } else if ([btnName isEqualToString:@"Yes"]) {
        [self sendFeedbackToServer];
    } 
    
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
