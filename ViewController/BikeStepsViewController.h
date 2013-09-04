//
//  BikeStepsViewController.h
//  Nimbler SF
//
//  Created by macmini on 04/08/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "LegMapViewController.h"
#import "UtilityFunctions.h"
#import "Step.h"

@interface BikeStepsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,MKMapViewDelegate>{
    UITableView *bikeStepsTableView;
    UIButton * handleControl;
    NSArray *annotationArray;
    MKPolyline *currentPolyLine;
    MKPointAnnotation *startPoint;
    
    float yPos;
}

@property (nonatomic, strong) IBOutlet  UITableView *bikeStepsTableView;
@property (nonatomic, strong) IBOutlet  UIButton * handleControl;
@property(nonatomic, strong)  IBOutlet MKMapView *mapView;
@property(nonatomic, strong) LegMapViewController* legMapVC;
@property(nonatomic, strong) UIButton *btnBackItem;
@property(nonatomic, strong) UIButton *btnForwardItem;
@property(nonatomic, strong) UIBarButtonItem *forwardButton;
@property(nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic) int mapHeight;
@property (nonatomic) int tableHeight;
@property (nonatomic, strong) NSArray *steps;
@property (nonatomic) int selectedRowIndex;
@property (nonatomic, strong) NSArray *annotationArray;
@property (nonatomic, strong) MKPolyline *currentPolyLine;
@property (nonatomic, strong) MKPointAnnotation *startPoint;
@property (nonatomic) float yPos;
 
- (IBAction) imageMoved:(id) sender withEvent:(UIEvent *) event;
- (void) refreshOverlay:(CLLocationCoordinate2D)coordinate;
- (void) createOverlayForSelectedStep:(CLLocationCoordinate2D)curCoordinate NextCoordinate:(CLLocationCoordinate2D)nextCoordinate;
@end
