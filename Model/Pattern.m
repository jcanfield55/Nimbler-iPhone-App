//
//  Pattern.m
//  Nimbler Caltrain
//
//  Created by macmini on 28/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Pattern.h"

@implementation Pattern
@synthesize agencyID;
@synthesize agencyName;
@synthesize route;
@synthesize routeShortName;
@synthesize routeLongName;
@synthesize mode;
@synthesize startTime;
@synthesize endTime;
@synthesize encodedString;
@synthesize distance;
@synthesize duration;
@synthesize toLat;
@synthesize fromLat;
@synthesize toLng;
@synthesize fromLng;

// This methods are used for archieving & unarchieving of Patterns object.
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.agencyID   forKey:@"agencyId"];
    [aCoder encodeObject:self.distance         forKey:@"distance"];
    [aCoder encodeObject:self.duration         forKey:@"duration"];
    [aCoder encodeObject:self.endTime         forKey:@"endTime"];
    [aCoder encodeObject:self.mode         forKey:@"mode"];
    [aCoder encodeObject:self.route         forKey:@"route"];
    [aCoder encodeObject:self.routeLongName         forKey:@"routeLongName"];
    [aCoder encodeObject:self.routeShortName         forKey:@"routeShortName"];
    [aCoder encodeObject:self.startTime         forKey:@"startTime"];
    [aCoder encodeObject:self.agencyName         forKey:@"agencyName"];
    [aCoder encodeObject:self.toLat         forKey:@"toLat"];
    [aCoder encodeObject:self.fromLat         forKey:@"fromLat"];
    [aCoder encodeObject:self.toLng         forKey:@"toLng"];
    [aCoder encodeObject:self.fromLng         forKey:@"fromLng"];
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init]))
    {
        self.agencyID = [aDecoder decodeObjectForKey:@"agencyId"];
        self.distance = [aDecoder decodeObjectForKey:@"distance"];
        self.duration = [aDecoder decodeObjectForKey:@"duration"];
        self.endTime = [aDecoder decodeObjectForKey:@"endTime"];
        self.mode = [aDecoder decodeObjectForKey:@"mode"];
        self.route = [aDecoder decodeObjectForKey:@"route"];
        self.routeLongName = [aDecoder decodeObjectForKey:@"routeLongName"];
        self.routeShortName = [aDecoder decodeObjectForKey:@"routeShortName"];
        self.startTime = [aDecoder decodeObjectForKey:@"startTime"];
        self.agencyName = [aDecoder decodeObjectForKey:@"agencyName"];
        self.toLat = [aDecoder decodeObjectForKey:@"toLat"];
        self.fromLat = [aDecoder decodeObjectForKey:@"fromLat"];
        self.toLng = [aDecoder decodeObjectForKey:@"toLng"];
        self.fromLng = [aDecoder decodeObjectForKey:@"fromLng"];
    }
    return self;
}

// Copy the required Paremeter From leg to Pattern.
+ (id)copyOfLegParameters:(Leg *)leg0;
{
    Pattern* pattern = [[Pattern alloc] init];
    pattern.agencyID = leg0.agencyId;
    pattern.distance = leg0.distance;
    pattern.duration = leg0.duration;
    pattern.endTime = leg0.endTime;
    pattern.mode = leg0.mode;
    pattern.route = leg0.mode;
    pattern.routeLongName = leg0.routeLongName;
    pattern.routeShortName = leg0.routeShortName;
    pattern.startTime = leg0.startTime;
    pattern.agencyName = leg0.agencyName;
    pattern.toLat = leg0.to.lat;
    pattern.toLng = leg0.to.lng;
    pattern.fromLat = leg0.from.lat;
    pattern.fromLng = leg0.from.lng;
    return pattern;
}

// Check if both patterns have mode walk if it is then check for Lat/Lng and distance if match return yes other wise return no.
// If The mode is not walk and both Patterns match the check if both patterns have routeShortName if not the check for routeLongName,agencyName, and Lat/Lng if not match then return no if patterns have routeShortName then check for routeShortname,agencyName And Lat/Lng if not match then return no else return yes.
// if all conditions not match then return no.
- (BOOL)isEquivalentPatternAs:(Pattern *)pattern{
    if([self.mode isEqualToString:@"WALK"] && [pattern.mode isEqualToString:@"WALK"]){
        if(self.toLat != pattern.toLat || self.toLng != pattern.toLng || self.fromLat !=pattern.fromLat || self.fromLng != pattern.fromLng || self.distance != pattern.distance){
            return NO;
        }
        return YES;
    }
    else if([self.mode isEqualToString:pattern.mode]){
        if(!self.routeShortName || !pattern.routeShortName){
            if(![self.routeLongName isEqualToString:pattern.routeLongName] || ![self.agencyName isEqualToString:pattern.agencyName] || self.toLat != pattern.toLat ||  self.toLng != pattern.toLng || self.fromLat != pattern.fromLat || self.fromLng != pattern.fromLng){
                return NO;
            }
        }
        else if(![self.routeShortName isEqualToString:pattern.routeShortName] || ![self.agencyName isEqualToString:pattern.agencyName] || self.toLat != pattern.toLat ||  self.toLng != pattern.toLng || self.fromLat != pattern.fromLat || self.fromLng != pattern.fromLng){
            return NO;
        }
        return YES;
    }
    else{
        return NO;
    }
}
@end
