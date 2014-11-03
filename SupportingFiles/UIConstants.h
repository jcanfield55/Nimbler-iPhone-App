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

//Latest UI Constants

// To & From table heights for regular (3.5") iPhone screen

#define TOFROM_HEIGHT_LOCATION_EDIT_MODE 380 // HEIGHT WHEN ONLY TOFROM LOCATION EDIT MODE

// To & From table heights for iPhone5 and other 4" screens

#define TOFROM_HEIGHT_LOCATION_EDIT_MODE_4INCH 465 // HEIGHT WHEN ONLY TOFROM LOCATION EDIT MODE

#define TOFROM_MAINBGVIEW_HEIGHT_EDIT_MODE 48
#define TOFROMVIEW_HEIGHT_EDIT_MODE 30
#define TXTFROMVIEW_X_POSITION_EDIT_MODE 39
#define TXTTOVIEW_X_POSITION_EDIT_MODE 23
#define TXTFROMVIEW_WIDTH_EDIT_MODE 19

// revealController
#define REVEAL_CONTROLLER_RIGHT_MARGIN 35

// ToFromViewController constants
#define TOFROM_MAIN_TABLE_HEIGHT 366
#define TOFROM_MAIN_TABLE_HEIGHT_4INCH 499
#define TOFROM_ROW_HEIGHT 36

// DatePicker constants (in ToFromViewController)
#define DATE_PICKER_HEIGHT 216
#define DATE_PICKER_TOOLBAR_HEIGHT 44
#define DATE_PICKER_MARGIN_FROM_BOTTOM 10

// To & From table heights for regular (3.5") iPhone screen
#define TO_TABLE_HEIGHT_CL_MODE 155
#define FROM_TABLE_HEIGHT_EDIT_MODE 300 // height when in Edit mode
#define TO_TABLE_HEIGHT_EDIT_MODE 300

// To & From table heights for iPhone5 and other 4" screens
#define TO_TABLE_HEIGHT_CL_MODE_4INCH 148
#define FROM_TABLE_HEIGHT_EDIT_MODE_4INCH 222 // height when in FROM_EDIT mode
#define TO_TABLE_HEIGHT_EDIT_MODE_4INCH 222 // height when in TO_EDIT mode

#define TOFROM_TABLE_WIDTH 320
#define TOFROM_INSERT_INTO_CELL_MARGIN 2 // spacer added to cell height when there is an inserted field or table
#define TOFROM_TABLE_CORNER_RADIUS 10.0

#define FROM_SECTION_LABEL_HEIGHT 23.0
#define TO_SECTION_LABEL_HEIGHT 35.0
#define TOFROM_SECTION_NOLABEL_HEIGHT 5.0 // spacer when there is no label
#define TOFROM_SECTION_NOLABEL_HEIGHT_4INCH 5.0 // spacer when there is no label
#define TOFROM_SECTION_FOOTER_HEIGHT 1.0

#define ADVISORY_BUTTON_WIDTH 47
#define ADVISORY_BUTTON_HEIGHT 26

// ToFromTableViewController constants
#define TOFROM_TABLE_HEADER_HEIGHT 25
#define TOFROM_TEXT_FIELD_INDENT 15
#define TOFROM_TABLE_HEADER_EDIT_BUTTON_MARGIN 45
#define TOFROM_TEXT_FIELD_XPOS 10
#define TOFROM_TEXT_FIELD_YPOS 1

// Corner Radius
#define CORNER_RADIUS_SMALL 5.0
#define CORNER_RADIUS_MEDIUM 10.0

// Update badge count to ZERO
#define BADGE_COUNT_ZERO 0

// RouteOptionsViewController
#define ROUTE_OPTIONS_TABLE_CELL_TEXT_WIDTH 280
#define EXCLUDE_BUTTON_HEIGHT 38
#define EXCLUDE_BUTTON_WIDTH 72
#define EXCLUDE_BUTTONS_PER_ROW 4

// RouteDetailsViewController
#define ROUTE_DETAILS_TABLE_CELL_TEXT_BORDER 47 // Amount to subtract from the cell width to determine the width for wrapping multi-line text.  Obtained thru trial & error.
#define ROUTE_DETAILS_MINIMUM_TABLE_HEIGHT 90  // Minimum margin on the bottom for route table and feedback button
#define ROUTE_DETAILS_MINIMUM_MAP_HEIGHT 40

// LegMapViewController
#define MAP_ALPHA_LIGHT 0.7
#define MAP_ALPHA_MEDIUM 0.8
#define MAP_ALPHA_LIGHTER 0.4
#define MAP_LINE_WIDTH 5   // Line width for maps

// SettingInfoViewController
#define DETAIL_SETTING_MAIN_LABEL_XPOS        10
#define DETAIL_SETTING_MAIN_LABEL_YPOS        5
#define DETAIL_SETTING_MAIN_LABEL_WIDTH       250
#define DETAIL_SETTING_MAIN_LABEL_HEIGHT      20

#define SLIDERS_XPOS                          33
#define SLIDERS_YPOS                          42
#define SLIDERS_YPOS1                         50
#define SLIDERS_WIDTH_BUFFER                  88   // difference between table width and slider width
#define SLIDERS_WIDTH_MINIMUM                 100  // minimum sliders width regardless of table width
#define SLIDERS_HEIGHT                        20

