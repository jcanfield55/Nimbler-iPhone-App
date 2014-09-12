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
#import "Plan.h"

@implementation UberMgr

@synthesize managedObjectContext;
@synthesize rkUberClient;
@synthesize uberQueueDictionary;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        rkUberClient = [RKClient clientWithBaseURL:UBER_API_BASE_URL];
        
        NSString *header = [@"Token " stringByAppendingString:UBER_SERVER_TOKEN];
        [rkUberClient setValue:header  forHTTPHeaderField:@"Authorization"];
        uberQueueDictionary = [NSMutableDictionary dictionaryWithCapacity:6];
        
        managedObjectContext = moc;
    }
    return self;
}

// Requests a Uber itinerary given the provided parameters (to and from lat and long)
// When a response is received from UberAPI, the itinFromUberArray property of parameters will be updated accordingly
// This method should be called with each unique copy of PlanRequestParameters associated with a particular
// user request.  The UberAPI will only be called once, but the results will be updated in all
// PlanRequestParameters.
- (void)requestUberItineraryWithParameters:(PlanRequestParameters *)parameters
{
    NSMutableDictionary *priceParams = [[NSMutableDictionary alloc] init];
    [priceParams setObject:parameters.latitudeFROM forKey:UBER_START_LATITUDE];
    [priceParams setObject:parameters.longitudeFROM forKey:UBER_START_LONGITUDE];
    [priceParams setObject:parameters.latitudeTO forKey:UBER_END_LATITUDE];
    [priceParams setObject:parameters.longitudeTO forKey:UBER_END_LONGITUDE];
    
    NSString *parameterKey = [UberQueueEntry parameterKeyWithParams:priceParams];
    UberQueueEntry *queueEntry = [uberQueueDictionary objectForKey:parameterKey];
    bool isNewRequest = false;
    
    if (queueEntry && [[queueEntry createTime] timeIntervalSinceNow] < -UBER_MAX_RETAIN_SECONDS) {
        // Delete the queueEntry if it is older than the maximum retain time
        [uberQueueDictionary removeObjectForKey:parameterKey];
        queueEntry = nil;
    }
    if (!queueEntry) {  // no identical request in the dictionary, so create a new one
        queueEntry = [[UberQueueEntry alloc] init];
        [uberQueueDictionary setObject:queueEntry forKey:parameterKey];  // store in dictionary
        isNewRequest = true;
    }
    [queueEntry addPlanRequestParametersObject:parameters]; // Save the PlanRequestParameters so we can retreive them when the UberAPI comes back
    queueEntry.parameterKey = parameterKey;

    // Call the Uber API only if it is a new request
    if (isNewRequest) {
        [rkUberClient get:UBER_PRICE_URL queryParams:priceParams delegate:self];
        NSMutableDictionary *timeParams = priceParams;
        [rkUberClient get:UBER_TIME_URL queryParams:timeParams delegate:self];
    }
    else if (queueEntry.itinerary) {
        // If the UberAPI has already come back and there is an itinerary array already
        // Add it to parameters
        parameters.itinFromUberArray = [NSArray arrayWithObject:queueEntry.itinerary];
    }
}

