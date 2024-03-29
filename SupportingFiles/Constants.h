// Constants.h
// Nimbler
//
// Created by Sitanshu Joshi on 5/26/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#ifndef Nimbler_Constants_h
#define Nimbler_Constants_h

#endif

//#define AUTOMATED_TESTING_SKIP_NCAPPDELEGATE 0 // if 1, skips nc_AppDelegate didFinishLaunchingWithOptions so we get a clean tests run

#define GENERATING_SEED_DATABASE  0 // when we are generating seed database the value is 1 otherwise 0
#define SKIP_REAL_TIME_UPDATES 0 // If 1, system will not request real-time updates

#define TRIP_GENERATE_URL     @"http://23.23.210.156:7070/TPServer/ws/"
//#define TRIP_GENERATE_URL @"http://ec2-23-22-169-158.compute-1.amazonaws.com:8080/opentripplanner-api-webapp/ws/"
#define GEO_RESPONSE_URL      @"http://maps.googleapis.com/maps/api/geocode/"
#define TEST_GEO_RESPONSE_URL  @"http://localhost:8080/TPServer/ws/mockgeolocation/"

// To select server URL select 1 otherwise select 0,At a time only one of below must be 1.
#define PRODUCTION_URL  1
#define STAGGING_URL    0
#define LOCAL_URL       0

#if PRODUCTION_URL
#define TRIP_PROCESS_URL    @"http://23.23.210.156:8080/TPServer/ws/"
#endif

#if STAGGING_URL
#define TRIP_PROCESS_URL    @"http://23.23.210.156:7070/TPServer/ws/"
#endif

#if LOCAL_URL
#define TRIP_PROCESS_URL      @"http://192.168.2.57:8080/TPServer/ws/"
#endif

// Bundle and App Types
#define CALTRAIN_BUNDLE_IDENTIFIER         @"com.Nimbler.Nimbler-Caltrain"
#define WMATA_BUNDLE_IDENTIFIER            @"com.nimbler.washingtondc"
#define PORTLAND_BUNDLE_IDENTIFIER         @"com.nimbler.Nimbler-Portland"

// App types
#define CALTRAIN_APP_TYPE   @"1"
#define SFMUNI_APP_TYPE     @"4"
#define WMATA_APP_TYPE      @"5"
#define PORTLAND_APP_TYPE   @"6"

#define TEST_TRIP_PROCESS_URL @"http://localhost:8080/TPServer/ws/"  // TP server for automated tests

#define GEO_FROM          @"1"
#define GEO_TO            @"1"
#define REVERSE_GEO_FROM  @"2"
#define REVERSE_GEO_TO    @"2"
#define PREDEFINE_TYPE    @"3"

#define ON_TIME           1
#define DELAYED           2
#define EARLY             3
#define EARLIER           4
#define ITINERARY_TIME_SLIPPAGE 5

#define ALERT_OFF        @"1"
#define ALERT_ON         @"2"
#define ALERT_URGENT     @"3"

#define TOFROM_LIST_TYPE          @"TOFROM_LIST" // Location type indicating a ToFromList

// Current Location
#define CURRENT_LOCATION_STARTING_FROM_FREQUENCY 7.0

// Testflight App Analytics and logging
#define TEST_FLIGHT_ENABLED 0 // If 0, then do not include testFlightApp at all
#define TEST_FLIGHT_UIDS 1 // If 1, then testFlightApp will collect device UIDs, if 0, it will not

#define LAST_SELECTED_TAB_INDEX       @"lastSelectedTabIndex"
#define LAST_REQUEST_REVERSE_GEO      @"lastRequestReverseGeoLocation"
#define APPLICATION_BUNDLE_IDENTIFIER  @"appBundleId"
#define APPLICATION_TYPE               @"appType"
#define APPLICATION_VERSION            @"appVer"

