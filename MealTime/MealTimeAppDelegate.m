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
      // App version was set, compare it to current
      NSString *savedAppVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"appVersion"];
      if (![appVersion isEqualToString:savedAppVersion]) {
        // Version DOES NOT MATCH
        DLog(@"App Version CHANGED FROM OLD: %@ <---> TO NEW: %@", savedAppVersion, appVersion);
        [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"appVersion"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Reset the SQLite DB
        NSString *sqliteDocumentsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", SQLITE_DB]];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:sqliteDocumentsPath error:&error];
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
  _isBackgrounded = NO;
  
  // PSLocationCenter set default behavior
  [[PSLocationCenter defaultCenter] setShouldMonitorSignificantChange:NO];
  [[PSLocationCenter defaultCenter] setShouldDisableAfterLocationFix:YES];
  
  // Call home
  _requestQueue = [[PSNetworkQueue alloc] init];
  [_requestQueue setMaxConcurrentOperationCount:2];
  [self sendRequestsHome];
  
  // Override StyleSheet
  [PSStyleSheet setStyleSheet:@"AppStyleSheet"];
  
  // Localytics
  [[LocalyticsSession sharedLocalyticsSession] startSession:@"9acaa48fe346d8d9aac0b09-c65cd5a8-d033-11e0-093d-007f58cb3154"];
  
  // PSFacebookCenter
  [PSFacebookCenter defaultCenter];
  
  // Initialize RootViewController
  RootViewController *rvc = [[[RootViewController alloc] init] autorelease];
  _navigationController = [[UINavigationController alloc] initWithRootViewController:rvc];
  _navigationController.navigationBar.tintColor = RGBACOLOR(80, 80, 80, 1.0);
  
  [self.window addSubview:_navigationController.view];
  [self.window makeKeyAndVisible];
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  _isBackgrounded = YES;
  [self sendRequestsHome];
  [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationSuspended object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
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
    NSString *smlURLString = [NSString stringWithFormat:@"%@/mealtime", API_BASE_URL];
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

- (void)dealloc
{
  RELEASE_SAFELY(_requestQueue);
  [_navigationController release];
  [_window release];
  [super dealloc];
}

@end
