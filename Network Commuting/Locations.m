//
//  Locations.m
//  Network Commuting
//
//  Created by John Canfield on 2/10/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Locations.h"
#import "ModelDataStore.h"

@implementation Locations

@synthesize modelDataStore;
@synthesize rkObjectManager;
@synthesize managedObjectContext;
@synthesize managedObjectModel;

- (id)initWithRKObjectManager:(RKObjectManager *)rko modelDataStore:(ModelDataStore *)mds
{
    self = [super init];
    if (self) {
        rkObjectManager = rko;
        modelDataStore = mds;
        managedObjectContext = [modelDataStore managedObjectContext];
        managedObjectModel = [modelDataStore managedObjectModel];
    }
    return self;
}

- (Location *)newEmptyLocation 
{
    Location *l = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
    return l;
}


// Returns first location that has an exact match for formattedAddress
- (Location *)locationWithFormattedAddress:(NSString *)formattedAddress
{
    NSFetchRequest *request = [managedObjectModel fetchRequestFromTemplateWithName:@"LocationByFormattedAddress" substitutionVariables:[NSDictionary dictionaryWithObject:formattedAddress forKey:@"ADDRESS2"]];
    
    NSError *error; 
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error]; 
    if (!result) { 
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]]; 
    }
    if ([result count]>=1) {            // if there is a match
        return [result objectAtIndex:0];  // Return the first object
    }
    else {
        return nil;   // return nil if no matching Location
    }
}

// Finds locations in Locations table that have the same Formatted Address string at Loc0
- (Location *)findEquivalentLocationTo:(Location *)loc0
{
    return [self locationWithFormattedAddress:[loc0 formattedAddress]];  
}

// Returns first location that has an exact match for a rawAddress
- (Location *)locationWithRawAddress:(NSString *)rawAddress
{
    // TODO build out this function
    return nil;
    
}

// Takes loc0 (typically a newly geocoded location) and see if there are any equivalent locations
// already in the Location store.  If so, then consolidate the two locations so there is only one left
// Returns a location -- either the original loc0 if there is no matching location, or 
// the consolidated matching location if there was a match in the store.
// Searches for equivalent matching locations simply looking for exact matches of Formatted Address.
// (this could be expanded in the future)
- (Location *)consolidateWithMatchingLocations:(Location *)loc0 
{
    Location *loc1 = [self locationWithFormattedAddress:[loc0 formattedAddress]];
    if (!loc1) {   // if there is no match...
        return nil;  // returns nil
    }
    else {  // consolidate from loc0 into loc1, delete loc0, and return loc1
        // loop thru and add each loc0 RawAddress and add to loc1
        for (NSString *loc0RawAddr in [loc0 rawAddresses]) {
            [loc1 addRawAddress:loc0RawAddr];
        }
        // Add from and to frequency from loc0 into loc1
        [loc1 setToFrequency:([loc1 toFrequency] + [loc0 toFrequency])];
        [loc1 setFromFrequency:([loc1 fromFrequency] + [loc0 fromFrequency])];
        
        // Delete loc0 & return loc1
        // TODO  resolve error about deleting across contexts
        [managedObjectContext deleteObject:loc0];
        return loc1;
    }
}

@end
