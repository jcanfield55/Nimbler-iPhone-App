//
//  WebView.m
//  Nimbler SF
//
//  Created by Julian Jennings-White on 4/6/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "WebView.h"

@implementation WebView

WebView *singleton;

+ (WebView *)instance {
    if (singleton == nil) {
        singleton = [[WebView alloc] init];
        singleton.frame = CGRectMake(0, 0,
                                     [[UIScreen mainScreen] bounds].size.width,
                                     [[UIScreen mainScreen] bounds].size.height - WEBVIEW_TOP_BAR_HEIGHT); // DE412 fix for auto-sizing
        [singleton setClipsToBounds:YES];
        [singleton setScalesPageToFit:YES];
    }
    
    return singleton;
}
@end
