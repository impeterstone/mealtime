//
//  WebViewController.h
//  MealTime
//
//  Created by Peter Shih on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSBaseViewController.h"

@interface WebViewController : PSBaseViewController <UIWebViewDelegate> {
  UIWebView *_webView;
  NSString *_URLString;
}

- (id)initWithURLString:(NSString *)URLString;
- (void)loadWebView;

@end
