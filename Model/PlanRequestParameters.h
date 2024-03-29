//
//  PlanRequestParameters.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/29/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
// Class containing the elements needed to make a plan request


#import <Foundation/Foundation.h>
#import "Location.h"
#import "MutableBoolean.h"

@class RouteExcludeSettings;

@class PlanRequestParameters;
@class Plan;

@protocol NewPlanAvailableDelegate<NSObject>
@required
// Call-back from PlanStore requestPlanFromLocation:... method when it has a plan
-(void)newPlanAvailable:(Plan *)newPlan
             fromObject:(id)referringObject
                 status:(PlanRequestStatus)status
       RequestParameter:(PlanRequestParameters *)requestParameter;
@end

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
@property (nonatomic) MutableBoolean *hasGoneToRouteOptions;  // pointer to boolean showing true if this plan has made the transition from ToFromView to RouteOptionsView.  The same NSNumber is used for all copies associated with a request
@property (nonatomic, unsafe_unretained) id<NewPlanAvailableDelegate> planDestination;
@property (nonatomic) BOOL haveMadeFirstCallback;  // Set to true after first callback
@property (strong, nonatomic) RouteExcludeSettings* routeExcludeSettings; // optional
@property (strong, nonatomic) NSString* otpExcludeAgencyString;  // Set by requestPlanFromOtpWithParameters method with the OTP exclude string
@property (strong, nonatomic) NSString* otpExcludeAgencyByModeString; // Set by requestPlanFromOtpWithParameters method with the OTP by mode exclude string
@property (strong, nonatomic) RouteExcludeSettings* routeExcludeSettingsUsedForOTPCall; // set by requestPlanFromOtpWithParameters with parameters used for its call (may be different than routeExcludeSettings)
@property (nonatomic) BOOL needToRequestRealtime;
@property (nonatomic, strong) NSArray *itinFromUberArray;  // Array where we can store Uber itineraries once generated (optional)


// Returns a new PlanRequestParameters object containing the same parameters as parameters0
+ (id)copyOfPlanRequestParameters:(PlanRequestParameters *)parameters0;

// Returns true if the planDestination goes to a ToFromViewController class
-(BOOL)isDestinationToFromVC;

// Returns true if the planDestination goes to a RouteOptionsViewController class
-(BOOL)isDestinationRouteOptionsVC;

@end
