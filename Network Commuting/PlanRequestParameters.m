//
//  PlanRequestParameters.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/29/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//


#import "PlanRequestParameters.h"


@implementation PlanRequestParameters

@synthesize toLocation;
@synthesize fromLocation;
@synthesize originalTripDate;
@synthesize thisRequestTripDate;
@synthesize maxWalkDistance;
@synthesize departOrArrive;
@synthesize serverCallsSoFar;
@synthesize planDestination;

// Returns a new PlanRequestParameters object containing the same parameters as parameters0
+ (id)copyOfPlanRequestParameters:(PlanRequestParameters *)parameters0
{
    PlanRequestParameters* newParameters = [[PlanRequestParameters alloc] init];
    newParameters.toLocation = parameters0.toLocation;
    newParameters.fromLocation = parameters0.fromLocation;
    newParameters.originalTripDate = parameters0.originalTripDate;
    newParameters.thisRequestTripDate = parameters0.thisRequestTripDate;
    newParameters.maxWalkDistance = parameters0.maxWalkDistance;
    newParameters.departOrArrive = parameters0.departOrArrive;
    newParameters.serverCallsSoFar = parameters0.serverCallsSoFar;
    newParameters.planDestination = parameters0.planDestination;
    
    return newParameters;
}
@end
