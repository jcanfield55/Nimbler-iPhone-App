// Constants.h
// Nimbler
//
// Created by Sitanshu Joshi on 5/26/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#ifndef Nimbler_Constants_h
#define Nimbler_Constants_h

#endif

#define AUTOMATED_TESTING_SKIP_NCAPPDELEGATE 0 // if 1, skips nc_AppDelegate didFinishLaunchingWithOptions so we get a clean tests run

#define TRIP_GENERATE_URL     @"http://23.23.210.156:8080/opentripplanner-api-webapp/ws/"
//#define TRIP_GENERATE_URL @"http://ec2-23-22-169-158.compute-1.amazonaws.com:8080/opentripplanner-api-webapp/ws/"
#define GEO_RESPONSE_URL      @"http://maps.googleapis.com/maps/api/geocode/"
#define TEST_GEO_RESPONSE_URL  @"http://localhost:8080/TPServer/ws/mockgeolocation/"

#define TRIP_PROCESS_URL    @"http://23.23.210.156:8080/TPServer/ws/"
//#define TRIP_PROCESS_URL      @"http://192.168.2.196:8080/TPServer/ws/"
#define TEST_TRIP_PROCESS_URL @"http://localhost:8080/TPServer/ws/"  // TP server for automated tests

// Core Data database filename
#define COREDATA_DB_FILENAME    @"store101.data"
#define TEST_COREDATA_DB_FILENAME  @"testDataStore.data" // For automated tests

#define TWITTER_SERARCH_URL    @"https://twitter.com/#!/search/realtime/TRAIN%20from%3Acaltrain%20OR%20from%3Acaltrain_news"
#define CALTRAIN_TWITTER_URL   @"https://twitter.com/#!/search/from%3Acaltrain%20OR%20from%3Acaltrain_news"

#define GEO_FROM          @"1"
#define GEO_TO            @"1"
#define REVERSE_GEO_FROM  @"2"
#define REVERSE_GEO_TO    @"2"
#define PREDEFINE_TYPE    @"3"

#define MIN_LAT           @"36.791000000000004"
#define MIN_LONG          @"-123.4631719"
#define MAX_LAT           @"38.7189988"
#define MAX_LONG          @"-121.025001"

#define ON_TIME           1
#define DELAYED           2
#define EARLY             3
#define EARLIER           4
#define ITINERARY_TIME_SLIPPAGE 5

#define ALERT_OFF        @"1"
#define ALERT_ON         @"2"
#define ALERT_URGENT     @"3"

// Preload file variables
#define CALTRAIN_PRELOAD_LOCATION_FILE     @"caltrain.json"
#define BART_PRELOAD_LOCATION_FILE         @"bart.json"
#define ACTRANSIT_PRELOAD_LOCATION_FILE         @"ac-transit.json"
#define SFMUNI_PRELOAD_LOCATION_FILE         @"sf-muni.json"

#define CALTRAIN_BUNDLE_IDENTIFIER         @"com.Nimbler.Nimbler-Caltrain"
#define BART_BUNDLE_IDENTIFIER         @"com.Nimbler.Nimbler-BART"

#define CALTRAIN_PRELOAD_VERSION_NUMBER    @"1.100"
#define CALTRAIN_PRELOAD_TEST_ADDRESS    @"San Martin Caltrain, San Martin, CA 95046, USA"

#define BART_PRELOAD_VERSION_NUMBER      @"1.052"
#define BART_PRELOAD_TEST_ADDRESS        @"24th St Mission BART, San Francisco, CA 94110, USA"

#define ACTRANSIT_PRELOAD_VERSION_NUMBER      @"1.500"
#define ACTRANSIT_PRELOAD_TEST_ADDRESS        @"Coelho Dr & Mooney Av"

#define SFMUNI_PRELOAD_VERSION_NUMBER      @"1.800"
#define SFMUNI_PRELOAD_TEST_ADDRESS        @"Powell St & O'Farrell St"

#define TOFROM_LIST_TYPE          @"TOFROM_LIST" // Location type indicating a ToFromList

// Current Location
#define CURRENT_LOCATION_STARTING_FROM_FREQUENCY 7.0

