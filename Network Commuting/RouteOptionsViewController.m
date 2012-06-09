//
//  RouteOptionsViewController.m
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RouteOptionsViewController.h"
#import "Leg.h"
#import "UtilityFunctions.h"
#import <math.h>
#import "TwitterSearch.h"
#import "FeedBackForm.h"

@implementation RouteOptionsViewController

@synthesize plan;
@synthesize feedBackPlanId;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        [[self navigationItem] setTitle:@"Itineraries"];
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];

    
       feedback = [[UIBarButtonItem alloc] initWithTitle:@"F" style:UIBarButtonItemStylePlain target:self action:@selector(feedBackSubmit)];

        self.navigationItem.rightBarButtonItem = feedback;
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[self tableView] reloadData];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

// Table view management methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[plan itineraries] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UIRouteOptionsViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:@"UIRouteOptionsViewCell"];
    }
    // Get the requested itinerary
    Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
    
    /*
        for feedback planId
     */
        
    // Set title
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
    NSString *titleText = [NSString stringWithFormat:@"%@ - %@ (%@)", 
                          [timeFormatter stringFromDate:[itin startTime]],
                          [timeFormatter stringFromDate:[itin endTime]],
                           durationString([[itin duration] floatValue])];
    [[cell textLabel] setText:titleText];
    
    // Set sub-title (show each leg's mode and route if available)
    NSMutableString *subTitle = [NSMutableString stringWithCapacity:30];
    NSArray *sortedLegs = [itin sortedLegs];
    for (int i = 0; i < [sortedLegs count]; i++) {
        Leg *leg = [sortedLegs objectAtIndex:i];
        if ([leg mode] && [[leg mode] length] > 0) {
            if (i > 0) {
                [subTitle appendString:@" -> "];
            }
            [subTitle appendString:[[leg mode] capitalizedString]];
            if ([leg route] && [[leg route] length] > 0) {
                [subTitle appendString:@" "];
                [subTitle appendString:[leg route]];
            }
        }
    }
    [[cell detailTextLabel] setText:subTitle];
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    
//   NSMutableString *subTitle = [NSMutableString stringWithCapacity:100];
//    CGSize size;
//    Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];
//    NSArray *sortedLegs = [itin sortedLegs];
//    for (int i = 0; i < [sortedLegs count]; i++) {
//        Leg *leg = [sortedLegs objectAtIndex:i];
//        if ([leg mode] && [[leg mode] length] > 0) {
//            if (i > 0) {
//                [subTitle appendString:@" -> "];
//            }
//            [subTitle appendString:[[leg mode] capitalizedString]];
//            if ([leg route] && [[leg route] length] > 0) {
//                [subTitle appendString:@" "];
//                [subTitle appendString:[leg route]];
//            }
//        }
//    }
//        
//    size = [subTitle 
//                sizeWithFont:[UIFont systemFontOfSize:14] 
//                constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
//   
//    return size.height + 10;
//}

// If selected, show the RouteDetailsViewController
- (void) tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RouteDetailsViewController *routeDetailsVC = [[RouteDetailsViewController alloc] initWithStyle:UITableViewStylePlain];
    [routeDetailsVC setFeedBackItinerary:[[feedBackPlanId sortedItineraries] objectAtIndex:[indexPath row]]];
    
    [routeDetailsVC setItinerary:[[plan sortedItineraries] objectAtIndex:[indexPath row]]];
    [[self navigationController] pushViewController:routeDetailsVC animated:YES];
}

#pragma mark - View lifecycle

/*
 Implement loadView to create a view hierarchy programmatically, without using a nib.
*/
 - (void)loadView
{
    [super loadView];
//    UIButton *submit = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    [submit addTarget:self 
//               action:@selector(feedBackSubmit)
//     forControlEvents:UIControlEventTouchDown];
//    [submit setTitle:@"feedback" forState:UIControlStateNormal];
//    submit.frame = CGRectMake(220.0, 370.0, 70.0, 20.0);
//    [super.view addSubview:submit];
    
}


-(void)feedBackSubmit
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:@"1" forKey:@"source"];
    [prefs setObject:[plan planId] forKey:@"uniqueid"];
           
    
    
    
    FeedBackForm *legMapVC = [[FeedBackForm alloc] initWithNibName:@"FeedBackForm" bundle:nil];   
    [[self navigationController] pushViewController:legMapVC animated:YES];
 
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
*/
 - (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"RouteOptions loaded");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"RouteOptions did appear");
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


#pragma Rest Request for TPServer

@end
