//
//  OTPLeg.h
//  Nimbler Caltrain
//
//  Created by macmini on 30/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Leg.h"

@interface OTPLeg : Leg

@property (nonatomic, retain) NSNumber * bogusNonTransitLeg;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSNumber * interlineWithPreviousLeg;
@property (nonatomic, retain) NSNumber * legGeometryLength;
@property (nonatomic, retain) NSString * legGeometryPoints;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSString * tripShortName;
@property (nonatomic, retain) NSString *arrivalTime;
@property (nonatomic, retain) NSString *arrivalFlag;
@property (nonatomic, retain) NSString *timeDiffInMins;

+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType;
+(NSDictionary *)agencyDisplayNameByAgencyId;
- (NSString *)summaryTextWithTime:(BOOL)includeTime;  // Returns a single-line summary of the leg useful for RouteOptionsView details
- (NSString *)directionsTitleText:(LegPositionEnum)legPosition;
- (NSString *)directionsDetailText:(LegPositionEnum)legPosition;
- (NSString *)ncDescription;
- (BOOL)isWalk;
- (BOOL)isBus;
- (BOOL)isHeavyTrain; // Note: legs that are isHeavyTrain=true are also isTrain=true
- (BOOL)isTrain;

// True if the main characteristics of referring Leg is equal to leg0
- (BOOL)isEqualInSubstance:(Leg *)leg0;
@end
