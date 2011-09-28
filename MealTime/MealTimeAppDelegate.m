//
//  MealTimeAppDelegate.m
//  MealTime
//
//  Created by Peter Shih on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MealTimeAppDelegate.h"
#import "PSConstants.h"
#import "RootViewController.h"
#import "PSFacebookCenter.h"
#import "PSDatabaseCenter.h"
#import "ASIHTTPRequest.h"
#import "PSDataCenter.h"
#import "PSNetworkQueue.h"
#import "PSLocationCenter.h"
#import "Crittercism.h"

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

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
  return [[PSFacebookCenter defaultCenter] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//  NSLog(@"fonts: %@",[UIFont familyNames]);
  
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
  _navigationController = [[UINavigationController alloc] initWithRootViewController:rvc];
  _navigationController.navigationBar.tintColor = RGBACOLOR(80, 80, 80, 1.0);
  
  [self.window addSubview:_navigationController.view];
  [self.window makeKeyAndVisible];
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] startSession:kLocalyticsKey];
  
  // Google Analytics
  [[GANTracker sharedTracker] startTrackerWithAccountID:@"UA-25898818-2" dispatchPeriod:kGANDispatchPeriodSec delegate:self];
  
  NSError *error;
  [[GANTracker sharedTracker] trackPageview:@"/appLaunch" withError:&error];
  
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
