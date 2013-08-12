//
//  BikeStepsViewController.m
//  Nimbler SF
//
//  Created by macmini on 04/08/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "BikeStepsViewController.h"

@implementation BikeStepsViewController

@synthesize bikeStepsTableView;
@synthesize handleControl;
@synthesize mapView;
@synthesize legMapVC;
@synthesize btnBackItem;
@synthesize btnForwardItem;
@synthesize forwardButton;
@synthesize backButton;
@synthesize mapHeight;
@synthesize tableHeight;
@synthesize steps;
@synthesize selectedRowIndex;
@synthesize annotationArray;
@synthesize currentPolyLine;

#define MAXIMUM_SCROLL_POINT 360
#define MAXIMUM_SCROLL_POINT_4_INCH 425
#define MINIMUM_SCROLL_POINT 15
#define IPHONE_SCREEN_WIDTH 320
#define MAIN_TABLE_Y_BUFFER 30
#define LINE_WIDTH  5
#define ALPHA_LIGHT 0.7
#define ALPHA_MEDIUM 0.8

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    @try {
        if (self) {
            if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
                [self.navigationController.navigationBar setBackgroundImage:NAVIGATION_BAR_IMAGE forBarMetrics:UIBarMetricsDefault];
            }
            else {
                [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:NAVIGATION_BAR_IMAGE] aboveSubview:self.navigationController.navigationBar];
            }
            
            UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
            [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
            lblNavigationTitle.text=BIKE_STEPS_VIEW_TITLE;
            lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
            [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
            lblNavigationTitle.backgroundColor =[UIColor clearColor];
            lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
            self.navigationItem.titleView=lblNavigationTitle;
            [self.view bringSubviewToFront:handleControl];
            
            UIImage* backImage = [UIImage imageNamed:@"img_backSelect.png"];
            UIImage* forwardImage = [UIImage imageNamed:@"img_forwardSelect.png"];
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0,
                                                                    (forwardImage.size.width+backImage.size.width),forwardImage.size.height)];
            // Set up the forward and back button
            btnBackItem = [[UIButton alloc] initWithFrame:CGRectMake(0,0,backImage.size.width,backImage.size.height)];
            [btnBackItem addTarget:self action:@selector(navigateBack:) forControlEvents:UIControlEventTouchUpInside];
            [btnBackItem setBackgroundImage:backImage forState:UIControlStateNormal];
            
            // Accessibility Label For UI Automation.
            btnBackItem.accessibilityLabel = BACKWARD_BUTTON;
            
            btnForwardItem = [[UIButton alloc] initWithFrame:CGRectMake(backImage.size.width,0,
                                                                        forwardImage.size.width,
                                                                        forwardImage.size.height)];
            [btnForwardItem addTarget:self action:@selector(navigateForward:) forControlEvents:UIControlEventTouchUpInside];
            [btnForwardItem setBackgroundImage:forwardImage forState:UIControlStateNormal];
            // Accessibility Label For UI Automation.
            btnForwardItem.accessibilityLabel =FORWARD_BUTTON;
            
            
            [view addSubview:btnBackItem];
            [view addSubview:btnForwardItem];
            backButton = [[UIBarButtonItem alloc] initWithCustomView:view];
            backButton.accessibilityLabel = BACK_BUTTON;
            self.navigationItem.rightBarButtonItem = backButton;

            
            // Preload the image files for table icons and put into a dictionary
        }
        mapHeight = mapView.frame.size.height;
        tableHeight = bikeStepsTableView.frame.size.height;
    }
    @catch (NSException *exception) {
        logException(@"RouteDetailsViewController->initWithNibName", @"", exception);
    }
    return self;
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


- (void)viewDidLoad{
    [super viewDidLoad];
    bikeStepsTableView.delegate = self;
    bikeStepsTableView.dataSource = self;
    
    UIImage* btnImage = [UIImage imageNamed:@"img_itineraryNavigation.png"];
   UIButton *btnGoToItinerary = [[UIButton alloc] initWithFrame:CGRectMake(0,0,76, 34)];
    [btnGoToItinerary addTarget:self action:@selector(popOutToItinerary) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToItinerary setBackgroundImage:btnImage forState:UIControlStateNormal];
    
    // Accessibility Label For UI Automation.
    btnGoToItinerary.accessibilityLabel =GO_TO_ITINERARY_BUTTON;
    
    UIBarButtonItem *backToItinerary = [[UIBarButtonItem alloc] initWithCustomView:btnGoToItinerary];
    self.navigationItem.leftBarButtonItem = backToItinerary;
}

