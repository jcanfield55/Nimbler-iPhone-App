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
#define DEFAULT_TIME_ZONE @"America/Los_Angeles"

// App specific user text
#define NEWGEOCODE_RESULT_MSG @"in the San Francisco Bay Area"
#define LOCATION_NOTAPPEAR_MSG @"Bay Area"
#define APP_TITLE              @"Nimbler SF"

#define METADATA_URL                   @"plan/graph/metadata?appType=4"

// Default boundaries for geolocation and routing
#define MIN_LAT           @"36.791000000000004"
#define MIN_LONG          @"-123.4631719"
#define MAX_LAT           @"38.7189988"
#define MAX_LONG          @"-121.025001"

// Flurry API Key
#define FLURRY_API_KEY @"27WGHH9DG5Z5MRCB5QRN"

// Facebook App ID (for tracking referrals)
#define FB_APP_ID @"247868928685317"  // Nimbler SF FB App ID

// Review reminder URL
#define NIMBLER_REVIEW_URL       @"itms-apps://itunes.apple.com/app/id638067545"
// old NIMBLER_REVIEW_URL @"http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=638067545"

// UserPreferernce (user settings) defaults, max, and min
#define PREFS_DEFAULT_IS_PUSH_ENABLE NO

// Geocode behavior
#define MK_LOCAL_SEARCH_SPAN 120000  // Meters span around the current location used by MKLocalSearch

#define STATION_LIST_TEXT   @"Station List"

#define ENABLE_SFMUNI_ADV_DEFAULT TRUE
#define ENABLE_BART_ADV_DEFAULT TRUE
#define ENABLE_ACTRANSIT_ADV_DEFAULT FALSE
#define ENABLE_CALTRAIN_ADV_DEFAULT FALSE
#define ENABLE_WMATA_ADV_DEFAULT FALSE
#define ENABLE_TRIMET_ADV_DEFAULT FALSE

// Core Data database filename
#define COREDATA_DB_FILENAME    @"store102.data"
#define TEST_COREDATA_DB_FILENAME  @"testDataStore.data" // For automated tests

#define LAST_TO_LOCATION              @"newLastToLocation"
#define LAST_FROM_LOCATION            @"newLastFromLocation"

#define ALL_STATION    @"all_st"

#endif
