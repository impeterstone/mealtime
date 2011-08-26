//
//  MealTimeAppDelegate.h
//  MealTime
//
//  Created by Peter Shih on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MealTimeAppDelegate : NSObject <UIApplicationDelegate> {
  UINavigationController *_navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
