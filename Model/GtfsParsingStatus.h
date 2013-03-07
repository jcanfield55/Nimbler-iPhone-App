//
//  GtfsParsingStatus.h
//  Nimbler SF
//
//  Created by John Canfield on 3/5/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define GTFS_PARSING_STATUS_SUBMITTED @"Submitted"  // Means request for trip and stopTime data has been submitted to the server, but not yet returned / process
#define GTFS_PARSING_STATUS_AVAILABLE @"Available" // Means Gtfs data for trip and stopTime is fully available
#define GTFS_PARSING_STATUS_NONE @"None"  // Means data not available and request not yet submitted

@interface GtfsParsingStatus : NSManagedObject

// Agency FeedId and route combined together in one string like @"%@_%@" (example 1_KT)
@property (nonatomic, retain) NSString* agencyFeedIdAndRoute;

// One of the above status strings
@property (nonatomic, retain) NSString* status;

// Date & time that the request for gtfs data was submitted
@property (nonatomic, retain) NSDate* dateRequested;

// True if request has been made for Gtfs data but data not yet received /parsed
-(BOOL)hasGtfsDownloadRequestBeenSubmitted;

// True if Gtfs data is fully available
-(BOOL)isGtfsDataAvailable;

// Sets that a Gtfs Request has been made
-(void)setGtfsRequestMade;

// Sets that Gtfs data is fully available
-(void)setGtfsDataAvailable;

@end
