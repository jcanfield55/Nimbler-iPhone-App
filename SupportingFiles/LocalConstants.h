//
//  Header.h
//  Nimbler SF
//
//  Created by John Canfield on 3/5/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#ifndef Nimbler_SF_Header_h
#define Nimbler_SF_Header_h

// Bundle and App Types
#define CALTRAIN_BUNDLE_IDENTIFIER         @"com.Nimbler.Nimbler-Caltrain"
#define CALTRAIN_APP_TYPE   @"1"
#define SFMUNI_APP_TYPE     @"4"

// Default boundaries for geolocation and routing
#define MIN_LAT           @"36.791000000000004"
#define MIN_LONG          @"-123.4631719"
#define MAX_LAT           @"38.7189988"
#define MAX_LONG          @"-121.025001"

//
// Preload station file variables and version numbers
//
#define STATION_LIST   @"Station List"

#define CALTRAIN_PRELOAD_LOCATION_FILE     @"caltrain.json"
#define BART_PRELOAD_LOCATION_FILE         @"bart.json"
#define ACTRANSIT_PRELOAD_LOCATION_FILE         @"ac-transit.json"
#define SFMUNI_PRELOAD_LOCATION_FILE         @"sf-muni.json"

#define CALTRAIN_PRELOAD_VERSION_NUMBER    @"1.100"
#define CALTRAIN_PRELOAD_TEST_ADDRESS    @"San Martin Caltrain, San Martin, CA 95046, USA"

#define BART_PRELOAD_VERSION_NUMBER      @"1.052"
#define BART_PRELOAD_TEST_ADDRESS        @"24th St Mission BART, San Francisco, CA 94110, USA"

#define ACTRANSIT_PRELOAD_VERSION_NUMBER      @"1.500"
#define ACTRANSIT_PRELOAD_TEST_ADDRESS        @"Coelho Dr & Mooney Av"

#define SFMUNI_PRELOAD_VERSION_NUMBER      @"1.800"
#define SFMUNI_PRELOAD_TEST_ADDRESS        @"Powell St & O'Farrell St"

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

#define ENABLE_SFMUNI_ADV_DEFAULT FALSE
#define ENABLE_BART_ADV_DEFAULT FALSE
#define ENABLE_ACTRANSIT_ADV_DEFAULT FALSE
#define ENABLE_CALTRAIN_ADV_DEFAULT TRUE
//
// Dictionaries to map between various agency names, IDs
//

#define AGENCY_FEED_ID_FROM_AGENCY_NAME_DICTIONARY [NSDictionary dictionaryWithKeysAndObjects: \
CALTRAIN_AGENCY_NAME, CALTRAIN_AGENCY_FEED_ID, \
BART_AGENCY_NAME, BART_AGENCY_FEED_ID, \
AIRBART_AGENCY_NAME, BART_AGENCY_FEED_ID, \
SFMUNI_AGENCY_NAME, SFMUNI_AGENCY_FEED_ID, \
ACTRANSIT_AGENCY_NAME, ACTRANSIT_AGENCY_FEED_ID, \
VTA_AGENCY_NAME, VTA_AGENCY_FEED_ID,\
MENLO_MIDDAY_AGENCY_NAME,MENLO_MIDDAY_AGENCY_FEED_ID,\
BLUE_GOLD_AGENCY_NAME,SF_FERRIES_AGENCY_FEED_ID,\
HARBOR_BAY_AGENCY_NAME ,SF_FERRIES_AGENCY_FEED_ID,\
BAYLINK_AGENCY_NAME ,SF_FERRIES_AGENCY_FEED_ID,\
GOLDEN_GATE_AGENCY_NAME ,SF_FERRIES_AGENCY_FEED_ID,\
nil]

#define AGENCY_NAME_FROM_AGENCY_FEED_ID_DICTIONARY [NSDictionary dictionaryWithKeysAndObjects: \
 CALTRAIN_AGENCY_FEED_ID, CALTRAIN_AGENCY_NAME,  \
 BART_AGENCY_FEED_ID, BART_AGENCY_NAME, \
 SFMUNI_AGENCY_FEED_ID, SFMUNI_AGENCY_NAME,  \
 ACTRANSIT_AGENCY_FEED_ID, ACTRANSIT_AGENCY_NAME,  \
VTA_AGENCY_FEED_ID, VTA_AGENCY_NAME, \
MENLO_MIDDAY_AGENCY_FEED_ID,MENLO_MIDDAY_AGENCY_NAME, \
SF_FERRIES_AGENCY_FEED_ID,BLUE_GOLD_AGENCY_NAME, \
nil]


#define AGENCY_SHORT_NAME_BY_AGENCY_ID_DICTIONARY [NSDictionary dictionaryWithKeysAndObjects: \
 @"AC Transit", @"AC Transit", \
 @"BART", @"BART", \
 @"AirBART", @"AirBART", \
 CALTRAIN_AGENCY_ID, @"Caltrain", \
 @"8", @"Blue & Gold Fleet", \
 @"10", @"Harbor Bay Ferry", \
 @"11", @"Baylink", \
 @"12", @"Golden Gate Ferry", \
 @"MIDDAY", @"Menlo Park Midday Shuttle", \
 @"SFMTA", @"Muni", \
 @"VTA", @"VTA", \
 nil]

// Button handling by agency
#define EXCLUDE_BUTTON_HANDLING_BY_AGENCY_DICTIONARY [NSDictionary dictionaryWithKeysAndObjects: \
 CALTRAIN_BUTTON, EXCLUSION_BY_AGENCY, \
 BART_BUTTON, EXCLUSION_BY_AGENCY, \
 AIRBART_BUTTON, EXCLUSION_BY_AGENCY, \
 MUNI_BUTTON, EXCLUSION_BY_RAIL_BUS, \
 ACTRANSIT_BUTTON, EXCLUSION_BY_AGENCY, \
 VTA_BUTTON, EXCLUSION_BY_RAIL_BUS, \
 MENLO_MIDDAY_BUTTON, EXCLUSION_BY_AGENCY, \
 BLUE_GOLD_BUTTON, EXCLUSION_BY_AGENCY, \
 HARBOR_BAY_BUTTON, EXCLUSION_BY_AGENCY, \
 BAYLINK_BUTTON,EXCLUSION_BY_AGENCY, \
 GOLDEN_GATE_BUTTON, EXCLUSION_BY_AGENCY, \
 nil]

// Agency short name (for buttons) by Agency Name
#define AGENCY_BUTTON_NAME_BY_AGENCY_NAME_DICTIONARY [NSDictionary dictionaryWithKeysAndObjects: \
 CALTRAIN_AGENCY_NAME, CALTRAIN_BUTTON, \
 BART_AGENCY_NAME, BART_BUTTON, \
 AIRBART_AGENCY_NAME, AIRBART_BUTTON, \
 SFMUNI_AGENCY_NAME, MUNI_BUTTON, \
 ACTRANSIT_AGENCY_NAME, ACTRANSIT_BUTTON, \
 VTA_AGENCY_NAME, VTA_BUTTON, \
 MENLO_MIDDAY_AGENCY_NAME, MENLO_MIDDAY_BUTTON, \
 BLUE_GOLD_AGENCY_NAME, BLUE_GOLD_BUTTON, \
 HARBOR_BAY_AGENCY_NAME, HARBOR_BAY_BUTTON, \
 BAYLINK_AGENCY_NAME, BAYLINK_BUTTON, \
 GOLDEN_GATE_AGENCY_NAME, GOLDEN_GATE_BUTTON, \
 nil];

#endif