// Testflight App Analytics and logging
#define TEST_FLIGHT_ENABLED 0 // If 0, then do not include testFlightApp at all
#define TEST_FLIGHT_UIDS 1 // If 1, then testFlightApp will collect device UIDs, if 0, it will not

#define LAST_SELECTED_TAB_INDEX       @"lastSelectedTabIndex"
#define LAST_TO_LOCATION              @"lastToLocation"
#define LAST_FROM_LOCATION            @"lastFromLocation"
#define LAST_REQUEST_REVERSE_GEO      @"lastRequestReverseGeoLocation"
#define APPLICATION_BUNDLE_IDENTIFIER  @"appBundleId"
#define APPLICATION_TYPE               @"appType"

// NSUserDefaults keys
#define USER_PREFERANCE                   @"UserPreference"
#define PREFS_DATE_LAST_SUCCESSFUL_SAVE  @"PrefsDateLastSuccessfulSave"
#define PREFS_DATE_LAST_CHANGE            @"PrefsDateLastChange"
#define PREFS_IS_PUSH_ENABLE              @"PrefsIsPushEnable"
#define PREFS_PUSH_NOTIFICATION_THRESHOLD @"PrefsPushNotificationThreshold"
#define PREFS_MAX_WALK_DISTANCE           @"PrefsMaxWalkDistance"
#define ENABLE_STANDARDNOTIFICATION_SOUND @"enableStdNotifSound"
#define ENABLE_URGENTNOTIFICATION_SOUND   @"enableUrgntNotifSound"
#define ENABLE_SFMUNI_ADV   @"enableSfMuniAdv"
#define ENABLE_BART_ADV     @"enableBartAdv"
#define ENABLE_ACTRANSIT_ADV @"enableAcTransitAdv"
#define ENABLE_CALTRAIN_ADV @"enableCaltrainAdv"
#define NOTIF_TIMING_MORNING @"notifTimingMorning"
#define NOTIF_TIMING_MIDDAY  @"notifTimingMidday"
#define NOTIF_TIMING_EVENING @"notifTimingEvening"
#define NOTIF_TIMING_NIGHT   @"notifTimingNight"
#define NOTIF_TIMING_WEEKEND @"notifTimingWeekend"
#define TRANSIT_MODE_SELECTED    @"transitMode"
#define PREFS_MAX_BIKE_DISTANCE  @"maxBikeDistance"
#define PREFS_BIKE_FAST_VS_SAFE  @"prefsBikeFastVsSafe"
#define PREFS_BIKE_FAST_VS_FLAT  @"prefsBikeFastVsFlat"
#define BIKE_TRIANGLE_FLAT          @"bikeTriangleFlat"
#define BIKE_TRIANGLE_BIKE_FRIENDLY @"bikeTriangleBikeFriendly"
#define BIKE_TRIANGLE_QUICK         @"bikeTriangleQuick"
#define MAX_BIKE_DISTANCE           @"maxBikeDist"

// SettingInfo Parameter for server (where different than for saving in NSUserDefaults)
#define ALERT_COUNT           @"alertCount"
#define MAXIMUM_WALK_DISTANCE @"maxDistance"
#define UPDATE_SETTING_REQ    @"users/preferences/update"

// UserPreferernce (user settings) defaults, max, and min
#define PREFS_DEFAULT_IS_PUSH_ENABLE YES
#define PREFS_DEFAULT_PUSH_NOTIFICATION_THRESHOLD 5
#define PREFS_DEFAULT_MAX_WALK_DISTANCE 0.75

#define URGENT_NOTIFICATION_DEFAULT_VALUE   1
#define STANDARD_NOTIFICATION_DEFAULT_VALUE 2

#define TRANSIT_MODE_TRANSIT_ONLY 2
#define TRANSIT_MODE_BIKE_ONLY 4
#define TRANSIT_MODE_BIKE_AND_TRANSIT 5
#define TRANSIT_MODE_DEFAULT 2

#define ENABLE_STANDARDNOTIF_SOUND_DEFAULT FALSE
#define ENABLE_URGENTNOTIF_SOUND_DEFAULT   TRUE
#define ENABLE_SFMUNI_ADV_DEFAULT FALSE
#define ENABLE_BART_ADV_DEFAULT FALSE
#define ENABLE_ACTRANSIT_ADV_DEFAULT FALSE
#define ENABLE_CALTRAIN_ADV_DEFAULT TRUE
#define NOTIF_TIMING_MORNING_DEFAULT TRUE
#define NOTIF_TIMING_MIDDAY_DEFAULT FALSE
#define NOTIF_TIMING_EVENING_DEFAULT TRUE
#define NOTIF_TIMING_NIGHT_DEFAULT FALSE
#define NOTIF_TIMING_WEEKEND_DEFAULT FALSE

