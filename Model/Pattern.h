//
//  Pattern.h
//  Nimbler Caltrain
//
//  Created by macmini on 28/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Leg.h"

@protocol NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end

@interface Pattern : NSObject{
    NSString *agencyID;
    NSString *agencyName;
    NSString *route;
    NSString *routeShortName;
    NSString *routeLongName;
    NSString *mode;
    NSDate *startTime;
    NSDate *endTime;
    NSString *encodedString;
    NSNumber *distance;
    NSNumber *duration;
    NSNumber *toLat;
    NSNumber *fromLat;
    NSNumber *toLng;
    NSNumber *fromLng;
}

@property (nonatomic, strong) NSString *agencyID;
@property (nonatomic, strong) NSString *agencyName;
@property (nonatomic, strong) NSString *route;
@property (nonatomic, strong) NSString *routeShortName;
@property (nonatomic, strong) NSString *routeLongName;
@property (nonatomic, strong) NSString *mode;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, strong) NSString *encodedString;
@property (nonatomic, strong) NSNumber *distance;
@property (nonatomic, strong) NSNumber *duration;
@property (nonatomic, strong) NSNumber *toLat;
@property (nonatomic, strong) NSNumber *fromLat;
@property (nonatomic, strong) NSNumber *toLng;
@property (nonatomic, strong) NSNumber *fromLng;

// Copy the required Paremeter From leg to Pattern.
+ (id)copyOfLegParameters:(Leg *)leg0;

// Compare two Patterns return true if two pattern match otherwise return false.
- (BOOL)isEquivalentPatternAs:(Pattern *)pattern;
@end
