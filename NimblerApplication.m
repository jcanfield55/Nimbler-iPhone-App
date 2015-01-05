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

@implementation NimblerApplication

// Open the custom Webview in case we click on advisories links.
// Open the appstore page when we click on App Store Review Button 
- (BOOL)openURL:(NSURL*)url {
    RXCustomTabBar *rxCustomTabbar = (RXCustomTabBar*)[nc_AppDelegate sharedInstance].tabBarController;
    twitterViewController *twitterVC = (twitterViewController *)((UINavigationController *)[rxCustomTabbar.viewControllers objectAtIndex:0]).visibleViewController;
    UIViewController *frontViewController = ((UINavigationController *) [nc_AppDelegate sharedInstance].revealViewController.frontViewController).topViewController;
    if([frontViewController isKindOfClass:[RouteDetailsViewController class]]){
        [(RouteDetailsViewController *)frontViewController openUrl:url];
        return NO;
    }
    else if ([twitterVC isKindOfClass:[twitterViewController class]]) {
        [(twitterViewController *)twitterVC openUrl:url];
         return NO;
    }
    return [super openURL:url];
}

/* Opens a URL without a webview */
- (BOOL)openURLWithoutWebView:(NSURL*)url
{
    return [super openURL:url];
}

@end
