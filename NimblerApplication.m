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
#import "RouteDetailsViewController.h"

#import "WebView.h"

@implementation NimblerApplication

// Open the custom Webview in case we click on advisories links.
// Open the appstore page when we click on App Store Review Button 
- (BOOL)openURL:(NSURL*)url {
    UIViewController *currentViewController = [nc_AppDelegate sharedInstance].revealController.rearViewController.navigationController.topViewController;
    if ([currentViewController isKindOfClass:[twitterViewController class]]) {
        [(twitterViewController *)currentViewController openUrl:url];
         return NO;
    }
    else if([currentViewController isKindOfClass:[RouteDetailsViewController class]]){
        [(RouteDetailsViewController *)currentViewController openUrl:url];
        return NO;
    }
    return [super openURL:url];
}

@end