// NSUserDefaults keys
#define USER_PREFERANCE                   @"UserPreference"
#define PREFS_DATE_LAST_SUCCESSFUL_SAVE  @"PrefsDateLastSuccessfulSave"
#define PREFS_DATE_LAST_CHANGE            @"PrefsDateLastChange"
#define PREFS_IS_PUSH_ENABLE              @"PrefsIsPushEnable"
#define PREFS_PUSH_NOTIFICATION_THRESHOLD @"PrefsPushNotificationThreshold"
#define PREFS_MAX_WALK_DISTANCE           @"PrefsMaxWalkDistance"
#define ENABLE_STANDARDNOTIFICATION_SOUND @"enableStdNotifSound"
#define ENABLE_URGENTNOTIFICATION_SOUND   @"enableUrgntNotifSound"
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
#define UPDATE_DEVICE_TOKEN   @"users/preferences/update/token"

// UserPreferernce (user settings) defaults, max, and min
#define PREFS_DEFAULT_PUSH_NOTIFICATION_THRESHOLD 5

#define URGENT_NOTIFICATION_DEFAULT_VALUE   1
#define STANDARD_NOTIFICATION_DEFAULT_VALUE 2

#define TRANSIT_MODE_TRANSIT_ONLY 2
#define TRANSIT_MODE_BIKE_ONLY 4
#define TRANSIT_MODE_BIKE_AND_TRANSIT 5
#define TRANSIT_MODE_DEFAULT 2

#define ENABLE_STANDARDNOTIF_SOUND_DEFAULT FALSE
#define ENABLE_URGENTNOTIF_SOUND_DEFAULT   TRUE
#define NOTIF_TIMING_MORNING_DEFAULT TRUE
#define NOTIF_TIMING_MIDDAY_DEFAULT FALSE
#define NOTIF_TIMING_EVENING_DEFAULT TRUE
#define NOTIF_TIMING_NIGHT_DEFAULT FALSE
#define NOTIF_TIMING_WEEKEND_DEFAULT FALSE

#define PUSH_FREQUENCY_MIN_VALUE              1
#define PUSH_FREQUENCY_MAX_VALUE              10
#define MAX_WALK_DISTANCE_DEFAULT_VALUE       2.0
#define MAX_WALK_DISTANCE_MIN_VALUE           0.25
#define MAX_WALK_DISTANCE_MAX_VALUE           2.5
#define BIKE_PREFERENCE_MIN_VALUE             0
#define BIKE_PREFERENCE_MAX_VALUE             1
#define BIKE_PREFERENCE_DEFAULT_VALUE         0.5
#define MAX_BIKE_DISTANCE_DEFAULT_VALUE       7.5
#define MAX_BIKE_DISTANCE_MIN_VALUE           1
#define MAX_BIKE_DISTANCE_MAX_VALUE           20

// Flurry analytics and logging
#define FLURRY_ENABLED 1
#define IS_KICKFOLIO 0

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
#define FLURRY_UBER_NO_NETWORK @"No network connection for Uber API"
#define FLURRY_UBER_OTHER_ERROR @"RK Error when retrieving Uber"
#define FLURRY_UBER_ITINERARY @"Uber itinerary"
#define FLURRY_EXCLUDE_SETTING_CHANGED @"ExcludeSetting changed"
#define FLURRY_ROUTE_SELECTED @"Route selected"
#define FLURRY_ROUTE_DETAILS_APPEAR @"RouteDetails appear"
#define FLURRY_UBER_DETAILS_APPEAR @"UberDetails appear"
#define FLURRY_UBER_APP_CALLED @"Uber App called"
#define FLURRY_UBER_WEBSITE_CALLED @"Uber Website called"
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
#define FLURRY_FEEDBACK_APPSTORE @"Appstore from Feedback page"
#define FLURRY_ADVISORIES_APPEAR @"Advisories appear"
#define FLURRY_ALERT_NO_NETWORK @"User alert: no network"
#define FLURRY_APPSTORE_FEEDBACK_REMINDER_SHOWN  @"Appstore Feedback Reminder Shown"
#define FLURRY_APPSTORE_FEEDBACK_REMINDER_ACTION @"Appstore Feedback Reminder Action"
#define FLURRY_DID_RECEIVE_MEMORY_WARNING @"Memory Warning"

