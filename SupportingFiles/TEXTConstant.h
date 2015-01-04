//
// TEXTConstant.h
// Nimbler Caltrain
//
// Created by Sitanshu Joshi on 7/10/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#ifndef Nimbler_Caltrain_TEXTConstant_h
#define Nimbler_Caltrain_TEXTConstant_h


// App specific constants
//#define APP_TITLE                      @"Nimbler SF"

// Feedback Page text
#define FB_RESPONSE_SUCCEES @"Feedback Sent Successfully"
#define FB_RESPONSE_FAIL @"Feedback Send Fail"
#define FB_TITLE_MSG @"Nimbler Feedback"

#define RECORD_MSG @"Recording your feedback \nSpeak ..."
#define SUBMIT_MSG @"Sending your feedback \nPlease wait ..."

#define RECORDING @"Recording...."
#define RECORDING_STOP @"Recording Stopped...."
#define RECORDING_CANCEL @"Recording Canceled...."
#define RECORDING_PAUSE @"Recording Paused...."
#define RECORDING_PLAY @"Record Playing...."
#define VOICE_FB_FILE @"voiceFeedback.caf"
#define PLAY_TIME @"Play Time : %02d"
#define TIME_LEFT @"Time Left : %02d"
#define REC_NOT_PLAY @"Error while playing recording...."
#define PLAY_COMPLETE @"Play complete...."
#define ANIMATION_PARAM @"anim"
#define FB_CONFIRMATION @"Are you sure you want to send feedback?"
#define FB_WHEN_NO_VOICE_OR_TEXT @"Please provide your text or voice feedback, then press Send"
#define ALERT_TRIP @"Trip Planner"

#define BUTTON_DONE @"Done"
#define BUTTON_CANCEL @"Cancel"
#define BUTTON_OK @"OK"

// Itinerary / Route Details strings
#define ROUTE_STARTPOINT_PREFIX @"Start at "
#define ROUTE_ENDPOINT_PREFIX @"End at "
#define ROUTE_TITLE_MSG @"Route"


// Null String
#define NULL_STRING @""


// UITabbar Item
#define TRIP_PLANNER_VIEW @"Trip Planner"
#define ADVISORIES_VIEW @"Advisories"
#define SETTING_VIEW @"Settings"

// Default PlaceHolder ToFrom Text
#define Placeholder_Text                  @"Search for location"


// NavigationBar Titles

#define LOCATION_PICKER_VIEW_TITLE @"Pick a location"
#define ROUTE_OPTIONS_VIEW_TITLE   @"Itineraries"
#define ROUTE_DETAIL_VIEW_TITLE    @"Route"
#define UBER_DETAILS_VIEW_TITLE    @"Options"
#define TWITTER_VIEW_TITLE         @"Advisories"
#define SETTING_VIEW_TITLE         @"App Settings"
#define FEED_BACK_VIEW_TITLE       @"Feedback"
#define BIKE_STEPS_VIEW_TITLE       @"Bike Steps"

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

// RouteOptionsViewController
#define MODE_BUTTON_TRAVEL_BY_TEXT @"Travel By:"

// RouteDetailsViewController
#define NO_REALTIME_UPDATES @"No Realtime Updates"
#define TIME_TO_NEXT_REFRESH @"Time to next refresh"

// Network Message
#define NO_NETWORK_ALERT   @"Unable to connect to server.  Please try again when you have network connectivity."

// US-163 user facing text (revised in v1.40, 12/2014)
#define FEED_BACK_SHEET_TITLE               @"Do you like using Nimbler?"
#define YES_BUTTON_TEXT                     @"Yes"
#define NO_BUTTON_TEXT                      @"No"

#define FEEDBACK_LIKE_QUESTION_2            @"Will you help spread the word?"
#define FEEDBACK_LIKE_QUESTION_2_UPGRADE_MESSAGE @"App Store ratings start from scratch with every new version."
#define APPSTORE_FEEDBACK_BUTTON_TITLE       @"Yes, rate in App Store"
#define REMIND_ME_LATER_BUTTON_TITLE         @"Remind Me Later"
#define NO_THANKS_BUTTON_TITLE               @"No Thanks"

#define FEEDBACK_DISLIKE_QUESTION_2          @"Can you provide feedback to make Nimbler better?"
#define NIMBLER_FEEDBACK_BUTTON_TITLE        @"Yes, provide feedback"


// NOTE :- Sequence matter.
#define BART_SEARCH_STRINGS_ARRAY [NSArray arrayWithObjects:@"bart station list",@"caltrain station list",@"current location",@" bart",@"bart ",@" airbart",@"airbart ",@" street",@"street ", nil]
#define BART_REPLACE_STRINGS_ARRAY [NSArray arrayWithObjects:@"",@"",@"",@"",@"",@"",@"",@" st",@"st ", nil]

