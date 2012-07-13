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

#define SETTING_TITLE       @"App Settings"
#define SETTING_ENTITY      @"UserPreferance"
#define SETTING_ALERT_MSG   @"Updating your settings \n Please wait..."
#define WALK_DISTANCE       @"walkDistance"
#define TRIGGER_AT_HOUR     @"triggerAtHour"
#define PUSH_ENABLE         @"pushEnable"
#define PUSH_NOTIFY_OFF     -1

@implementation SettingInfoViewController

@synthesize steperPushHour,sliderMaxWalkDistance,managedObjectContext;

int pushHour;
bool isPush;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[self navigationItem] setTitle:SETTING_TITLE];
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
    [self fetchUserSettingData];
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
            pushHour = PUSH_NOTIFY_OFF;
            isPush = NO;
        } else {
            isPush = YES;
        }   
        alertView = [self upadetSettings];    
        [alertView show];
        // Update in local DB
        NSFetchRequest *requestFetchUserSettingEntity = [[NSFetchRequest alloc] init]; 
        NSEntityDescription *userSettingEntity = [NSEntityDescription entityForName:SETTING_ENTITY     
                                                   inManagedObjectContext:self.managedObjectContext];
        [requestFetchUserSettingEntity setEntity:userSettingEntity];    
        NSArray *settingEntityDataArray =[self.managedObjectContext executeFetchRequest:requestFetchUserSettingEntity error:nil]; 
        if ([settingEntityDataArray count] > 0){ 
            UserPreferance *user = [settingEntityDataArray objectAtIndex:0]; 
            user.pushEnable = [NSNumber numberWithBool:isPush];
            user.triggerAtHour = [NSNumber numberWithInt:pushHour];
            user.walkDistance = [NSNumber numberWithFloat:sliderMaxWalkDistance.value];
            [self.managedObjectContext save:nil]; 
        } 
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *token = [prefs objectForKey:DEVICE_TOKEN];
        
        // Update in TPServer DB
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSString *udid = [UIDevice currentDevice].uniqueIdentifier; 
        
        NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects: 
                                DEVICE_ID, udid,
                                ALERT_COUNT,[NSNumber numberWithInt:pushHour],
                                DEVICE_TOKEN, token,
                                MAXIMUM_WALK_DISTANCE,[NSNumber numberWithFloat:sliderMaxWalkDistance.value],
                                nil];
        NSString *twitCountReq = [UPDATE_SETTING_REQ appendQueryParams:params];
        [[RKClient sharedClient]  get:twitCountReq delegate:self];
        
         [NSTimer scheduledTimerWithTimeInterval:TIMER_SMALL_REQUEST_DELAY target:self selector:@selector(popOutFromSettingView) userInfo:nil repeats: NO];
    }
    @catch (NSException *exception) {
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
        [self.navigationController popViewControllerAnimated:YES];
         NSLog(@"exception at upadting Setting : %@", exception);
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
                           initWithTitle:SETTING_ALERT_MSG  
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

-(void)fetchUserSettingData
{
    @try {
        NSManagedObjectContext *moc = [self managedObjectContext];
        NSEntityDescription *entityDescription = [NSEntityDescription
                                                  entityForName:SETTING_ENTITY inManagedObjectContext:moc];
        NSFetchRequest *request = [[NSFetchRequest alloc] init] ;
        [request setEntity:entityDescription];
        
        NSError *error = nil;
        NSArray *arrayUserSetting  = [moc executeFetchRequest:request error:&error];
        if (arrayUserSetting == nil)
        {
            // Deal with error...
        } else {
            // set stored value for userSettings       
            [sliderMaxWalkDistance setValue:[[[arrayUserSetting valueForKey:WALK_DISTANCE] objectAtIndex:0] doubleValue]];
            [steperPushHour setValue:[[[arrayUserSetting valueForKey:TRIGGER_AT_HOUR] objectAtIndex:0] intValue]];
            lblPushTrigger.text = [NSString stringWithFormat:@"%d",[[[arrayUserSetting valueForKey:TRIGGER_AT_HOUR] objectAtIndex:0] intValue]];
            pushHour = [[[arrayUserSetting valueForKey:TRIGGER_AT_HOUR] objectAtIndex:0] intValue];
            if ([[[arrayUserSetting valueForKey:PUSH_ENABLE] objectAtIndex:0] intValue] == 0) {
                [switchPushEnable setOn:NO];
            } else {
                [switchPushEnable setOn:YES];
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at fetch data from core data and set to views: %@",exception);
    }
}
@end