// Flurry parameter names
#define FLURRY_NOTIFICATION_TOKEN @"(Notification Token)"
#define FLURRY_IS_KICKFOLIO @"(Kickfolio)"
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
#define FLURRY_CHANGED_EXCLUDE_SETTING @"(Changed Setting)"
#define FLURRY_NEW_EXCLUDE_SETTINGS @"(New Settings)"
#define FLURRY_SELECTED_DEPARTURE_TIME @"(Selected departure time)"
#define FLURRY_EDIT_MODE_VALUE @"(Edit mode value)"
#define FLURRY_USER_EMAIL @"(User email)"
#define FLURRY_FEEDBACK_TEXT @"(Feedback text)"
#define FLURRY_SETTING_WALK_DISTANCE @"(Settings walk distance)"
#define FLURRY_SETTING_ALERT_COUNT @"(Settings alert count)"
#define FLURRY_SETTING_ALERT_SOUNDS @"(Alert sounds)"
#define FLURRY_SETTING_ALERT_HOURS @"(Alert hours)"
#define FLURRY_SETTING_ADVISORY_STREAMS @"(Advisory streams)"
#define FLURRY_UBER_PRICE @"(Uber Price)"
#define FLURRY_UBER_MINUTES @"(Uber Minutes)"
#define FLURRY_UBER_SERVICE @"(Uber Service)"
#define FLURRY_LAT @"(Lat)"
#define FLURRY_LNG @"(Lng)"
#define FLURRY_SUPPORTED_REGION_STRING @"(Supported Region String)"
#define FLURRY_ALERT_LOCATION @"(Alert Location)"
#define FLURRY_APPSTORE_FB_REMINDER_USER_SELECTION @"(User Selection)"
#define FLURRY_APPSTORE_FB_REMINDER_DAYS_SINCE_START @"(Days since app first use)"



// Geocode behavior
#define IOS_GEOCODE_VER_THRESHOLD (6.0)  // Version at which we start using iOS geocoding (rather than Google)
// Local Search behavior
#define IOS_LOCALSEARCH_VER (6.1)  // Version at which we start using iOS MAPKIT LOCAL SEARCH

// Reverse Geocode behavior
#define REVERSE_GEO_DISTANCE_THRESHOLD  (50.0)  // Maximum distance in meters before we redo a reverse geolocation
#define REVERSE_GEO_TIME_THRESHOLD  (60)  // Minimum seconds between reverse geocode requests
#define REVERSE_GEO_PLAN_FETCH_TIME_THRESHOLD (120)  // Maximum seconds that a plan without a reverse geocode can be used in plan cache

// Locations behavior
#define TOFROM_FREQUENCY_VISIBILITY_CUTOFF 0.99
#define LOCATIONS_THRESHOLD_TO_SEARCH_USING_COREDATA 500

// ToFromTableViewController behavior
#define FREQUENCY_BOOST_FOR_FAVORITE_LOCATIONS 100000

// Plan, PlanStore, and Plan caching behavior
#define PLAN_MAX_ITINERARIES_TO_SHOW (30) /* Show at most 20 results */
#define PLAN_BUFFER_SECONDS_BEFORE_ITINERARY (3*60+1) /* Take cached itineraries up to 3 minutes before the requestDate */
#define PLAN_MAX_TIME_FOR_RESULTS_TO_SHOW (6*60*60) /* Show at most 6 hours of results */
#define PLAN_MAX_SERVER_CALLS_PER_REQUEST (3) /* Maximum calls to the server for a single user request */
#define PLAN_NEXT_REQUEST_TIME_INTERVAL_SECONDS (60)

