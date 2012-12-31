//
//  Itinerary.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Itinerary.h"
#import "Leg.h"
#import "Plan.h"
#import "UtilityFunctions.h"
#import "nc_AppDelegate.h"

@interface Itinerary()
{
    // Internal variables
    NSArray* legDescTitleSortedArr;
    NSArray* legDescSubtitleSortedArr;
    NSArray* legDescToLegMapArray;
}

//Internal methods
- (void)makeLegDescriptionSortedArrays;  

@end


@implementation Itinerary
@dynamic duration;
@dynamic endTime;
@dynamic endTimeOnly;
@dynamic itineraryCreationDate;
@dynamic startTime;
@dynamic startTimeOnly;
@dynamic legs;
@dynamic plan;
@dynamic itinId;
@dynamic planRequestChunks;
@synthesize sortedLegs;
@synthesize itinArrivalFlag;

// Compare Two Itineraries
// This match itinerary like leg by leg if all match the return yes otherwise return no.
- (BOOL) isEquivalentItinerariAs:(Itinerary *)itinerary{
    NSArray *arrItinerary1 = [self sortedLegs];
    NSArray *arrItinerary2 = [itinerary sortedLegs];
    if([arrItinerary1 count] == [arrItinerary2 count]){
        for(int i=0;i<[arrItinerary1 count];i++){
            Leg *leg1 = [arrItinerary1 objectAtIndex:i];
            Leg *leg2 = [arrItinerary2 objectAtIndex:i];
            if(![leg1 isEquivalentLegAs:leg2]){
                return NO;
            }
        }
        return YES;
    }
    else{
        return NO;
    }
}

@end
