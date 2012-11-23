//
// UIConstants.h
// Nimbler Caltrain
//
// Created by John Canfield on 7/3/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
// Constants for defining dimensions and characteristics of the user interface

#ifndef Nimbler_Caltrain_UIConstants_h
#define Nimbler_Caltrain_UIConstants_h

// ToFromViewController constants
#define TOFROM_MAIN_TABLE_HEIGHT 319
#define TOFROM_MAIN_TABLE_HEIGHT_4INCH 405
#define TOFROM_TIME_DATE_HEIGHT 36
#define TOFROM_ROW_HEIGHT 36

// To & From table heights for regular (3.5") iPhone screen 
#define FROM_TABLE_HEIGHT_NO_CL_MODE 107 // height when not isCurrentLocationMode
#define TO_TABLE_HEIGHT_NO_CL_MODE 113
#define FROM_TABLE_HEIGHT_CL_MODE 71 // height when isCurrentLocationMode
#define TO_TABLE_HEIGHT_CL_MODE 152 
#define FROM_TABLE_HEIGHT_EDIT_MODE 148 // height when in Edit mode
#define TO_TABLE_HEIGHT_EDIT_MODE 148

// To & From table heights for iPhone5 and other 4" screens
#define FROM_TABLE_HEIGHT_NO_CL_MODE_4INCH 148 // height when not isCurrentLocationMode
#define TO_TABLE_HEIGHT_NO_CL_MODE_4INCH 148 
#define FROM_TABLE_HEIGHT_CL_MODE_4INCH 148 // height when isCurrentLocationMode
#define TO_TABLE_HEIGHT_CL_MODE_4INCH 148 
#define FROM_TABLE_HEIGHT_EDIT_MODE_4INCH 222 // height when in FROM_EDIT mode
#define TO_TABLE_HEIGHT_EDIT_MODE_4INCH 222 // height when in TO_EDIT mode


#define TOFROM_TABLE_WIDTH 300
#define TOFROM_INSERT_INTO_CELL_MARGIN 2 // spacer added to cell height when there is an inserted field or table
#define TOFROM_TABLE_CORNER_RADIUS 10.0

#define TOFROM_SECTION_LABEL_HEIGHT 23.0
#define TOFROM_SECTION_LABEL_WIDTH 60.0
#define TOFROM_SECTION_NOLABEL_HEIGHT 5.0 // spacer when there is no label
#define TOFROM_SECTION_NOLABEL_HEIGHT_4INCH 5.0 // spacer when there is no label
#define TOFROM_SECTION_LABEL_INDENT 15.0
#define TOFROM_SECTION_FOOTER_HEIGHT 1.0

// ToFromTableViewController constants
#define TOFROM_TEXT_FIELD_INDENT 15
#define TOFROM_TEXT_FIELD_XPOS 10
#define TOFROM_TEXT_FIELD_YPOS 1

// Corner Radius
#define CORNER_RADIUS_SMALL 5.0
#define CORNER_RADIUS_MEDIUM 10.0

// Upadate badge count to ZERO
#define BADGE_COUNT_ZERO 0

#define ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH 280

// RouteDetailsViewController & LegMapViewController
#define ROUTE_DETAILS_TABLE_CELL_TEXT_WIDTH 279 // Obtained thru trial & error, DE-230 fix 
#define ROUTE_LEGMAP_X_ORIGIN 5
#define ROUTE_LEGMAP_Y_ORIGIN 5
#define ROUTE_LEGMAP_WIDTH 309
#define ROUTE_LEGMAP_MIN_HEIGHT 190  // DE192 fix
#define ROUTE_DETAILS_TABLE_MAX_HEIGHT 170
#define ROUTE_DETAILS_TABLE_MAX_HEIGHT_4INCH 220
#define ROUTE_LEGMAP_MIN_HEIGHT_4INCH 220


// Table cell height
#define STANDARD_TABLE_CELL_MINIMUM_HEIGHT 40
// Fixed DE-230 Changed Value from 7 to 15
#define VARIABLE_TABLE_CELL_HEIGHT_BUFFER 7
#define ROUTE_OPTIONS_TABLE_CELL_MINIMUM_HEIGHT 60
#define ROUTE_OPTIONS_VARIABLE_TABLE_CELL_HEIGHT_BUFFER 25

// Font Size
#define STANDARD_FONT_SIZE 13.0
#define MEDIUM_FONT_SIZE 14.0
#define MEDIUM_LARGE_FONT_SIZE 15.0

#define NAVIGATION_LABEL_WIDTH 200.0
#define NAVIGATION_LABEL_HEIGHT 40.0
#define LABEL_MAXWALK_Distance_WIDTH 35.0
#define LABEL_MAXWALK_Distance_HEIGHT 21.0


// Font styles
#define MEDIUM_FONT fontWithName:@"Helvetica" size:14.0
#define MEDIUM_BOLD_FONT fontWithName:@"Helvetica-Bold" size:14.0
#define MEDIUM_OBLIQUE_FONT fontWithName:@"Helvetica-Oblique" size:14.0
#define MEDIUM_LARGE_BOLD_FONT fontWithName:@"Helvetica-Bold" size:15.0
#define MEDIUM_OBLIQUE_FONT    fontWithName:@"Helvetica-Oblique" size:13
#define MEDIUM_LARGE_OBLIQUE_FONT fontWithName:@"Helvetica-Oblique" size:15.0
#define LARGE_BOLD_FONT fontWithName:@"Helvetica-Bold" size:20.0

// Colors
#define NIMBLER_RED_FONT_COLOR colorWithRed:252.0/255.0 green:103.0/255.0 blue:88.0/255.0 alpha:1.0
// #define NIMBLER_YELLOW_FONT_COLOR colorWithRed:255.0/255.0 green:161.0/255.0 blue:77.0/255.0 alpha:1.0
#define NAVIGATION_TITLE_COLOR colorWithRed:98.0/256.0 green:96.0/256.0 blue:96.0/256.0 alpha:1.0
#define GRAY_FONT_COLOR colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0

#define CELL_BACKGROUND_ROUTE_OPTION_VIEW colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:0.04

// UIanimation motion
#define ANIMATION_STANDART_MOTION_SPEED 0.3

// Images

#define NAVIGATION_BAR_IMAGE  [UIImage imageNamed:@"img_navigationbar.png"]

#define NAVIGATION_ITEM1_XPOS 2
#define NAVIGATION_ITEM2_XPOS 78
#define NAVIGATION_ITEM3_XPOS 160
#define NAVIGATION_ITEM4_XPOS 240


#define NAVIGATION_ITEM_YPOS_4INCH      517
#define NAVIGATION_ITEM_WIDTH_4INCH     78
#define NAVIGATION_ITEM_HEIGHT_4INCH    49

#define NAVIGATION_ITEM_YPOS      436
#define NAVIGATION_ITEM_WIDTH     78
#define NAVIGATION_ITEM_HEIGHT    42
 
#define ROUTE_BUTTON_XPOS_4INCH       124
#define ROUTE_BUTTON_YPOS_4INCH       410
#define ROUTE_BUTTON_WIDTH_4INCH      72
#define ROUTE_BUTTON_HEIGHT_4INCH     37

#define IPHONE5HEIGHT                  568

#endif