// RouteExcludeSettings
#define BIKE_BUTTON @"Bike"
#define MY_BIKE @"My Bike"
#define BIKE_SHARE @"Bike Share"
#define RENTED_BIKE @"rentedBike"
#define EXCLUSION_BY_AGENCY @"By Agency"
#define EXCLUSION_BY_RAIL_BUS  @"By Rail/Bus"

// gtfsParser
#define MIN_TRANSFER_TIME (3*60) // Minimum # of seconds for transfers inserted when creating itineraries
#define SMALL_TIME_THRESHOLD (15) // Number of seconds considered to be equal in time (used with timeIntervalSinceDate method)
#define GTFS_MAX_TIME_TO_PULL_SCHEDULES (7*60*60) // Inspect up to 7 hours of schedules for each leg of the trip
#define DB_ROWS_BEFORE_SAVING_TO_PSC 1000  // Number of rows to insert into CoreData before saving context

// realtime
#define REALTIME_BUFFER_FOR_DELAY (15*60)
#define REALTIME_BUFFER_FOR_EARLY  (5*60)
#define REALTIME_UPPER_LIMIT (5*60)
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

#define NIMBLER_AGENCY_ID  @"nimberAgencyId"
#define GTFS_AGENCY_ID     @"gtfsAgencyId"
#define AGENCY_NAME        @"agencyName"
#define DISPLAY_NAME       @"displayName"
#define EXCLUSION_TYPE     @"exclusionType"

#define APP_AGENCIES                  @"users/getAppAgencies"
#define AGENCIES_DICTIONARY           @"agencies"
#define EXCLUDE_BUTTON_HANDLING_BY_AGENCY_DICTIONARY @"excludeButtonHandlingByAgencyDictionary"
#define AGENCY_BUTTON_NAME_BY_AGENCY_DICTIONARY @"agencyButtonNameByAgencyDictionary"
#define AGENCY_SHORT_NAME_BY_AGENCY_ID_DICTIONARY @"agencyShortNameByAgencyIdDictionary"
#define AGENCY_FEED_ID_FROM_AGENCY_NAME_DICTIONARY @"agencyFeedIdFromAgencyNameDictionary"
#define AGENCY_NAME_FROM_AGENCY_FEED_ID_DICTIONARY @"agencyNameFromAgencyFeedIdDictionary"

#define SUPPORTED_FEED_ID_STRING   @"supportedFeedIdString"

// Request timer Count
#define TWEET_COUNT_POLLING_INTERVAL 120.0
#define TIMER_SMALL_REQUEST_DELAY 1.0
#define TIMER_MEDIUM_REQUEST_DELAY 30.0
#define TIMER_STANDARD_REQUEST_DELAY 120.0

// errorCodes from TPResponce
#define RESPONSE_SUCCESSFULL 105
#define RESPONSE_DATA_NOT_EXIST 107
#define RESPONSE_INVALID_REQUEST 106
#define RESPONSE_RETRY 100

// Float thresholds
#define TINY_FLOAT 0.000001


#define UPDATE_TIME_URL @"gtfs/updateTime"
#define SERVICE_BY_WEEKDAY_URL @"gtfs/serviceByWeekday"
#define CALENDAR_BY_DATE_URL @"gtfs/calendarByDate"

#define GTFS_UPDATE_TIME @"gtfsUpdateTime"
#define GTFS_SERVICE_BY_WEEKDAY @"gtfsServiceByWeekDay"
#define GTFS_SERVICE_EXCEPTIONS_DATES @"gtfsServiceExceptionDates"
#define CURRENT_DATE @"current_Date"
#define CURRENT_DATE_AGENCIES @"current_Date_Agencies"
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

