//  Constants.h
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#ifndef Nimbler_Constants_h
#define Nimbler_Constants_h

#endif

#define TRIP_GENERATE_URL       @"http://23.23.210.156:8080/opentripplanner-api-webapp/ws/"
//#define TRIP_GENERATE_URL       @"http://ec2-23-22-169-158.compute-1.amazonaws.com:8080/opentripplanner-api-webapp/ws/"

#define GEO_RESPONSE_URL        @"http://maps.googleapis.com/maps/api/geocode/"

//#define TRIP_PROCESS_URL        @"http://23.23.210.156:8080/TPServer/ws/"
//#define TRIP_PROCESS_URL        @"http://ec2-23-22-169-158.compute-1.amazonaws.com:8080/TPServer/ws/"
#define TRIP_PROCESS_URL        @"http://192.168.2.148:8080/TPServer/ws/"

#define TWITTER_SERARCH_URL     @"https://twitter.com/#!/search/realtime/TRAIN%20from%3Acaltrain%20OR%20from%3Acaltrain_news"
#define CALTRAIN_TWITTER_URL    @"https://twitter.com/#!/search/from%3Acaltrain%20OR%20from%3Acaltrain_news"

#define GEO_FROM                @"1"
#define GEO_TO                  @"1"
#define REVERSE_GEO_FROM        @"2"
#define REVERSE_GEO_TO          @"2"

#define MIN_LAT                 @"36.791000000000004"
#define MIN_LONG                @"-123.4631719"
#define MAX_LAT                 @"38.7189988"
#define MAX_LONG                @"-121.025001"

#define ON_TIME                 1
#define DELAYED                 2
#define EARLY                   3
#define EARLIER                 4
#define ITINERARY_TIME_SLIPPAGE 5

#define ALERT_OFF               @"1"
#define ALERT_ON                @"2"
#define ALERT_URGENT            @"3"

// Preload file variables
#define PRELOAD_LOCATION_FILE   @"caltrain-station.json"
#define PRELOAD_VERSION_NUMBER  @"1.02"
#define PRELOAD_TEST_ADDRESS    @"San Martin Caltrain, San Martin, CA 95046, USA" // station for testing version number
#define TOFROM_LIST_TYPE        @"TOFROM_LIST" // Location type indicating a ToFromList

// Locations behavior
#define TOFROM_FREQUENCY_VISIBILITY_CUTOFF 0.99

// LegMapView
#define LEGMAP_DOT_IMAGE_FILE               @"mapDot"

// Request timer Count
#define TWEET_COUNT_POLLING_INTERVAL   60.0
#define TIMER_SMALL_REQUEST_DELAY      1.0
#define TIMER_MEDIUM_REQUEST_DELAY     30.0
#define TIMER_STANDARD_REQUEST_DELAY   60.0

// errorCodes from TPResponce
#define RESPONSE_SUCCESSFULL            105
#define RESPONSE_DATA_NOT_EXIST         107
#define RESPONSE_INVALID_REQUEST        106

// Float thresholds 
#define TINY_FLOAT                      0.000001