- (NSString *)encodeStringWithCoordinates:(NSArray *)coordinates{
    NSMutableString *encodedString = [NSMutableString string];
    int val = 0;
    int value = 0;
    CLLocationCoordinate2D prevCoordinate = CLLocationCoordinate2DMake(0, 0);
    for (NSValue *coordinateValue in coordinates) {
        CLLocationCoordinate2D coordinate = [coordinateValue MKCoordinateValue];
        // Encode latitude
        val = round((coordinate.latitude - prevCoordinate.latitude) * 1e5);
        val = (val < 0) ? ~(val<<1) : (val <<1);
        while (val >= 0x20) {
            int value = (0x20|(val & 31)) + 63;
            [encodedString appendFormat:@"%c", value];
            val >>= 5;
        }
        [encodedString appendFormat:@"%c", val + 63];
        // Encode longitude
        val = round((coordinate.longitude - prevCoordinate.longitude) * 1e5);
        val = (val < 0) ? ~(val<<1) : (val <<1);
        while (val >= 0x20) {
            value = (0x20|(val & 31)) + 63;
            [encodedString appendFormat:@"%c", value];
            val >>= 5;
        }
        [encodedString appendFormat:@"%c", val + 63];
        prevCoordinate = coordinate;
    }
    return encodedString;
}