// Server request keys
#define FROM_PLACE                      @"fromPlace"
#define TO_PLACE                        @"toPlace"
#define REQUEST_TRIP_DATE               @"date"
#define REQUEST_TRIP_TIME               @"time"
#define ARRIVE_BY                       @"arriveBy"
#define MAX_WALK_DISTANCE               @"maxWalkDistance"
#define REQUEST_BIKE_TRIANGLE_QUICK     @"triangleTimeFactor"
#define REQUEST_BIKE_TRIANGLE_FLAT      @"triangleSlopeFactor"
#define REQUEST_BIKE_TRIANGLE_BIKE_FRIENDLY @"triangleSafetyFactor"
#define REQUEST_TRANSIT_MODE            @"mode"
#define REQUEST_TRANSIT_MODE_TRANSIT    @"TRANSIT,WALK"
#define REQUEST_MODE_WALK_BIKE    @"WALK,BICYCLE"
#define REQUEST_TRANSIT_MODE_BIKE_ONLY  @"BICYCLE"
#define REQUEST_TRANSIT_MODE_TRANSIT_BIKE @"TRANSIT,BICYCLE"
#define REQUEST_TRANSIT_MODE_WALK_BIKE @"TRANSIT,WALK,BICYCLE"
#define REQUEST_MODE_WALK   @"WALK"
#define REQUEST_MODE_TRANSIT   @"TRANSIT"

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
#define NEXT_LEGS_PLAN                 @"plan/nextlegs"

// US-163 Appstore Feedback reminder constants
#define DATE_OF_FIRST_USE       @"dateOfFirstUse"
#define DAYS_TO_SHOW_FEEDBACK_ALERT   @"daysToShowFeedBackAlert"
#define DATE_OF_USE                 @"dateOfUse"
#define DAYS_COUNT                 @"daysCount"
#define FEEDBACK_REMINDER_PENDING  @"feedbackReminderPending"
#define FEEDBACK_LIKES_DISLIKES     @"feedbackLikesDislikes"
#define FEEDBACK_LIKES_VALUE        @"likes"
#define FEEDBACK_DISLIKES_VALUE     @"dislikes"
#define APP_VERSION                 @"appVersion"
#define IS_UPGRADED_CUSTOMER           @"isUpgradedCustomer"

#define DAYS_TO_SHOW_FEEDBACK_ALERT_NUMBER  7  // Updated 12/26/14 by JC
#define DAYS_TO_SHOW_FEEDBACK_ALERT_UPGRADE_NUMBER  4  // For customer upgrading to a new version
#define DAYS_TO_SHOW_FEEDBACK_ALERT_REMIND_ME_LATER_NUMBER  5

// User Preferance
#define DEVICE_TOKEN      @"deviceToken"
#define DUMMY_TOKEN_ID    @"dummyTokenId"
#define USER_EMAIL        @"eMailId"
#define TWEET_COUNT       @"tweetCount"
#define DEVICE_TOKEN_UPDATED @"deviceTokenUpdated"

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

// OTP Mode value strings returned in Leg object
#define OTP_BIKE_MODE       @"BICYCLE"
#define OTP_WALK_MODE       @"WALK"
#define OTP_RAIL_MODE       @"RAIL"
#define OTP_SUBWAY_MODE     @"SUBWAY"
#define OTP_TRAM_MODE       @"TRAM"
#define OTP_BUS_MODE        @"BUS"
#define OTP_CABLE_CAR       @"cable_car"
#define OTP_FERRY           @"ferry"

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

#define EXCLUDE_SETTINGS_DICTIONARY @"ExcludeSettingsDictionary"
#define MODE @"mode"
#define BANNED_AGENCIES @"bannedAgencies"
#define BANNED_AGENCIES_WITH_MODE @"bannedAgenciesWithMode"

#define SHOW_INTERMEDIATE_STOPS @"showIntermediateStops"

#define LIVE_FEEDS_BY_VEHICLE_POSITION @"livefeeds/vehiclePosition"

//
// Settings Page Rows
//
// Sections
#define SETTINGS_NUMBER_OF_SECTIONS 3