#define BIKE_DISTANCE_LABEL_XPOS              20
#define BIKE_DISTANCE_LABEL_YPOS              41
#define BIKE_DISTANCE_LABEL_WIDTH             50
#define BIKE_DISTANCE_LABEL_HEIGHT            20

#define DETAILS_RIGHT_LABEL_RIGHT_BUFFER     (35 + 4) // Buffer between right side of right label and trailing superview edge

#define BIKE_PREFERENCE_LABEL_XPOS                  10
#define BIKE_PREFERENCE_LABEL_YPOS                  29
#define BIKE_PREFERENCE_LABEL_WIDTH                 150
#define BIKE_PREFERENCE_LABEL_HEIGHT                20

#define LABEL_FREQUENTLY_XPOS   3
#define LABEL_FREQUENTLY_YPOS   42
#define LABEL_FREQUENTLY_WIDTH  70
#define LABEL_FREQUENTLY_HEIGHT 20

#define RIGHT_LABEL_BUFFER      4   // Buffer between slider and right label
#define LABEL_RARELY_YPOS       42
#define LABEL_RARELY_WIDTH      50
#define LABEL_RARELY_HEIGHT     20

#define SLIDER_PUSH_FREQUENCY_XPOS    33
#define SLIDER_PUSH_FREQUENCY_YPOS    42
#define SLIDER_PUSH_FREQUENCY_HEIGHT  12

#define SETTING_MAIN_LABEL_XPOS        35
#define SETTING_MAIN_LABEL_YPOS        5
#define SETTING_MAIN_LABEL_WIDTH       250
#define SETTING_MAIN_LABEL_HEIGHT      20
#define SETTING_MAIN_LABEL_XPOS_IOS7   50
#define SETTING_MAIN_LABEL_WIDTH_IOS7 235


#define SETTING_SUB_LABEL_XPOS        5
#define SETTING_SUB_LABEL_YPOS        41
#define SETTING_SUB_LABEL_WIDTH       50
#define SETTING_SUB_LABEL_HEIGHT      20

// Feedback
#define FEEDBACK_POPUP_CANCEL_RIGHT_MARGIN 8

// Table cell height
#define STANDARD_TABLE_CELL_MINIMUM_HEIGHT 40
// Fixed DE-230 Changed Value from 7 to 15
#define VARIABLE_TABLE_CELL_HEIGHT_BUFFER 7
#define ROUTE_OPTIONS_TABLE_CELL_MINIMUM_HEIGHT 60
#define ROUTE_OPTIONS_VARIABLE_TABLE_CELL_HEIGHT_BUFFER 25

// Font Size
#define SMALL_FONT_SIZE 12.0
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
#define SMALL_FONT fontWithName:@"Helvetica-Bold" size:13.0
#define SMALL_OBLIQUE_FONT    fontWithName:@"Helvetica-Oblique" size:13
#define MEDIUM_LARGE_OBLIQUE_FONT fontWithName:@"Helvetica-Oblique" size:15.0
#define LARGE_BOLD_FONT fontWithName:@"Helvetica-Bold" size:20.0

// Colors
#define NIMBLER_RED_FONT_COLOR colorWithRed:252.0/255.0 green:103.0/255.0 blue:88.0/255.0 alpha:1.0
// #define NIMBLER_YELLOW_FONT_COLOR colorWithRed:255.0/255.0 green:161.0/255.0 blue:77.0/255.0 alpha:1.0
#define NAVIGATION_TITLE_COLOR colorWithRed:98.0/256.0 green:96.0/256.0 blue:96.0/256.0 alpha:1.0
#define GRAY_FONT_COLOR colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1.0

#define GRAY_FONT_COLOR_CELLDETAILTEXT colorWithRed:137.0/255.0 green:137.0/255.0 blue:137.0/255.0 alpha:1.0
#define GRAY_FONT_COLOR_CELLTEXT colorWithRed:29.0/255.0 green:29.0/255.0 blue:29.0/255.0 alpha:1.0

#define CELL_BACKGROUND_ROUTE_OPTION_VIEW colorWithRed:109.0/255.0 green:109.0/255.0 blue:109.0/255.0 alpha:0.04
#define LIGHT_GRAY_FONT_COLOR colorWithRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:1.0

// UIanimation motion
#define ANIMATION_STANDART_MOTION_SPEED 0.3

// Images
#define NAVIGATION_BAR_IMAGE  [UIImage imageNamed:@"navBar.png"]

#define NAVIGATION_ITEM1_XPOS 0

#define NAVIGATION_ITEM_YPOS      436
#define NAVIGATION_ITEM_WIDTH     95
#define NAVIGATION_ITEM_HEIGHT    49

#define ROUTE_BUTTON_XPOS_4INCH       124
#define ROUTE_BUTTON_YPOS_4INCH       450
#define ROUTE_BUTTON_WIDTH_4INCH      72
#define ROUTE_BUTTON_HEIGHT_4INCH     37

// iPhone model screen sizes, for reference only
#define IPHONE4_WIDTH       320
#define IPHONE4_HEIGHT      480
#define IPHONE5_WIDTH       320
#define IPHONE5HEIGHT       568
#define IPHONE6_WIDTH       375
#define IPHONE6_HEIGHT      667
#define IPHONE6PLUS_WIDTH   414
#define IPHONE6PLUS_HEIGHT  (2208/3)

#endif