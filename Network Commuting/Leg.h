//
//  Leg.h
//  Network Commuting
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import "PlanPlace.h"
#import "enums.h"

@class Itinerary, PlanPlace, Step;

@interface Leg : NSManagedObject

// See this URL for documentation on the elements: http://www.opentripplanner.org/apidoc/data_ns0.html#leg
// This URL has example data http://groups.google.com/group/opentripplanner-dev/msg/4535900a5d18e61f?
@property (nonatomic, retain) NSString * agencyId;
@property (nonatomic, retain) NSNumber * bogusNonTransitLeg;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSString * headSign;
@property (nonatomic, retain) NSNumber * interlineWithPreviousLeg;
@property (nonatomic, retain) NSNumber * legGeometryLength;
@property (nonatomic, retain) NSString * legGeometryPoints;
@property (nonatomic, retain) NSString * mode;
@property (nonatomic, retain) NSString * route;
@property (nonatomic, retain) NSString * routeLongName;
@property (nonatomic, retain) NSString * routeShortName;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSString * tripShortName;
@property (nonatomic, retain) PlanPlace *from;
@property (nonatomic, retain) Itinerary *itinerary;
@property (nonatomic, retain) NSSet *steps;
@property (nonatomic, retain) PlanPlace *to;
@property (nonatomic, strong) NSArray *sortedSteps;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType;
- (NSArray *)sortedSteps;
- (NSString *)ncDescription;

@end

@interface Leg (CoreDataGeneratedAccessors)

- (void)addStepsObject:(Step *)value;
- (void)removeStepsObject:(Step *)value;
- (void)addSteps:(NSSet *)values;
- (void)removeSteps:(NSSet *)values;
@end