#define PUSH_FREQUENCY_DEFAULT_VALUE          5
#define PUSH_FREQUENCY_MIN_VALUE              1
#define PUSH_FREQUENCY_MAX_VALUE              10
#define MAX_WALK_DISTANCE_DEFAULT_VALUE       0.75
#define MAX_WALK_DISTANCE_MIN_VALUE           0.25
#define MAX_WALK_DISTANCE_MAX_VALUE           2.5
#define BIKE_PREFERENCE_MIN_VALUE             0
#define BIKE_PREFERENCE_MAX_VALUE             1
#define BIKE_PREFERENCE_DEFAULT_VALUE         0.5
#define MAX_BIKE_DISTANCE_DEFAULT_VALUE       5
#define MAX_BIKE_DISTANCE_MIN_VALUE           1
#define MAX_BIKE_DISTANCE_MAX_VALUE           20

// Flurry analytics and logging
#define FLURRY_ENABLED 0

// Flurry events
#define FLURRY_APPDELEGATE_START @"Start of App Delegate"
#define FLURRY_CURRENT_LOCATION_AVAILABLE @"Current Location Available"
#define FLURRY_PRELOADED_FILE @"Preloaded file"
#define FLURRY_PUSH_AVAILABLE @"Push Notification Available"
#define FLURRY_TOFROMVC_APPEAR @"ToFromView appear"
#define FLURRY_TOFROMTABLE_SELECT_ROW @"ToFromTable select row"
#define FLURRY_TOFROMTABLE_NEW_EDIT_MODE @"ToFrom new edit mode"
#define FLURRY_TOFROMTABLE_CALTRAIN_LIST @"ToFrom selected Caltrain list"
#define FLURRY_TOFROM_SWAP_LOCATION @"ToFrom swap location"
#define FLURRY_TOFROMTABLE_GEOCODE_REQUEST @"ToFrom Geocode request"
#define FLURRY_GEOCODE_RESULTS_ONE @"Geocode: 1 result"
#define FLURRY_GEOCODE_RESULTS_MULTIPLE @"Geocode: multiple results"
#define FLURRY_GEOCODE_RESULTS_NONE @"Geocode: no results"
#define FLURRY_GEOCODE_IOS_PARTIAL_RESULTS_NONE @"Geocode: IOS partial, no results"
#define FLURRY_GEOCODE_RESULTS_NONE_IN_REGION @"Geocode: none in region"
#define FLURRY_GEOCODE_OVER_GOOGLE_QUOTA @"Geocode error: over Google quota"
#define FLURRY_GEOCODE_NO_NETWORK @"Geocode error: no network connection"
#define FLURRY_GEOCODE_OTHER_ERROR @"Geocode error: other error"
#define FLURRY_DATE_PICKER_APPEAR @"DatePicker appear"
#define FLURRY_DATE_PICKER_CANCEL @"DatePicker cancel"
#define FLURRY_DATE_PICKER_NEW_DATE @"DatePicker new date selected"
#define FLURRY_LOCATION_PICKER_APPEAR @"LocationPicker appear"
#define FLURRY_ROUTE_REQUESTED @"Route Requested"
#define FLURRY_MAPKIT_DIRECTIONS_REQUEST @"MapKit Directions Request"
#define FLURRY_ROUTE_FROM_CACHE @"Route retrieved from cache"
#define FLURRY_ROUTE_NOT_IN_CACHE @"Route not in cache"
#define FLURRY_ROUTE_NO_NETWORK @"No network connection for retrieving Plan"
#define FLURRY_CURRENT_LOCATION_NOT_IN_SUPPORTED_REGION @"Route request not in supported region"
#define FLURRY_ROUTE_TO_FROM_SAME @"Route request to & from location identical"
#define FLURRY_ROUTE_NOT_AVAILABLE_THAT_TIME @"Route not available that time"
#define FLURRY_ROUTE_NO_MATCHING_ITINERARIES @"Route no matching itineraries"
#define FLURRY_ROUTE_OTHER_ERROR @"RK Error when retrieving Plan"
#define FLURRY_ROUTE_OPTIONS_APPEAR @"RouteOptions appear"
#define FLURRY_ROUTE_SELECTED @"Route selected"
#define FLURRY_ROUTE_DETAILS_APPEAR @"RouteDetails appear"
#define FLURRY_ROUTE_DETAILS_NEWITINERARY_NUMBER @"RouteDetails NewItinerary #"
#define FLURRY_SETTINGS_APPEAR @"Settings appear"
#define FLURRY_SETTINGS_SUBMITTED1 @"Settings submitted"
#define FLURRY_SETTINGS_SUBMITTED2 @"Settings submitted 2"
#define FLURRY_FEEDBACK_APPEAR @"Feedback appear"
#define FLURRY_FEEDBACK_RECORD @"Feedback record button"
#define FLURRY_FEEDBACK_PLAY @"Feedback play button"
#define FLURRY_FEEDBACK_PAUSE @"Feedback pause button"
#define FLURRY_FEEDBACK_STOP @"Feedback stop button"
#define FLURRY_FEEDBACK_SUBMIT @"Feedback submit"
#define FLURRY_ADVISORIES_APPEAR @"Advisories appear"
#define FLURRY_ALERT_NO_NETWORK @"User alert: no network"
#define FLURRY_APPSTORE_FEEDBACK_REMINDER_SHOWN  @"Appstore Feedback Reminder Shown"
#define FLURRY_APPSTORE_FEEDBACK_REMINDER_ACTION @"Appstore Feedback Reminder Action"

