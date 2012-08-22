//
//  PlanRequestCache.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
// This class is an element of each Plan.  It keeps track of the different requests that have been
// consolidated into the plan, and provides methods to see whether a particular user request can be
// partially or fully met by cached elements.

#import <Foundation/Foundation.h>
#import "PlanRequestChunk.h"

@interface PlanRequestCache : NSObject

@property (strong, nonatomic) NSMutableArray *requestChunkArray; // Sorted array of PlanRequestChunks

//
// Methods
//
// Initializer for an existing (legacy) Plan that does not have any planRequestCache but has a bunch of existing itineraries.  Creates a new PlanRequestChunk for every itinerary in sortedItineraryArray
- (id)initWithRawItineraries:(NSArray *)sortedItineraryArray;

// Initializer for a new plan fresh from a OTP request
// Creates one PlanRequestChunk with all the itineraries as part of it
- (id)initWithRequestDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive sortedItineraries:(NSArray *)sortedItinArray;

- (NSArray *)relevantRequestChunksForDate:(NSDate *)requestDate departOrArrive:(DepartOrArrive)depOrArrive;

@end
