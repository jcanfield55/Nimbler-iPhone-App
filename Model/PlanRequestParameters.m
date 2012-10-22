//
//  PlanRequestParameters.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/29/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
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

@synthesize formattedAddressTO;
@synthesize formattedAddressFROM;
@synthesize latitudeFROM;
@synthesize longitudeFROM;
@synthesize latitudeTO;
@synthesize longitudeTO;
@synthesize fromType;
@synthesize toType;
@synthesize rawAddressFROM;
@synthesize timeFROM;
@synthesize timeTO;
@synthesize rawAddressTO;

@synthesize bikeTriangleBikeFriendly;
@synthesize bikeTriangleFlat;
@synthesize bikeTriangleQuick;
@synthesize maxBikeDistance;
@synthesize transitMode;


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
    
    newParameters.formattedAddressTO = parameters0.formattedAddressTO;
    newParameters.formattedAddressFROM = parameters0.formattedAddressFROM;
    newParameters.latitudeFROM = parameters0.latitudeFROM;
    newParameters.longitudeFROM = parameters0.longitudeFROM;
    newParameters.latitudeTO = parameters0.latitudeTO;
    newParameters.longitudeTO = parameters0.longitudeTO;
    newParameters.fromType = parameters0.fromType;
    newParameters.toType = parameters0.toType;
    newParameters.rawAddressFROM = parameters0.rawAddressFROM;
    newParameters.timeFROM = parameters0.timeFROM;
    newParameters.timeTO = parameters0.timeTO;
    newParameters.rawAddressTO = parameters0.rawAddressTO;
    
    newParameters.bikeTriangleFlat = parameters0.bikeTriangleFlat;
    newParameters.bikeTriangleBikeFriendly = parameters0.bikeTriangleBikeFriendly;
    newParameters.bikeTriangleQuick = parameters0.bikeTriangleQuick;
    newParameters.maxBikeDistance = parameters0.maxBikeDistance;
    newParameters.transitMode = parameters0.transitMode;
    
    return newParameters;
}
@end