// Flurry parameter names
#define FLURRY_NOTIFICATION_TOKEN @"(Notification Token)"
#define FLURRY_PRELOADED_FILE_NAME @"(Preloaded file name)"
#define FLURRY_TO_SELECTED_ADDRESS @"(To Selected Address)"
#define FLURRY_FROM_SELECTED_ADDRESS @"(From Selected Address)"
#define FLURRY_TOFROM_WHICH_TABLE @"(ToFrom which table)"
#define FLURRY_SELECTED_ROW_NUMBER @"(Table selected row #)"
#define FLURRY_NUMBER_OF_GEOCODES @"(Number of geocodes)"
#define FLURRY_GEOCODE_ERROR @"(Geocode error)"
#define FLURRY_RK_RESPONSE_ERROR @"(RK Response error)"
#define FLURRY_GEOCODE_RAWADDRESS @"(Geocode raw address)"
#define FLURRY_GEOCODE_API @"(Geocode API)"
#define FLURRY_FORMATTED_ADDRESS @"(Formatted Address)"
#define FLURRY_NEW_DATE @"(New date)"
#define FLURRY_SELECTED_DEPARTURE_TIME @"(Selected departure time)"
#define FLURRY_EDIT_MODE_VALUE @"(Edit mode value)"
#define FLURRY_USER_EMAIL @"(User email)"
#define FLURRY_FEEDBACK_TEXT @"(Feedback text)"
#define FLURRY_SETTING_WALK_DISTANCE @"(Settings walk distance)"
#define FLURRY_SETTING_ALERT_COUNT @"(Settings alert count)"
#define FLURRY_SETTING_ALERT_SOUNDS @"(Alert sounds)"
#define FLURRY_SETTING_ALERT_HOURS @"(Alert hours)"
#define FLURRY_SETTING_ADVISORY_STREAMS @"(Advisory streams)"
#define FLURRY_LAT @"(Lat)"
#define FLURRY_LNG @"(Lng)"
#define FLURRY_SUPPORTED_REGION_STRING @"(Supported Region String)"
#define FLURRY_ALERT_LOCATION @"(Alert Location)"
#define FLURRY_APPSTORE_FB_REMINDER_USER_SELECTION @"(User Selection)"
#define FLURRY_APPSTORE_FB_REMINDER_DAYS_SINCE_START @"(Days since app first use)"



// Geocode behavior
#define IOS_GEOCODE_VER_THRESHOLD (6.0)  // Version at which we start using iOS geocoding (rather than Google)

