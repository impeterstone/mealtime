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
#import "GANTracker.h"
#import "LocalyticsSession.h"

#define kLocalyticsKey @"d700c1cd0a07dd9dbc70c51-dd6fed50-e57d-11e0-2071-00c25d050352"

#define CATEGORIES @"Afghan|African|American (New)|American (Traditional)|Argentine|Asian Fusion|Barbeque|Basque|Belgian|Brasseries|Brazilian|Breakfast & Brunch|British|Buffets|Burgers|Burmese|Cafes|Cajun/Creole|Cambodian|Caribbean|Cheesesteaks|Chicken Wings|Chinese|Creperies|Cuban|Delis|Diners|Ethiopian|Fast Food|Filipino|Fish & Chips|Fondue|Food Stands|French|Gastropubs|German|Gluten-Free|Greek|Halal|Hawaiian|Himalayan/Nepalese|Hot Dogs|Hungarian|Indian|Indonesian|Irish|Italian|Japanese|Korean|Kosher|Latin American|Live/Raw Food|Malaysian|Mediterranean|Mexican|Middle Eastern|Modern European|Mongolian|Moroccan|Pakistani|Persian/Iranian|Peruvian|Pizza|Polish|Portuguese|Russian|Sandwiches|Scandinavian|Seafood|Singaporean|Soul Food|Soup|Southern|Spanish|Steakhouses|Sushi Bars|Taiwanese|Tapas Bars|Tapas/Small Plates|Tex-Mex|Thai|Turkish|Ukrainian|Vegan|Vegetarian|Vietnamese|Afghan|African|American (New)|American (Traditional)|Argentine|Asian Fusion|Barbeque|Basque|Belgian|Brasseries|Brazilian|Breakfast & Brunch|British|Buffets|Burgers|Burmese|Cafes|Cajun/Creole|Cambodian|Caribbean|Cheesesteaks|Chicken Wings|Chinese|Creperies|Cuban|Delis|Diners|Ethiopian|Fast Food|Filipino|Fish & Chips|Fondue|Food Stands|French|Gastropubs|German|Gluten-Free|Greek|Halal|Hawaiian|Himalayan/Nepalese|Hot Dogs|Hungarian|Indian|Indonesian|Irish|Italian|Japanese|Korean|Kosher|Latin American|Live/Raw Food|Malaysian|Mediterranean|Mexican|Middle Eastern|Modern European|Mongolian|Moroccan|Pakistani|Persian/Iranian|Peruvian|Pizza|Polish|Portuguese|Russian|Sandwiches|Scandinavian|Seafood|Singaporean|Soul Food|Soup|Southern|Spanish|Steakhouses|Sushi Bars|Taiwanese|Tapas Bars|Tapas/Small Plates|Tex-Mex|Thai|Turkish|Ukrainian|Vegan|Vegetarian|Vietnamese|Bagels|Bakeries|Beer, Wine & Spirits|Breweries|Butcher|Coffee & Tea|Convenience Stores|Desserts|Do-It-Yourself Food|Donuts|Farmers Market|Food Delivery Services|Grocery|Ice Cream & Frozen Yogurt|Internet Cafes|Juice Bars & Smoothies|Specialty Food|Street Vendors|Tea Rooms|Wineries|Dim Sum|Wine Bars|Meat Shops|Restaurants|Sports Bars|Cheese Shops|Ethnic Food|Seafood Markets|Bistros|Kebab|Delicatessen|Serbo Croatian|Canteen|Austrian|International|Local Flavor|Beer Garden|Curry Sausage|Lebanese|Lounges|Bars|Pubs"

// Milano, ITALY|Roma, ITALY|Barcelona, SPAIN|Madrid, SPAIN
// Zürich, SWITZERLAND

