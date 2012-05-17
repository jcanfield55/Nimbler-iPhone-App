//
//  FeedBackViewController.m
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/15/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "FeedBackViewController.h"


@implementation FeedBackViewController

@synthesize actSpinner;

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
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"voiceFeedback.caf"];
    
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

-(void)setUpUI
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self 
               action:@selector(startRecord)
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
    
	AVAudioSession * audioSession = [AVAudioSession sharedInstance];
	[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
	[audioSession setActive:YES error: nil];
    
    actSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [actSpinner setCenter:CGPointMake(320/2.0, 460/2.0)]; // I do this because I'm in landscape mode
    [self.view addSubview:actSpinner];
}

@end
