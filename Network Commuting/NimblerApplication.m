//
//  NimblerApplication.m
//  Nimbler SF
//
//  Created by Julian Jennings-White on 4/6/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "NimblerApplication.h"
#import "nc_AppDelegate.h"
#import "twitterViewController.h"

#import "WebView.h"

@implementation NimblerApplication

- (BOOL)openURL:(NSURL*)url {
    UIViewController *currentViewController = ((UINavigationController *)((nc_AppDelegate *)self.delegate).tabBarController.selectedViewController).topViewController;
    if ([currentViewController isKindOfClass:[twitterViewController class]]) {
        [(twitterViewController *)currentViewController openUrl:url];
    }
    
    return NO;
}

@end
