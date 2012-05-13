//
//  enums.h
//  Network Commuting
//
//  Created by John Canfield on 1/18/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#ifndef Network_Commuting_enums_h
#define Network_Commuting_enums_h

// Supported Geocoder services.  For each new service, objectMapperForGeocoder method needs updating.  
typedef enum {
    GOOGLE_GEOCODER,
    OTP_PLANNER,
    ERROR_PLANNER,
    BAYAREA_PLANNER
} APIType;

typedef enum {
    DEPART,
    ARRIVE
} DepartOrArrive;

#endif
