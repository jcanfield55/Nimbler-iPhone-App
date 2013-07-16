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

+ (WebView *)instance:(int)width {
    if (singleton == nil) {
        singleton = [[WebView alloc] init];
        
        if ([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT) {
            singleton.frame = CGRectMake(0, 0, width, 430);
        } else {
            singleton.frame = CGRectMake(0, 0, width, 366);
        }
        [singleton setClipsToBounds:YES];
    }
    
    return singleton;
}
@end