#define SETTINGS_ADVISORY_SECTION_NUM  0
#define SETTINGS_PUSH_SECTION_NUM  1
#define SETTINGS_BIKE_WALK_SECTION_NUM  2

#define SETTINGS_ADVISORY_SECTION_ROWS  1

#define SETTINGS_PUSH_SECTION_ROWS_IF_ON  4  // Row defs follow
#define SETTINGS_PUSH_ON_OFF_ROW_NUM 0
#define SETTINGS_PUSH_FREQUENCY_ROW_NUM 1
#define SETTINGS_PUSH_SOUND_ROW_NUM 2
#define SETTINGS_PUSH_TIMING_ROW_NUM 3

#define SETTINGS_BIKE_WALK_SECTION_ROWS  2 // Row defs follow
#define SETTINGS_MAX_WALK_DISTANCE_ROW_NUM 0
#define SETTINGS_BIKE_PREF_ROW_NUM 1
#define SETTINGS_TRANSIT_MODE_ROW_NUM 999  // This function is de-activated from the UI

// Codes for detail pages
#define N_SETTINGS_ROW_ADVISORY 0
#define N_SETTINGS_ROW_PUSH_SOUND 3
#define N_SETTINGS_ROW_PUSH_TIMING 4
#define N_SETTINGS_ROW_TRANSIT_MODE 5
#define N_SETTINGS_ROW_BIKE_PREF 7

#define N_SETTINGS_ADVISORY_ROWS 4  // Row defs follow
#define WMATA_SETTINGS_ADVISORIES_ROWS 1
#define TRIMET_SETTINGS_ADVISORIES_ROWS 1
#define SETTINGS_ADVISORY_SFMUNI_ROW 0
#define SETTINGS_ADVISORY_BART_ROW 1
#define SETTINGS_ADVISORY_ACTRANSIT_ROW 2
#define SETTINGS_ADVISORY_CALTRAIN_ROW 3
#define SETTINGS_ADVISORY_WMATA_ROW 0
#define SETTINGS_ADVISORY_TRIMET_ROW 0

#define N_SETTINGS_PUSH_SOUND_ROWS 2  // Row defs follow
#define SETTINGS_SOUNDS_URGENT_ROW 0
#define SETTINGS_SOUNDS_STANDARD_ROW 1

#define N_SETTINGS_PUSH_TIMING_ROWS 5  // Row defs follow
#define SETTINGS_TIMING_WEEKDAY_MORNING_ROW 0
#define SETTINGS_TIMING_WEEKDAY_MIDDAY_ROW 1
#define SETTINGS_TIMING_WEEKDAY_EVENING_ROW 2
#define SETTINGS_TIMING_WEEKDAY_NIGHT_ROW 3
#define SETTINGS_TIMING_WEEKEND_ROW 4

#define N_SETTINGS_TRANSIT_MODE_ROWS 3 // Note: this function is not being used currently

#define N_SETTINGS_BIKE_PREF_ROWS 3  // Row defs follow
#define SETTINGS_BIKE_MAX_DISTANCE_ROW 0
#define SETTINGS_FAST_VS_SAFE_ROW 1
#define SETTINGS_FAST_VS_FLAT_ROW 2

//Mode Define
#define BIKE_MODE_Tag @"101"
#define TRANSIT_MODE_Tag @"102"
#define CAR_MODE_Tag @"103"
#define BIKE_SHARE_MODE_Tag @"104"

#define MODE_ENABLE @"1"
#define MODE_DISABLE @"0"

#define DEFAULT_BIKE_MODE @"bikeModeEnable"
#define DEFAULT_SHARE_MODE @"bikeShareModeEnable"
#define DEFAULT_TRANSIT_MODE @"TransitModeEnable"
#define DEFAULT_CAR_MODE @"carModeEnable"

//
// Preload station file variables and version numbers
//
#define CALTRAIN_PRELOAD_LOCATION_FILE_CALTRAIN_APPLICATION @"caltrain-station.json"
#define BART_BACKGROUND_PRELOAD_LOCATION_FILE @"bart-station-background.json"

