//
//  PlanRequestParameters.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/29/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
// Class containing the elements needed to make a plan request


#import <Foundation/Foundation.h>
#import "Location.h"

typedef enum {
    PLAN_DESTINATION_TO_FROM_VC,
    PLAN_DESTINATION_ROUTE_OPTIONS_VC
} PlanDestination;

@interface PlanRequestParameters : NSObject

@property (strong, nonatomic) NSString* formattedAddressTO;
@property (strong, nonatomic) NSString* formattedAddressFROM;
@property (strong, nonatomic) NSString* latitudeFROM;
@property (strong, nonatomic) NSString* longitudeFROM;
@property (strong, nonatomic) NSString* latitudeTO;
@property (strong, nonatomic) NSString* longitudeTO;
@property (strong, nonatomic) NSString* fromType;
@property (strong, nonatomic) NSString* toType;
@property (strong, nonatomic) NSString* rawAddressFROM;
@property (strong, nonatomic) NSString* geoResponseFROM;
@property (strong, nonatomic) NSString* geoResponseTO;
@property (strong, nonatomic) NSString* timeFROM;
@property (strong, nonatomic) NSString* timeTO;
@property (strong, nonatomic) NSString* rawAddressTO;

@property (strong, nonatomic) Location* fromLocation;
@property (strong, nonatomic) Location* toLocation;
@property (strong, nonatomic) NSDate* originalTripDate; // original date & time requested by user
@property (strong, nonatomic) NSDate* thisRequestTripDate; // date & time request for iterative plan requests to the server
@property (nonatomic) DepartOrArrive departOrArrive;
@property (nonatomic) int maxWalkDistance;
@property (nonatomic) int serverCallsSoFar; // number of calls to the server that have been made for this request
@property (nonatomic) PlanDestination planDestination;

// Returns a new PlanRequestParameters object containing the same parameters as parameters0
+ (id)copyOfPlanRequestParameters:(PlanRequestParameters *)parameters0;

@end
