//
//  FeedBackForm.h
//  Nimbler
//
//  Created by JaY Kumbhani on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import "TPResponse.h"
#import "Plan.h"


@interface FeedBackForm : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate,RKObjectLoaderDelegate, RKRequestDelegate>{
    
   	NSString *soundFilePath;
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    TPResponse *tpResponse;
    NSString *tpURLResource;
    IBOutlet UITextView *txtFeedBack;

}
@property (strong, nonatomic) TPResponse *tpResponse; 
@property(nonatomic,retain) NSString *tpURLResource;

-(IBAction)recordRecording:(id)sender;
-(IBAction)stopRecording:(id)sender;
-(IBAction)pausRecording:(id)sender;
-(IBAction)playRecording:(id)sender;
-(IBAction)submitFeedBack:(id)sender;

@end

