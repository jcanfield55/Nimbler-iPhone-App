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
            singleton.frame = CGRectMake(0, 0, 320, 430);
        } else {
            singleton.frame = CGRectMake(0, 0, 320, 366);
        }
        [singleton setClipsToBounds:YES];
    }
    
    return singleton;
}
@end
