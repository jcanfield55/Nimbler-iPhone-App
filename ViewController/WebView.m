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
        if ([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT) {
            singleton.frame = CGRectMake(0, 0, 320, 479);
        } else {
            singleton.frame = CGRectMake(0, 0, 320, 415);
        }
        [singleton setClipsToBounds:YES];
        [singleton setScalesPageToFit:YES];
    }
    
    return singleton;
}
@end