// Reverse Geocode behavior
#define REVERSE_GEO_DISTANCE_THRESHOLD  (50.0)  // Maximum distance in meters before we redo a reverse geolocation
#define REVERSE_GEO_TIME_THRESHOLD  (60)  // Minimum seconds between reverse geocode requests
#define REVERSE_GEO_PLAN_FETCH_TIME_THRESHOLD (120)  // Maximum seconds that a plan without a reverse geocode can be used in plan cache

// Locations behavior
#define TOFROM_FREQUENCY_VISIBILITY_CUTOFF 0.99

// Plan, PlanStore, and Plan caching behavior
#define PLAN_MAX_ITINERARIES_TO_SHOW (30) /* Show at most 20 results */
#define PLAN_BUFFER_SECONDS_BEFORE_ITINERARY (3*60+1) /* Take cached itineraries up to 3 minutes before the requestDate */
#define PLAN_MAX_TIME_FOR_RESULTS_TO_SHOW (6*60*60) /* Show at most 6 hours of results */
#define PLAN_MAX_SERVER_CALLS_PER_REQUEST (3) /* Maximum calls to the server for a single user request */
#define PLAN_NEXT_REQUEST_TIME_INTERVAL_SECONDS (60)
#define PLAN_ROUTE_EXCLUDE @"Exclude" // Value for RouteExcludeSettings indicating to exclude a route
#define PLAN_ROUTE_INCLUDE @"Include" // Value for RouteExcludeSettings indicating to includ a route

// gtfsParser
#define MIN_TRANSFER_TIME (3*60) // Minimum # of seconds for transfers inserted when creating itineraries
#define SMALL_TIME_THRESHOLD (15) // Number of seconds considered to be equal in time (used with timeIntervalSinceDate method)
#define GTFS_MAX_TIME_TO_PULL_SCHEDULES (7*60*60) // Inspect up to 7 hours of schedules for each leg of the trip

// realtime
#define REALTIME_BUFFER_FOR_DELAY (15*60)
#define REALTIME_BUFFER_FOR_EARLY  (5*60)
#define REALTIME_UPPER_LIMIT (30*60)
#define REALTIME_LOWER_LIMIT (-5*60)
#define CURRENT_DATE_PLUS_INTERVAL 90*60

// RequestChunks
#define REQUEST_CHUNK_OVERLAP_BUFFER_IN_SECONDS (4*60 + 30)

// LegMapView
#define LEGMAP_DOT_IMAGE_FILE @"img_mapDot"

// KeyObjectStore Keys (if strings are changed, stored data will be inaccessible)
#define TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY @"TransitCalendarLastGTFSLoadDateByAgency"
#define TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY @"TransitCalendarServiceByWeekdayByAgency"
#define TR_CALENDAR_BY_DATE_BY_AGENCY @"TransitCalendarByDateByAgency"


// Request timer Count
#define TWEET_COUNT_POLLING_INTERVAL 120.0
#define TIMER_SMALL_REQUEST_DELAY 1.0
#define TIMER_MEDIUM_REQUEST_DELAY 30.0
#define TIMER_STANDARD_REQUEST_DELAY 60.0

// errorCodes from TPResponce
#define RESPONSE_SUCCESSFULL 105
#define RESPONSE_DATA_NOT_EXIST 107
#define RESPONSE_INVALID_REQUEST 106

// Float thresholds
#define TINY_FLOAT 0.000001

#define AGENCY_IDS   @"agencyIds"
#define CALTRAIN_AGENCY_IDS  @"1"
#define BART_AGENCY_ID       @"2"
#define SFMUNI_AGENCY_ID    @"3"
#define ACTRANSIT_AGENCY_ID @"4"

#define CALTRAIN_AGENCY_NAME    @"Caltrain"
#define BART_AGENCY_NAME        @"Bay Area Rapid Transit"
#define ACTRANSIT_AGENCY_NAME   @"AC Transit"
#define SFMUNI_AGENCY_NAME      @"San Francisco Municipal Transportation Agency"
#define AIRBART_AGENCY_NAME     @"AirBART"
#define VTA_AGENCY_NAME         @"VTA"
#define MENLO_MIDDAY_AGENCY_NAME  @"Menlo Park Midday Shuttle"
#define BLUE_GOLD_AGENCY_NAME   @"Blue & Gold Fleet"
#define HARBOR_BAY_AGENCY_NAME  @"Harbor Bay Ferry"
#define BAYLINK_AGENCY_NAME     @"Baylink"
#define GOLDEN_GATE_AGENCY_NAME @"Golden Gate Ferry"

