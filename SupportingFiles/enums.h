//
//  enums.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#ifndef Network_Commuting_enums_h
#define Network_Commuting_enums_h

// Supported Geocoder services.  For each new service, objectMapperForGeocoder method needs updating.  
typedef enum {
    GOOGLE_GEOCODER,
    OTP_PLANNER,
    ERROR_PLANNER,
    BAYAREA_PLANNER,
    IOS_GEOCODER,
    STATION_PARSER
} APIType;

typedef enum {
    DEPART,
    ARRIVE
} DepartOrArrive;

typedef enum {
    PLAN_STATUS_OK,
    PLAN_GENERIC_EXCEPTION,  // Provide an error saying we are unable to perform route
    PLAN_NO_NETWORK,
    PLAN_NOT_AVAILABLE_THAT_TIME 
} PlanRequestStatus;

typedef enum {
    GEOCODE_STATUS_OK,
    GEOCODE_ZERO_RESULTS,
    GEOCODE_OVER_QUERY_LIMIT,
    GEOCODE_REQUEST_DENIED,
    GEOCODE_GENERIC_ERROR,
    GEOCODE_NO_NETWORK
} GeocodeRequestStatus;

#endif
