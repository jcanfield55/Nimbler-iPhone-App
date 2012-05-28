//
//  FeedBackForm.m
//  Nimbler
//
//  Created by JaY Kumbhani on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "FeedBackForm.h"
#import <RestKit/RKJSONParserJSONKit.h>

#define FEEDBACK_TEXT           @"1"
#define FEEDBACK_AUDIO          @"2"
#define FEEDBACK_BOTH           @"3"
#define FB_RESPOSE_SUCCEES      @"FeedBack Send Successfully"
#define FB_RESPONSE_FAIL        @"Please Send Again"

@implementation FeedBackForm

@synthesize tpResponse,tpURLResource;

static RKObjectManager *rkTPResponse;
static Plan *fbPlan;
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
    
    NSLog(@"start recording");
    
    NSArray *tempDirPath;
    NSString *docsDir;
    
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
-(IBAction)stopRecording:(id)sender{
    
    if (audioRecorder.recording)
    {
        [audioRecorder stop];
    } else if (audioPlayer.playing) {
        [audioPlayer stop];
    }    
    NSLog(@"Stop Recording");
    
}
-(IBAction)pausRecording:(id)sender{
    
    if (audioPlayer.playing) {
        [audioPlayer pause];
    }  
    
}
-(IBAction)playRecording:(id)sender{
    
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
            
            [audioPlayer play];
        }
    }   
}


#pragma audio player delegate method
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"SuccessFully Playing");
    
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


#pragma RestKit response handler
- (void)setRkTPResponse:(RKObjectManager *)rkTPResponse0
{
    rkTPResponse = rkTPResponse0;
    [[rkTPResponse mappingProvider] setMapping:[TPResponse objectMappingforTPResponse:OTP_PLANNER] forKeyPath:@"tpResponse"];
}


-(void)setPlanForTPFeedBack:(Plan *)plan
{
    fbPlan = plan;
}


#pragma mark Restful request response

-(IBAction)submitFeedBack:(id)sender
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *source = [prefs objectForKey:@"source"];
    NSString *uniqueId = [prefs objectForKey:@"uniqueid"];
    NSString *udid = [UIDevice currentDevice].uniqueIdentifier;
    
    RKClient *client = [RKClient clientWithBaseURL:@"http://23.23.210.156:8080/TPServer"];
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
    
    if(soundFilePath != nil && txtFeedBack.text != nil){
        [rkp setValue:FEEDBACK_BOTH forParam:@"formattype"]; 
    }
    
    [rkp setValue:udid forParam:@"deviceid"]; 
    [rkp setValue:source forParam:@"source"]; 
    [rkp setValue:uniqueId forParam:@"uniqueid"]; 
    [rkp setValue:@"3.5" forParam:@"rating"];
    
    [[RKClient sharedClient]  post:@"/ws/feedback/new" params:rkp delegate:self];
}


- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects 
{        
    
    NSLog(@"wel i");
    if ([[objectLoader resourcePath] isEqualToString:tpURLResource]) 
    {   
        NSInteger statusCode = [[objectLoader response] statusCode];
        NSLog(@"Planning HTTP status code = %d", statusCode);
        
        @try {
            
            if (objects && [objects objectAtIndex:0]) {
                tpResponse = [objects objectAtIndex:0];
                NSLog(@"success");
            }
        }
        @catch (NSException *exception) {            
            NSLog(@"Error object ==============================: %@", exception);            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nimbler" message:@"Trip is not possible. Your start or end point might not be safely accessible" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
            [alert show];            
            return ;
        }
        
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Sorry, we are unable to send your feedback to Trip Planner" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];    
    NSLog(@"Error received from RKObjectManager:");
    NSLog(@"%@", error);
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    if ([request isGET]) {
        // Handling GET /foo.xml

        
    } else if ([request isPOST]) {  
        NSLog(@"Got aresponse back from TPResponse! %@", [response bodyAsString]);
        
        if ([response isOK]) {
            // Success! Let's take a look at the data
            NSLog(@"Retrieved XML: %@", [response bodyAsString]);
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
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Trip FeedBack" message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                }
                
            }
            
        }
    } 
}



- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}
@end
