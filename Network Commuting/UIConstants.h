//
//  UIConstants.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 7/3/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//
// Constants for defining dimensions and characteristics of the user interface

#ifndef Nimbler_Caltrain_UIConstants_h
#define Nimbler_Caltrain_UIConstants_h

// ToFromViewController constants
#define TOFROM_MAIN_TABLE_HEIGHT            358
#define TOFROM_TIME_DATE_HEIGHT             37
#define TOFROM_ROW_HEIGHT                   37
#define FROM_HEIGHT_CL_MODE                 37
#define TOFROM_TABLE_HEIGHT_NO_CL_MODE      110  // height when not isCurrentLocationMode
#define TO_TABLE_HEIGHT_CL_MODE             185  // height when isCurrentLocationMode
#define TOFROM_TABLE_WIDTH                  300
#define TOFROM_INSERT_INTO_CELL_MARGIN      1  // spacer added to cell height when there is an inserted field or table 
#define TOFROM_TABLE_CORNER_RADIUS          10.0


// ToFromTableViewController constants
#define TOFROM_TEXT_FIELD_INDENT            10

// Corner Radius
#define CORNER_RADIUS_SMALL                 5.0

// Upadate badge count to ZERO
#define BADGE_COUNT_ZERO                    0

// RouteDetailsViewController & LegMapViewController
#define ROUTE_DETAILS_TABLE_CELL_TEXT_WIDTH  298 // Obtained thru trial & error for DE95 fix
#define ROUTE_LEGMAP_X_ORIGIN               0
#define ROUTE_LEGMAP_Y_ORIGIN               0
#define ROUTE_LEGMAP_WIDTH                  320
#define ROUTE_LEGMAP_MIN_HEIGHT             190
#define ROUTE_DETAILS_TABLE_MAX_HEIGHT      180

// Table cell height
#define STANDARD_TABLE_CELL_MINIMUM_HEIGHT  44
#define VARIABLE_TABLE_CELL_HEIGHT_BUFFER   7

// Font Size
#define STANDARD_FONT_SIZE                  12.0
#define MEDIUM_FONT_SIZE                    14.0
#define LARGE_FONT_SIZE                     16.0
#define LARGER_FONT_SIZE                    20.0

#endif
