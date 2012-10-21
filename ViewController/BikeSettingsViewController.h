//
//  BikeSettingsViewController.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 10/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "enums.h"



@interface BikeSettingsViewController : UIViewController


@property(nonatomic, strong) IBOutlet UISegmentedControl *modeSelector;
@property(nonatomic, strong) IBOutlet UISlider *quickVsHillsSlider;
@property(nonatomic, strong) IBOutlet UISlider *quickVsBikeFriendlySlider;
@property(nonatomic, strong) IBOutlet UISlider *maxBikeDistanceSlider;
@property(nonatomic, readonly) float bikeTriangleQuick;
@property(nonatomic, readonly) float bikeTriangleFlat;
@property(nonatomic, readonly) float bikeTriangleBikeFriendly;

@property(nonatomic) float maxBikeDistance;

@property(nonatomic) TransitModeChoice transitMode;

-(IBAction)sliderQuickVsHillsChanged:(id)sender;
-(IBAction)sliderQuickVsBikeFriendlyChanged:(id)sender;
-(IBAction)sliderMaxBikeDistanceChanged:(id)sender;
-(IBAction)modeSelectorChanged:(id)sender;
@end
