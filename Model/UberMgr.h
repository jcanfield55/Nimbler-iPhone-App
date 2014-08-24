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

@interface UberMgr : NSObject <RKRequestDelegate>

@property (strong,nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong,nonatomic)  RKClient *rkUberClient;
@property (strong,nonatomic) PlanRequestParameters *currentRequest;
@property (strong,nonatomic) NSMutableArray *itineraryArray;  // Array of ItineraryFromUber objects for currentRequest

// Designated initializer
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc;

// Requests a Uber itinerary given the provided parameters (to and from lat and long)
- (void)requestUberItineraryWithParameters:(PlanRequestParameters *)parameters;

@end
