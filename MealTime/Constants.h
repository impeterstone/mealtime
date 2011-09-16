/*
 *  Constants.h
 *  PhotoTime
 *
 *  Created by Peter Shih on 10/8/10.
 *  Copyright 2010 Seven Minute Apps. All rights reserved.
 *
 */

#import "MealTimeAppDelegate.h"
#import "NetworkConstants.h"
#import "LocalyticsSession.h"
#import "UINavigationBar+Custom.h"
#import "UIToolbar+Custom.h"

#warning sql reset
//#define USE_FIXTURES 1
//#define SHOULD_RESET_SQLITE

// Core Data (From PSConstants.h)
#define CORE_DATA_SQL_FILE @"spotlight.sqlite"
#define CORE_DATA_MOM @"MealTime"

// User Agent
#define USER_AGENT @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5"
//#define USER_AGENT @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/534.48.3 (KHTML, like Gecko) Version/5.1 Safari/534.48.3"

// App Delegate Macro
#define APP_DELEGATE ((MealTimeAppDelegate *)[[UIApplication sharedApplication] delegate])

// Tags
#define kSortActionSheet 7070
#define kFilterActionSheet 7071

#define kAlertCall 8010
#define kAlertReviews 8011
#define kAlertShare 8012
#define kAlertDirections 8013
#define kAlertGPSError 8014

// Notifications
#define kLocationAcquired @"LocationAcquired"
#define kLocationUnchanged @"LocationUnchanged"
#define kLogoutRequested @"LogoutRequested"
#define kOrientationChanged @"OrientationChangedNotification"

// Facebook
#define FB_APP_ID @"251612101539714"
#define FB_APP_SECRET @"77686ad944e00b40cae96dbeb2b28fd6"
#define FB_PERMISSIONS_PUBLISH @"publish_stream"
#define FB_PARAMS @"id,first_name,last_name,name,gender,locale"

// ERROR STRINGS
#define LOGOUT_ALERT @"Are you sure you want to logout?"
#define PS_NETWORK_ERROR @"We have encountered a network error. Please check your network connection and try again."

// FONTS
#define CAPTION_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0]
#define TITLE_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0]
#define LARGE_FONT [UIFont fontWithName:@"HelveticaNeue" size:16.0]
#define NORMAL_FONT [UIFont fontWithName:@"HelveticaNeue" size:14.0]
#define BOLD_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0]
#define SUBTITLE_FONT [UIFont fontWithName:@"HelveticaNeue" size:12.0]
#define TIMESTAMP_FONT [UIFont fontWithName:@"HelveticaNeue" size:10.0]
#define NAV_BUTTON_FONT [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0]

// Colors
#define COLOR_CHARCOAL RGBCOLOR(33,33,33)

// CELLS
#define CELL_WHITE_COLOR [UIColor whiteColor]
#define CELL_BLACK_COLOR [UIColor blackColor]
#define CELL_GRAY_BLUE_COLOR RGBCOLOR(62,76,102)
#define CELL_BLUE_COLOR FB_BLUE_COLOR
#define CELL_DARK_BLUE_COLOR FB_COLOR_DARK_BLUE
#define CELL_LIGHT_BLUE_COLOR KUPO_LIGHT_BLUE_COLOR
#define CELL_GRAY_COLOR GRAY_COLOR
#define CELL_LIGHT_GRAY_COLOR VERY_LIGHT_GRAY
#define CELL_VERY_LIGHT_BLUE_COLOR FB_COLOR_VERY_LIGHT_BLUE

#define CELL_BACKGROUND_COLOR CELL_BLACK_COLOR
#define CELL_UNREAD_COLOR KUPO_BLUE_COLOR
#define CELL_COLOR_ALPHA RGBACOLOR(255,255,255,0.9)
#define CELL_COLOR RGBCOLOR(255,255,255)
#define CELL_SELECTED_COLOR KUPO_BLUE_COLOR

#define TABLE_BG_COLOR_ALPHA RGBACOLOR(235,235,235,0.9)
#define TABLE_BG_COLOR RGBCOLOR(235,235,235)

// NAV
#define NAV_COLOR_DARK_BLUE RGBCOLOR(62,76,102)

#define KUPO_LIGHT_GREEN_COLOR RGBCOLOR(205,225,200)
#define KUPO_BLUE_COLOR RGBCOLOR(45.0,147.0,204.0)
#define KUPO_LIGHT_BLUE_COLOR RGBCOLOR(0,179,249)

// GENERIC COLORS
// FB DARK BLUE 51/78/141
// FB LIGHT BLUE 161/176/206
#define FB_COLOR_VERY_LIGHT_BLUE RGBCOLOR(220.0,225.0,235.0)
#define FB_COLOR_LIGHT_BLUE RGBCOLOR(161.0,176.0,206.0)
#define FB_COLOR_DARK_BLUE RGBCOLOR(51.0,78.0,141.0)
#define LIGHT_GRAY RGBCOLOR(247.0,247.0,247.0)
#define VERY_LIGHT_GRAY RGBCOLOR(226.0,231.0,237.0)
#define GRAY_COLOR RGBCOLOR(87.0,108.0,137.0)
#define SECTION_HEADER_COLOR RGBCOLOR(50,50,50)

#define SEPARATOR_COLOR RGBCOLOR(200.0,200.0,200.0)

#define FB_BLUE_COLOR RGBCOLOR(59.0,89.0,152.0)
#define FB_COLOR_DARK_GRAY_BLUE RGBCOLOR(79.0,92.0,117.0)

