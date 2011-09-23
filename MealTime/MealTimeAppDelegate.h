//
//  MealTimeAppDelegate.h
//  MealTime
//
//  Created by Peter Shih on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GANTracker.h"

@class PSNetworkQueue;

@interface MealTimeAppDelegate : NSObject <UIApplicationDelegate, GANTrackerDelegate> {
  UINavigationController *_navigationController;
  PSNetworkQueue *_requestQueue;
  
  BOOL _isBackgrounded;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