#define CALTRAIN_BUTTON @"Caltrain"
#define BART_BUTTON @"BART"
#define AIRBART_BUTTON @"AirBART"
#define MUNI_BUTTON @"Muni"
#define ACTRANSIT_BUTTON @"AC Transit"
#define VTA_BUTTON  @"VTA"
#define MENLO_MIDDAY_BUTTON @"Menlo"
#define BLUE_GOLD_BUTTON  @"Blue & Gold"
#define HARBOR_BAY_BUTTON  @"Harbor Bay"
#define BAYLINK_BUTTON     @"Baylink"
#define GOLDEN_GATE_BUTTON @"Golden Gate"

#define AC_TRANSIT @"ac_transit"
#define BART       @"bart"
#define CALTRAIN   @"caltrain"
#define SF_MUNI    @"sf-muni"

#define CALTRAIN_APP_TYPE   @"1"
#define SFMUNI_APP_TYPE     @"4"


#define UPDATE_TIME_URL @"gtfs/updateTime"
#define SERVICE_BY_WEEKDAY_URL @"gtfs/serviceByWeekday"
#define CALENDAR_BY_DATE_URL @"gtfs/calendarByDate"

#define GTFS_UPDATE_TIME @"gtfsUpdateTime"
#define GTFS_SERVICE_BY_WEEKDAY @"gtfsServiceByWeekDay"
#define GTFS_SERVICE_EXCEPTIONS_DATES @"gtfsServiceExceptionDates"
#define CURRENT_DATE @"current_Date"
#define TIMER_TYPE  @"continueGetTime"

#define GET_PLAN_URL  @"plan/get"
#define PLAN_GENERATE_URL  @"plan/generate"
#define GET_APP_TYPE   @"users/getAppType"

// savePlanInTPServer Method Constants
#define NEW_PLAN_REQUEST         @"plan/new"
#define PLAN_JSON_STRING         @"planJsonString"
#define FORMATTED_ADDRESS_TO     @"frmtdAddTo"
#define FORMATTED_ADDRESS_FROM   @"frmtdAddFrom"
#define LATITUDE_FROM            @"latFrom"
#define LONGITUDE_FROM           @"lonFrom"
#define LATITUDE_TO              @"latTo"
#define LONGITUDE_TO             @"lonTo"
#define CURRENT_LOCATION         @"Current Location"
#define FROM_TYPE                @"fromType"
#define TO_TYPE                  @"toType"
#define RAW_ADDRESS_FROM         @"rawAddFrom"
#define GEO_RES_FROM             @"geoResFrom"
#define TIME_FROM                @"timeFrom"
#define TIME_TO                  @"timeTo"
#define RAW_ADDRESS_TO           @"rawAddTO"
#define GEO_RES_TO               @"geoResTO"
#define SAVE_PLAN                @"savePlan"

#define FROM_PLACE                      @"fromPlace"
#define TO_PLACE                        @"toPlace"
#define REQUEST_TRIP_DATE               @"date"
#define REQUEST_TRIP_TIME               @"time"
#define ARRIVE_BY                       @"arriveBy"
#define MAX_WALK_DISTANCE               @"maxWalkDistance"

#define REQUEST_ID              @"reqId"
#define REQUEST_ID_LENGTH       16

#define PLAN_ID                        @"planid"
#define LIVE_FEEDS_BY_PLAN_URL         @"livefeeds/plan"
#define ITINERARY_ID                   @"itineraryid"
#define LIVE_FEEDS_BY_ITINERARIES_URL  @"livefeeds/itineraries"
#define LIVE_FEEDS_BY_LEGS             @"livefeeds/bylegs"
#define FOR_TODAY                      @"forToday"
#define LEGS                           @"legs"
#define LIVE_FEEDS_IMAGE_DOWNLOAD_URL  @"advisories/download"
#define METADATA_URL                   @"metadata"

