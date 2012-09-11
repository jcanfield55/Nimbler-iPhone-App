//
//  DateTimeViewController.m
//  Network Commuting
//
//  Created by John Canfield on 3/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "DateTimeViewController.h"

#if FLURRY_ENABLED
#include "Flurry.h"
#endif

@interface DateTimeViewController ()

@end

@implementation DateTimeViewController

@synthesize datePicker;
@synthesize departArriveSelector;
@synthesize cancelButton;
@synthesize doneButton;
@synthesize date;
@synthesize toFromViewController;
@synthesize departOrArrive;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [datePicker setMinuteInterval:5];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#if FLURRY_ENABLED
    [Flurry logEvent:FLURRY_DATE_PICKER_APPEAR];
#endif
    [datePicker setDate:date];
    isCancelButtonPressed = NO;
    if (departOrArrive == DEPART) {
        [departArriveSelector setSelectedSegmentIndex:0];
    }
    else {
        [departArriveSelector setSelectedSegmentIndex:1];
    }
}

- (IBAction)datePickerChange:(id)sender forEvent:(UIEvent *)event
{
    date = [datePicker date];
}

// Return back without updating the toFromViewController settings
- (IBAction)cancelButtonPressed:(id)sender forEvent:(UIEvent *)event 
{
    isCancelButtonPressed = YES;
    [[self navigationController] popViewControllerAnimated:YES];
}

// Update the toFromViewController with new settings and then return back
- (IBAction)doneButtonPressed:(id)sender forEvent:(UIEvent *)event 
{
    isCancelButtonPressed = NO;
    [[self navigationController] popViewControllerAnimated:YES];
}

// if the person presses back on the NavBar, save the new settings to toFromViewController
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];    
    
    if (!isCancelButtonPressed) {
        
#if FLURRY_ENABLED
        NSDictionary *params = [NSDictionary 
                                dictionaryWithObjectsAndKeys:
                                FLURRY_NEW_DATE, [NSString stringWithFormat:@"%@", date], nil];
        [Flurry logEvent:FLURRY_DATE_PICKER_NEW_DATE withParameters:params];
#endif
        [toFromViewController setTripDate:date];
        [toFromViewController setTripDateLastChangedByUser:[[NSDate alloc] init]];
        [toFromViewController setIsTripDateCurrentTime:NO];
        [toFromViewController setDepartOrArrive:departOrArrive];
    } else {
#if FLURRY_ENABLED
        [Flurry logEvent:FLURRY_DATE_PICKER_CANCEL];
#endif
    }
}


- (IBAction)departArriveSelectorChange:(id)sender forEvent:(UIEvent *)event
{
    if ([departArriveSelector selectedSegmentIndex] == 0) {
        departOrArrive = DEPART;
    }
    else {
        departOrArrive = ARRIVE;
        // Move date to at least one hour from now if not already
        NSDate* nowPlus1hour = [[NSDate alloc] initWithTimeIntervalSinceNow:(60.0*60)];  // 1 hour from now
        if ([date earlierDate:nowPlus1hour] == date) { // if date is earlier than 1 hour from now
            date = nowPlus1hour;
            [datePicker setDate:date animated:YES];
        }
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload{
    [super viewDidUnload];
    self.datePicker = nil;
    self.departArriveSelector = nil;
    self.cancelButton = nil;
    self.doneButton = nil;
}

- (void)dealloc{
    self.datePicker = nil;
    self.departArriveSelector = nil;
    self.cancelButton = nil;
    self.doneButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
