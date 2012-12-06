//
//  GtfsAgency.h
//  Nimbler Caltrain
//
//  Created by macmini on 06/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GtfsAgency : NSManagedObject

@property (nonatomic, retain) NSString * agencyID;
@property (nonatomic, retain) NSString * agencyName;
@property (nonatomic, retain) NSString * agencyURL;
@property (nonatomic, retain) NSString * agencyTimeZone;
@property (nonatomic, retain) NSString * agencyPhone;
@property (nonatomic, retain) NSString * agencyLang;

@end
