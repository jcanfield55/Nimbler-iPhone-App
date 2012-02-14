//
//  Locations.m
//  Network Commuting
//
//  Created by John Canfield on 2/10/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Locations.h"

@implementation Locations

@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize areLocationsChanged;

// Called after there has been a significant update to a Location so that cache is invalidated
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self setAreLocationsChanged:YES];  // mark cache for refresh
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        managedObjectContext = moc;
        managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
    }
    // Set the static variable for Location class
    [Location setLocations:self];
    
    areLocationsChanged = YES;  // Force cache stale upon start-up
    
    return self;
}

- (Location *)newEmptyLocation 
{
    Location *l = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
    return l;
}

// Returns the number of locations to show in the to or from table.  isFrom = true if it is the from table.
// Implementation only counts locations with frequency>0.   
- (int)numberOfLocations:(bool)isFrom {

    if (areLocationsChanged) { // if cache outdated, then query & update the internal memory array
        [self updateInternalCache];
    }
    // Now that the internal variables are updated, return the row value
    if (isFrom) {
        return fromRowCount;
    }
    else {
        return toRowCount;
    }
}

// Returns the Location from the sorted array at the specified index.  isFrom = true if it is the from table. 
- (Location *)locationAtIndex:(int)index isFrom:(BOOL)isFrom {

    if (areLocationsChanged) { // if cache outdated, then query & update the internal memory array
        [self updateInternalCache];
    }
    // Now that the internal variables are updated, return the row value
    if (isFrom) {
        return [sortedFromLocations objectAtIndex:index];
    }
    else {
        return [sortedToLocations objectAtIndex:index];
    }
}


// Internal method for updating cache after locations have changed
// Only include those locations with frequency >= 1 in the row count
- (void)updateInternalCache
{
    if (!locationsFetchRequest) {  // create the fetch request if we have not already done so
        locationsFetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *e = [[managedObjectModel entitiesByName] objectForKey:@"Location"];
        [locationsFetchRequest setEntity:e];
        NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:@"fromFrequency" 
                                                              ascending:NO];
        NSSortDescriptor *sd2 = [NSSortDescriptor sortDescriptorWithKey:@"dateLastUsed"
                                                              ascending:NO];
        [locationsFetchRequest setSortDescriptors:[NSArray arrayWithObjects:sd1,sd2,nil]];
    }
    
    // Fetch the sortedFromLocations array
    NSError *error;
    sortedFromLocations = [managedObjectContext executeFetchRequest:locationsFetchRequest
                                                              error:&error];
    if (!sortedFromLocations) {
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]];
    }
    
    // Now create a different array with the sorted To descriptors
    NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:@"toFrequency" 
                                                          ascending:NO];
    NSSortDescriptor *sd2 = [NSSortDescriptor sortDescriptorWithKey:@"dateLastUsed"
                                                          ascending:NO];
    sortedToLocations = [sortedFromLocations sortedArrayUsingDescriptors:
                         [NSArray arrayWithObjects:sd1,sd2,nil]];
    
    // Calculate the count, up to the first location with frequency=0
    int i;
    for (i=0; (i < [sortedFromLocations count]) && 
         ([[sortedFromLocations objectAtIndex:i] fromFrequency] != 0); i++);
    fromRowCount = i;
    for (i=0; (i < [sortedToLocations count]) && 
         ([[sortedToLocations objectAtIndex:i] toFrequency] != 0); i++);
    toRowCount = i;
    
    NSLog(@"fromLocations: %@", sortedFromLocations);
    NSLog(@"toLocations: %@", sortedToLocations);
    NSLog(@"fromRowCount: %d", fromRowCount);
    NSLog(@"toRowCount: %d", toRowCount);

    
    [self setAreLocationsChanged:NO];  // reset again
}

// Returns an array of Location objects that have an exact match for formattedAddress 
// (could be empty if no matches)
- (NSArray *)locationsWithFormattedAddress:(NSString *)formattedAddress
{
    NSFetchRequest *request = [managedObjectModel fetchRequestFromTemplateWithName:@"LocationByFormattedAddress" substitutionVariables:[NSDictionary dictionaryWithObject:formattedAddress forKey:@"ADDRESS2"]];
    
    NSError *error; 
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error]; 
    if (!result) { 
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]]; 
    } 
    return result;  // Return the array of matches (could be empty)
}

// Returns first location that has an exact match for a rawAddress
- (Location *)locationWithRawAddress:(NSString *)rawAddress
{
    // Fetch all RawAddress objects that match the string
    NSFetchRequest *request = [managedObjectModel fetchRequestFromTemplateWithName:@"RawAddressByString" substitutionVariables:[NSDictionary dictionaryWithObject:rawAddress forKey:@"ADDRESS"]];
    
    NSError *error; 
    NSArray *result = [managedObjectContext executeFetchRequest:request error:&error]; 
    if (!result) { 
        [NSException raise:@"Fetch failed" format:@"Reason: %@", [error localizedDescription]]; 
    }
    if ([result count]>=1) {            // if there is a match
        // Return the Location that corresponds to that RawAddress
        RawAddress *rawAddrObj = [result objectAtIndex:0];
        return [rawAddrObj location];  
    }
    else {
        return nil;   // return nil if no matching Location
    }    
}

// Takes loc0 (typically a newly geocoded location) and see if there are any equivalent locations
// already in the Location store.  If so, then consolidate the two locations so there is only one left
// Returns a location -- either the original loc0 if there is no matching location, or 
// the consolidated matching location if there was a match in the store.
// Searches for equivalent matching locations simply looking for exact matches of Formatted Address.
// (this could be expanded in the future)
- (Location *)consolidateWithMatchingLocations:(Location *)loc0 
{
    NSArray *matches = [self locationsWithFormattedAddress:[loc0 formattedAddress]];
    if (!matches) {   
        return loc0;  // returns nil
    }
    else {  
        for (Location *loc1 in matches) {
            if (loc0 != loc1) {  // if this is actually a different object
                // consolidate from loc0 into loc1, delete loc0, and return loc1
                // loop thru and add each loc0 RawAddress and add to loc1
                for (RawAddress *loc0RawAddr in [loc0 rawAddresses]) {
                    [loc1 addRawAddressesObject:loc0RawAddr];
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
    }
    return loc0;  // return loc0 if no different matches were found
}

@end
