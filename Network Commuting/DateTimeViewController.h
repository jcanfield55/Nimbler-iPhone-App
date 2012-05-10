//
//  DateTimeViewController.h
//  Network Commuting
//
//  Created by John Canfield on 3/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "enums.h"
#import "ToFromViewController.h"

@interface DateTimeViewController : UIViewController {
    BOOL isCancelButtonPressed;   // Indicates cancel button pressed when view is finished
}

@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UISegmentedControl *departArriveSelector;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) NSDate* date;    // Current selected date
@property (unsafe_unretained, nonatomic) ToFromViewController* toFromViewController;
@property (nonatomic) DepartOrArrive departOrArrive;

- (IBAction)datePickerChange:(id)sender forEvent:(UIEvent *)event;
- (IBAction)doneButtonPressed:(id)sender forEvent:(UIEvent *)event;
- (IBAction)cancelButtonPressed:(id)sender forEvent:(UIEvent *)event;
- (IBAction)departArriveSelectorChange:(id)sender forEvent:(UIEvent *)event;

@end
