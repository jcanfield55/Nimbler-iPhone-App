//
// TEXTConstant.h
// Nimbler Caltrain
//
// Created by Sitanshu Joshi on 7/10/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#ifndef Nimbler_Caltrain_TEXTConstant_h
#define Nimbler_Caltrain_TEXTConstant_h

// Feedback responses
#define FB_RESPONSE_SUCCEES @"Feedback Sent Successfully"
#define FB_RESPONSE_FAIL @"Feedback Send Fail"
#define FB_TITLE_MSG @"Nimbler Feedback"

// Itinerary / Route Details strings
#define ROUTE_STARTPOINT_PREFIX @"Start at "
#define ROUTE_ENDPOINT_PREFIX @"End at "
#define ROUTE_TITLE_MSG @"Route"

// Null String
#define NULL_STRING @""


#define APP_TITLE                      @"Nimbler Caltrain"

// UITabbar Item
#define TRIP_PLANNER_VIEW @"Trip Planner"
#define ADVISORIES_VIEW @"Advisories"
#define SETTING_VIEW @"Settings"
#define FEEDBACK_VIEW @"Feedback"

// NavigationBar Titles

#define LOCATION_PICKER_VIEW_TITLE @"Pick a location"
#define ROUTE_OPTIONS_VIEW_TITLE   @"Itineraries"
#define ROUTE_DETAIL_VIEW_TITLE    @"Route"
#define TWITTER_VIEW_TITLE         @"Advisories"
#define SETTING_VIEW_TITLE         @"App Settings"
#define FEED_BACK_VIEW_TITLE       @"Feedback"

// Alert text
#define ALERT_TRIP_NOT_AVAILABLE       @"Sorry, we are unable to calculate a route for that To & From address"
#define ROUTE_NOT_POSSIBLE_MSG         @"Route is not possible"
#define OK_BUTTON_TITLE                @"OK"

// Current Location related messages
#define ALERT_LOCATION_SERVICES_DISABLED_TITLE @"Current Location not available"
#define ALERT_LOCATION_SERVICES_RESTRICTED_MSG @"Please enter an address for your route start and end point"
#define ALERT_LOCATION_SERVICES_DISABLED_MSG @"To route from Current Location, please go to the Settings App, and activate Locations Services for Nimbler."
#define ALERT_LOCATION_SERVICES_DISABLED_MSG_V6 @"To route from Current Location, please go to the Settings App, Privacy section, and activate Locations Services for Nimbler."

// ToFromViewController Date Picker
#define DATE_PICKER_NOW @"Now"
#define DATE_PICKER_DONE @"Done"
#define DATE_PICKER_DEPART @"Depart"
#define DATE_PICKER_ARRIVE @"Arrive"

// ToFromTableViewController
#define TOFROMTABLE_ENTER_ADDRESS_TEXT @"Enter New Address"

// Network Message
#define NO_NETWORK_ALERT   @"Unable to connect to server.  Please try again when you have network connectivity."

// US-163 user facing text
#define FEED_BACK_SHEET_TITLE               @"Now that you have used the app a bit, would you share your feedback?"
#define NO_THANKS_BUTTON_TITLE               @"No Thanks"
#define APPSTORE_FEEDBACK_BUTTON_TITLE       @"AppStore feedback"
#define NIMBLER_FEEDBACK_BUTTON_TITLE        @"Feedback for Nimbler"
#define REMIND_ME_LATER_BUTTON_TITLE         @"Remind Me Later"
#define NIMBLER_REVIEW_URL                   @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=567382474"

#define LAST_SELECTED_TAB_INDEX       @"lastSelectedTabIndex"
#define LAST_TO_LOCATION              @"lastToLocation"
#define LAST_FROM_LOCATION            @"lastFromLocation"
#define LAST_REQUEST_REVERSE_GEO      @"lastRequestReverseGeoLocation"

#define APPLICATION_BUNDLE_IDENTIFIER  @"appBundleId"
#define APPLICATION_TYPE               @"appType"

// NOTE :- Sequence matter.
#define BART_SEARCH_STRINGS_ARRAY [NSArray arrayWithObjects:@"bart station list",@"caltrain station list",@"current location",@" bart",@"bart ",@" airbart",@"airbart ",@" street",@"street ", nil]
#define BART_REPLACE_STRINGS_ARRAY [NSArray arrayWithObjects:@"",@"",@"",@"",@"",@"",@"",@" st",@"st ", nil]

#define CALTRAIN_SEARCH_STRINGS_ARRAY [NSArray arrayWithObjects:@"bart station list",@"caltrain station list",@"current location",@" caltrain",@"caltrain ", nil]
#define CALTRAIN_REPLACE_STRINGS_ARRAY [NSArray arrayWithObjects:@"",@"",@"",@"",@"", nil]

// New AppSetting Constants
#define ADVISORY_CHOICES  @"Advisory Choices"
#define PUSH_NOTIFICATION @"Push Notification"
#define TRANSIT_MODE      @"Transit mode"
#define BIKE_PREFERENCES  @"Bike preferences"

#define SFMUNI_ADVISORIES    @"SF Muni advisories"
#define BART_ADVISORIES      @"BART advisories"
#define ACTRANSIT_ADVISORIES @"A/C transit advisories"
#define CALTRAIN_ADVISORIES  @"Caltrain advisories"


#define FREQUENCY_OF_PUSH       @"Frequency of push notification"
#define NOTIFICATION_SOUND      @"Notification sound"
#define URGENT_NOTIFICATIONS    @"Urgent notifications"
#define STANDARD_NOTIFICATIONS  @"Standard notifications"
#define NOTIFICATION_TIMING     @"Notification timing"
#define WEEKDAY_MORNING         @"Weekday Morning (5 - 10:00 am)"
#define WEEKDAY_MIDDAY          @"Weekday Midday (10 - 3:00pm)"
#define WEEKDAY_EVENING_PEAK    @"Weekday Evening peak (3 - 7:30pm)"
#define WEEKDAY_NIGHT           @"Weekday Night (7:30 - 12:00)"
#define WEEKENDS                @"Weekends"


#define TRANSIT_ONLY     @"Transit only"
#define BIKE_ONLY        @"Bike only"
#define BIKE_AND_TRANSIT @"Bike + Transit"

#define MAXIMUM_WALK_DISTANCE_LABEL @"Maximum Walk Distance"


#define MAXIMUM_BIKE_DISTANCE   @"Maximum bike distance"
#define PREFERENCE_FAST_VS_SAFE @"Preference fast vs safe"
#define PREFERENCE_FAST_VS_FLAT @"Preference fast vs flat"




#endif