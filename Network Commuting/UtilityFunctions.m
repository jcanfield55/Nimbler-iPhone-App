//
//  UtilityFunctions.m
//  Network Commuting
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "UtilityFunctions.h"

// This function will construct the full path for a file with name *filename
// in the Documents Directory
NSString *pathInDocumentDirectory(NSString *fileName)
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    // Get the one and only document directory from the list
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:fileName];
}


void saveContext(NSManagedObjectContext *managedObjectContext)
{
    NSError *error = nil;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

// Converts from milliseconds to a string formatted as "X days, Y hours, Z minutes"
NSString *durationString(double milliseconds)
{
    NSString *returnString;
    double minutes = milliseconds / (1000.0 * 60.0);
    if (minutes < 1.0) {
        returnString = @"less than 1 minute";
    }
    else if (minutes <1.5) {
        returnString = @"1 minute";
    }
    else if (minutes < 60.0) {
        returnString = [NSString stringWithFormat:@"%d minutes", (int) round(minutes)];
    }
    else {  // hours
        NSString *daysString = @"";
        NSString *hoursString;
        int hours = (int) floor(minutes/60);
        minutes = minutes - hours * 60;  // redo minutes to remaining minutes after hours taken out
        if (hours == 1) {
            hoursString = @"1 hour";
        }
        else if (hours < 24) {
            hoursString = [NSString stringWithFormat:@"%d hours", hours];
        }
        else { // days
            int days = (int) floor((float) hours / 24.0);
            hours = hours - (days * 24);  // redo hours to remianing hours after days taken out
            if (days == 1) {
                daysString = @"1 day";
            }
            else {
                daysString = [NSString stringWithFormat:@"%d days", days];
            }
            if (hours > 1) {
                hoursString = [NSString stringWithFormat:@"%@, %d hours", daysString, hours];
            }
            else if (hours == 1) {
                hoursString = [NSString stringWithFormat:@"%@, %d hour", daysString, hours];
            }
            else {
                hoursString = daysString;
            }
        }
        NSString *minutesString = durationString(minutes * 60.0 * 1000.0);
        if ([minutesString isEqualToString:@"less than 1 minute"]) {
            returnString = hoursString;  
        }
        else {
            returnString = [NSString stringWithFormat:@"%@, %@", hoursString, minutesString];        
        }
    }
    return returnString;
}

// Converts from meters to a string in either miles or feed
NSString *distanceStringInMilesFeet(double meters) {
    NSString *returnString;
    double feet = meters * 3.2808398950131235;  // from http://www.calculateme.com/Length/Meters/ToFeet.htm
    double miles = feet / 5280.0;
    if (miles < 0.1) {  // convey in feet
        if (feet < 1.0) {
            returnString = @"less than 1 foot";
        }
        else if (feet < 1.5) {
            returnString = @"1 foot";
        }
        else {
            returnString = [NSString stringWithFormat:@"%d feet", (int) round(feet)];
        }
    }
    else { // convey in miles
        returnString = [NSString stringWithFormat:@"%.1f miles", miles];
    }
    return returnString;
}


// Returns an MKPolyline corresponding to a polyline encoded string
// This code is from the following post: http://objc.id.au/post/9245961184/mapkit-encoded-polylines
//
MKPolyline *polylineWithEncodedString(NSString *encodedString)
{
    const char *bytes = [encodedString UTF8String];
    NSUInteger length = [encodedString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger idx = 0;
    
    NSUInteger count = length / 4;
    CLLocationCoordinate2D *coords = calloc(count, sizeof(CLLocationCoordinate2D));
    NSUInteger coordIdx = 0;
    
    float latitude = 0;
    float longitude = 0;
    while (idx < length) {
        char byte = 0;
        int res = 0;
        char shift = 0;
        
        do {
            byte = bytes[idx++] - 63;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLat = ((res & 1) ? ~(res >> 1) : (res >> 1));
        latitude += deltaLat;
        
        shift = 0;
        res = 0;
        
        do {
            byte = bytes[idx++] - 0x3F;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLon = ((res & 1) ? ~(res >> 1) : (res >> 1));
        longitude += deltaLon;
        
        float finalLat = latitude * 1E-5;
        float finalLon = longitude * 1E-5;
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(finalLat, finalLon);
        coords[coordIdx++] = coord;
        
        if (coordIdx == count) {
            NSUInteger newCount = count + 10;
            coords = realloc(coords, newCount * sizeof(CLLocationCoordinate2D));
            count = newCount;
        }
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords count:coordIdx];
    free(coords);
    
    return polyline;
}


