//
//  LocationPickerViewController.m
//  Nimbler
//
//  Created by John Canfield on 6/8/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LocationPickerViewController.h"
#import "FeedBackForm.h"

#if FLURRY_ENABLED
#import "Flurry.h"
#endif

@interface LocationPickerViewController ()
{
    BOOL locationPicked;  // True if a location is picked before returning to ToFromViewController
}
@end

@implementation LocationPickerViewController

@synthesize mainTable;
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
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"img_navigationbar.png"] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        [UIColor colorWithRed:98.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0], UITextAttributeTextColor,
                                                                         nil]];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#if FLURRY_ENABLED
    [Flurry logEvent:FLURRY_LOCATION_PICKER_APPEAR];
#endif
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:MEDIUM_LARGE_FONT_SIZE]];        
    [[cell textLabel] setText:[loc shortFormattedAddress]];  
    cell.textLabel.textColor = [UIColor colorWithRed:252.0/255.0 green:103.0/255.0 blue:88.0/255.0 alpha:1.0];
    tableView.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"img_line.png"]];
    cell.contentView.backgroundColor = [UIColor colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:0.01];
    [cell sizeToFit];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:0.3];
    // Send back the picked location and pop the view controller back to ToFromViewController
    [toFromTableVC setPickedLocation:[locationArray objectAtIndex:[indexPath row]] 
                       locationArray:locationArray isGeocodedResults:isGeocodeResults];
    locationPicked = TRUE;
    [self popOutToNimbler];   
}

//DE:21 dynamic cell height 
#pragma mark - UIDynamic cell heght methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Location *loc = [locationArray objectAtIndex:[indexPath row]];
        
    NSString *cellText = [loc formattedAddress];
    CGSize size = [cellText 
                sizeWithFont:[UIFont systemFontOfSize:MEDIUM_LARGE_FONT_SIZE] 
                constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
    
    CGFloat height = size.height + VARIABLE_TABLE_CELL_HEIGHT_BUFFER;
    if (height < STANDARD_TABLE_CELL_MINIMUM_HEIGHT) { // Set a minumum row height
        height = STANDARD_TABLE_CELL_MINIMUM_HEIGHT;
    }
    // static height for better UI
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
   UIButton *btnGoToNimbler = [[UIButton alloc] initWithFrame:CGRectMake(0,0,82,34)];
    [btnGoToNimbler addTarget:self action:@selector(popOutToNimbler) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToNimbler setBackgroundImage:[UIImage imageNamed:@"img_nimblerNavigation.png"] forState:UIControlStateNormal];
    
    UIBarButtonItem *backTonimbler = [[UIBarButtonItem alloc] initWithCustomView:btnGoToNimbler];
    self.navigationItem.leftBarButtonItem = backTonimbler;
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

-(void)popOutToNimbler
{
    [toFromTableVC textSubmitted:nil forEvent:nil];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    [[self navigationController] popViewControllerAnimated:NO];
}

@end
