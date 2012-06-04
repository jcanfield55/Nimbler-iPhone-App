//
//  FeedBackForm.m
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "FeedBackForm.h"
#import <RestKit/RKJSONParserJSONKit.h>

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
    if(secondsLeft == 0){
        [process dismissWithClickedButtonIndex:0 animated:NO];

        NSLog(@"timer finish");
        isRepeat = NO;
        [time setHidden:YES];
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

#pragma mark-Recording functions

-(IBAction)recordRecording:(id)sender{
    
    NSLog(@"start recording");
    
    NSArray *tempDirPath;
    NSString *docsDir;
    mesg = RECORD_MSG;
    process = [self WaitPrompt];
     
    secondsLeft = 60;
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
    
    [process dismissWithClickedButtonIndex:0 animated:NO];
    if (audioRecorder.recording)
    {
        [audioRecorder stop];
    } else if (audioPlayer.playing) {
        [audioPlayer stop];
    }    
    NSLog(@"Stop Recording");
    
}
-(IBAction)pausRecording:(id)sender
{
    if (audioPlayer.playing) {
        [audioPlayer pause];
    }  
    
}
-(IBAction)playRecording:(id)sender
{
    NSLog(@"play Recording");
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
            [audioPlayer play];
        }
    }   
}


#pragma mark audio player delegate method

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"SuccessFully Playing");
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
    
    process = [self WaitPrompt];
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


-(UIAlertView *) WaitPrompt  
{  
    UIAlertView *alert = [[UIAlertView alloc]   
                          initWithTitle:mesg  
                          message:nil delegate:nil cancelButtonTitle:@"OK"  
                          otherButtonTitles: @"Cancel", nil];  
    
    [alert show];  
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]  
                                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];  
    
    indicator.center = CGPointMake(alert.bounds.size.width / 2,   
                                   alert.bounds.size.height - 50);  
    [indicator startAnimating];  
    [alert addSubview:indicator];  
    
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];  
    
    return alert;
}  

-(void)alertView: (UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    
}

@end
