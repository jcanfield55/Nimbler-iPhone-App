//
//  SettingInfoViewController.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SettingInfoViewController.h"
#import "nc_AppDelegate.h"
#import "UserPreferance.h"

@implementation SettingInfoViewController

@synthesize steperPushHour,sliderMaxWalkDistance,managedObjectContext;

int pushHour;
bool isPush;

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
    

    self.managedObjectContext = [[nc_AppDelegate sharedInstance] managedObjectContext]; 
        
    // Do any additional setup after loading the view from its nib.
    [self fetchData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(IBAction)UpdateSetting:(id)sender
{
    @try {
        
        if (!switchPushEnable.on) {
            // set -1 for stop getting push notification
            pushHour = -1;
            isPush = NO;
        } else {
            isPush = YES;
        }   
                
        alertView = [self upadetSettings];    
        [alertView show];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *token = [prefs objectForKey:@"DeviceToken"];
        
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSString *udid = [UIDevice currentDevice].uniqueIdentifier; 
        
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                @"deviceid", udid,
                                @"alertCount",[NSString stringWithFormat:@"%d",pushHour],
                                @"deviceToken", token,
                                @"maxDistance", [NSString stringWithFormat:@"%f",sliderMaxWalkDistance.value],
                                nil];
        
        
        NSString *twitCountReq = [@"users/preferences/update" appendQueryParams:params];
        
        [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(popOutFromSettingView) userInfo:nil repeats: NO];
        [[RKClient sharedClient]  get:twitCountReq delegate:self];
        NSFetchRequest *request1 = [[NSFetchRequest alloc] init]; 
        NSEntityDescription *entity1 = [NSEntityDescription entityForName:@"UserPreferance"     
                                                   inManagedObjectContext:self.managedObjectContext];
       
        [request1 setEntity:entity1];    
        NSArray *empArray=[self.managedObjectContext executeFetchRequest:request1 error:nil]; 
        
        if ([empArray count] > 0){ 
            UserPreferance *user = [empArray objectAtIndex:0]; 
            user.pushEnable = [NSNumber numberWithBool:isPush];
            user.triggerAtHour = [NSNumber numberWithInt:pushHour];
            user.walkDistance = [NSNumber numberWithFloat:sliderMaxWalkDistance.value];
            [self.managedObjectContext save:nil]; 

        }      
    }
    @catch (NSException *exception) {
        NSLog(@"exception at upadting plan : %@", exception);
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        [self.navigationController popViewControllerAnimated:YES]; 
    }
       
}

-(IBAction)stepperValueChanged:(UIStepper *)sender
{
    pushHour = steperPushHour.value;
    lblPushTrigger.text = [NSString stringWithFormat:@"%d",pushHour];
}

-(IBAction)sliderWalkDistanceValueChanged:(UISlider *)sender
{
    float walkDistance = sliderMaxWalkDistance.value;
    [sliderMaxWalkDistance setValue:sliderMaxWalkDistance.value];
    [sliderMaxWalkDistance setSelected:YES];
    
    NSLog(@"walk distance: %f", walkDistance);
}

-(void)popOutFromSettingView { 
    [alertView dismissWithClickedButtonIndex:0 animated:NO];
    [self.navigationController popViewControllerAnimated:YES];    
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    @try {
        if ([request isGET]) {
            NSLog(@"response for userUpdateSettings:  %@", [response bodyAsString]);
        }
    }  @catch (NSException *exception) {
        NSLog( @"Exception while getting unique IDs from TP Server response: %@", exception);
    } 
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

-(void)fetchData
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"UserPreferance" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init] ;
    [request setEntity:entityDescription];
       
    NSError *error = nil;
       NSArray *arrayUserSetting  = [moc executeFetchRequest:request error:&error];
    if (arrayUserSetting == nil)
    {
        // Deal with error...
    } else {
        // set stored value for userSettings       
        [sliderMaxWalkDistance setValue:[[[arrayUserSetting valueForKey:@"walkDistance"] objectAtIndex:0] doubleValue]];
        [steperPushHour setValue:[[[arrayUserSetting valueForKey:@"triggerAtHour"] objectAtIndex:0] intValue]];
        lblPushTrigger.text = [NSString stringWithFormat:@"%d",[[[arrayUserSetting valueForKey:@"triggerAtHour"] objectAtIndex:0] intValue]];
        pushHour = [[[arrayUserSetting valueForKey:@"triggerAtHour"] objectAtIndex:0] intValue];
        if ([[[arrayUserSetting valueForKey:@"pushEnable"] objectAtIndex:0] intValue] == 0) {
            [switchPushEnable setOn:NO];
        } else {
            [switchPushEnable setOn:YES];
        }
        
    }
      
}
@end