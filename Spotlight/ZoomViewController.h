//
//  ZoomViewController.h
//  PhotoTime
//
//  Created by Peter Shih on 8/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSViewController.h"
#import "PSImageView.h"

@interface ZoomViewController : PSViewController <UIScrollViewDelegate> {
  UIScrollView *_containerView;
  PSImageView *_imageView;
}

@property (nonatomic, retain) PSImageView *imageView;

@end
