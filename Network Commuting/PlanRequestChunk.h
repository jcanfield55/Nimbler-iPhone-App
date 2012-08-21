//
//  PlanRequestChunk.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
//
// PlanRequestChunks are individual elements of a PlanRequestCache.
// They represent the history of individual plan requests

#import <Foundation/Foundation.h>
#import "Itinerary.h"
#import "enums.h"

@interface PlanRequestChunk : NSObject

// Time & date that the user originally requested for the itinerary (i.e. when he wanted to do the travel)
@property (strong, nonatomic) NSDate* requestedTimeDate;

// Whether the user asked for a "depart at" or an "arrive by" plan request
@property (nonatomic) DepartOrArrive departOrArrive;

// List of itineraries that are part of this PlanRequestChunk
@property (strong, nonatomic) NSMutableArray* itineraries;

@end