// US-163 Appstore Feedback reminder constants
#define DATE_OF_FIRST_USE       @"dateOfFirstUse"
#define DAYS_TO_SHOW_FEEDBACK_ALERT   @"daysToShowFeedBackAlert"
#define DATE_OF_USE                 @"dateOfUse"
#define DAYS_COUNT                 @"daysCount"
#define FEEDBACK_REMINDER_PENDING  @"feedbackReminderPending"
#define DAYS_TO_SHOW_FEEDBACK_ALERT_NUMBER  10

// User Preferance
#define DEVICE_TOKEN      @"deviceToken"
#define USER_EMAIL        @"eMailId"
#define TWEET_COUNT       @"tweetCount"

// Tweeter Parameter
#define LATEST_TWEETS_REQ       @"advisories/latest"
#define LAST_TWEET_TIME         @"tweetTime"
#define ALL_TWEETS_REQ          @"advisories/all"
#define TWEET_COUNT_URL         @"advisories/count"

// Feedback Parameter
#define FB_FILE_MARKER @"file"
#define FB_FILE_TYPE @"audio/caf"
#define FB_FILE_NAME @"FBSound.caf"
#define FB_FILE_FORMAT_TYPE @"formattype"
#define FEEDBACK_TEXT 1
#define FEEDBACK_AUDIO 2
#define FEEDBACK_TEXT_AUDIO 3
#define FB_TEXT @"txtfb"
#define EMAIL_ID @"emailid"
#define FEEDBACK_SOURCE @"source"
#define FEEDBACK_RATING @"rating"
#define FB_SOURCE_PLAN 1
#define FB_SOURCE_ITINERARY 2
#define FB_SOURCE_LEG 3
#define FB_SOURCE_GENERAL 4
#define FB_FORMATTEDADDR_FROM @"rawAddFrom"
#define FB_FORMATTEDADDR_TO @"rawAddTo"
#define FB_DATE @"date"
#define FB_UNIQUEID @"uniqueid"
#define FB_REQUEST @"feedback/new"

#define FB_RESPONSE_MSG @"msg"
#define FB_RESPONCE_CODE @"code"


// Response codes
#define ERROR_CODE @"errCode"
#define RESPONSE_CODE @"code"
#define TWIT_COUNT @"tweetCount"
#define OTP_ERROR_STATUS @"error"

#define DEVICE_ID @"deviceid"
#define DEVICE_CFUUID @"deviceCFUUID"

#define PUSH_NOTIFY_OFF     -1

//US-184 Constant
#define CALTRAIN_LOCAL                 @"Local"
#define CALTRAIN_LIMITED               @"Limited"
#define CALTRAIN_BULLET                @"Bullet"
#define CALTRAIN_AGENCY_ID    @"caltrain-ca-us"
#define CALTRAIN_TRAIN                 @"Train"

// Gtfs Requests Constant
#define GTFS_RAWDATA @"gtfs/rawdata"
#define ENTITY  @"entity"
#define AGENCY_IDS @"agencyIds"
#define GTFS_STOP_TIMES  @"gtfs/stoptimes"
#define GTFS_TRIPS @"gtfs/trips"
#define AGENCY_ID_AND_ROUTE_ID @"agencyAndRouteIds"

#define GTFS_AGENCY_COUNTER    @"gtfsAgencyCounter"
#define GTFS_CALENDAR_COUNTER  @"gtfsCalendarCounter"
#define GTFS_CALENDAR_DATES_COUNTER @"gtfsCalendarDatesCounter"
#define GTFS_ROUTES_COUNTER @"gtfsRoutesCounter"
#define GTFS_STOPS_COUNTER @"gtfsStopsCounter"
#define GTFS_TRIPS_COUNTER @"gtfsTripsCounter"
#define GTFS_STOPTIMES_COUNTER @"gtfsStopTimesCounter"

#define OTP_ITINERARY  0
#define GTFS_ITINERARY 1
#define REALTIME_ITINERARY 2

#define CONTAINS_LIST_TYPE 1
#define LOCATION_TYPE 2
#define PRELOADSTOP_TYPE 3

#define STATION_LIST   @"Station List"
#define ALL_STATION    @"all_st"

#define EXCLUDE_SETTINGS_DICTIONARY @"ExcludeSettingsDictionary"
#define BIKE_MODE @"Bike"  // Key for RouteExcludeSettings


