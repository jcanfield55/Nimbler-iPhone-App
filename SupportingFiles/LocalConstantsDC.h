//
//  LocalConstants.h
//  Nimbler SF
//
//  Created by John Canfield on 3/5/13.
//  Copyright (c) 2013 Network Commuting. All rights reserved.
//

#ifndef Nimbler_SF_Header_h
#define Nimbler_SF_Header_h

// Default time zone
#define DEFAULT_TIME_ZONE @"America/New_York"

// App specific user text
#define NEWGEOCODE_RESULT_MSG @"in the Washington DC Metro Area"
#define LOCATION_NOTAPPEAR_MSG @"Washington DC"
#define APP_TITLE              @"Nimbler DC"

#define METADATA_URL                   @"plan/graph/metadata?appType=5"

// Default boundaries for geolocation and routing
#define MIN_LAT @"38.5"
#define MIN_LONG @"-77.6"
#define MAX_LAT @"39.191489"
#define MAX_LONG @"-76.668939"

// Flurry API Key
#define FLURRY_API_KEY @"34N6BPVG3TR3GYTSFY9P"

// Facebook App ID (for tracking referrals)
#define FB_APP_ID @"" // Nimbler DC FB App ID

// Review reminder URL
#define NIMBLER_REVIEW_URL @"itms-apps://itunes.apple.com/app/id668593695"
// old NIMBLER_REVIEW_URL @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=668593695"

// UserPreferernce (user settings) defaults, max, and min
#define PREFS_DEFAULT_IS_PUSH_ENABLE NO

// Geocode behavior
#define MK_LOCAL_SEARCH_SPAN 200000  // Meters span around the current location used by MKLocalSearch

#define STATION_LIST_TEXT   @"Station List"

#define ENABLE_SFMUNI_ADV_DEFAULT FALSE
#define ENABLE_BART_ADV_DEFAULT FALSE
#define ENABLE_ACTRANSIT_ADV_DEFAULT FALSE
#define ENABLE_CALTRAIN_ADV_DEFAULT FALSE
#define ENABLE_WMATA_ADV_DEFAULT TRUE
#define ENABLE_TRIMET_ADV_DEFAULT FALSE

// Core Data database filename
#define COREDATA_DB_FILENAME    @"store101.data"
#define TEST_COREDATA_DB_FILENAME  @"testDataStore.data" // For automated tests

#define LAST_TO_LOCATION              @"lastToLocation"
#define LAST_FROM_LOCATION            @"lastFromLocation"

#define ALL_STATION    @"all_st"

#endif
