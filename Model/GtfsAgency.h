//
//  GtfsAgency.h
//  Nimbler Caltrain
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GtfsRoutes;

@interface GtfsAgency : NSManagedObject

@property (nonatomic, retain) NSString * agencyID;
@property (nonatomic, retain) NSString * agencyName;
@property (nonatomic, retain) NSString * agencyURL;
@property (nonatomic, retain) NSSet *routes;
@end

@interface GtfsAgency (CoreDataGeneratedAccessors)

- (void)addRoutesObject:(GtfsRoutes *)value;
- (void)removeRoutesObject:(GtfsRoutes *)value;
- (void)addRoutes:(NSSet *)values;
- (void)removeRoutes:(NSSet *)values;
@end
