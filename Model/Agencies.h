//
//  Agencies.h
//  Nimbler SF
//
//  Created by macmini on 23/04/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@interface Agencies : NSObject<RKRequestDelegate>

@property(strong, nonatomic) RKClient* rkTpClient;   // RestKit client for TP Server

@property (nonatomic, strong) NSDictionary *agenciesDictionary;
@property (nonatomic, strong) NSDictionary *excludeButtonHandlingByAgencyDictionary;
@property (nonatomic, strong) NSDictionary *agencyButtonNameByAgencyDictionary;
@property (nonatomic, strong) NSDictionary *agencyShortNameByAgencyIdDictionary;
@property (nonatomic, strong) NSDictionary *agencyFeedIdFromAgencyNameDictionary;
@property (nonatomic, strong) NSDictionary *agencyNameFromAgencyFeedIdDictionary;
@property (nonatomic, strong) NSString *supportedFeedIdString;

@property (nonatomic, strong) NSDictionary *advisoriesChoices;

- (void)updateAgenciesFromServer;

// returns the singleton value.
+ (Agencies *)agencies;
@end
