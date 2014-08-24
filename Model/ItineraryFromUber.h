//
//  ItineraryFromUber.h
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Itinerary.h"

@interface ItineraryFromUber : Itinerary
// See https://developer.uber.com/v1/endpoints/ for explanation of the variables below from price & time estimates
@property (nonatomic, strong) NSString *uberProductID;
@property (nonatomic, strong) NSString *uberDisplayName;
@property (nonatomic, strong) NSString *uberPriceEstimate;
@property (nonatomic) int uberLowEstimate;
@property (nonatomic) int uberHighEstimate;
@property (nonatomic) float uberSurgeMultiplier;
@property (nonatomic) int uberTimeEstimateSeconds;


@end
