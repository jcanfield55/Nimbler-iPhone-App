//
//  FeedBackViewController.h
//  Nimbler
//
//  Created by JaY Kumbhani on 5/15/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface FeedBackViewController : UIViewController <AVAudioRecorderDelegate>{
    
    BOOL toggle;
	
	//Variables setup for access in the class:
	NSURL * recordedTmpFile;
	AVAudioRecorder * recorder;
}
@property (nonatomic,retain) UIActivityIndicatorView * actSpinner;




@end
