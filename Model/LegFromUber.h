//
//  LegFromUber.h
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Leg.h"

@interface LegFromUber : Leg
// See https://developer.uber.com/v1/endpoints/ for explanation of the variables below from price & time estimates
@property (nonatomic, strong) NSString *uberProductID;
@property (nonatomic, strong) NSString *uberDisplayName;
@property (nonatomic, strong) NSString *uberPriceEstimate;
@property (nonatomic, strong) NSNumber *uberLowEstimate;
@property (nonatomic, strong) NSNumber *uberHighEstimate;
@property (nonatomic, strong) NSNumber *uberSurgeMultiplier;
@property (nonatomic, strong) NSNumber *uberTimeEstimateSeconds;
@property (nonatomic) int displaySequenceNumber;   // For ordering the display of the Uber legs
#define DISPLAY_SEQUENCE_NUMBER_KEY @"displaySequenceNumber"

-(int)uberTimeEstimateMinutes;
@end
