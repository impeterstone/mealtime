//
//  MealTimeAppDelegate.m
//  MealTime
//
//  Created by Peter Shih on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MealTimeAppDelegate.h"
#import "PSConstants.h"
#import "PSStyleSheet.h"
#import "RootViewController.h"
#import "PSFacebookCenter.h"
#import "PSDatabaseCenter.h"
#import "ASIHTTPRequest.h"
#import "PSDataCenter.h"
#import "PSNetworkQueue.h"
#import "PSLocationCenter.h"
#import "Crittercism.h"
#import "PSReachabilityCenter.h"

// Dispatch period in seconds
static const NSInteger kGANDispatchPeriodSec = 10;

@interface MealTimeAppDelegate (Private)

+ (void)setupDefaults;

- (void)sendRequestsHome;

@end

@implementation MealTimeAppDelegate

@synthesize window = _window;

+ (void)initialize {
  [self setupDefaults];
}

#pragma mark - Initial Defaults
+ (void)setupDefaults {
  if ([self class] == [MealTimeAppDelegate class]) {
    NSString *initialDefaultsPath = [[NSBundle mainBundle] pathForResource:@"InitialDefaults" ofType:@"plist"];
    assert(initialDefaultsPath != nil);
    
    NSDictionary *initialDefaults = [NSDictionary dictionaryWithContentsOfFile:initialDefaultsPath];
    assert(initialDefaults != nil);
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:initialDefaults];
    
    // Set app version if first launch
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"appVersion"]) {
      
      [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"appVersion"];
      [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
      NSString *savedAppVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"appVersion"];
      
      if (![appVersion isEqualToString:savedAppVersion]) {
        // App Version DOES NOT MATCH
        DLog(@"App Version CHANGED FROM OLD: %@ <---> TO NEW: %@", savedAppVersion, appVersion);
        
        // Reset how many filters we should try to scrape to 999.
        // This eventually falls back to 99 if the server 403's
        [[NSUserDefaults standardUserDefaults] setInteger:999 forKey:@"filterNumPhotos"];
        
//#define SHOULD_RESET_USER_DEFAULTS
#ifdef SHOULD_RESET_USER_DEFAULTS
        // Clear all user defaults
        [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
#endif
        
        // IF we are going from v1 to v2, we need to perform DB MIGRATION
        if ([savedAppVersion floatValue] < 2.0 && [appVersion floatValue] >= 2.0) {
          [[self class] migrateDatabaseV1toV2];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"appVersion"];
        [[NSUserDefaults standardUserDefaults] synchronize];
      }
    }
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"schemaVersion"]) {
      // No schema found, reset the DB anyways
      NSString *sqliteDocumentsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", SQLITE_DB]];
      NSError *error = nil;
      [[NSFileManager defaultManager] removeItemAtPath:sqliteDocumentsPath error:&error];
      
      [[NSUserDefaults standardUserDefaults] setObject:SCHEMA_VERSION forKey:@"schemaVersion"];
      [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
      NSString *savedSchemaVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"schemaVersion"];
      if (![savedSchemaVersion isEqualToString:SCHEMA_VERSION]) {
        // SQL schema changed
        // Reset the SQLite DB
        NSString *sqliteDocumentsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", SQLITE_DB]];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:sqliteDocumentsPath error:&error];
        
        [[NSUserDefaults standardUserDefaults] setObject:SCHEMA_VERSION forKey:@"schemaVersion"];
        [[NSUserDefaults standardUserDefaults] synchronize];
      }
    }
    
    // Copy SQLite to Documents
    NSString *sqlitePath = [[NSBundle mainBundle] pathForResource:SQLITE_DB ofType:@"sqlite"];
    assert(sqlitePath != nil);
    
    NSString *sqliteDocumentsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", SQLITE_DB]];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:sqlitePath 
                                            toPath:sqliteDocumentsPath 
                                             error:&error];
    assert(sqliteDocumentsPath != nil);
  }
}

