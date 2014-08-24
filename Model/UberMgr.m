//
//  UberMgr.m
//  Nimbler SF
//
//  Created by John Canfield on 8/21/14.
//  Copyright (c) 2014 Nimbler World Inc. All rights reserved.
//

// Used for calling Uber API from App and generating Uber itineraries

#import "UberMgr.h"
#import "Logging.h"
#import "UtilityFunctions.h"
#import <Restkit/RKJSONParserJSONKit.h>

@implementation UberMgr

@synthesize managedObjectContext;
@synthesize rkUberClient;
@synthesize itineraryArray;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        rkUberClient = [RKClient clientWithBaseURL:UBER_BASE_URL];
        
        NSString *header = [@"Token " stringByAppendingString:UBER_SERVER_TOKEN];
        [rkUberClient setValue:header  forHTTPHeaderField:@"Authorization"];
        itineraryArray = [NSMutableArray arrayWithCapacity:6];
    }
    return self;
}

// Requests a Uber itinerary given the provided parameters (to and from lat and long)
- (void)requestUberItineraryWithParameters:(PlanRequestParameters *)parameters
{
    self.currentRequest = parameters;
    [self.itineraryArray removeAllObjects]; // Clear the itinerary array
    
    NSMutableDictionary *priceParams = [[NSMutableDictionary alloc] init];
    [priceParams setObject:parameters.latitudeFROM forKey:UBER_START_LATITUDE];
    [priceParams setObject:parameters.longitudeFROM forKey:UBER_START_LONGITUDE];
    [priceParams setObject:parameters.latitudeTO forKey:UBER_END_LATITUDE];
    [priceParams setObject:parameters.longitudeFROM forKey:UBER_END_LONGITUDE];

    [rkUberClient get:UBER_PRICE_URL queryParams:priceParams delegate:self];
    
    NSMutableDictionary *timeParams = priceParams;
    [rkUberClient get:UBER_TIME_URL queryParams:timeParams delegate:self];
    
}

// Callback from restkit with response
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    @try {
        // TODO: find way to ensure this is in response to currentParameters
        
        NIMLOG_UBER(@"Resource_Path: %@",request.resourcePath);
        NIMLOG_UBER(@"Response: %@", response.bodyAsString);
        
        RKJSONParserJSONKit* parser1 = [RKJSONParserJSONKit new];
        NSDictionary *responseDictionary = [parser1 objectFromString:[response bodyAsString] error:nil];
        
        NSString *arrayKey;
        if ([request.resourcePath isEqualToString:UBER_PRICE_URL]) {   // Price request response
            arrayKey = UBER_PRICES_KEY;
        }
        else if ([request.resourcePath isEqualToString:UBER_TIME_URL]) {   // Time request response
            arrayKey = UBER_TIMES_KEY;
        }
        
        NSArray *responseArray = [responseDictionary objectForKey:arrayKey];
        
        if (responseArray) {
            for (NSDictionary* responseElement in responseArray) {
                NSString *productID = [responseElement objectForKey:UBER_PRODUCT_ID_KEY];
                if (productID) {
                    // Search for an existing itinerary with the same product id
                    ItineraryFromUber *matchingItin = nil;
                    for (ItineraryFromUber* itin in self.itineraryArray) {
                        if ([itin.uberProductID isEqualToString:productID]) {
                            matchingItin = itin;
                            break;
                        }
                    }
                    if (!matchingItin) {  // If no matching itinerary, create one
                        matchingItin = [NSEntityDescription insertNewObjectForEntityForName:@"ItineraryFromUber" inManagedObjectContext:self.managedObjectContext];
                        [self.itineraryArray addObject:matchingItin]; 
                        matchingItin.uberProductID = productID;
                        matchingItin.uberDisplayName = [responseElement objectForKey:UBER_DISPLAY_NAME_KEY];

                    }
                    
                    // Now fill in matchingItin with the data
                    if ([request.resourcePath isEqualToString:UBER_PRICE_URL]) {   // Price request response
                        matchingItin.uberPriceEstimate = [responseElement objectForKey:UBER_PRICE_ESTIMATE_KEY];
                        matchingItin.uberHighEstimate = [[responseElement objectForKey:UBER_HIGH_ESTIMATE_KEY] intValue];
                        matchingItin.uberLowEstimate = [[responseElement objectForKey:UBER_LOW_ESTIMATE_KEY] intValue];
                        matchingItin.uberSurgeMultiplier = [[responseElement objectForKey:UBER_SURGE_MULTIPLIER_KEY] floatValue];
                    }
                    else if ([request.resourcePath isEqualToString:UBER_TIME_URL]) {   // Time request response
                        matchingItin.uberTimeEstimateSeconds = [[responseElement objectForKey:UBER_TIME_ESTIMATE_KEY] intValue];
                        
                        // Set startTime to be requestTime + time estimate
                        // TODO This assumes Uber cars always available with same timing & price as now.  Is this appropriate?
                        matchingItin.startTime = [[self.currentRequest originalTripDate] dateByAddingTimeInterval:matchingItin.uberTimeEstimateSeconds];
                    }
                }
            }

            
        }
    }
    @catch (NSException *exception) {
        logException(@"PlanStore->requestPlanWithParameters:", @"", exception);
    }

}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    if ([[error localizedDescription] rangeOfString:@"client is unable to contact the resource"].location != NSNotFound) {
        logEvent(FLURRY_UBER_NO_NETWORK,
                 FLURRY_RK_RESPONSE_ERROR, [error localizedDescription],
                 nil, nil, nil, nil, nil, nil);
    } else {
        logEvent(FLURRY_UBER_OTHER_ERROR,
                 FLURRY_RK_RESPONSE_ERROR, [error localizedDescription],
                 nil, nil, nil, nil, nil, nil);
    }
}
@end
