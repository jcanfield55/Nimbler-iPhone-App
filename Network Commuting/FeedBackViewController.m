//
//  FeedBackViewController.m
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/15/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "FeedBackViewController.h"
#import <RestKit/RKJSONParserJSONKit.h>


#define FEEDBACK_TEXT           @"1"
#define FEEDBACK_AUDIO          @"2"
#define FEEDBACK_BOTH           @"3"
#define FB_RESPOSE_SUCCEES      @"FeedBack Send Successfully"
#define FB_RESPONSE_FAIL        @"Please Send Again"

@implementation FeedBackViewController

@synthesize actSpinner;
@synthesize textFieldRounded;
@synthesize label;
@synthesize tpURLResource;
@synthesize tpResponse;
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
    //self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"feedback.png"]];  
      
    self.view.backgroundColor = [UIColor whiteColor];
    [super viewDidLoad];
    
    [self setUpUI];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(void)startRecording
{
     
    NSLog(@"start recording");
    [actSpinner startAnimating];
            
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


-(void)stopRecordingFeedback
{
    [actSpinner stopAnimating];
    
    if (audioRecorder.recording)
    {
        [audioRecorder stop];
    } else if (audioPlayer.playing) {
        [audioPlayer stop];
    }    [actSpinner stopAnimating];
    NSLog(@"Stop Recording");
}

-(void)playRecordedFile
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
            
            [audioPlayer play];
        }
    }    
}


-(void)pausePlaying
{
    if (audioPlayer.playing) {
        [audioPlayer pause];
    }    
}


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

// One-time set-up of the RestKit Trip Planner Object Manager's mapping
- (void)setRkTPResponse:(RKObjectManager *)rkTPResponse0
{
    rkTPResponse = rkTPResponse0;
    [[rkTPResponse mappingProvider] setMapping:[TPResponse objectMappingforTPResponse:OTP_PLANNER] forKeyPath:@"tpResponse"];
}


-(void)setPlanForTPFeedBack:(Plan *)plan
{
    fbPlan = plan;
}

// Delegate methods for when the RestKit has results from the Planner
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


-(void)setUpUI
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self 
               action:@selector(startRecording)
     forControlEvents:UIControlEventTouchDown];
    [button setImage:[UIImage imageNamed:@"rec_up.png"] forState:UIControlStateNormal];
    button.frame = CGRectMake(100.0, 45.0, 40.0, 40.0);
    [self.view addSubview:button];
    
    UIButton *stopRec = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [stopRec addTarget:self 
                action:@selector(stopRecordingFeedback)
      forControlEvents:UIControlEventTouchDown];
    [stopRec setImage:[UIImage imageNamed:@"stopRec.png"] forState:UIControlStateNormal];
    stopRec.frame = CGRectMake(150.0, 45.0, 40.0, 40.0);
    [self.view addSubview:stopRec];
    
    
    UIButton *pause = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [pause addTarget:self 
                action:@selector(pausePlaying)
      forControlEvents:UIControlEventTouchDown];
    [pause setImage:[UIImage imageNamed:@"pausePlay.png"] forState:UIControlStateNormal];
    pause.frame = CGRectMake(200.0, 45.0, 40.0, 40.0);
    [self.view addSubview:pause];
    
    UIButton *playRec = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [playRec addTarget:self 
                action:@selector(playRecordedFile)
      forControlEvents:UIControlEventTouchDown];
    [playRec setImage:[UIImage imageNamed:@"playRec.png"] forState:UIControlStateNormal];
    playRec.frame = CGRectMake(250.0, 45.0, 40.0, 40.0);
    [self.view addSubview:playRec];
    
    UIButton *submit = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [submit addTarget:self 
                action:@selector(feedBackSubmit)
      forControlEvents:UIControlEventTouchDown];
    [submit setTitle:@"submit" forState:UIControlStateNormal];
    submit.frame = CGRectMake(220.0, 15.0, 80.0, 25.0);
    [self.view addSubview:submit];
    
	AVAudioSession * audioSession = [AVAudioSession sharedInstance];
	[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
	[audioSession setActive:YES error: nil];
    
    actSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [actSpinner setCenter:CGPointMake(320/2.0, 460/2.0)]; // I do this because I'm in landscape mode
    [self.view addSubview:actSpinner];
        
    textFieldRounded = [[UITextField alloc] initWithFrame:CGRectMake(20, 150, 280, 100)];
    textFieldRounded.borderStyle = UITextBorderStyleRoundedRect;
    textFieldRounded.textColor = [UIColor blackColor]; 
    textFieldRounded.font = [UIFont systemFontOfSize:17.0]; 
    textFieldRounded.placeholder = @"Lorem ipsum dolor sit er elite lamet, consectetatur etc....";  //place holder
    textFieldRounded.autocorrectionType = UITextAutocorrectionTypeNo;   
    textFieldRounded.backgroundColor = [UIColor clearColor];
    textFieldRounded.keyboardType = UIKeyboardTypeDefault;  
    textFieldRounded.returnKeyType = UIReturnKeyDone;
        
    textFieldRounded.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    [textFieldRounded setReturnKeyType: UIReturnKeyDone];
    [self.view addSubview:textFieldRounded];    
    textFieldRounded.delegate = self;
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 20)];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentLeft; // UITextAlignmentCenter, UITextAlignmentLeft    
    label.text = @"Voice Feedback";
   
    [self.view addSubview:label];
    label = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 300, 260)];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentLeft; // UITextAlignmentCenter, UITextAlignmentLeft
    
    label.text = @"You can also write with text feedback";
    [self.view addSubview:label];
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

-(void)feedBackSubmit
{
   
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *source = [prefs objectForKey:@"source"];
    NSString *uniqueId = [prefs objectForKey:@"uniqueid"];
    NSString *udid = [UIDevice currentDevice].uniqueIdentifier;
        
    RKClient *client = [RKClient clientWithBaseURL:@"http://10.0.0.36:8080/TPServer"];
    RKParams *rkp = [RKParams params];
    [RKClient setSharedClient:client];
   
    if (soundFilePath != nil) {
        NSString *myFile =soundFilePath;
        RKParamsAttachment* attachment = [rkp setFile:myFile forParam:@"file"];
        attachment.MIMEType = @"audio/caf";
        attachment.fileName = @"FBSound.caf";
             [rkp setValue:FEEDBACK_AUDIO forParam:@"formattype"];
    } 
    if (textFieldRounded.text != nil){
        [rkp setValue:textFieldRounded.text forParam:@"txtfb"];
        [rkp setValue:FEEDBACK_TEXT forParam:@"formattype"];
    } 
   
    if(soundFilePath != nil && textFieldRounded.text != nil){
        [rkp setValue:FEEDBACK_BOTH forParam:@"formattype"]; 
    }
    
    [rkp setValue:udid forParam:@"deviceid"]; 
    [rkp setValue:source forParam:@"source"]; 
    [rkp setValue:uniqueId forParam:@"uniqueid"]; 
    [rkp setValue:@"3.5" forParam:@"rating"];
       
    [[RKClient sharedClient]  post:@"/ws/feedback/new" params:rkp delegate:self];

}
@end
