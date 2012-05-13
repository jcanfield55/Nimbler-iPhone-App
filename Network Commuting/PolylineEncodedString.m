//
//  PolylineEncodedString.m
//  Nimbler
//
//  Created by John Canfield on 3/31/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "PolylineEncodedString.h"
@interface PolylineEncodedString()
-(void) updateWithNewEncodedString;
@end


@implementation PolylineEncodedString
@synthesize encodedString;
@synthesize polyline;
@synthesize startCoord;
@synthesize endCoord;

// Sets up the polyline, startCoord, and endCoord instance variables using encodedSring
- (id)initWithEncodedString:(NSString *)encStr
{
    self = [super init];
    if (self) {
        encodedString = encStr;
        [self updateWithNewEncodedString];
    }
    return self;
}

- (void)setEncodedString:(NSString *)encStr
{
    encodedString = encStr;
    [self updateWithNewEncodedString];
}

// Sets the instance variables for polyline, startCoord, and endCoord
// This code is from the following post: http://objc.id.au/post/9245961184/mapkit-encoded-polylines
//
-(void) updateWithNewEncodedString
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
    
    polyline = [MKPolyline polylineWithCoordinates:coords count:coordIdx];
    startCoord = coords[0];
    endCoord = coords[coordIdx-1];
    
    free(coords);

}

@end
