//
//  UberDetailViewController.m
//  Nimbler SF
//
//  Created by John Canfield on 9/12/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import "UberDetailViewController.h"
#import "UtilityFunctions.h"
#import "Logging.h"
#import "UberMgr.h"
#import "FeedBackForm.h"

@interface UberDetailViewController ()

@end

@implementation UberDetailViewController

@synthesize mainTable;
@synthesize uberItin;
@synthesize plan;
@synthesize btnFeedBack;
@synthesize btnGoToItinerary;

UIImage* imageDetailDisclosure;

- (void)viewDidLoad {
    [super viewDidLoad];

    if([[[UIDevice currentDevice] systemVersion] intValue] >= 7){
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.mainTable.delegate = self;
    self.mainTable.dataSource = self;
    
    // Accessibility Label For UI Automation.
    self.mainTable.accessibilityLabel = UBER_DETAILS_TABLE_VIEW;    
    
    UIImage* btnImage = [UIImage imageNamed:@"img_itineraryNavigation.png"];
    btnGoToItinerary = [[UIButton alloc] initWithFrame:CGRectMake(0,0,76, 34)];
    [btnGoToItinerary addTarget:self action:@selector(popOutToItinerary) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToItinerary setBackgroundImage:btnImage forState:UIControlStateNormal];
    
    // Accessibility Label For UI Automation.
    btnGoToItinerary.accessibilityLabel =GO_TO_ITINERARY_BUTTON;
    
    UIBarButtonItem *backToItinerary = [[UIBarButtonItem alloc] initWithCustomView:btnGoToItinerary];
    self.navigationItem.leftBarButtonItem = backToItinerary;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
        [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
        lblNavigationTitle.text=UBER_DETAILS_VIEW_TITLE;
        lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
        [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
        lblNavigationTitle.backgroundColor =[UIColor clearColor];
        lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
        self.navigationItem.titleView=lblNavigationTitle;
        
        imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    logEvent(FLURRY_UBER_DETAILS_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
    
    mainTable.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"img_line.png"]];
    [mainTable reloadData];
}

//
// TableView datasource methods
//

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return uberItin.legs.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UberDetailViewCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"UberDetailViewCell"];
        [cell.imageView setImage:nil];
        UIImageView *imgViewDetailDisclosure = [[UIImageView alloc] initWithImage:imageDetailDisclosure];
        [cell setAccessoryView:imgViewDetailDisclosure];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.numberOfLines = 2;
        [cell setBackgroundColor:[UIColor clearColor]];
        
        [[cell textLabel] setFont:[UIFont MEDIUM_BOLD_FONT]];
        cell.textLabel.textColor = [UIColor NIMBLER_RED_FONT_COLOR];
        [[cell detailTextLabel] setFont:[UIFont MEDIUM_FONT]];
        cell.detailTextLabel.textColor = [UIColor GRAY_FONT_COLOR];
    }
    
    LegFromUber* uberLeg = [uberItin.uberSortedLegs objectAtIndex:[indexPath row]];  // Get the uberLeg for this cell
    [[cell textLabel] setText:uberLeg.uberDisplayName];
    
    NSMutableString* pricelabel = [NSMutableString stringWithCapacity:40];
    if (uberLeg.uberTimeEstimateSeconds) {
        [pricelabel appendFormat:@"In %d min", uberLeg.uberTimeEstimateMinutes];
    }
    if (uberLeg.uberPriceEstimate) {
        [pricelabel appendFormat:@" \u2013 %@",uberLeg.uberPriceEstimate];
    }
    if (uberLeg.uberSurgeMultiplier.floatValue > 1.00000001) {
        [pricelabel appendString:@" (surge)"];
    }
    [[cell detailTextLabel] setText:pricelabel];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LegFromUber* uberLeg = [uberItin.uberSortedLegs objectAtIndex:[indexPath row]];  // Get the uberLeg for this row
    [UberMgr callUberWith:uberLeg forPlan:plan];  // Call Uber with URL using uberLeg and plan information
}


//DE:21 dynamic cell height
#pragma mark - UIDynamic cell heght methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    LegFromUber* uberLeg = [uberItin.uberSortedLegs objectAtIndex:[indexPath row]];  // Get the uberLeg for this cell
    NSString *titleText = uberLeg.uberDisplayName;
    
    NSMutableString* pricelabel = [NSMutableString stringWithCapacity:40];
    if (uberLeg.uberTimeEstimateSeconds) {
        [pricelabel appendFormat:@"In %d min  ", uberLeg.uberTimeEstimateMinutes];
    }
    if (uberLeg.uberPriceEstimate) {
        [pricelabel appendFormat:@"  %@",uberLeg.uberPriceEstimate];
    }
    if (uberLeg.uberSurgeMultiplier.floatValue > 1.00000001) {
        [pricelabel appendString:@" (surge)"];
    }

    CGSize titleSize = [titleText sizeWithFont:[UIFont MEDIUM_BOLD_FONT]
                             constrainedToSize:CGSizeMake(ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH, CGFLOAT_MAX)];
    
    CGSize subtitleSize = [pricelabel sizeWithFont:[UIFont MEDIUM_FONT]
                                   constrainedToSize:CGSizeMake(ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH, CGFLOAT_MAX)];
    
    CGFloat height = titleSize.height + subtitleSize.height + ROUTE_OPTIONS_VARIABLE_TABLE_CELL_HEIGHT_BUFFER;
    if (height < ROUTE_OPTIONS_TABLE_CELL_MINIMUM_HEIGHT) { // Set a minumum row height
        height = ROUTE_OPTIONS_TABLE_CELL_MINIMUM_HEIGHT;
    }
    
    return height;
}

-(void)popOutToItinerary{

    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setRemovedOnCompletion:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
    [[self navigationController] popViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)feedBackClicked:(id)sender{
    FeedBackForm *feedBackForm;
    feedBackForm = [[FeedBackForm alloc] initWithNibName:@"FeedBackFormPopUp" bundle:nil];
    feedBackForm.isViewPresented = true;
    [self presentViewController:feedBackForm animated:YES completion:nil];
}

@end
