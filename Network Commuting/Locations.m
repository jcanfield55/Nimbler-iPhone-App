//
//  Locations.m
//  Network Commuting
//
//  Created by John Canfield on 2/10/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Locations.h"

// Internal variables and methods

@interface Locations () 
{
    NSArray *sortedMatchingFromLocations; // All from locations that somehow match the typedFromString
    int matchingFromRowCount;  // Count of from locations (including frequency=0) that match the typedFromString
    NSArray *sortedMatchingToLocations;
    int matchingToRowCount;
    NSArray *sortedFromLocations;  // All locations sorted by from frequency
    NSArray *sortedToLocations;    // All locations sorted by to frequency
    NSFetchRequest *locationsFetchRequest;
    Location* oldSelectedFromLocation; // This stores the previous selectedFromLocation when a new one is entered
    Location* oldSelectedToLocation; // This stores the previous selectedToLocation when a new one is entere

}
- (void)updateWithSelectedLocationIsFrom:(BOOL)isFrom selectedLocation:(Location *)selectedLocation oldSelectedLocation:(Location *)oldSelectedLocation;
- (void)updateInternalCache;

@end


@implementation Locations

@synthesize typedFromString;
@synthesize typedToString;
@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize selectedFromLocation;
@synthesize selectedToLocation;
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

// Updates to selected location methods to update sorting

// Convenience method for updated either the To or From selected location
- (void)updateSelectedLocation:(Location *)sL isFrom:(BOOL)isFrom
{
    if (isFrom) {
        [self setSelectedFromLocation:sL];
    } else {
        [self setSelectedToLocation:sL];
    }
}
- (void)setSelectedFromLocation:(Location *)sFL
{
    selectedFromLocation = sFL;
    [self updateWithSelectedLocationIsFrom:TRUE selectedLocation:selectedFromLocation oldSelectedLocation:oldSelectedFromLocation];
    oldSelectedFromLocation = selectedFromLocation;
}

-(void)setSelectedToLocation:(Location *)sTL
{
    selectedToLocation = sTL;
    [self updateWithSelectedLocationIsFrom:FALSE selectedLocation:selectedToLocation oldSelectedLocation:oldSelectedToLocation];
    oldSelectedToLocation = selectedToLocation;
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
    areMatchingLocationsChanged = NO;
    // updateFromTyping(typedFromStr0, &typedFromString, &sortedMatchingFromLocations, &matchingFromRowCount);
    if (!typedFromStr0 || [typedFromStr0 length] == 0) { // if sorted string = 0
        sortedMatchingFromLocations = sortedFromLocations;
        typedFromString = typedFromStr0;  
        areMatchingLocationsChanged = YES;

        // Calculate the count, up to the first location with frequency=0 (excluding the selectedLocation)
        int i;
        for (i=0; (i < [sortedMatchingFromLocations count]) && 
             ((selectedFromLocation == [sortedMatchingFromLocations objectAtIndex:i]) ||
              [[sortedMatchingFromLocations objectAtIndex:i] fromFrequencyInt] != 0); i++);
        matchingFromRowCount = i;
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
        matchingFromRowCount = [sortedMatchingFromLocations count];  // cases that match typing are included even if they have frequency=0
    }
}

// Custom setter for updated typedToString that recomputes the sortedMatchingToLocations and row count
- (void)setTypedToString:(NSString *)typedToStr0
{
    areMatchingLocationsChanged = NO;
    // updateToTyping(typedToStr0, &typedToString, &sortedMatchingToLocations, &matchingToRowCount);
    if (!typedToStr0 || [typedToStr0 length] == 0) { // if sorted string = 0
        sortedMatchingToLocations = sortedToLocations;
        typedToString = typedToStr0;
        areMatchingLocationsChanged = YES;

        // Calculate the count, up to the first location with frequency=0 (excluding the selected Location)
        int i;
        for (i=0; (i < [sortedMatchingToLocations count]) && 
             ((selectedToLocation == [sortedMatchingToLocations objectAtIndex:i]) ||
             [[sortedMatchingToLocations objectAtIndex:i] toFrequencyInt] != 0); i++);
        matchingToRowCount = i;
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
        matchingToRowCount = [sortedMatchingToLocations count];  // cases that match typing are included even if they have frequency=0
    }
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

    // Force recomputation of the selectedLocations
    [self updateWithSelectedLocationIsFrom:TRUE selectedLocation:selectedFromLocation oldSelectedLocation:oldSelectedFromLocation];
    [self updateWithSelectedLocationIsFrom:FALSE selectedLocation:selectedToLocation oldSelectedLocation:oldSelectedToLocation];
    
    // Force the recomputation of the sortedMatchedLocations arrays
    [self setTypedToString:[self typedToString]];
    [self setTypedFromString:[self typedFromString]];
    
    [self setAreLocationsChanged:NO];  // reset again
}

// Updates sortedToLocations or sortedFromLocations to put the selectedLocation at the top of the list
// Note: this does not update the sortedMatchingLocations array, so this method should only be used when
// typing field is already cleared
- (void)updateWithSelectedLocationIsFrom:(BOOL)isFrom selectedLocation:(Location *)selectedLocation oldSelectedLocation:(Location *)oldSelectedLocation
{
    NSMutableArray* newArray;
    if (isFrom) {
        newArray = [[NSMutableArray alloc] initWithArray:sortedFromLocations];
    } else {
        newArray = [[NSMutableArray alloc] initWithArray:sortedToLocations];
    }
    if (oldSelectedLocation && (oldSelectedLocation != selectedLocation)) { // if there was a non-nil oldSelectedLocation, and this is a new request, then re-sort
        NSSortDescriptor *sd1 = [NSSortDescriptor 
                                 sortDescriptorWithKey:(isFrom ? @"fromFrequency" : @"toFrequency")
                                                              ascending:NO];
        NSSortDescriptor *sd2 = [NSSortDescriptor sortDescriptorWithKey:@"dateLastUsed"
                                                              ascending:NO];
        [newArray sortUsingDescriptors:[NSArray arrayWithObjects:sd1,sd2, nil]];
    }
    if (selectedLocation) { // if there is a non-nil selectedLocation, then move it to the top
        [newArray removeObject:selectedLocation];  // remove selected object from current location
        [newArray insertObject:selectedLocation atIndex:0];  // inserts it at the front of the object
    }
    
    // Write newArray back into the appropriate sorted array
    if (isFrom) {
        sortedFromLocations = [NSArray arrayWithArray:newArray];
    } else {
        sortedToLocations = [NSArray arrayWithArray:newArray];
    }
}

// Returns an array of Location objects that have an exact match for formattedAddress 
// (could be empty if no matches)
- (NSArray *)locationsWithFormattedAddress:(NSString *)formattedAddress
{
    if (!formattedAddress) {
        return nil;
    }
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
    if (!rawAddress) {
        return nil;
    }
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
        return loc0;  
    }
    else {  
        for (Location *loc1 in matches) {
            if (loc0 != loc1) {  // if this is actually a different object
                // consolidate from loc0 into loc1, delete loc0, and return loc1
                // loop thru and add each loc0 RawAddress and add to loc1
                for (RawAddress *loc0RawAddr in [loc0 rawAddresses]) {
                    [loc1 addRawAddressString:[loc0RawAddr rawAddressString]];
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

// Remove location from Core Data
- (void)removeLocation:(Location *)loc0
{
    [managedObjectContext deleteObject:loc0];
}

@end