#pragma mark - Migration
+ (void)migrateDatabaseV1toV2 {
  NSLog(@"Migrading Databse from V1 to V2");
  
  // Read old lists, write into new lists
  EGODatabase *oldDatabase = [EGODatabase databaseWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"sml.sqlite"]]];
  
  [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"BEGIN TRANSACTION"];
                              
  EGODatabaseResult *oldListsRes = [oldDatabase executeQueryWithParameters:@"SELECT * FROM lists", nil];
  for (EGODatabaseRow *row in oldListsRes) {
    NSString *query = [NSString stringWithFormat:@"INSERT INTO lists (sid, name, position, timestamp, notes) VALUES (?, ?, ?, ?, ?)"];
    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, [row stringForColumn:@"sid"], [row stringForColumn:@"name"], [NSNumber numberWithInt:[row intForColumn:@"position"]], [NSDate dateWithTimeIntervalSince1970:[row doubleForColumn:@"timestamp"]], [row stringForColumn:@"notes"], nil];
  }
  
  // Read old lists_places, write into new lists_places
  NSMutableArray *oldPlacesBiz = [NSMutableArray arrayWithCapacity:1];
  
  EGODatabaseResult *oldListsPlacesRes = [oldDatabase executeQueryWithParameters:@"SELECT * FROM lists_places", nil];
  
//  [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"BEGIN TRANSACTION"];
  for (EGODatabaseRow *row in oldListsPlacesRes) {
    NSString *query = [NSString stringWithFormat:@"INSERT INTO lists_places (list_sid, place_biz) VALUES (?, ?)"];
    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, [row stringForColumn:@"list_sid"], [row stringForColumn:@"place_biz"], nil];
    [oldPlacesBiz addObject:[row stringForColumn:@"place_biz"]];
  }
  
  // Convert old places to new format
  NSMutableString *q = [NSMutableString string];
  [q appendString:@"SELECT * FROM places WHERE biz IN ("];
  if ([oldPlacesBiz count] > 0) {
    [q appendString:@"?"];
  }
  for (int i = 1; i < [oldPlacesBiz count]; i++) {
    [q appendString:@","];
    [q appendString:@"?"];
  }
  [q appendString:@")"];
  
  EGODatabaseResult *oldPlacesRes = [oldDatabase executeQuery:q parameters:oldPlacesBiz];
  for (EGODatabaseRow *row in oldPlacesRes) {
    NSData *oldPlaceData = [row dataForColumn:@"data"];
    NSMutableDictionary *oldPlaceDict = [NSMutableDictionary dictionaryWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:oldPlaceData]];
    NSLog(@"place: %@", oldPlaceDict);
    
    // Manipulate this into the new format and write it back into the DB
    NSMutableDictionary *newPlaceDict = [NSMutableDictionary dictionary];
    [newPlaceDict setObject:[oldPlaceDict objectForKey:@"alias"] forKey:@"yid"];
    [newPlaceDict setObject:[oldPlaceDict objectForKey:@"biz"] forKey:@"biz"];
    [newPlaceDict setObject:[oldPlaceDict objectForKey:@"name"] forKey:@"name"];
    [newPlaceDict setObject:[oldPlaceDict objectForKey:@"category"] forKey:@"categories"];
    [newPlaceDict setObject:[oldPlaceDict objectForKey:@"coverPhoto"] forKey:@"cover_photo"];
    [newPlaceDict setObject:[oldPlaceDict objectForKey:@"numReviews"] forKey:@"review_count"];
    [newPlaceDict setObject:[oldPlaceDict objectForKey:@"formattedAddress"] forKey:@"formatted_address"];
    [newPlaceDict setObject:[oldPlaceDict objectForKey:@"latitude"] forKey:@"latitude"];
    [newPlaceDict setObject:[oldPlaceDict objectForKey:@"longitude"] forKey:@"longitude"];
    
    // Convert Rating (round)
    NSNumber *oldRatingNum = [oldPlaceDict objectForKey:@"rating"];
    CGFloat oldRating = [oldRatingNum floatValue];
    CGFloat newRating = 0.0;
    if (oldRating > 4.75 && oldRating <= 5.0) {
      newRating = 5.0;
    } else if (oldRating > 4.25 && oldRating <= 4.75) {
      newRating = 4.5;
    } else if (oldRating > 3.75 && oldRating <= 4.25) {
      newRating = 4.0;
    } else if (oldRating > 3.25 && oldRating <= 3.75) {
      newRating = 3.5;
    } else if (oldRating > 2.75 && oldRating <= 3.25) {
      newRating = 3.0;
    } else if (oldRating > 2.25 && oldRating <= 2.75) {
      newRating = 2.5;
    } else if (oldRating > 1.75 && oldRating <= 2.25) {
      newRating = 2.0;
    } else if (oldRating > 1.25 && oldRating <= 1.75) {
      newRating = 1.5;
    } else if (oldRating > 0.75 && oldRating <= 1.25) {
      newRating = 1.0;
    } else if (oldRating > 0.25 && oldRating <= 0.75) {
      newRating = 0.5;
    } else {
      newRating = 0.0;
    }
    [newPlaceDict setObject:[NSNumber numberWithFloat:newRating] forKey:@"rating"];
    
    NSData *newPlaceData = [NSKeyedArchiver archivedDataWithRootObject:newPlaceDict];
    [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"INSERT OR REPLACE INTO places (yid, biz, data, latitude, longitude, rating, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)" parameters:[NSArray arrayWithObjects:[newPlaceDict objectForKey:@"yid"], [newPlaceDict objectForKey:@"biz"], newPlaceData, [newPlaceDict objectForKey:@"latitude"], [newPlaceDict objectForKey:@"longitude"], [newPlaceDict objectForKey:@"rating"], [NSDate distantPast], nil]];
  }
  
  [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"COMMIT"];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
  return [[PSFacebookCenter defaultCenter] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  return [[PSFacebookCenter defaultCenter] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//  NSLog(@"fonts: %@",[UIFont familyNames]);
  
//#warning DEBUG always migrate
//  [[self class] migrateDatabaseV1toV2];
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isFirstLaunch"]) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isFirstLaunch"];
    NSDictionary *cookieProperty = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:339434502],
                                    @"Created",
                                    @"m.yelp.com",
                                    @"Domain",
                                    @"np",
                                    @"Name",
                                    @"/biz",
                                    @"Path",
                                    @"x",
                                    @"Value",
                                    nil];
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperty];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
  }
  
  [PSReachabilityCenter defaultCenter];
  
  _isBackgrounded = NO;
  
  // PSLocationCenter set default behavior
  [[PSLocationCenter defaultCenter] setShouldMonitorSignificantChange:NO];
  [[PSLocationCenter defaultCenter] setShouldDisableAfterLocationFix:NO];
  
  // Call home
  _requestQueue = [[PSNetworkQueue alloc] init];
  [_requestQueue setMaxConcurrentOperationCount:2];
  [self sendRequestsHome];
  
  // Override StyleSheet
  [PSStyleSheet setStyleSheet:@"AppStyleSheet"];
  
  // PSFacebookCenter
  [PSFacebookCenter defaultCenter];
  
  // Initialize RootViewController
  RootViewController *rvc = [[[RootViewController alloc] init] autorelease];
  
  _navigationController = [[[[NSBundle mainBundle] loadNibNamed:@"PSNavigationController" owner:self options:nil] lastObject] retain];
  _navigationController.viewControllers = [NSArray arrayWithObject:rvc];
  