- (void)generatePolyLineArray{
    NSMutableArray *coordinateArray = [[NSMutableArray alloc] init];
    NSMutableArray *annotations = [[NSMutableArray alloc] init];
    for(int i=0;i<[steps count];i++){
        Step *step = [steps objectAtIndex:i];
        CLLocationCoordinate2D coordinate =  CLLocationCoordinate2DMake([step.startLat doubleValue],[step.startLng doubleValue]);
        NSValue *value = [NSValue valueWithMKCoordinate:coordinate];
        [coordinateArray addObject:value];
        
        float langcoord = [step.startLat floatValue];
        float longcoord = [step.startLng floatValue];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(langcoord, longcoord);
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        [point setCoordinate:coord];
        [point setTitle:[NSString stringWithFormat:@"%@",step.streetName]];
        if(step.relativeDirection){
            [point setSubtitle:[NSString stringWithFormat:@"%@ -> %@",step.absoluteDirection,step.relativeDirection]];
        }
        else{
            [point setSubtitle:step.absoluteDirection];
        }

        [annotations addObject:point];
        [mapView addAnnotation:point];
    }
    annotationArray = annotations;
    NSString *str = [self encodeStringWithCoordinates:coordinateArray];
    PolylineEncodedString *encodedString = [[PolylineEncodedString alloc] initWithEncodedString:str];
    MKPolyline *polyLine = [encodedString polyline];
    [mapView addOverlay:polyLine];
    
    Step *step = [steps objectAtIndex:selectedRowIndex];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([step.startLat doubleValue],[step.startLng doubleValue]);
    MKCoordinateRegion mpRegion = MKCoordinateRegionMakeWithDistance(coordinate, 400, 400);
    [mapView setRegion:mpRegion animated:NO];
}
- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    mapView.layer.borderWidth = 3.0;
    mapView.layer.borderColor = [UIColor whiteColor].CGColor;
    [mapView setDelegate:self];
    
    selectedRowIndex = 0;
    [self generatePolyLineArray];
    [mapView setNeedsDisplay];
    if(selectedRowIndex == 0){
        [btnBackItem setEnabled:FALSE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnBackItem setEnabled:TRUE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backSelect.png"] forState:UIControlStateNormal];
    }
    if(selectedRowIndex == [steps count] - 1){
        [btnForwardItem setEnabled:FALSE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnForwardItem setEnabled:TRUE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardSelect.png"] forState:UIControlStateNormal];
    }
    
    Step *step = [steps objectAtIndex:selectedRowIndex];
    CLLocationCoordinate2D curCoordinate = CLLocationCoordinate2DMake([step.startLat doubleValue],[step.startLng doubleValue]);
    if([steps count] > selectedRowIndex + 1){
        Step *nextStep = [steps objectAtIndex:selectedRowIndex+1];
        CLLocationCoordinate2D nextCoordinate = CLLocationCoordinate2DMake([nextStep.startLat doubleValue],[nextStep.startLng doubleValue]);
        [self createOverlayForSelectedStep:curCoordinate NextCoordinate:nextCoordinate];
    }
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) imageMoved:(id) sender withEvent:(UIEvent *) event{
    CGPoint point = [[[event allTouches] anyObject] locationInView:self.view];
    int maxHeight;
    if([[UIScreen mainScreen] bounds].size.height == IPHONE5HEIGHT){
        maxHeight = MAXIMUM_SCROLL_POINT_4_INCH;
    }
    else{
        maxHeight = MAXIMUM_SCROLL_POINT;
    }
    if(point.y <= maxHeight && point.y >=MINIMUM_SCROLL_POINT){
        [handleControl setFrame:CGRectMake(handleControl.frame.origin.x, point.y, IPHONE_SCREEN_WIDTH, handleControl.frame.size.height)];
        [mapView setFrame:CGRectMake(mapView.frame.origin.x,mapView.frame.origin.y,mapView.frame.size.width,mapView.frame.size.height+(point.y-mapHeight-5))];
        [bikeStepsTableView setFrame:CGRectMake(bikeStepsTableView.frame.origin.x,handleControl.frame.origin.y+handleControl.frame.size.height,IPHONE_SCREEN_WIDTH,self.view.frame.size.height-(handleControl.frame.size.height+mapView.frame.size.height))];
        mapHeight = mapView.frame.size.height;
        tableHeight = bikeStepsTableView.frame.size.height;
    }
    [self.view bringSubviewToFront:handleControl];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [steps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%d",indexPath.row]];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[NSString stringWithFormat:@"%d",indexPath.row]];
    }
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:STANDARD_FONT_SIZE]];
    [[cell textLabel] setLineBreakMode:UILineBreakModeWordWrap];
    [[cell textLabel] setNumberOfLines:2];
    [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:STANDARD_FONT_SIZE]];
    [[cell detailTextLabel] setLineBreakMode:UILineBreakModeWordWrap];
    [[cell detailTextLabel] setNumberOfLines:0];
    
    if(indexPath.row == 0){
        Step *step = [steps objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"Bike %@ on %@ - %@",step.absoluteDirection,step.streetName,distanceStringInMilesFeet([step.distance doubleValue])];
    }
    else{
        Step *step = [steps objectAtIndex:indexPath.row];
        NSString *direction = step.relativeDirection;
        if(!direction){
            direction = step.absoluteDirection;
        }
        cell.textLabel.text = [NSString stringWithFormat:@"%@ on %@ - %@",direction,step.streetName,distanceStringInMilesFeet([step.distance doubleValue])];
    }
    if(indexPath.row == selectedRowIndex){
       [cell.textLabel setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]]; 
    }
    else{
       [cell.textLabel setTextColor:[UIColor GRAY_FONT_COLOR]];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (IBAction)navigateBack:(id)sender {
    
    Step *step = [steps objectAtIndex:selectedRowIndex];
    CLLocationCoordinate2D curCoordinate = CLLocationCoordinate2DMake([step.startLat doubleValue],[step.startLng doubleValue]);
    if([steps count] > selectedRowIndex - 1){
        Step *nextStep = [steps objectAtIndex:selectedRowIndex-1];
        CLLocationCoordinate2D nextCoordinate = CLLocationCoordinate2DMake([nextStep.startLat doubleValue],[nextStep.startLng doubleValue]);
        [self createOverlayForSelectedStep:curCoordinate NextCoordinate:nextCoordinate];
    }
    
    if(selectedRowIndex > 0){
        selectedRowIndex = selectedRowIndex - 1;
        [bikeStepsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRowIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [bikeStepsTableView reloadData];
        Step *step = [steps objectAtIndex:selectedRowIndex];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([step.startLat doubleValue],[step.startLng doubleValue]);
        [self refreshOverlay:coordinate];
    }
    if(selectedRowIndex == 0){
        [btnBackItem setEnabled:FALSE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnBackItem setEnabled:TRUE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backSelect.png"] forState:UIControlStateNormal];
    }
    if(selectedRowIndex == [steps count] - 1){
        [btnForwardItem setEnabled:FALSE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnForwardItem setEnabled:TRUE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardSelect.png"] forState:UIControlStateNormal];
    }
}

// Callback for when user presses the navigate forward button on the right navbar
- (IBAction)navigateForward:(id)sender {
    if(selectedRowIndex < [steps count]-1){
        selectedRowIndex = selectedRowIndex + 1;
        [bikeStepsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRowIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
         [bikeStepsTableView reloadData];
        Step *step = [steps objectAtIndex:selectedRowIndex];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([step.startLat doubleValue],[step.startLng doubleValue]);
        [self refreshOverlay:coordinate];
    }
    if(selectedRowIndex == 0){
        [btnBackItem setEnabled:FALSE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnBackItem setEnabled:TRUE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backSelect.png"] forState:UIControlStateNormal];
    }
    if(selectedRowIndex == [steps count] - 1){
        [btnForwardItem setEnabled:FALSE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnForwardItem setEnabled:TRUE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardSelect.png"] forState:UIControlStateNormal];
    }
    
    Step *step = [steps objectAtIndex:selectedRowIndex];
    CLLocationCoordinate2D curCoordinate = CLLocationCoordinate2DMake([step.startLat doubleValue],[step.startLng doubleValue]);
    if([steps count] > selectedRowIndex + 1){
        Step *nextStep = [steps objectAtIndex:selectedRowIndex+1];
        CLLocationCoordinate2D nextCoordinate = CLLocationCoordinate2DMake([nextStep.startLat doubleValue],[nextStep.startLng doubleValue]);
        [self createOverlayForSelectedStep:curCoordinate NextCoordinate:nextCoordinate];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
     selectedRowIndex = indexPath.row;
    [bikeStepsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [bikeStepsTableView reloadData];
    Step *step = [steps objectAtIndex:selectedRowIndex];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([step.startLat doubleValue],[step.startLng doubleValue]);
    [self refreshOverlay:coordinate];
    if(selectedRowIndex == 0){
        [btnBackItem setEnabled:FALSE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnBackItem setEnabled:TRUE];
        [btnBackItem setBackgroundImage:[UIImage imageNamed:@"img_backSelect.png"] forState:UIControlStateNormal];
    }
    if(selectedRowIndex == [steps count] - 1){
        [btnForwardItem setEnabled:FALSE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardUnSelect.png"] forState:UIControlStateNormal];
    } else {
        [btnForwardItem setEnabled:TRUE];
        [btnForwardItem setBackgroundImage:[UIImage imageNamed:@"img_forwardSelect.png"] forState:UIControlStateNormal];
    }
    
    CLLocationCoordinate2D curCoordinate = CLLocationCoordinate2DMake([step.startLat doubleValue],[step.startLng doubleValue]);
    if([steps count] > selectedRowIndex + 1){
        Step *nextStep = [steps objectAtIndex:selectedRowIndex+1];
        CLLocationCoordinate2D nextCoordinate = CLLocationCoordinate2DMake([nextStep.startLat doubleValue],[nextStep.startLng doubleValue]);
        [self createOverlayForSelectedStep:curCoordinate NextCoordinate:nextCoordinate];
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    @try {
        if ([overlay isKindOfClass:[MKPolyline class]]) {
            MKPolylineView *aView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
            if([overlay isEqual:currentPolyLine]){
               aView.strokeColor = [[UIColor blackColor] colorWithAlphaComponent:ALPHA_MEDIUM];
            }
            else{
               aView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:ALPHA_MEDIUM]; 
            }
            aView.lineWidth = LINE_WIDTH;
            return aView;
        }
        return nil;
    }
    @catch (NSException *exception) {
        logException(@"LegMapViewController -> viewForOverlay", @"", exception);
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]){
        return nil;
    }
    // Handle point annotations
            MKPinAnnotationView* pinView = (MKPinAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"MyPinAnnotationView"];
            
            if (!pinView)
            {
                // If an existing pin view was not available, create one.
                pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:@"MyPinAnnotation"];
                pinView.animatesDrop = NO;
                pinView.canShowCallout = YES;
            }
            else
                pinView.annotation = annotation;
                pinView.pinColor = MKPinAnnotationColorRed;
            return pinView;
}

- (void) refreshOverlay:(CLLocationCoordinate2D)coordinate{
    MKCoordinateRegion mpRegion = MKCoordinateRegionMakeWithDistance(coordinate, 400, 400);
    [mapView setRegion:mpRegion animated:NO];
    [mapView setNeedsDisplay];
}


- (void) createOverlayForSelectedStep:(CLLocationCoordinate2D)curCoordinate NextCoordinate:(CLLocationCoordinate2D)nextCoordinate{
    if(currentPolyLine){
        [mapView removeOverlay:currentPolyLine];
    }
    NSValue *value1 = [NSValue valueWithMKCoordinate:curCoordinate];
    NSValue *value2 = [NSValue valueWithMKCoordinate:nextCoordinate];
    NSArray *coordinateArray = [NSArray arrayWithObjects:value1,value2, nil];
    NSString *str = [self encodeStringWithCoordinates:coordinateArray];
    PolylineEncodedString *encodedString = [[PolylineEncodedString alloc] initWithEncodedString:str];
    MKPolyline *polyLine = [encodedString polyline];
    currentPolyLine = polyLine;
    [mapView addOverlay:polyLine];
    MKCoordinateRegion mpRegion = MKCoordinateRegionMakeWithDistance(curCoordinate, 400, 400);
    [mapView setRegion:mpRegion animated:NO];
    [mapView setNeedsDisplay];
}
@end
