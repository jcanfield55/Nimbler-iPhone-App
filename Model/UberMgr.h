//
//  UberMgr.h
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Nimbler World Inc. All rights reserved.
//

// Used for calling Uber API from App and generating Uber itineraries

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "ItineraryFromUber.h"
#import "LegFromUber.h"
#import "PlanRequestParameters.h"
#import "UberQueueEntry.h"


@interface UberMgr : NSObject <RKRequestDelegate>

@property (strong,nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong,nonatomic)  RKClient *rkUberClient;
@property (strong,nonatomic) NSMutableDictionary *uberQueueDictionary;  // dictionary of all UberQueueEntry objects corresponding to Uber API requests

// Designated initializer
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc;

// Requests a Uber itinerary given the provided parameters (to and from lat and long)
// When a response is received from UberAPI, the itinFromUberArray property of parameters will be updated accordingly
// This method should be called with each unique copy of PlanRequestParameters associated with a particular
// user request.  The UberAPI will only be called once, but the results will be updated in all
// PlanRequestParameters.
- (void)requestUberItineraryWithParameters:(PlanRequestParameters *)parameters;


@end
