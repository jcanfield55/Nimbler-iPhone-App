//
//  FeedBackReqParam.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/14/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "FeedBackReqParam.h"

@implementation FeedBackReqParam

@synthesize deviceId;
@synthesize fbSource;
@synthesize uniqueId;
@synthesize date;
@synthesize fromAddress;
@synthesize toAddress;
@synthesize currentLocation;
@synthesize toReverseLocation;
@synthesize fromReverseLocation;
@synthesize latTo;
@synthesize longTo;


- (id)initWithParam:(NSString *)name source:(NSNumber *)fbSources uniqueId:(NSString *)uniqueID date:(NSString *)tripDate 
          fromAddress:(NSString *)fromaddress toAddress:(NSString *)toaddress  
{
    self = [super init];
        [self setFbSource:fbSources];
        [self setUniqueId:uniqueID] ;
        [self setDate:tripDate] ;
        [self setFromAddress:fromaddress] ;
        [self setToAddress:toaddress] ;
    
    return self;
}

-(void) setDate:(NSString *) tripDate {
    date = tripDate;
}

-(NSString *) getDate {
    return date;
}

-(void) setCurrentLocation:(NSString *)currentLocations {
    currentLocation = currentLocations;
}

-(NSString *) getCurrentLocation{
    return currentLocation;   
}

-(void) setDeviceId:(NSString *)deviceIds {
    deviceId = deviceIds;
}

-(NSString *) getDeviceId {
    return deviceId;
}

-(NSNumber *) getfbSource {
    return fbSource;
}

-(void) setFbSource:(NSNumber *)feedbackSource {
    fbSource = feedbackSource;
}

-(NSString *) getUniqueId {
    return uniqueId;
}

- (void) setUniqueID: (NSString *) uniqueID {
    uniqueId = uniqueID;
}


-(NSString *) getFromAddress {
    return fromAddress;
}

- (void) setFromAddress: (NSString *) fromAddr {
    fromAddress = fromAddr;
}

-(NSString *) getToAddress {
    return toAddress;
}

- (void) setToAddress: (NSString *) toAddr {
    toAddress = toAddr;
}

-(NSString *) getToReverseLocation {
    return toReverseLocation;
}

- (void) setToReverseLocation: (NSString *) toReverseLoc {
    toReverseLocation = toReverseLoc;
}

-(NSString *) getFromReverseLocation {
    return fromReverseLocation;
}

- (void) setFromReverseLocation: (NSString *) fromReverseLoc {
    fromReverseLocation = fromReverseLoc;
}

-(NSString *) getLatTo {
    return latTo;
}

- (void) setLatTo: (NSString *) latitudeTo {
    latTo = latitudeTo;
}

-(NSString *) getLongTo {
    return longTo;
}

- (void) setLongTo: (NSString *) longitudeTo {
    longTo = longitudeTo;
}

@end
