//
//  twitterSearch.h
//  Nimbler
//
//  Created by JaY Kumbhani on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface twitterSearch : UIViewController <UIWebViewDelegate>{
    IBOutlet UIWebView *twitterWebView;
    IBOutlet UIActivityIndicatorView *loadProcess;
}
-(void)loadRequest:(NSString*) URL;
@end
