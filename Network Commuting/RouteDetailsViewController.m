//
//  RouteDetailsViewController.m
//  Network Commuting
//
//  Created by John Canfield on 2/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RouteDetailsViewController.h"
#import "Leg.h"
#import "UtilityFunctions.h"

@implementation RouteDetailsViewController

@synthesize itinerary;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        [[self navigationItem] setTitle:@"Route"];
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return self;
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
    if ([[itinerary legs] count] > 0) {
        return [[itinerary legs] count]+2;  // # of legs plus start & end point
    }
    else {
        return 0;  // TODO come up with better handling for no legs in this itinerary
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UIRouteDetailsViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:@"UIRouteDetailsViewCell"];
    }

    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:12.0]];
    [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:12.0]];

    NSMutableString *titleText=[NSMutableString stringWithString:@""];
    NSString *subTitle=@"";
    NSArray *sortedLegs = [itinerary sortedLegs];
    if ([indexPath row] == 0) { // if first row, put in start point
        titleText = [NSString stringWithFormat:@"Start at %@", [[[sortedLegs objectAtIndex:0] from] name]];
    }
    else if ([indexPath row] == [[itinerary sortedLegs] count] + 1) { // if last row, put in end point
        titleText = [NSString stringWithFormat:@"End at %@", [[[sortedLegs objectAtIndex:([sortedLegs count]-1)] to] name]];
    }
    else {  // otherwise, it is one of the legs
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:([indexPath row]-1)];
        if ([[leg mode] isEqualToString:@"WALK"]) {
            titleText = [NSString stringWithFormat:@"Walk to %@", [[leg to] name]];
            subTitle = [NSString stringWithFormat:@"About %@, %@", 
                        durationString([[leg duration] floatValue]), 
                        distanceStringInMilesFeet([[leg distance] floatValue])];
        }
        else if ([[leg mode] isEqualToString:@"BUS"]) {
            titleText = [NSMutableString stringWithFormat:@"Bus %@ - %@", [leg routeShortName], [leg routeLongName]];
            if ([leg headSign]) {
                [titleText appendFormat:@" to %@", [leg headSign]];
            }
            subTitle = [NSString stringWithFormat:@"%@    Depart %@\n%@    Arrive %@",
                        [timeFormatter stringFromDate:[leg startTime]],
                        [[leg from] name],
                        [timeFormatter stringFromDate:[leg endTime]],
                        [[leg to] name]];
        }
        else {
            titleText = [NSString stringWithFormat:@"%@ %@ - %@", [leg mode], [leg routeShortName], [leg routeLongName]];
            subTitle = [NSString stringWithFormat:@"%@    Depart %@\n%@    Arrive %@",
                        [timeFormatter stringFromDate:[leg startTime]],
                        [[leg from] name],
                        [timeFormatter stringFromDate:[leg endTime]],
                        [[leg to] name]];            
        }

    }
    [[cell textLabel] setText:titleText];
    [[cell detailTextLabel] setLineBreakMode:UILineBreakModeWordWrap];
    [[cell detailTextLabel] setNumberOfLines:0];
    [[cell detailTextLabel] setText:subTitle];
    return cell;
}

@end
