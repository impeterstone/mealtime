//
//  UINavigationBar+Custom.m
//  MealTime
//
//  Created by Peter Shih on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UINavigationBar+Custom.h"
#import <QuartzCore/QuartzCore.h>

@implementation UINavigationBar (Custom)

- (void)drawRect:(CGRect)rect {
  UIImage *image = [[UIImage imageNamed:@"bg_navigationbar.png"] retain];
  [image drawInRect:CGRectMake(0, 0, rect.size.width, rect.size.height + 7)];
  [image release];
}

@end