//  _navigationController = [[UINavigationController alloc] initWithRootViewController:rvc];
//  if([_navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)] ) {
//    //iOS 5 new UINavigationBar custom background
//    [_navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_navbar.png"] forBarMetrics:UIBarMetricsDefault];
//  } else {
//    UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_navbar.png"]] autorelease];
//    [_navigationController.navigationBar insertSubview:bg atIndex:0];
//  }
  
  [self.window addSubview:_navigationController.view];
  [self.window makeKeyAndVisible];
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] startSession:kLocalyticsKey];
  
  // Google Analytics
//  [[GANTracker sharedTracker] startTrackerWithAccountID:@"UA-25898818-2" dispatchPeriod:kGANDispatchPeriodSec delegate:self];
//  
//  NSError *error;
//  [[GANTracker sharedTracker] trackPageview:@"/appLaunch" withError:&error];
  
  // Crittercism
  [Crittercism initWithAppID: @"4e7919a8ddf520403007beb0"
                      andKey:@"4e7919a8ddf520403007beb0l8haqgmx"
                   andSecret:@"4jhap5c6gtuexebkmj2x9i8cwq0im1ln"
       andMainViewController:_navigationController];
  
#ifdef CREATE_DUMMY_LISTS
  // Create 1 list
  NSString *sid = [NSString stringFromUUID];
  NSNumber *timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
  NSString *query = @"INSERT INTO lists (sid, name, timestamp) VALUES (?, ?, ?)";
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, sid, @"Test List 1", timestamp, nil];

  // J T McHart
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO lists_places (list_sid, place_biz) VALUES (?, ?)", sid, @"cyTlYYW6q8w8LBXwTZ-Ifw", nil];
  
  // Cafe Macs
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO lists_places (list_sid, place_biz) VALUES (?, ?)", sid, @"hJPioxjTyjubyRPbeYYM0g", nil];
  
  // Create another list
  sid = [NSString stringFromUUID];
  timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
  query = @"INSERT INTO lists (sid, name, timestamp) VALUES (?, ?, ?)";
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, sid, @"Test List 2", timestamp, nil];
  
  // Cafe Macs
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO lists_places (list_sid, place_biz) VALUES (?, ?)", sid, @"hJPioxjTyjubyRPbeYYM0g", nil];
#endif
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  _isBackgrounded = YES;
  
  [[LocalyticsSession sharedLocalyticsSession] close];
  [[LocalyticsSession sharedLocalyticsSession] upload];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationSuspended object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  [self sendRequestsHome];
  [[LocalyticsSession sharedLocalyticsSession] resume];
  [[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  if (_isBackgrounded) {
    _isBackgrounded = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationResumed object:nil];
  }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  [[LocalyticsSession sharedLocalyticsSession] close];
  [[LocalyticsSession sharedLocalyticsSession] upload];
}

