//
//  UINavigationBar+Custom.m
//  PhotoTime
//
//  Created by Peter Shih on 2/28/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "UINavigationBar+Custom.h"
#import <QuartzCore/QuartzCore.h>

@implementation UINavigationBar (Custom)

- (void)drawRect:(CGRect)rect
{
  UIImage *image = [[UIImage imageNamed:@"bg_navigationbar.png"] retain];
	[image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
  [super willMoveToWindow:newWindow];
  [self applyDropShadow];
  self.tintColor = [UIColor darkGrayColor];
}

- (void)applyDropShadow
{
  // add the drop shadow
  self.layer.masksToBounds = NO;
  self.layer.shadowColor = [[UIColor blackColor] CGColor];
  self.layer.shadowOffset = CGSizeMake(0.0, 3.0);
  self.layer.shadowOpacity = 0.5;
}

@end
