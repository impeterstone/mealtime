//
//  TutorialViewController.m
//  MealTime
//
//  Created by Peter Shih on 10/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TutorialViewController.h"

@implementation TutorialViewController

- (void)loadView {
  NSString *imgName = isDeviceIPad() ? @"walkthrough_pad.png" : @"walkthrough.png";
  
  PSTutorialView *tutorialView = [[[PSTutorialView alloc] initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.width, [UIApplication sharedApplication].keyWindow.height - 20) image:[UIImage imageNamed:imgName]] autorelease];
  tutorialView.autoresizingMask = ~UIViewAutoresizingNone;
  tutorialView.delegate = self;
  
  [self setView:tutorialView];
}

- (void)tutorialDidFinish:(id)sender {
  [self dismissModalViewControllerAnimated:YES];
}

@end