#define CALTRAIN_SEARCH_STRINGS_ARRAY [NSArray arrayWithObjects:@"bart station list",@"caltrain station list",@"current location",@" caltrain",@"caltrain ", nil]
#define CALTRAIN_REPLACE_STRINGS_ARRAY [NSArray arrayWithObjects:@"",@"",@"",@"",@"", nil]

#define SEARCH_STRINGS_ARRAY [NSArray arrayWithObjects:@"&",@"street",@"st.",@"st",@"avenue",@"ave.",@"ave",@"av.",@"av",@"dr.",@"dr",@"and",@"ca.",@"ca",@"usa",@",", nil]

// New AppSetting Constants
#define ADVISORY_CHOICES   @"Advisory Choices"
#define PUSH_NOTIFICATION  @"Push Notification"
#define TRANSIT_MODE       @"Transit mode"
#define BIKE_PREFERENCES   @"Bike preferences"
#define WALK_BIKE_SETTINGS @"Walk / Bike Settings"

#define SFMUNI_ADVISORIES    @"SF Muni advisories"
#define BART_ADVISORIES      @"BART advisories"
#define ACTRANSIT_ADVISORIES @"A/C transit advisories"
#define CALTRAIN_ADVISORIES  @"Caltrain advisories"
#define WMATA_ADVISORIES     @"WMATA advisories"
#define TRIMET_ADVISORIES     @"Trimet advisories"


#define FREQUENCY_OF_PUSH       @"Frequency Of Push Notification"
#define NOTIFICATION_SOUND      @"Notification sound"
#define URGENT_NOTIFICATIONS    @"Urgent Notifications"
#define STANDARD_NOTIFICATIONS  @"Standard Notifications"
#define NOTIFICATION_TIMING     @"Notification Timing"
#define WEEKDAY_MORNING         @"Weekday Morning (5 - 10:00 am)"
#define WEEKDAY_MIDDAY          @"Weekday Midday (10 - 3:00pm)"
#define WEEKDAY_EVENING_PEAK    @"Weekday Evening peak (3 - 7:30pm)"
#define WEEKDAY_NIGHT           @"Weekday Night (7:30 - 12:00)"
#define WEEKENDS                @"Weekends"


#define TRANSIT_ONLY     @"Walk + Transit"
#define BIKE_ONLY        @"Bike only"
#define BIKE_AND_TRANSIT @"Bike + Transit"

#define MAXIMUM_WALK_DISTANCE_LABEL @"Maximum Walk Distance (miles)"


#define MAXIMUM_BIKE_DISTANCE   @"Maximum bike distance(miles)"
#define PREFERENCE_FAST_VS_SAFE @"Preference fast vs safe"
#define PREFERENCE_FAST_VS_FLAT @"Preference fast vs flat"

#define QUICK_WITH_HILLS      @"Fast with hills"
#define GO_AROUNG_HILLS       @"Go around hills"
#define QUICK_WITH_ANY_STREET @"Fast, any street"
#define BIKE_FRIENDLY_STREET  @"Bike friendly street"

#define LABEL_FREQUENTLY      @"More"
#define LABEL_RARELY          @"Less"

#define URGENT_AND_STANDARD     @"Urgent + Standard"
#define URGENT                  @"Urgent Only"
#define STANDARD                @"Standard Only"

#define LABEL_ALL               @"All"
#define LABEL_NONE              @"None"
#define LABEL_SFMUNI            @"SFMuni"
#define LABEL_BART              @"Bart"
#define LABEL_ACTRANSIT         @"Ac Transit"
#define LABEL_CALTRAIN          @"Caltrain"
#define LABEL_WMATA             @"Wmata"
#define LABEL_TRIMET            @"Trimet"

#define LABEL_NO_NOTIFICATIONS  @"No Notifications"
#define LABEL_WKDAY_ALL         @"Wkday all"
#define LABEL_WEEKENDS          @"Weekends"
#define LABEL_WKKDAY            @"Wkday"
#define LABEL_WKENDS            @"Wkends"
#define LABEL_MORNING           @"morning"
#define LABEL_MIDDAY            @"midday"
#define LABEL_EVENING           @"evening"
#define LABEL_NIGHT             @"night"

#define CURRENT_DATE_INC_DEC_INTERVAL 12*60*60
#define ITINERARY_START_DATE_INC_DEC_INTERVAL 4*60*60

// Key that states current view controller from 1,2 or 3
// 1 - Advisories View  2 - Settings View 3 - Feedback View  
#define CURRENT_VIEW_CONTROLLER @"currentViewController"

#endif