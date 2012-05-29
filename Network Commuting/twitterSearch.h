//
//  TwitterSearch.h
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterSearch : UIViewController <UIWebViewDelegate>{
    IBOutlet UIWebView *twitterWebView;
    IBOutlet UIActivityIndicatorView *loadProcess;
}
-(void)loadRequest:(NSString*) URL;
@end
