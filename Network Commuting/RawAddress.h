//
//  RawAddress.h
//  Network Commuting
//
//  Created by John Canfield on 2/9/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface RawAddress : NSManagedObject {
    NSString *rawAddressString;
    Location *location;
}

@property (nonatomic, strong) NSString * rawAddressString;
@property (nonatomic, weak) Location *location;

@end
