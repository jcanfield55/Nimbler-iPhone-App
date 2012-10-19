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

// US-163 constants
#define DAYS_TO_SHOW_FEEDBACK_ALERT   @"daysToShowFeedBackAlert"
#define DATE_OF_START                 @"dateOfStart"
#define FEED_BACK_SHEET_TITLE               @"Now that you have used the app a bit, would you share your thoughts with others"
#define NO_THANKS_BUTTON_TITLE               @"No ThankS"
#define APPSTORE_FEEDBACK_BUTTON_TITLE       @"AppStore feedback"
#define NIMBLER_FEEDBACK_BUTTON_TITLE        @"Nimbler feedback"
#define REMIND_ME_LATER_BUTTON_TITLE         @"Remind Me Later"
#define NIMBLER_REVIEW_URL                   @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=567382474"
#define NO_THANKS_ACTION                     @"noThanksAction"

#define LAST_SELECTED_TAB_INDEX       @"lastSelectedTabIndex"
#define LAST_TO_LOCATION              @"lastToLocation"
#define LAST_FROM_LOCATION            @"lastFromLocation"


#endif