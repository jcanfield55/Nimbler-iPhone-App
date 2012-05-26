//
//  twitterSearch.m
//  Nimbler
//
//  Created by JaY Kumbhani on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "twitterSearch.h"

@implementation twitterSearch

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma utility methods

-(void)loadRequest:(NSString*) URL{

    NSLog(@"load request %@", URL);
    NSURL *tw_url = [NSURL URLWithString:CALTRAIN_TWITTER_URL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:tw_url];
    
    [twitterWebView loadRequest:requestObj];
}

#pragma webView Delegate Method
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    loadProcess.hidden = NO;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    loadProcess.hidden = YES;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    loadProcess.hidden = YES;
    NSLog(@"Not loading Properly.......");
}

@end
