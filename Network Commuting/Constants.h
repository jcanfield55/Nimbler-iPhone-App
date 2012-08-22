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

#define TRIP_PROCESS_URL        @"http://23.23.210.156:8080/TPServer/ws/"

//#define TRIP_PROCESS_URL        @"http://192.168.2.148:8080/TPServer/ws/"

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

// Testflight App Analytics and logging
#define TEST_FLIGHT_ENABLED 0  // If 0, then do not include testFlightApp at all 
#define TEST_FLIGHT_UIDS 1  // If 1, then testFlightApp will collect device UIDs, if 0, it will not

// NSUserDefaults keys
#define USER_PREFERANCE                    @"UserPreference"
#define PREFS_IS_PUSH_ENABLE               @"PrefsIsPushEnable"
#define PREFS_PUSH_NOTIFICATION_THRESHOLD  @"PrefsPushNotificationThreshold"
#define PREFS_MAX_WALK_DISTANCE            @"PrefsMaxWalkDistance"
#define ENABLE_STANDARDNOTIFICATION_SOUND       @"enableStdNotifSound"
#define ENABLE_URGENTNOTIFICATION_SOUND         @"enableUrgntNotifSound"

// UserPreferernce defaults
#define PREFS_DEFAULT_IS_PUSH_ENABLE                YES
#define PREFS_DEFAULT_PUSH_NOTIFICATION_THRESHOLD   3
#define PREFS_DEFAULT_MAX_WALK_DISTANCE             0.75

// Flurry analytics and logging
#define FLURRY_ENABLED                  0

// Flurry events
#define FLURRY_APPDELEGATE_START            @"Start of App Delegate"
#define FLURRY_CURRENT_LOCATION_AVAILABLE   @"Current Location Available"
#define FLURRY_PUSH_AVAILABLE               @"Push Notification Available"
#define FLURRY_TOFROMVC_APPEAR              @"ToFromView appear"
#define FLURRY_TOFROMTABLE_SELECT_ROW       @"ToFromTable select row"
#define FLURRY_TOFROMTABLE_NEW_EDIT_MODE    @"ToFrom new edit mode"
#define FLURRY_TOFROMTABLE_CALTRAIN_LIST    @"ToFrom selected Caltrain list"
#define FLURRY_TOFROM_SWAP_LOCATION         @"ToFrom swap location"
#define FLURRY_TOFROMTABLE_GEOCODE_REQUEST  @"ToFrom Geocode request"
#define FLURRY_GEOCODE_RESULTS_ONE          @"Geocode: 1 result"
#define FLURRY_GEOCODE_RESULTS_MULTIPLE     @"Geocode: multiple results"
#define FLURRY_GEOCODE_RESULTS_NONE         @"Geocode: no results"
#define FLURRY_GEOCODE_RESULTS_NONE_IN_REGION @"Geocode: none in region"
#define FLURRY_GEOCODE_OVER_GOOGLE_QUOTA    @"Geocode: over Google quota"
#define FLURRY_GEOCODE_OTHER_ERROR          @"Geocode: other error"
#define FLURRY_DATE_PICKER_APPEAR           @"DatePicker appear"
#define FLURRY_DATE_PICKER_CANCEL           @"DatePicker cancel"
#define FLURRY_DATE_PICKER_NEW_DATE         @"DatePicker new date selected"
#define FLURRY_LOCATION_PICKER_APPEAR       @"LocationPicker appear"
#define FLURRY_ROUTE_REQUESTED              @"Route Requested"
#define FLURRY_ROUTE_OPTIONS_APPEAR         @"RouteOptions appear"
#define FLURRY_ROUTE_SELECTED               @"Route selected"
#define FLURRY_ROUTE_DETAILS_APPEAR         @"RouteDetails appear"
#define FLURRY_ROUTE_DETAILS_NEWITINERARY_NUMBER @"RouteDetails NewItinerary #"
#define FLURRY_SETTINGS_APPEAR              @"Settings appear"
#define FLURRY_FEEDBACK_APPEAR              @"Feedback appear"
#define FLURRY_FEEDBACK_RECORD              @"Feedback record button"
#define FLURRY_FEEDBACK_PLAY                @"Feedback play button"
#define FLURRY_FEEDBACK_PAUSE               @"Feedback pause button"
#define FLURRY_FEEDBACK_STOP                @"Feedback stop button"
#define FLURRY_FEEDBACK_SUBMIT              @"Feedback submit"
#define FLURRY_ADVISORIES_APPEAR            @"Advisories appear"

// Flurry parameter names
#define FLURRY_NOTIFICATION_TOKEN           @"(Notification Token)"
#define FLURRY_TO_SELECTED_ADDRESS          @"(To Selected Address)"
#define FLURRY_FROM_SELECTED_ADDRESS        @"(From Selected Address)"
#define FLURRY_TOFROM_WHICH_TABLE           @"(ToFrom which table)"
#define FLURRY_SELECTED_ROW_NUMBER          @"(Table selected row #)"
#define FLURRY_NUMBER_OF_GEOCODES           @"(Number of geocodes)"
#define FLURRY_GEOCODE_ERROR                @"(Geocode error)"
#define FLURRY_GEOCODE_RAWADDRESS           @"(Geocode raw address)"
#define FLURRY_FORMATTED_ADDRESS            @"(Formatted Address)"
#define FLURRY_NEW_DATE                     @"(New date)"
#define FLURRY_SELECTED_DEPARTURE_TIME      @"(Selected departure time)"
#define FLURRY_EDIT_MODE_VALUE              @"(Edit mode value)"
#define FLURRY_USER_EMAIL                   @"(User email)"
#define FLURRY_FEEDBACK_TEXT                @"(Feedback text)"
#define FLURRY_SETTING_WALK_DISTANCE        @"(Settings walk distance)"
#define FLURRY_SETTING_ALERT_COUNT          @"(Settings alert count)"

/*  Template code for inserting Flurry logging
 #if FLURRY_ENABLED
 NSDictionary *params = [NSDictionary 
 dictionaryWithObjectsAndKeys:@"", @"", nil];
 [Flurry logEvent: withParameters:params];
 #endif
 */

// Locations behavior
#define TOFROM_FREQUENCY_VISIBILITY_CUTOFF 0.99

// LegMapView
#define LEGMAP_DOT_IMAGE_FILE          @"img_mapDot"

// KeyObjectStore Keys (if strings are changed, stored data will be inaccessible)
#define TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY      @"TransitCalendarLastGTFSLoadDateByAgency"
#define TR_CALENDAR_SERVICE_BY_WEEKDAY_ARRAY           @"TransitCalendarServiceByWeekdayArray"
#define TR_CALENDAR_DATES_DICTIONARY                   @"TransitCalendarDatesDictionary"


// Request timer Count
#define TWEET_COUNT_POLLING_INTERVAL   120.0
#define TIMER_SMALL_REQUEST_DELAY      1.0
#define TIMER_MEDIUM_REQUEST_DELAY     30.0
#define TIMER_STANDARD_REQUEST_DELAY   60.0

// errorCodes from TPResponce
#define RESPONSE_SUCCESSFULL            105
#define RESPONSE_DATA_NOT_EXIST         107
#define RESPONSE_INVALID_REQUEST        106

// Float thresholds 
#define TINY_FLOAT                      0.000001
