//
//  UberQueueEntry.h
//  Nimbler SF
//
//  Created by John Canfield on 9/1/14.
//  Copyright (c) 2014 Nimbler World, Inc. All rights reserved.
//
// Class to keep track of all the PlanRequestParameters associated with a certain Uber API
// call and the Uber results from that call.
// That way, when the API response comes back, UberMgr knows which PlanRequestParameter
// values to update.

#import <Foundation/Foundation.h>
#import "PlanRequestParameters.h"

@interface UberQueueEntry : NSObject

@property (strong,nonatomic) NSMutableArray *planRequestParamArray;  // Array of PlanRequestParameters objects associated with a particular Uber API call
@property (strong,nonatomic) NSDate *createTime;  // date,time when API call was created
@property (strong,nonatomic) NSString *parameterKey; // string of the Uber API call parameters which can be used ot uniquely identify the call.  parameterKey is used as the key to a dictionary containing UberQueueEntry objects
@property (strong,nonatomic) NSMutableArray *itineraryArray;  // Array of ItineraryFromUber objects associated with this request
@property (nonatomic) BOOL receivedTimes; // have Uber time estimates been received?
@property (nonatomic) BOOL receivedPrices; // have Uber prices been received?

// Returns a unique parameterKey string based on params dictionary.
+ (NSString *)parameterKeyWithParams:(NSDictionary *)params;

-(void)addPlanRequestParametersObject:(PlanRequestParameters *)planReqParObject;

@end
