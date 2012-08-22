//
//  KeyObjectPair.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/21/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

// General Purpose CoreData storage pair for objects that meet NSCoding protocol
// See KeyObjectStore wrapper class for methods to create and retrieve objects
//
#import <CoreData/CoreData.h>

@interface KeyObjectPair : NSManagedObject

@property (nonatomic, retain) NSString* key;
@property (nonatomic, retain) id object;  // must conform to NSEncoding protocol in order to be stored

@end
