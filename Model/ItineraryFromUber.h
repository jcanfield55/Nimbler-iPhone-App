//
//  ItineraryFromUber.h
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Itinerary.h"
#import "LegFromUber.h"

@interface ItineraryFromUber : Itinerary
// See https://developer.uber.com/v1/endpoints/ for explanation of the variables below from price & time estimates

// The following properties are derived from the LegFromUber object which is the best to show
@property (nonatomic, strong, readonly) NSString *uberPriceEstimate;
@property (nonatomic, strong, readonly) NSNumber *uberLowEstimate;
@property (nonatomic, strong, readonly) NSNumber *uberHighEstimate;
@property (nonatomic, strong, readonly) NSNumber *uberSurgeMultiplier;
@property (nonatomic, strong, readonly) NSNumber *uberTimeEstimateSeconds;
@property (nonatomic, strong, readonly) NSArray *uberSortedLegs;

-(int)uberTimeEstimateMinutes;

@end
