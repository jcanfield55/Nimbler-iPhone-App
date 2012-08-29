//
//  TEXTConstant.h
//  Nimbler Caltrain
//
//  Created by Sitanshu Joshi on 7/10/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#ifndef Nimbler_Caltrain_TEXTConstant_h
#define Nimbler_Caltrain_TEXTConstant_h


// User Preferance 
#define DEVICE_TOKEN                @"deviceToken"
#define USER_EMAIL                  @"eMailId"
#define TWEET_COUNT                 @"tweetCount"

// SettingInfo Parameter 
#define ALERT_COUNT                 @"alertCount"
#define MAXIMUM_WALK_DISTANCE       @"maxDistance"
#define UPDATE_SETTING_REQ          @"users/preferences/update"

// Tweeter Parameter
#define LATEST_TWEETS_REQ           @"advisories/latest"
#define LAST_TWEET_TIME             @"tweetTime"
#define ALL_TWEETS_REQ              @"advisories/all"

// Feedback Parameter
#define FILE                        @"file"
#define FILE_TYPE                   @"audio/caf"
#define FILE_NAME                   @"FBSound.caf"
#define FILE_FORMATE_TYPE           @"formattype"
#define FEEDBACK_TEXT               1
#define FEEDBACK_AUDIO              2
#define FEEDBACK_TEXT_AUDIO         3
#define FB_TEXT                     @"txtfb"
#define EMAIL_ID                    @"emailid"
#define FEEDBACK_SOURCE             @"source"
#define FEEDBACK_RATING             @"rating"
#define FB_SOURCE_PLAN              1
#define FB_SOURCE_ITINERARY         2
#define FB_SOURCE_LEG               3
#define FB_SOURCE_GENERAL           4
#define FB_FORMATTEDADDR_FROM       @"rawAddFrom"
#define FB_FORMATTEDADDR_TO         @"rawAddTo"
#define FB_DATE                     @"date"
#define FB_UNIQUEID                 @"uniqueid"
#define FB_REQUEST                  @"feedback/new"

#define FB_RESPONSE_MSG             @"msg"
#define FB_RESPONCE_CODE            @"code"

#define FB_RESPONSE_SUCCEES         @"Feedback Sent Successfully"
#define FB_RESPONSE_FAIL            @"Feedback Send Fail"
#define FB_TITLE_MSG                @"Nimbler Feedback"

// Itinerary / Route Details strings
#define ROUTE_STARTPOINT_PREFIX     @"Start at "
#define ROUTE_ENDPOINT_PREFIX       @"End at "
#define ROUTE_TITLE_MSG             @"Route"

// Null String
#define NULL_STRING                 @""

// Response codes
#define ERROR_CODE                  @"errCode"
#define CODE                        @"code"
#define TWIT_COUNT                  @"tweetCount"

#define DEVICE_ID                   @"deviceid"
#define DEVICE_CFUUID               @"deviceCFUUID"

// UITabbar Item
#define TRIP_PLANNER_VIEW           @"Trip Planner"
#define ADVISORIES_VIEW             @"Advisories"
#define SETTING_VIEW                @"Settings"
#define FEEDBACK_VIEW               @"Feedback"

// ToFromViewController Date Picker
#define DATE_PICKER_NOW             @"Now"
#define DATE_PICKER_DONE            @"Done"
#define DATE_PICKER_DEPART          @"Depart"
#define DATE_PICKER_ARRIVE          @"Arrive"

// ToFromTableViewController
#define TOFROMTABLE_ENTER_ADDRESS_TEXT @"Enter New Address"

#endif
