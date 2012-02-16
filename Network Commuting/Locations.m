//
//  Locations.m
//  Network Commuting
//
//  Created by John Canfield on 2/10/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Locations.h"

// Internal utility functions

@implementation Locations

@synthesize typedFromString;
@synthesize typedToString;
@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize areLocationsChanged;
@synthesize areMatchingLocationsChanged;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        managedObjectContext = moc;
        managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
    }
    // Set the static variable for Location class
    [Location setLocations:self];
    
    areLocationsChanged = YES;  // Force cache stale upon start-up so it gets properly loaded
    
    return self;
}

// Called after there has been a significant update to a Location so that cache is invalidated
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self setAreLocationsChanged:YES];  // mark cache for refresh
}

- (Location *)newEmptyLocation 
{
    Location *l = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:managedObjectContext];
    return l;
}

// Utility function used by setTypedFromString & setTypedToString.  On hold for now
/* void updateFromTyping(NSString *typedXStr0, NSString **typedXString, NSArray **sortedMatchingXLocations, 
                      int *matchingXRowCount)
 */

// Custom setter for updated typedFromString that recomputes the sortedMatchingFromLocations and row count
- (void)setTypedFromString:(NSString *)typedFromStr0
{
    // updateFromTyping(typedFromStr0, &typedFromString, &sortedMatchingFromLocations, &matchingFromRowCount);
    if (!typedFromStr0 || [typedFromStr0 length] == 0) { // if sorted string = 0
        sortedMatchingFromLocations = sortedFromLocations;
        typedFromString = typedFromStr0;  
        areMatchingLocationsChanged = YES;
    }
    else {
        NSArray *startArray = nil;
        if (typedFromString && [typedFromString length]>0 && [typedFromStr0 hasPrefix:typedFromString]) { // if new string is an extension of the previous one...
            startArray = sortedMatchingFromLocations;  // start with the last array of matches, and narrow from there
        }
        else {
            startArray = sortedFromLocations;    // otherwise, start fresh with all from locations
        }
        typedFromString = typedFromStr0;   
        NSMutableArray *newArray = [NSMutableArray array];   
        for (Location *loc in startArray) {
            if ([loc isMatchingTypedString:typedFromString]) {  // if loc matches the new string
                [newArray addObject:loc];  //  add loc to the new array
            }
        }
        NSArray *finalNewArray = [NSArray arrayWithArray:newArray];  // makes a non-mutable copy
        if (![finalNewArray isEqualToArray:sortedMatchingFromLocations]) { // if there is a change
            sortedMatchingFromLocations = finalNewArray;
            areMatchingLocationsChanged = YES;   // mark for refreshing the table
        }
    }
    matchingFromRowCount = [sortedMatchingFromLocations count];
}

// Custom setter for updated typedToString that recomputes the sortedMatchingToLocations and row count
- (void)setTypedToString:(NSString *)typedToStr0
{
    // updateToTyping(typedToStr0, &typedToString, &sortedMatchingToLocations, &matchingToRowCount);
    if (!typedToStr0 || [typedToStr0 length] == 0) { // if sorted string = 0
        sortedMatchingToLocations = sortedToLocations;
        typedToString = typedToStr0;
        areMatchingLocationsChanged = YES;
    }
    else {
        NSArray *startArray = nil;
        if (typedToString && [typedToString length]>0 && [typedToStr0 hasPrefix:typedToString]) { // if new string is an extension of the previous one...
            startArray = sortedMatchingToLocations;  // start with the last array of matches, and narrow from there
        }
        else {
            startArray = sortedToLocations;    // otherwise, start fresh with all To locations
        }
        typedToString = typedToStr0;   
        NSMutableArray *newArray = [NSMutableArray array];   
        for (Location *loc in startArray) {
            if ([loc isMatchingTypedString:typedToString]) {  // if loc matches the new string
                [newArray addObject:loc];  //  add loc to the new array
            }
        }
        NSArray *finalNewArray = [NSArray arrayWithArray:newArray];  // makes a non-mutable copy
        if (![finalNewArray isEqualToArray:sortedMatchingToLocations]) { // if there is a change
            sortedMatchingToLocations = finalNewArray;
            areMatchingLocationsChanged = YES;   // mark for refreshing the table
        }
    }
    matchingToRowCount = [sortedMatchingToLocations count];
}


// Returns the number of locations to show in the to or from table.  isFrom = true if it is the from table.
// Implementation only counts locations with frequency>0.   
- (int)numberOfLocations:(BOOL)isFrom {

    if (areLocationsChanged) { // if cache outdated, then query & update the internal memory array
        [self updateInternalCache];
    }
    // Now that the internal variables are updated, return the row value
    if (isFrom) {
        return matchingFromRowCount;
    }
    else {
        return matchingToRowCount;
    }
}

// Returns the Location from the sorted array at the specified index.  isFrom = true if it is the from table. 
- (Location *)locationAtIndex:(int)index isFrom:(BOOL)isFrom {

    if (areLocationsChanged) { // if cache outdated, then query & update the internal memory array
        [self updateInternalCache];
    }
    // Now that the internal variables are updated, return the row value
    if (isFrom) {
        return [sortedMatchingFromLocations objectAtIndex:index];
    }
    else {
        return [sortedMatchingToLocations objectAtIndex:index];
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
         ([[sortedFromLocations objectAtIndex:i] fromFrequencyInt] != 0); i++);
    fromRowCount = i;
    for (i=0; (i < [sortedToLocations count]) && 
         ([[sortedToLocations objectAtIndex:i] toFrequencyInt] != 0); i++);
    toRowCount = i;
    
    NSLog(@"fromLocations: %@", sortedFromLocations);
    NSLog(@"toLocations: %@", sortedToLocations);
    NSLog(@"fromRowCount: %d", fromRowCount);
    NSLog(@"toRowCount: %d", toRowCount);

    // Force the recomputation of the sortedMatchedLocations arrays
    [self setTypedToString:[self typedToString]];
    [self setTypedFromString:[self typedFromString]];
    
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
                [loc1 setToFrequencyInt:([loc1 toFrequencyInt] + [loc0 toFrequencyInt])];
                [loc1 setFromFrequencyInt:([loc1 fromFrequencyInt] + [loc0 fromFrequencyInt])];
                
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