#pragma mark - Send Requests Home
- (void)sendRequestsHome {
  EGODatabaseResult *result = [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"SELECT id, biz, type, data, strftime('%s',timestamp) as timestamp from requests"];
  
  if ([result count] == 0) return;
  
  for (EGODatabaseRow *row in result) {
    NSMutableDictionary *storedRequest = [NSMutableDictionary dictionaryWithCapacity:2];
    [storedRequest setObject:[row stringForColumn:@"biz"] forKey:@"biz"];
    [storedRequest setObject:[row stringForColumn:@"type"] forKey:@"type"];
    [storedRequest setObject:[[row stringForColumn:@"data"] objectFromJSONString] forKey:@"data"];
    [storedRequest setObject:[row stringForColumn:@"timestamp"] forKey:@"timestamp"];

    // Upload data
    NSString *smlURLString = [NSString stringWithFormat:@"%@/mealtime?type=%@", API_BASE_URL, [storedRequest objectForKey:@"type"]];
    NSURL *smlURL = [NSURL URLWithString:smlURLString];
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:smlURL];
    request.numberOfTimesToRetryOnTimeout = 1;
    [request setShouldContinueWhenAppEntersBackground:YES];
    request.requestMethod = POST;
    [request addRequestHeader:@"Content-Type" value:@"gzip/json"];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request setShouldCompressRequestBody:YES];
    [request setValidatesSecureCertificate:NO];
    
    NSData *postData = [storedRequest JSONData];
    request.postBody = [NSMutableData dataWithData:postData];
    
    request.userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[row intForColumn:@"id"]] forKey:@"storedRequestId"];
    [request setCompletionBlock:^{
      if (request.responseStatusCode > 200) {
        NSLog(@"mealtime request failed with code: %d and message: %@", request.responseStatusCode, request.responseStatusMessage);
      } else {
        NSLog(@"mealtime request success: %@", request.responseString);
        
        // Delete row
        NSString *query = @"DELETE FROM requests WHERE id = ?";
        [[[PSDatabaseCenter defaultCenter] database] executeQuery:query parameters:[NSArray arrayWithObject:[request.userInfo objectForKey:@"storedRequestId"]]];
      }
    }];
    
    [request setFailedBlock:^{
      NSLog(@"mealtime request failed, unreachable");
    }];
    
    request.queuePriority = NSOperationQueuePriorityVeryLow;
    [_requestQueue addOperation:request];
//    [request startAsynchronous];
  }
}

#pragma mark - GANTrackerDelegate
- (void)hitDispatched:(NSString *)hitString {
  VLog(@"GAN Hit Dispatched: %@", hitString)
}

- (void)trackerDispatchDidComplete:(GANTracker *)tracker eventsDispatched:(NSUInteger)hitsDispatched eventsFailedDispatch:(NSUInteger)hitsFailedDispatch {
  VLog(@"GAN hitsDispatched: %d, hitsFailedDispatch: %d", hitsDispatched, hitsFailedDispatch);
}

- (void)dealloc
{
  RELEASE_SAFELY(_requestQueue);
  [_navigationController release];
  [_window release];
  [super dealloc];
}

@end
