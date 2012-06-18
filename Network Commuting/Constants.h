//
//  Constants.h
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/26/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#ifndef Nimbler_Constants_h
#define Nimbler_Constants_h


#endif

// #define TRIP_GENERATE_URL       @"http://23.23.210.156:8080/opentripplanner-api-webapp/ws/"
#define TRIP_GENERATE_URL       @"http://ec2-23-22-169-158.compute-1.amazonaws.com:8080/opentripplanner-api-webapp/ws/"

#define GEO_RESPONSE_URL        @"http://maps.googleapis.com/maps/api/geocode/"
// #define TRIP_PROCESS_URL        @"http://23.23.210.156:8080/TPServer/ws/"
#define TRIP_PROCESS_URL        @"http://ec2-23-22-169-158.compute-1.amazonaws.com:8080/TPServer/ws/"

#define TWITTER_SERARCH_URL     @"https://twitter.com/#!/search/realtime/TRAIN%20from%3Acaltrain%20OR%20from%3Acaltrain_news"
#define CALTRAIN_TWITTER_URL    @"https://twitter.com/#!/search/from%3Acaltrain%20OR%20from%3Acaltrain_news"
#define GEO_FROM                @"1"
#define GEO_TO                  @"1"
#define REVERSE_GEO_FROM        @"2"
#define REVERSE_GEO_TO          @"2"

#define FEEDBACK_TEXT           @"1"
#define FEEDBACK_AUDIO          @"2"
#define FEEDBACK_BOTH           @"3"
#define FB_RESPOSE_SUCCEES      @"FeedBack Send Successfully"
#define FB_RESPONSE_FAIL        @"Please Send Again"
#define FB_TITLE_MSG            @"Trip Feedback"

#define MIN_LAT                 @"36.791000000000004"
#define MIN_LONG                @"-123.4631719"
#define MAX_LAT                 @"38.7189988"
#define MAX_LONG                @"-121.025001"

#define FB_SOURCE_PLAN          @"1"
#define FB_SOURCE_ITINERARY     @"2"
#define FB_SOURCE_LEG           @"3"
#define FB_SOURCE_GENERAL       @"4"

#define TINY_FLOAT              0.00000001