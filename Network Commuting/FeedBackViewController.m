//
//  FeedBackViewController.m
//  Nimbler
//
//  Created by JaY Kumbhani on 5/15/12.
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
    [super viewDidLoad];
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

    UIButton *playRec = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [playRec addTarget:self 
                action:@selector(playRecordedFile)
      forControlEvents:UIControlEventTouchDown];
    [playRec setImage:[UIImage imageNamed:@"playRec.png"] forState:UIControlStateNormal];
    playRec.frame = CGRectMake(200.0, 45.0, 40.0, 40.0);
    [self.view addSubview:playRec];
    
    toggle = YES;
	AVAudioSession * audioSession = [AVAudioSession sharedInstance];
	[audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
	[audioSession setActive:YES error: nil];
    
    actSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [actSpinner setCenter:CGPointMake(320/2.0, 460/2.0)]; // I do this because I'm in landscape mode
    [self.view addSubview:actSpinner];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    NSFileManager * fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:[recordedTmpFile path] error:nil];
	recorder = nil;
	recordedTmpFile = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)startRecord
{
     
    NSLog(@"start recording");
    [actSpinner startAnimating];
            
    NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue :[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey]; 
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];

     recordedTmpFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"caf"]]];
   
    NSLog(@"Using File called: %@",recordedTmpFile);
    
    recorder = [[ AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:nil];
        [recorder setDelegate:self];
    
    [recorder record];
    //There is an optional method for doing the recording for a limited time see 
    [recorder recordForDuration:(NSTimeInterval) 10];

}

-(void)stopRecordingFeedback
{
    [recorder stop];
    [actSpinner stopAnimating];
    NSLog(@"Stop Recording");
}

-(void)playRecordedFile
{
    NSLog(@"play Recording");
    AVAudioPlayer * avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordedTmpFile error:nil];
	[avPlayer prepareToPlay];
	[avPlayer play];
}

@end
