//
//  LocationPickerViewController.m
//  Nimbler
//
//  Created by John Canfield on 6/8/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LocationPickerViewController.h"
#import "FeedBackForm.h"

@interface LocationPickerViewController ()
{
    BOOL locationPicked;  // True if a location is picked before returning to ToFromViewController
}
@end

@implementation LocationPickerViewController

@synthesize mainTable;
@synthesize feedbackButton;
@synthesize toFromTableVC;
@synthesize locationArray;
@synthesize isFrom;
@synthesize isGeocodeResults;

int const LOCATION_PICKER_TABLE_HEIGHT = 370;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"Pick a location"];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    locationPicked = FALSE;
    
    // Enforce height of main table
    CGRect rect0 = [mainTable frame];
    rect0.size.height = LOCATION_PICKER_TABLE_HEIGHT;
    [mainTable setFrame:rect0];
    mainTable.delegate = self;
    mainTable.dataSource = self;
    [mainTable reloadData];
}

//
// TableView datasource methods
//

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [locationArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    Location *loc = [locationArray objectAtIndex:[indexPath row]];
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"LocationPickerViewCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                      reuseIdentifier:@"LocationPickerViewCell"];
        cell.textLabel.numberOfLines= 2;     
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    }
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];        
    [[cell textLabel] setText:[loc shortFormattedAddress]];    
    [cell sizeToFit];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Send back the picked location and pop the view controller back to ToFromViewController
    [toFromTableVC setPickedLocation:[locationArray objectAtIndex:[indexPath row]] 
                       locationArray:locationArray isGeocodedResults:isGeocodeResults];
    locationPicked = TRUE;
    [[self navigationController] popViewControllerAnimated:YES];
}

//DE:21 dynamic cell height 
#pragma mark - UIDynamic cell heght methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Location *loc = [locationArray objectAtIndex:[indexPath row]];
        
    NSString *cellText = [loc formattedAddress];
    CGSize size = [cellText 
                sizeWithFont:[UIFont systemFontOfSize:14] 
                constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
    
    CGFloat height = size.height + 7;
    if (height < 44.0) { // Set a minumum row height
        height = 44.0;
    }
    return height;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (locationPicked == FALSE) {   // If user just returning back to main page...
        for (Location* loc in locationArray) { 
            // remove all the locations from Core Data if they have frequency = 0
            if ([loc fromFrequencyFloat]<TINY_FLOAT && [loc toFrequencyFloat]<TINY_FLOAT) {
                [[toFromTableVC locations] removeLocation:loc];
            }
        }
        
        // return to the appropriate edit mode so users can continue editing
        if (isFrom) {
            [[toFromTableVC toFromVC] setEditMode:FROM_EDIT];
        }
        else {
            [[toFromTableVC toFromVC] setEditMode:TO_EDIT];
        }
    }
}

// Feedback button responder
- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event 
{
    FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:[NSNumber numberWithInt:FB_SOURCE_GENERAL] uniqueId:nil date:nil fromAddress:nil toAddress:nil];
    FeedBackForm *feedbackVC =  [[FeedBackForm alloc] initWithFeedBack:@"FeedBackForm" fbParam:fbParam bundle:nil];
    [[self navigationController] pushViewController:feedbackVC animated:YES];

}

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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
