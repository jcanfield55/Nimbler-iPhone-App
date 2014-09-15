//
//  ItineraryFromUber.m
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import "ItineraryFromUber.h"
#import "LegFromUber.h"

@interface ItineraryFromUber()
{
    // Variables for internal use
    LegFromUber *bestLegToShow;  // Internal variable containing the best leg's data to summarize in the itinerary's uber properties (typically the least expensive)
}
@end

@implementation ItineraryFromUber

@synthesize uberPriceEstimate;
@synthesize uberLowEstimate;
@synthesize uberHighEstimate;
@synthesize uberSurgeMultiplier;
@synthesize uberTimeEstimateSeconds;
@synthesize uberSortedLegs;

NSSortDescriptor *sortDescriptor;

-(LegFromUber *)getBestLegToShow {
    if (!bestLegToShow) {
        int lowestPrice = INT_MAX;
        for (Leg *leg in self.legs) {
            LegFromUber *uLeg = (LegFromUber *)leg;
            if (uLeg.uberLowEstimate && uLeg.uberLowEstimate.intValue < lowestPrice) {
                lowestPrice = uLeg.uberLowEstimate.intValue;
                bestLegToShow = uLeg;
            }
        }
    }
    return bestLegToShow;
}

-(NSString *)uberPriceEstimate {
    return self.getBestLegToShow.uberPriceEstimate;
}
-(NSNumber *)uberLowEstimate {
    return self.getBestLegToShow.uberLowEstimate;
}
-(NSNumber *)uberHighEstimate {
    return self.getBestLegToShow.uberHighEstimate;
}
-(NSNumber *)uberSurgeMultiplier {
    return self.getBestLegToShow.uberSurgeMultiplier;
}
-(NSNumber *)uberTimeEstimateSeconds {
    return self.getBestLegToShow.uberTimeEstimateSeconds;
}

-(NSArray *)uberSortedLegs {
    if (!uberSortedLegs) {
        if (!sortDescriptor) {
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:DISPLAY_SEQUENCE_NUMBER_KEY
                                                           ascending:TRUE];
        }
        uberSortedLegs = [self.legs sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    }
    return uberSortedLegs;
}

-(int)uberTimeEstimateMinutes
{
    int minutes = ceil(self.uberTimeEstimateSeconds.floatValue / 60.0);
    return minutes;
}

@end
