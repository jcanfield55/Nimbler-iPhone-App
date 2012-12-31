//
//  Leg.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Leg.h"
#import "Itinerary.h"
#import "Step.h"
#import "UtilityFunctions.h"
#import "KeyObjectStore.h"


@implementation Leg

@dynamic agencyId;
@dynamic distance;
@dynamic duration;
@dynamic headSign;
@dynamic mode;
@dynamic route;
@dynamic routeLongName;
@dynamic routeShortName;
@dynamic from;
@dynamic itinerary;
@dynamic steps;
@dynamic to;
@dynamic legId;
@dynamic tripId;
@dynamic agencyName;
@synthesize sortedSteps;
@synthesize polylineEncodedString;

// Compare Two Legs
// If Leg is walk then compatr TO&From location lat/Lng and distance.
// If leg is not walk then compare routeShortname if not nill else compare routeLongName then compate TO&From Location Lat/Lng and agencyname.
// If legs are equal then return yes otherwise return no
- (BOOL) isEquivalentLegAs:(Leg *)leg{
   if([self.mode isEqualToString:@"WALK"] && [leg.mode isEqualToString:@"WALK"]){
        if([self.to.lat doubleValue] != [leg.to.lat doubleValue] || [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] !=[leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue] || [self.distance doubleValue] != [leg.distance doubleValue]){
            return NO;
        }
        return YES;
    }
    else if([self.mode isEqualToString:leg.mode]){
        if(!self.routeShortName || !leg.routeShortName){
            if(![self.routeLongName isEqualToString:leg.routeLongName] || ![self.agencyName isEqualToString:leg.agencyName] || [self.to.lat doubleValue] != [leg.to.lat doubleValue] ||  [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] != [leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue]){
                return NO;
            }
        }
        else if(![self.routeShortName isEqualToString:leg.routeShortName] || ![self.agencyName isEqualToString:leg.agencyName] || [self.to.lat doubleValue] != [leg.to.lat doubleValue] ||  [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] != [leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue]){
            return NO;
        }
        return YES;
    }
    else{
        return NO;
    }
}

@end
