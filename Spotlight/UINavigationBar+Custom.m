//
//  UINavigationBar+Custom.m
//  PhotoTime
//
//  Created by Peter Shih on 2/28/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "UINavigationBar+Custom.h"
#import <QuartzCore/QuartzCore.h>
#import "PSConstants.h"

@implementation UINavigationBar (Custom)

//- (void)drawRect:(CGRect)rect
//{
//  UIImage *image = [[UIImage imageNamed:@"bg_navigationbar.png"] retain];
//	[image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
//}

//- (void)layoutSubviews {
//  [super layoutSubviews];
//  self.tintColor = RGBACOLOR(80, 80, 80, 1.0);
//}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
  [super willMoveToWindow:newWindow];
  [self applyDropShadow];
}

- (void)applyDropShadow
{
  // add the drop shadow
  self.layer.shadowColor = [[UIColor blackColor] CGColor];
  self.layer.shadowOffset = CGSizeMake(0.0, 3.0);
  self.layer.shadowOpacity = 0.33;
  self.layer.masksToBounds = NO;
  self.layer.shouldRasterize = YES;
}

@end
