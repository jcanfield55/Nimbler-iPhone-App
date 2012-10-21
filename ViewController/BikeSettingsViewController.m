//
//  BikeSettingsViewController.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 10/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "BikeSettingsViewController.h"
#import "PlanStore.h"
#import "nc_AppDelegate.h"

@interface BikeSettingsViewController ()
{
    float quickVsBikeFriendly;
    float quickVsHills;
}
- (void)recomputeBikeTriangle;
-(void)popOutToNimbler;

@end

@implementation BikeSettingsViewController

@synthesize modeSelector;
@synthesize quickVsBikeFriendlySlider;
@synthesize quickVsHillsSlider;
@synthesize maxBikeDistanceSlider;
@synthesize maxBikeDistance;
@synthesize bikeTriangleQuick;
@synthesize bikeTriangleFlat;
@synthesize bikeTriangleBikeFriendly;
@synthesize transitMode;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
        [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
        lblNavigationTitle.text=BIKE_SETTINGS_VIEW_TITLE;
        lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
        [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
        lblNavigationTitle.backgroundColor =[UIColor clearColor];
        lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
        self.navigationItem.titleView=lblNavigationTitle;
    }
    return self;
}


- (IBAction)sliderQuickVsHillsChanged:(id)sender
{
    quickVsHills = [quickVsHillsSlider value];
    [self recomputeBikeTriangle];
}

- (IBAction)sliderQuickVsBikeFriendlyChanged:(id)sender
{
    quickVsBikeFriendly = [quickVsBikeFriendlySlider value];
    [self recomputeBikeTriangle];
}

- (IBAction)sliderMaxBikeDistanceChanged:(id)sender
{
    maxBikeDistance = [maxBikeDistanceSlider value];
}

- (void)recomputeBikeTriangle
{
    float denominator = 0.5*quickVsHills + 0.5*quickVsBikeFriendly + 1;
    bikeTriangleFlat = quickVsHills / denominator;
    bikeTriangleBikeFriendly = quickVsBikeFriendly / denominator;
    bikeTriangleQuick = (2 - quickVsHills - quickVsBikeFriendly)/(2 * denominator);
    NIMLOG_BIKE(@"Bike triangle: Quick = %f, Flat = %f, BikeFriendly = %f",
                bikeTriangleQuick, bikeTriangleFlat, bikeTriangleBikeFriendly);
}

- (IBAction)modeSelectorChanged:(id)sender
{
    if (modeSelector.selectedSegmentIndex == 0) {
        transitMode = MODE_TRANSIT;
    }
    else if (modeSelector.selectedSegmentIndex == 1) {
        transitMode = MODE_BIKE_ONLY;
    }
    else {
        transitMode = MODE_TRANSIT_AND_BIKE;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    PlanStore *planStrore = [[nc_AppDelegate sharedInstance] planStore];
    [planStrore  clearCache];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
    }
    UIButton *btnGoToNimbler = [[UIButton alloc] initWithFrame:CGRectMake(0,0,65,34)];
    [btnGoToNimbler addTarget:self action:@selector(popOutToNimbler) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToNimbler setBackgroundImage:[UIImage imageNamed:@"img_nimblerNavigation.png"] forState:UIControlStateNormal];
    
    // Accessibility Label For UI Automation.
    btnGoToNimbler.accessibilityLabel =BACK_TO_NIMBLER_BUTTON;
    
    UIBarButtonItem *backTonimbler = [[UIBarButtonItem alloc] initWithCustomView:btnGoToNimbler];
    self.navigationItem.leftBarButtonItem = backTonimbler;
    
    // Set default bike values
    quickVsHills = [quickVsBikeFriendlySlider value];
    quickVsBikeFriendly = [quickVsBikeFriendlySlider value];
    maxBikeDistance = [maxBikeDistanceSlider value];
    if (modeSelector.selectedSegmentIndex == 0) {
        transitMode = MODE_TRANSIT;
        NIMLOG_BIKE(@"Transit mode Transit Only");
    }
    else if (modeSelector.selectedSegmentIndex == 1) {
        transitMode = MODE_BIKE_ONLY;
        NIMLOG_BIKE(@"Transit mode Bike Only");
    }
    else {
        transitMode = MODE_TRANSIT_AND_BIKE;
        NIMLOG_BIKE(@"Transit mode Bike + Transit");
    }
    [self recomputeBikeTriangle];
}

-(void)popOutToNimbler{
    NSLog(@"Begin popOutToNimbler");
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    NSLog(@"Will popViewControllerAnimated");
    [[self navigationController] popViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
