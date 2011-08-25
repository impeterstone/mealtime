//
//  UIViewController+Ad.h
//  Spotlight
//
//  Created by Peter Shih on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

@interface UIViewController (Ad)

- (ADBannerView *)newAdBannerViewWithDelegate:(id)delegate;

@end