#define CALTRAIN_PRELOAD_LOCATION_FILE     @"caltrain.json"
#define BART_PRELOAD_LOCATION_FILE         @"bart.json"
#define ACTRANSIT_PRELOAD_LOCATION_FILE         @"ac-transit.json"
#define SFMUNI_PRELOAD_LOCATION_FILE         @"sf-muni.json"
#define WMATA_PRELOAD_LOCATION_FILE          @"wmata-station.json"
#define PORTLAND_PRELOAD_LOCATION_FILE          @"trimet.json"

#define CALTRAIN_PRELOAD_VERSION_NUMBER    @"1.100"
#define CALTRAIN_PRELOAD_TEST_ADDRESS    @"San Martin Caltrain, San Martin, CA 95046, USA"

#define BART_PRELOAD_VERSION_NUMBER      @"1.052"
#define BART_PRELOAD_TEST_ADDRESS        @"24th St Mission BART, San Francisco, CA 94110, USA"

#define ACTRANSIT_PRELOAD_VERSION_NUMBER      @"1.500"
#define ACTRANSIT_PRELOAD_TEST_ADDRESS        @"Coelho Dr & Mooney Av"

#define SFMUNI_PRELOAD_VERSION_NUMBER      @"1.800"
#define SFMUNI_PRELOAD_TEST_ADDRESS        @"Powell St & O'Farrell St"

#define WMATA_PRELOAD_VERSION_NUMBER    @"1.120"
#define WMATA_PRELOAD_TEST_ADDRESS    @"Anacostia Metro Station, Washington, DC 20020, USA"

#define PORTLAND_PRELOAD_VERSION_NUMBER    @"2.100"
#define PORTLAND_PRELOAD_TEST_ADDRESS      @"Hatfield Government Center MAX Station"

//
// Agency IDs, names, shortnames, etc
//
#define AGENCY_IDS   @"agencyIds"
#define CALTRAIN_AGENCY_FEED_ID  @"1"
#define BART_AGENCY_FEED_ID       @"2"
#define SFMUNI_AGENCY_FEED_ID    @"3"
#define ACTRANSIT_AGENCY_FEED_ID @"4"
#define VTA_AGENCY_FEED_ID       @"5"
#define MENLO_MIDDAY_AGENCY_FEED_ID @"6"
#define SF_FERRIES_AGENCY_FEED_ID        @"7"
#define WMATA_AGENCY_FEED_ID @"8"
#define SAM_TRANS_AGENCY_FEED_ID    @"9"
#define TRIMET_AGENCY_FEED_ID    @"21"

// Agencies without a feed ID will not get GTFS schedules (need to do mapping only through OTP)

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
#define DC_CIRCULATOR_AGENCY_NAME @"DC Circulator"
#define METRO_AGENCY_NAME         @"METRO"
#define SAM_TRANS_AGENCY_NAME     @"SamTrans"

// Keys for RouteExcludeSettings Agencies
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
#define DC_CIRCULATOR_BUTTON @"DC Cir"
#define METRO_BUTTON @"Metro"
#define SAM_TRANS_BUTTON @"SamTrans"

#define AC_TRANSIT @"ac_transit"
#define BART       @"bart"
#define CALTRAIN   @"caltrain"
#define SF_MUNI    @"sf-muni"

//US-184 Constant
#define CALTRAIN_LOCAL                 @"Local"
#define CALTRAIN_LIMITED               @"Limited"
#define CALTRAIN_BULLET                @"Bullet"
#define CALTRAIN_AGENCY_ID    @"caltrain-ca-us"
#define CALTRAIN_TRAIN                 @"Train"

