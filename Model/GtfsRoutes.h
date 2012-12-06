//
//  GtfsRoutes.h
//  Nimbler Caltrain
//
//  Created by macmini on 06/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsAgency;

@interface GtfsRoutes : NSManagedObject

@property (nonatomic, retain) NSString * routeID;
@property (nonatomic, retain) NSString * routeShortName;
@property (nonatomic, retain) NSString * routeLongname;
@property (nonatomic, retain) NSString * routeDesc;
@property (nonatomic, retain) NSString * routeType;
@property (nonatomic, retain) NSString * routeURL;
@property (nonatomic, retain) NSString * routeColor;
@property (nonatomic, retain) NSString * routeTextColor;
@property (nonatomic, retain) GtfsAgency *agency;

@end
