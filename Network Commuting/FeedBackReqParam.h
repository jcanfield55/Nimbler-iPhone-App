//
//  FeedBackReqParam.h
//  Nimbler
//
//  Created by JaY Kumbhani on 6/14/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FeedBackReqParam : NSObject

@property(nonatomic, retain)    NSString *deviceId;
@property(nonatomic, retain)    NSString *fbSource;
@property(nonatomic, retain)    NSString *uniqueId;
@property(nonatomic, retain)    NSString *date;
@property(nonatomic, retain)    NSString *fromAddress;
@property(nonatomic, retain)    NSString *toAddress;
@property(nonatomic, retain)    NSString *currentLocation;
@property(nonatomic, retain)    NSString *toReverseLocation;
@property(nonatomic, retain)    NSString *fromReverseLocation;
@property(nonatomic, retain)    NSString *latTo;
@property(nonatomic, retain)   NSString *longTo;


- (id)initWithParam:(NSString *)name source:(NSString *)fbSources uniqueId:(NSString *)uniqueID date:(NSString *)tripDate 
        fromAddress:(NSString *)fromaddress toAddress:(NSString *)toaddress ;

-(id)initWithFeedBack:(NSString *)nibNameOrNil fbParam:(FeedBackReqParam *)fbParam bundle:(NSBundle *)nibBundle;
@end
