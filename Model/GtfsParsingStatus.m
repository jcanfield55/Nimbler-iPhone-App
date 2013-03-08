//
//  GtfsParsingStatus.m
//  Nimbler SF
//
//  Created by John Canfield on 3/5/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#import "GtfsParsingStatus.h"


@implementation GtfsParsingStatus

@dynamic agencyFeedIdAndRoute;
@dynamic status;
@dynamic dateRequested;
@dynamic requestingPlan;

// True if request has been made for Gtfs data but data not yet received /parsed
-(BOOL)hasGtfsDownloadRequestBeenSubmitted
{
    if ([self.dateRequested timeIntervalSinceNow] < -(10*60)) { // if more than 10 minutes
        return false;  // treat as if no request has been made
        
    }
    return [self.status isEqualToString:GTFS_PARSING_STATUS_SUBMITTED];
}

// True if Gtfs data is fully available
-(BOOL)isGtfsDataAvailable
{
    return [self.status isEqualToString:GTFS_PARSING_STATUS_AVAILABLE];
}

// Sets that a Gtfs Request has been made
-(void)setGtfsRequestMadeFor:(Plan *)plan
{
    self.requestingPlan = plan;
    [self setDateRequested:[NSDate date]];
    [self setStatus:GTFS_PARSING_STATUS_SUBMITTED];
}

// Sets that Gtfs data is fully available
-(void)setGtfsDataAvailable
{
    [self setStatus:GTFS_PARSING_STATUS_AVAILABLE];
}


@end
