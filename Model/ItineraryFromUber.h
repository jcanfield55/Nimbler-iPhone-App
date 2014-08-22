//
//  ItineraryFromUber.h
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Network Commuting. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Itinerary.h"

@interface ItineraryFromUber : Itinerary
+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType;
@end
