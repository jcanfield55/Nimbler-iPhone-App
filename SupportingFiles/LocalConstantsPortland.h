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
#define NEWGEOCODE_RESULT_MSG @"in the Portland"
#define LOCATION_NOTAPPEAR_MSG @"Portland"
#define APP_TITLE              @"Nimbler Portland"

#define METADATA_URL                   @"plan/graph/metadata?appType=6"

// Default boundaries for geolocation and routing
#define MIN_LAT           @"45.096058"
#define MIN_LONG          @"-123.2109336"
#define MAX_LAT           @"45.896979"
#define MAX_LONG          @"-122.11313380000001"

// Flurry Key
#define FLURRY_API_KEY @"VV2CQHMG5JJ93VXZ56BD"

// Facebook App ID (for tracking referrals)
#define FB_APP_ID @""  // Nimbler SF FB App ID

// Review reminder URL
#define NIMBLER_REVIEW_URL       @"itms-apps://itunes.apple.com/app/id883524784"
// old NIMBLER_REVIEW_URL @"http://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=883524784"

// UserPreferernce (user settings) defaults, max, and min
#define PREFS_DEFAULT_IS_PUSH_ENABLE NO

// Geocode behavior
#define MK_LOCAL_SEARCH_SPAN 120000  // Meters span around the current location used by MKLocalSearch

#define STATION_LIST_TEXT   @"Trimet Station List"

#define ENABLE_SFMUNI_ADV_DEFAULT TRUE
#define ENABLE_BART_ADV_DEFAULT TRUE
#define ENABLE_ACTRANSIT_ADV_DEFAULT FALSE
#define ENABLE_CALTRAIN_ADV_DEFAULT FALSE
#define ENABLE_WMATA_ADV_DEFAULT FALSE
#define ENABLE_TRIMET_ADV_DEFAULT TRUE

// Core Data database filename
#define COREDATA_DB_FILENAME    @"store101.data"
#define TEST_COREDATA_DB_FILENAME  @"testDataStore.data" // For automated tests

#define LAST_TO_LOCATION              @"lastToLocation"
#define LAST_FROM_LOCATION            @"lastFromLocation"

#define ALL_STATION    @"trimet_st_list"

#endif