// User Preferences settings constants for activating advisories
#define ENABLE_SFMUNI_ADV   @"enableSfMuniAdv"
#define ENABLE_BART_ADV     @"enableBartAdv"
#define ENABLE_ACTRANSIT_ADV @"enableAcTransitAdv"
#define ENABLE_CALTRAIN_ADV @"enableCaltrainAdv"
#define ENABLE_WMATA_ADV     @"enableWmataAdv"
#define ENABLE_TRIMET_ADV     @"enableTrimetAdv"

// See https://developer.uber.com/v1/endpoints/ for details of the Uber API
#define UBER_ENABLED  1   // 1 to enable Uber in RouteExcludeSettings, 0 otherwise
#define UBER_API_BASE_URL    @"https://api.uber.com/v1"
#define UBER_PRODUCTS_URL    @"/products"
#define UBER_PRICE_URL    @"/estimates/price"
#define UBER_TIME_URL    @"/estimates/time"
#define UBER_SERVER_TOKEN @"8wPZ8UFdreBCTwk_DVeL8Al-ejn7Z3GsPbUX4w45"
#define UBER_CLIENT_ID @"m2FjJwmSSurnjRUpfYjYhyb_zX5--zE6"
#define UBER_START_LATITUDE @"start_latitude"
#define UBER_START_LONGITUDE @"start_longitude"
#define UBER_END_LATITUDE @"end_latitude"
#define UBER_END_LONGITUDE @"end_longitude"
#define UBER_EXCLUDE_BUTTON_DISPLAY_NAME @"Uber"
#define UBER_TIMES_KEY @"times"
#define UBER_PRICES_KEY @"prices"
#define UBER_PRODUCT_ID_KEY @"product_id"
#define UBER_DISPLAY_NAME_KEY @"display_name"
#define UBER_PRICE_ESTIMATE_KEY @"estimate"
#define UBER_LOW_ESTIMATE_KEY @"low_estimate"
#define UBER_HIGH_ESTIMATE_KEY @"high_estimate"
#define UBER_SURGE_MULTIPLIER_KEY @"surge_multiplier"
#define UBER_TIME_ESTIMATE_KEY @"estimate"
#define UBER_APP_BASE_URL @"uber://"
#define UBER_APP_ACTION_KEY @"action"
#define UBER_APP_ACTION_PICKUP @"setPickup"
#define UBER_APP_PICKUP_LATITUDE @"pickup[latitude]"
#define UBER_APP_PICKUP_LONGITUDE @"pickup[longitude]"
#define UBER_APP_PICKUP_NICKNAME @"pickup[nickname]"
#define UBER_APP_PICKUP_FORMATTED_ADDRESS @"pickup[formatted_address]"
#define UBER_APP_DROPOFF_LATITUDE @"dropoff[latitude]"
#define UBER_APP_DROPOFF_LONGITUDE @"dropoff[longitude]"
#define UBER_APP_DROPOFF_NICKNAME @"dropoff[nickname]"
#define UBER_APP_DROPOFF_FORMATTED_ADDRESS @"dropoff[formatted_address]"
#define UBER_WEB_BASE_URL @"https://m.uber.com/sign-up"
#define UBER_WEB_PICKUP_LATITUDE @"pickup_latitude"
#define UBER_WEB_PICKUP_LONGITUDE @"pickup_longitude"
#define UBER_WEB_PICKUP_NICKNAME @"pickup_nickname"
#define UBER_WEB_PICKUP_FORMATTED_ADDRESS @"pickup_address"
#define UBER_WEB_DROPOFF_LATITUDE @"dropoff_latitude"
#define UBER_WEB_DROPOFF_LONGITUDE @"dropoff_longitude"
#define UBER_WEB_DROPOFF_NICKNAME @"dropoff_nickname"
#define UBER_WEB_DROPOFF_FORMATTED_ADDRESS @"dropoff_address"
#define UBER_WEB_CLIENT_ID_KEY @"client_id"
#define UBER_WEB_COUNTRY_CODE @"country_code"
#define UBER_MAX_RETAIN_SECONDS 120  // Maximum amount of time before a partial Uber request result is thrown out


