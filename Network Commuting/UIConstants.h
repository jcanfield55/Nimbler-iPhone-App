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
#define TOFROM_MAIN_TABLE_HEIGHT            319
#define TOFROM_TIME_DATE_HEIGHT             37
#define TOFROM_ROW_HEIGHT                   37
#define FROM_HEIGHT_CL_MODE                 37
#define TOFROM_TABLE_HEIGHT_NO_CL_MODE      110  // height when not isCurrentLocationMode
#define TO_TABLE_HEIGHT_CL_MODE             185  // height when isCurrentLocationMode
#define TOFROM_TABLE_WIDTH                  300
#define TOFROM_INSERT_INTO_CELL_MARGIN      1  // spacer added to cell height when there is an inserted field or table 
#define TOFROM_TABLE_CORNER_RADIUS          10.0

#define TOFROM_SECTION_LABEL_HEIGHT         23.0
#define TOFROM_SECTION_LABEL_WIDTH          60.0
#define TOFROM_SECTION_NOLABEL_HEIGHT        5.0 // spacer when there is no label
#define TOFROM_SECTION_LABEL_INDENT         15.0
#define TOFROM_SECTION_FOOTER_HEIGHT         1.0

// ToFromTableViewController constants
#define TOFROM_TEXT_FIELD_INDENT            10

// Corner Radius
#define CORNER_RADIUS_SMALL                 5.0
#define CORNER_RADIUS_MEDIUM                10.0

// Upadate badge count to ZERO
#define BADGE_COUNT_ZERO                    0

// RouteDetailsViewController & LegMapViewController
#define ROUTE_DETAILS_TABLE_CELL_TEXT_WIDTH  298 // Obtained thru trial & error for DE95 fix
#define ROUTE_LEGMAP_X_ORIGIN               5
#define ROUTE_LEGMAP_Y_ORIGIN               5
#define ROUTE_LEGMAP_WIDTH                  309
#define ROUTE_LEGMAP_MIN_HEIGHT             250
#define ROUTE_DETAILS_TABLE_MAX_HEIGHT      110

// Table cell height
#define STANDARD_TABLE_CELL_MINIMUM_HEIGHT  40
#define VARIABLE_TABLE_CELL_HEIGHT_BUFFER   7

// Font Size
#define STANDARD_FONT_SIZE                  13.0
#define MEDIUM_FONT_SIZE                    14.0
#define MEDIUM_LARGE_FONT_SIZE              15.0


// Font styles
#define MEDIUM_BOLD_FONT                    fontWithName:@"Helvetica-Bold" size:14.0
#define MEDIUM_OBLIQUE_FONT                 fontWithName:@"Helvetica-Oblique" size:14.0
#define MEDIUM_LARGE_BOLD_FONT              fontWithName:@"Helvetica-Bold" size:15.0
#define MEDIUM_LARGE_OBLIQUE_FONT           fontWithName:@"Helvetica-Oblique" size:15.0

// Colors
#define NIMBLER_RED_FONT_COLOR              colorWithRed:252.0/255.0 green:103.0/255.0 blue:88.0/255.0 alpha:1.0

#endif
