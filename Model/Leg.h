//
//  Leg.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import "PlanPlace.h"
#import "enums.h"
#import "PolylineEncodedString.h"

typedef enum {
    FIRST_LEG,
    MIDDLE_LEG,
    LAST_LEG
} LegPositionEnum;

@class OTPItinerary, PlanPlace, Step;

@interface Leg : NSManagedObject 

// See this URL for documentation on the elements: http://www.opentripplanner.org/apidoc/data_ns0.html#leg
// This URL has example data http://groups.google.com/group/opentripplanner-dev/msg/4535900a5d18e61f?
@property (nonatomic, retain) NSString * agencyId;
@property (nonatomic, retain) NSString * legId;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * headSign;
@property (nonatomic, retain) NSString * mode;
@property (nonatomic, retain) NSString * route;
@property (nonatomic, retain) NSString * routeLongName;
@property (nonatomic, retain) NSString * routeShortName;
@property (nonatomic, retain) PlanPlace *from;
@property (nonatomic, retain) OTPItinerary *itinerary;
@property (nonatomic, retain) NSSet *steps;
@property (nonatomic, retain) NSString * tripId;
@property (nonatomic, retain) NSString * agencyName;
@property (nonatomic, retain) PlanPlace *to;
@property (nonatomic, strong) NSArray *sortedSteps;
@property (nonatomic, strong) PolylineEncodedString *polylineEncodedString;

- (NSArray *)sortedSteps;

// Compare Two Legs
// If Leg is walk then compatr TO&From location lat/Lng and distance.
// If leg is not walk then compare routeShortname if not nill else compare routeLongName then compate TO&From Location Lat/Lng and agencyname.
// If legs are equal then return yes otherwise return no
- (BOOL) isEquivalentLegAs:(Leg *)leg;

@end

@interface Leg (CoreDataGeneratedAccessors)

- (void)addStepsObject:(Step *)value;
- (void)removeStepsObject:(Step *)value;
- (void)addSteps:(NSSet *)values;
- (void)removeSteps:(NSSet *)values;
@end
