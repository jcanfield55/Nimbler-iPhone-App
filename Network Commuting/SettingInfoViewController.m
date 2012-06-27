//
//  SettingInfoViewController.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SettingInfoViewController.h"

@implementation SettingInfoViewController
NSString *alertCount;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[self navigationItem] setTitle:@"App Settings"];
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
    arrayTweets = [[NSMutableArray alloc] init];
    [arrayTweets addObject:@"Never"];
    [arrayTweets addObject:@"1"];
    [arrayTweets addObject:@"2"];
    [arrayTweets addObject:@"3"];
    [arrayTweets addObject:@"4"];
    [arrayTweets addObject:@"5"];
    [arrayTweets addObject:@"6"];
    
    PickerTweetCount.delegate = self;
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

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [arrayTweets count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [arrayTweets objectAtIndex:row];   
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSLog(@"select hour: %@", [arrayTweets objectAtIndex:row]);
    if ([[arrayTweets objectAtIndex:row] isEqualToString:@"Never"]) {
        alertCount = @"-1";
    } else {
        alertCount = [arrayTweets objectAtIndex:row];
    }
    [txtMaxWalkDistance resignFirstResponder];
}


-(IBAction)UpdateSetting:(id)sender
{
    alertView = [self upadetSettings];    
    [alertView show];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *token = [prefs objectForKey:@"DeviceToken"];
    RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
    [RKClient setSharedClient:client];
    NSString *udid = [UIDevice currentDevice].uniqueIdentifier;            
    NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                            @"deviceid", udid,
                            @"alertCount", alertCount,
                            @"deviceToken", token,
                            @"maxDistance", txtMaxWalkDistance.text,
                            nil];    
    NSString *twitCountReq = [@"users/preferences/update" appendQueryParams:params];
    
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(popOutFromSettingView) userInfo:nil repeats: NO];
    [[RKClient sharedClient]  get:twitCountReq delegate:self];
}

-(UIAlertView *) upadetSettings
{
    UIAlertView *alerts = [[UIAlertView alloc]   
                           initWithTitle:@"Updating your settings \n Please wait..."  
                           message:nil delegate:nil cancelButtonTitle:nil  
                           otherButtonTitles:nil];  
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]  
                                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];  
    
    indicator.frame = CGRectMake(135, 70, 20, 20);
    [indicator startAnimating];  
    [alerts addSubview:indicator]; 
    [alerts show];
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];  
    return alerts;
    
}

-(void)popOutFromSettingView { 
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    [self.navigationController popViewControllerAnimated:YES];    
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    @try {
        if ([request isGET]) {
            NSLog(@" %@", [response bodyAsString]);
        }
    }  @catch (NSException *exception) {
        NSLog( @"Exception while getting unique IDs from TP Server response: %@", exception);
    } 
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Any additional checks to ensure you have the correct textField here.
    if(textField == txtMaxWalkDistance) {
        [txtMaxWalkDistance resignFirstResponder];
        return NO;
    }
    return YES;    
}


#pragma mark TextField animation at selected

- (void) animateTextField: (UITextField*) textField up: (BOOL) up{
    int txtPosition = (textField.frame.origin.y - 160);
    const int movementDistance = (txtPosition < 0 ? 0 : txtPosition); // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [self animateTextField: textField up: YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self animateTextField: textField up: NO];
}

@end