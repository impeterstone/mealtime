//
//  SpotlightAppDelegate.m
//  Spotlight
//
//  Created by Peter Shih on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpotlightAppDelegate.h"
#import "PSConstants.h"
#import "RootViewController.h"

@interface SpotlightAppDelegate (Private)

+ (void)setupDefaults;

@end

@implementation SpotlightAppDelegate

@synthesize window = _window;

+ (void)initialize {
  [self setupDefaults];
}

#pragma mark - Initial Defaults
+ (void)setupDefaults {
  if ([self class] == [SpotlightAppDelegate class]) {
    NSString *initialDefaultsPath = [[NSBundle mainBundle] pathForResource:@"InitialDefaults" ofType:@"plist"];
    assert(initialDefaultsPath != nil);
    
    NSDictionary *initialDefaults = [NSDictionary dictionaryWithContentsOfFile:initialDefaultsPath];
    assert(initialDefaults != nil);
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:initialDefaults];
  }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Override StyleSheet
  [PSStyleSheet setStyleSheet:@"AppStyleSheet"];
  
  
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
  /*
   Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationSuspended object:nil];
  /*
   Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
   If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationResumed object:nil];
  /*
   Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  /*
   Called when the application is about to terminate.
   Save data if appropriate.
   See also applicationDidEnterBackground:.
   */
}

- (void)dealloc
{
  [_navigationController release];
  [_window release];
  [super dealloc];
}

@end
