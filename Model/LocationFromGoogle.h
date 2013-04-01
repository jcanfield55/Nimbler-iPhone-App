//
//  LocationFromGoogle.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 9/20/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
//  Subclass of Location implemented with Google Geocoding obtained via a RESTful call managed by RestKit

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import "Location.h"
#import "AddressComponent.h"
#import "GeoRectangle.h"

@class AddressComponent;

@interface LocationFromGoogle : Location

@property (nonatomic, strong) NSArray *types;  // Array of NSStrings with type properties (street address, locality)
@property (nonatomic, strong) GeoRectangle *viewPort;   // Rectangle defining the view for the location
@property (nonatomic, strong) NSSet *addressComponents;  // Set of AddressComponent items
#define LOCATION_ADDRESS_COMPONENT @"addressComponents"

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)gt;

// Creates and adds a new AddressComponent to self with the given parameters using ManagedObjectContext context
-(void)addAddressComponentWithLongName:(NSString *)longName
                             shortName:(NSString *)shortName
                                 types:(NSArray *)types
                               context:(NSManagedObjectContext *)context;

@end

@interface LocationFromGoogle (CoreDataGeneratedAccessors)

- (void)addAddressComponentsObject:(AddressComponent *)value;
- (void)removeAddressComponentsObject:(AddressComponent *)value;
- (void)addAddressComponents:(NSSet *)values;
- (void)removeAddressComponents:(NSSet *)values;
@end