#define LOCATIONS @"Wien, AUSTRIA|Antwerpen, BELGIUM|Bruxelles, BELGIUM|Calgary, CANADA|Edmonton, CANADA|Halifax, CANADA|Montréal, CANADA|Ottawa, CANADA|Toronto, CANADA|Vancouver, CANADA|Lyon, FRANCE|Marseille, FRANCE|Paris, FRANCE|Berlin, GERMANY|Frankfurt, GERMANY|Hamburg, GERMANY|Köln, GERMANY|München, GERMANY|Dublin, IRELAND|Amsterdam, NETHERLANDS|Belfast, UNITED KINGDOM|Brighton, UNITED KINGDOM|Bristol, UNITED KINGDOM|Cardiff, UNITED KINGDOM|Edinburgh, UNITED KINGDOM|Glasgow, UNITED KINGDOM|Leeds, UNITED KINGDOM|Liverpool, UNITED KINGDOM|London, UNITED KINGDOM|Manchester, UNITED KINGDOM|Phoenix, AZ|Scottsdale, AZ|Tempe, AZ|Tucson, AZ|Alameda, CA|Albany, CA|Alhambra, CA|Anaheim, CA|Belmont, CA|Berkeley, CA|Beverly Hills, CA|Big Sur, CA|Burbank, CA|Cheviot Hills, CA|Concord, CA|Costa Mesa, CA|Culver City, CA|Cupertino, CA|Daly City, CA|Davis, CA|Dublin, CA|Emeryville, CA|Foster City, CA|Fremont, CA|Glendale, CA|Hayward, CA|Healdsburg, CA|Huntington Beach, CA|Irvine, CA|La Jolla, CA|Livermore, CA|Long Beach, CA|Los Altos, CA|Los Angeles, CA|North Hollywood, CA|Sherman Oaks, CA|Los Gatos, CA|Marina del Rey, CA|Menlo Park, CA|Mill Valley, CA|Millbrae, CA|Milpitas, CA|Monterey, CA|Mountain View, CA|Napa, CA|Newark, CA|Newport Beach, CA|Oakland, CA|Orange County, CA|Palo Alto, CA|Park La Brea, CA|Pasadena, CA|Pleasanton, CA|Redondo Beach, CA|Redwood City, CA|Sacramento, CA|San Bruno, CA|San Carlos, CA|San Diego, CA|San Francisco, CA|San Jose, CA|San Leandro, CA|San Mateo, CA|San Rafael, CA|Santa Barbara, CA|Santa Clara, CA|Santa Cruz, CA|Santa Monica, CA|Santa Rosa, CA|Sausalito, CA|Sonoma, CA|South Lake Tahoe, CA|Stockton, CA|Studio City, CA|Sunnyvale, CA|Torrance, CA|Union City, CA|Venice, CA|Walnut Creek, CA|West Hollywood, CA|West Los Angeles, CA|Westwood, CA|Yountville, CA|Boulder, CO|Denver, CO|Hartford, CT|New Haven, CT|Washington, DC|Fort Lauderdale, FL|Gainesville, FL|Miami, FL|Miami Beach, FL|Orlando, FL|Tampa, FL|Atlanta, GA|Savannah, GA|Honolulu, HI|Lahaina, HI|Iowa City, IA|Boise, ID|Chicago, IL|Evanston, IL|Naperville, IL|Schaumburg, IL|Skokie, IL|Bloomington, IN|Indianapolis, IN|Louisville, KY|New Orleans, LA|Allston, MA|Boston, MA|Brighton, MA|Brookline, MA|Cambridge, MA|Somerville, MA|Baltimore, MD|Ann Arbor, MI|Detroit, MI|Minneapolis, MN|Saint Paul, MN|Kansas City, MO|Saint Louis, MO|Charlotte, NC|Durham, NC|Raleigh, , NC|Newark, NJ|Princeton, NJ|Albuquerque, NM|Santa Fe, NM|Las Vegas, NV|Reno, NV|Brooklyn, NY|Long Island City, NY|New York, NY|Flushing, NY|Cincinnati, OH|Cleveland, OH|Columbus, OH|Portland, OR|Salem, OR|Philadelphia, PA|Pittsburgh, PA|Providence, RI|Charleston, SC|Memphis, TN|Nashville, TN|Austin, TX|Dallas, TX|Houston, TX|San Antonio, TX|Salt Lake City, UT|Alexandria, VA|Arlington, VA|Richmond, VA|Burlington, VT|Bellevue, WA|Redmond, WA|Seattle, WA|Madison, WI|Milwaukee, WI"

//#define USE_FIXTURES 1
//#define SHOULD_RESET_SQLITE
#define SCHEMA_VERSION @"20"

// Core Data (From PSConstants.h)
#define CORE_DATA_SQL_FILE @"mealtime.sqlite"
#define CORE_DATA_MOM @"MealTime"

// User Agent
#define USER_AGENT @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_5 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5"
//#define USER_AGENT @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/534.48.3 (KHTML, like Gecko) Version/5.1 Safari/534.48.3"

// App Delegate Macro
#define APP_DELEGATE ((MealTimeAppDelegate *)[[UIApplication sharedApplication] delegate])

#define HIGHLY_RATED_REVIEWS 99
#define HIGHLY_RATED_RATING 3.5

// Tags
#define kSortActionSheet 7070
#define kFilterActionSheet 7071

#define kAlertCall 8010
#define kAlertYelp 8011
#define kAlertShare 8012
#define kAlertDirections 8013
#define kAlertGPSError 8014
#define kAlertSendLove 8015
#define kAlertRenameList 8016
#define kAlertNewList 8017

#define kActionSheetFilter 9010

// Notifications
#define kLocationAcquired @"LocationAcquired"
#define kLocationUnchanged @"LocationUnchanged"
#define kLogoutRequested @"LogoutRequested"
#define kOrientationChanged @"OrientationChangedNotification"

// Facebook
#define FB_APP_ID @"262079367168011"
#define FB_PERMISSIONS_PUBLISH @"publish_stream"
#define FB_BASIC_PERMISISONS [NSArray arrayWithObjects:@"offline_access", nil]

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


// Time in seconds
#define DAY_SECONDS 86400
#define WEEK_SECONDS 604800