// Callback from restkit with response
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    @try {
        
        NIMLOG_UBER(@"Resource_Path: %@",request.resourcePath);
        NIMLOG_UBER(@"Response: %@", response.bodyAsString);
        
        NSString *parameterKey = [UberQueueEntry parameterKeyWithParams:[(RKURL *)[request URL] queryParams]];
        UberQueueEntry *queueEntry = [uberQueueDictionary objectForKey:parameterKey];
        if (!queueEntry) {
            logError(@"UberMgr->didLoadResponse",
                     [NSString stringWithFormat:@"No queueEntry object found for parameterKey %@",
                      parameterKey]);
            return;  // Give up on the rest of the Uber returned objects
        }
        
        RKJSONParserJSONKit* parser1 = [RKJSONParserJSONKit new];
        NSDictionary *responseDictionary = [parser1 objectFromString:[response bodyAsString] error:nil];
        
        NSString *arrayKey;
        if ([request.resourcePath isEqualToString:UBER_PRICE_URL]) {   // Price request response
            arrayKey = UBER_PRICES_KEY;
            queueEntry.receivedPrices = true;
        }
        else if ([request.resourcePath isEqualToString:UBER_TIME_URL]) {   // Time request response
            arrayKey = UBER_TIMES_KEY;
            queueEntry.receivedTimes = true;
        }
        
        NSArray *responseArray = [responseDictionary objectForKey:arrayKey];
        
        if (responseArray) {
            for (NSDictionary* responseElement in responseArray) {
                NSString *productID = NSStringFromNSObject([responseElement objectForKey:UBER_PRODUCT_ID_KEY]);
                if (productID) {
                    if (!queueEntry.itinerary) {
                        // Create an itinerary for this queueEntry if there is not one already
                        queueEntry.itinerary = [NSEntityDescription insertNewObjectForEntityForName:@"ItineraryFromUber" inManagedObjectContext:self.managedObjectContext];
                    }
                    // Search for an existing itinerary with the same product id
                    LegFromUber *matchingLeg = nil;
                    for (Leg* leg in queueEntry.itinerary.legs) {
                        LegFromUber* uLeg = (LegFromUber *) leg;
                        if ([uLeg.uberProductID isEqualToString:productID]) {
                            matchingLeg = uLeg;
                            break;
                        }
                    }
                    if (!matchingLeg) {  // If no matching itinerary, create one
                        matchingLeg = [NSEntityDescription insertNewObjectForEntityForName:@"LegFromUber" inManagedObjectContext:self.managedObjectContext];
                        [queueEntry.itinerary addLegsObject:matchingLeg];
                        matchingLeg.uberProductID = productID;
                        matchingLeg.uberDisplayName = NSStringFromNSObject([responseElement objectForKey:UBER_DISPLAY_NAME_KEY]);

                    }
                    
                    // Now fill in matchingLeg with the data
                    if ([request.resourcePath isEqualToString:UBER_PRICE_URL]) {   // Price request response
                        matchingLeg.uberPriceEstimate = NSStringFromNSObject([responseElement objectForKey:UBER_PRICE_ESTIMATE_KEY]);
                        matchingLeg.uberHighEstimate = NSNumberFromNSObject([responseElement objectForKey:UBER_HIGH_ESTIMATE_KEY]);
                        matchingLeg.uberLowEstimate = NSNumberFromNSObject([responseElement objectForKey:UBER_LOW_ESTIMATE_KEY]);
                        matchingLeg.uberSurgeMultiplier = NSNumberFromNSObject([responseElement objectForKey:UBER_SURGE_MULTIPLIER_KEY]);
                    }
                    else if ([request.resourcePath isEqualToString:UBER_TIME_URL]) {   // Time request response
                        matchingLeg.uberTimeEstimateSeconds = NSNumberFromNSObject([responseElement objectForKey:UBER_TIME_ESTIMATE_KEY]);
                        
                        // Set startTime to be requestTime + time estimate
                        // TODO This assumes Uber cars always available with same timing & price as now.  Is this appropriate?
                        matchingLeg.startTime = [[[queueEntry.planRequestParamArray objectAtIndex:0] originalTripDate] dateByAddingTimeInterval:[matchingLeg.uberTimeEstimateSeconds intValue]];
                    }
                }
            }
            // If we have received all the responses back from Uber API
            if (queueEntry.receivedTimes && queueEntry.receivedPrices) {
                // Eliminate any itinerary that does not have a time and a price estimate
                NSSet *legSet = [NSSet setWithSet:queueEntry.itinerary.legs];
                for (Leg *leg in legSet) {
                    LegFromUber* uLeg = (LegFromUber *) leg;
                    if (uLeg.uberTimeEstimateSeconds && uLeg.uberPriceEstimate) {
                        // All is good, keep that leg
                    }
                    else { // leg does not have both time and price estimates, delete it
                        [queueEntry.itinerary removeLegsObject:uLeg]; // remove leg from itinerary
                        [managedObjectContext deleteObject:uLeg];  // Delete the leg
                    }
                }
                
                // Save Uber itineraries in all the request parameters if we have received both prices and times
                for (PlanRequestParameters* planReqParams in queueEntry.planRequestParamArray) {
                    planReqParams.itinFromUberArray = [NSArray arrayWithObject:queueEntry.itinerary];
                }
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"UberMgr->requestPlanWithParameters:", @"", exception);
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

// Prepares the URL for calling Uber app (if installed) or Uber website using the provided legFromUber
+(void)callUberWith:(LegFromUber *)legFromUber forPlan:(Plan *)plan {
    NSMutableDictionary *paramDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
    [paramDictionary setObject:legFromUber.uberProductID forKey:UBER_PRODUCT_ID_KEY];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"uber://"]]) {
        // Uber app is installed.  Deep link into app.
        [paramDictionary setObject:UBER_APP_ACTION_PICKUP forKey:UBER_APP_ACTION_KEY];
        [paramDictionary setObject:plan.fromLocation.lat forKey:UBER_APP_PICKUP_LATITUDE];
        [paramDictionary setObject:plan.fromLocation.lng forKey:UBER_APP_PICKUP_LONGITUDE];
        [paramDictionary setObject:plan.fromLocation.shortFormattedAddress forKey:UBER_APP_PICKUP_FORMATTED_ADDRESS];
        if (plan.fromLocation.nickName) {
            [paramDictionary setObject:plan.fromLocation.nickName forKey:UBER_APP_PICKUP_NICKNAME];
        }
        [paramDictionary setObject:plan.toLocation.lat forKey:UBER_APP_DROPOFF_LATITUDE];
        [paramDictionary setObject:plan.toLocation.lng forKey:UBER_APP_DROPOFF_LONGITUDE];
        [paramDictionary setObject:plan.toLocation.shortFormattedAddress forKey:UBER_APP_DROPOFF_FORMATTED_ADDRESS];
        if (plan.fromLocation.nickName) {
            [paramDictionary setObject:plan.toLocation.nickName forKey:UBER_APP_DROPOFF_NICKNAME];
        }
        
        NSString *uberAppURLString = [UBER_APP_BASE_URL appendQueryParams:paramDictionary];
        NSURL *uberAppURL = [NSURL URLWithString:uberAppURLString];
        [[UIApplication sharedApplication] openURL:uberAppURL];
    }
    else { // No Uber app. Open Mobile Website.
        [paramDictionary setObject:plan.fromLocation.lat forKey:UBER_WEB_PICKUP_LATITUDE];
        [paramDictionary setObject:plan.fromLocation.lng forKey:UBER_WEB_PICKUP_LONGITUDE];
        [paramDictionary setObject:plan.fromLocation.shortFormattedAddress forKey:UBER_WEB_PICKUP_FORMATTED_ADDRESS];
        if (plan.fromLocation.nickName) {
            [paramDictionary setObject:plan.fromLocation.nickName forKey:UBER_WEB_PICKUP_NICKNAME];
        }
        [paramDictionary setObject:plan.toLocation.lat forKey:UBER_WEB_DROPOFF_LATITUDE];
        [paramDictionary setObject:plan.toLocation.lng forKey:UBER_WEB_DROPOFF_LONGITUDE];
        [paramDictionary setObject:plan.toLocation.shortFormattedAddress forKey:UBER_WEB_DROPOFF_FORMATTED_ADDRESS];
        if (plan.fromLocation.nickName) {
            [paramDictionary setObject:plan.toLocation.nickName forKey:UBER_WEB_DROPOFF_NICKNAME];
        }
        [paramDictionary setObject:@"US" forKey:UBER_WEB_COUNTRY_CODE];
        [paramDictionary setObject:UBER_CLIENT_ID forKey:UBER_WEB_CLIENT_ID_KEY];
        
        NSString *uberWebURLString = [UBER_WEB_BASE_URL appendQueryParams:paramDictionary];
        NSURL *uberWebURL = [NSURL URLWithString:uberWebURLString];
        [[UIApplication sharedApplication] openURL:uberWebURL];   // Go to webview with designated URL
    }
}

@end
