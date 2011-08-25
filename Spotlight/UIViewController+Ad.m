//
//  UIViewController+Ad.m
//  Spotlight
//
//  Created by Peter Shih on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIViewController+Ad.h"

@implementation UIViewController (Ad)

- (ADBannerView *)newAdBannerViewWithDelegate:(id)delegate {
  ADBannerView *adView = [[ADBannerView alloc] initWithFrame:CGRectZero];
  adView.delegate = delegate;
  return adView;
}

@end
