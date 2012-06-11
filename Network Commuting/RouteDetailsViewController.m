//
//  RouteDetailsViewController.m
//  Network Commuting
//
//  Created by John Canfield on 2/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RouteDetailsViewController.h"
#import "Leg.h"
#import "LegMapViewController.h"
#import "RootMap.h"
#import "TwitterSearch.h"
#import "FeedBackForm.h"

@implementation RouteDetailsViewController

@synthesize itinerary;
@synthesize feedBackItinerary;

-(void)loadView
{
    [super loadView];   
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        [[self navigationItem] setTitle:@"Route"];
        
        UIImage *mapTmg = [UIImage imageNamed:@"map.png"];
        UIButton *mapBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        mapBtn.bounds = CGRectMake( 0, 0, mapTmg.size.width, mapTmg.size.height );
        [mapBtn setImage:mapTmg forState:UIControlStateNormal];
        [mapBtn addTarget:self action:@selector(mapOverView)
             forControlEvents:UIControlEventTouchDown];

        map = [[UIBarButtonItem alloc] initWithCustomView:mapBtn]; 
        
        feedback = [[UIBarButtonItem alloc] initWithTitle:@"F" style:UIBarButtonItemStylePlain target:self action:@selector(feedBackSubmit)];
       
        
        UIImage *twit = [UIImage imageNamed:@"twitter.png"];
        UIButton *twitterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        twitterBtn.bounds = CGRectMake( 0, 0, twit.size.width, twit.size.height );
        [twitterBtn setImage:twit forState:UIControlStateNormal];
        [twitterBtn addTarget:self action:@selector(twitterSubmit)
          forControlEvents:UIControlEventTouchDown];
        twitterCaltrain = [[UIBarButtonItem alloc] initWithCustomView:twitterBtn];
        barArray = [NSArray arrayWithObjects: feedback,map, nil];
        
        self.navigationItem.rightBarButtonItems = barArray;
               
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
//        [[self tableView] setRowHeight:60];
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

    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
    [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:14.0]];
    
    NSString *titleText;
    NSString *subTitle;
    if ([indexPath row] == 0) { // if first row, put in start point
        titleText = [NSString stringWithFormat:@"Start at %@", [[itinerary from] name]];
    }
    else if ([indexPath row] == [[itinerary sortedLegs] count] + 1) { // if last row, put in end point
        titleText = [NSString stringWithFormat:@"End at %@", [[itinerary to] name]];
    }
    else {  // otherwise, it is one of the legs
       
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:([indexPath row]-1)];
        titleText = [leg directionsTitleText];
        subTitle = [leg directionsDetailText];
        if ( [leg isTrain]) {
            barArray = [NSArray arrayWithObjects: feedback,twitterCaltrain,map, nil];
             self.navigationItem.rightBarButtonItems = barArray;
        }
        
        /*
         DE4 Fix - Apprika Systems
         Edited by Sitanshu Joshi.
         */
        
//        if ([subTitle length] > 70) {
//            NSString * add1;
//            NSString * add2;
//            
//            NSLog(@"more %@",subTitle);
//            NSArray *firstSplit = [subTitle componentsSeparatedByString:@"\n"];
//            NSLog(@"%@",firstSplit);
//            for(int i=0;i<[firstSplit count];i++){
//                NSString *str=[firstSplit objectAtIndex:i];               
//                if ([str length] > 37) {
//                    str = [str substringToIndex:37];
//                    if(i==0){
//                        add1 = [str stringByAppendingString:@"...\n"];
//                        NSLog(@"Saperate %@",str);
//                    }else if(i==1){
//                        add2 = [str stringByAppendingString:@"..."];
//                        NSLog(@"Saperate %@",str);
//                    }
//                } else {
//                    if(i==0){
//                        add1 = [str stringByAppendingString:@"\n"];
//                    } else if(i==1){
//                        add2 = [str stringByAppendingString:@" "];
//                    }
//                }                          
//            }
//            subTitle = [add1 stringByAppendingString:add2];  
//        }
    }
        
    [[cell textLabel] setText:titleText];
    [[cell detailTextLabel] setLineBreakMode:UILineBreakModeWordWrap];
    [[cell detailTextLabel] setNumberOfLines:0];
    [[cell detailTextLabel] setText:subTitle];
    
    
//        if (subTitle && [subTitle length] > 40) {
//        [[cell detailTextLabel] sizeToFit];
//    }
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    NSString   *titleText,*patchString;
    CGSize size;
    if ([indexPath row] == 0) { // if first row, put in start point
        titleText = [NSString stringWithFormat:@"Start at %@", [[itinerary from] name]];
        size = [titleText 
                sizeWithFont:[UIFont systemFontOfSize:14] 
                constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
    }
    else if ([indexPath row] == [[itinerary sortedLegs] count] + 1) { // if last row, put in end point
        titleText = [NSString stringWithFormat:@"End at %@", [[itinerary to] name]];
        size = [titleText 
                sizeWithFont:[UIFont systemFontOfSize:14] 
                constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
    }
    else {
    
    Leg *leg = [[itinerary sortedLegs] objectAtIndex:([indexPath row]-1)];
    titleText= [leg directionsDetailText];
   
    // DE:48  Wrapping issue while directionsTitleText & directionsDetailText lenght is small.
        
        if ([[leg directionsTitleText] length] < 20) {
           patchString  = [[leg directionsTitleText] stringByAppendingString:@"adding Patch string for UI" ];
            size = [[titleText stringByAppendingString:patchString] 
                    sizeWithFont:[UIFont systemFontOfSize:14] 
                    constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
        } else {
            size = [[titleText stringByAppendingString:[leg directionsTitleText]] 
                    sizeWithFont:[UIFont systemFontOfSize:14] 
                    constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)];
        }
        
    
    }
    return size.height + 7;
}


// If selected, show the LegMapViewController
- (void) tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Initialize the LegMapView Controller
    LegMapViewController *legMapVC = [[LegMapViewController alloc] initWithNibName:nil bundle:nil];
    // Initialize the leg VC with the full itinerary and the particular leg object chosen
    [legMapVC setItinerary:itinerary itineraryNumber:[indexPath row]];
    [[self navigationController] pushViewController:legMapVC animated:YES];
}


-(void)twitterSubmit
{
    @try {
        NSLog(@"twiit");
        TwitterSearch *twitter_search = [[TwitterSearch alloc] initWithNibName:@"TwitterSearch" bundle:nil];
        [[self navigationController] pushViewController:twitter_search animated:YES];
        [twitter_search loadRequest:CALTRAIN_TWITTER_URL];
    }
    @catch (NSException *exception) {
        NSLog(@" twitter print : %@", exception);
    } 
}


-(void)feedBackSubmit
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:@"2" forKey:@"source"];
    [prefs setObject:[itinerary itinId] forKey:@"uniqueid"];
    
    FeedBackForm *feedbackvc = [[FeedBackForm alloc] initWithNibName:@"FeedBackForm" bundle:nil];   
    [[self navigationController] pushViewController:feedbackvc animated:YES];
    
}


- (void)mapOverView
{
    RootMap *l = [[RootMap alloc] initWithNibName:nil bundle:nil];
    [l setItinerarys:itinerary itineraryNumber:2];
    [[self navigationController] pushViewController:l animated:YES];
}
@end
