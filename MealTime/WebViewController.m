//
//  WebViewController.m
//  MealTime
//
//  Created by Peter Shih on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WebViewController.h"

@implementation WebViewController

- (id)initWithURLString:(NSString *)URLString {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _URLString = [URLString copy];
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_webView);
}

- (void)dealloc
{
  RELEASE_SAFELY(_URLString);
  
  RELEASE_SAFELY(_webView);
  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_darkwood.jpg"]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  return bg;
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  _navTitleLabel.text = @"Loading...";
  self.navigationItem.leftBarButtonItem = [UIBarButtonItem navBackButtonWithTarget:self action:@selector(back)];
  
  // WebView
  _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  _webView.autoresizingMask = self.view.autoresizingMask;
  _webView.delegate = self;
  [self.view addSubview:_webView];
  [self loadWebView];
}

- (void)loadWebView {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_URLString]];
  [_webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)req navigationType:(UIWebViewNavigationType)navigationType {
  NSMutableURLRequest *request = (NSMutableURLRequest *)req;
  
  if ([request respondsToSelector:@selector(setValue:forHTTPHeaderField:)]) {
    [request setValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
  }
  
  if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted || navigationType == UIWebViewNavigationTypeFormResubmitted) {
    WebViewController *wvc = [[WebViewController alloc] initWithURLString:[req.URL absoluteString]];
    [self.navigationController pushViewController:wvc animated:YES];
    [wvc release];
    return NO;
  } else {
    return YES;
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
  _navTitleLabel.text = [[webView stringByEvaluatingJavaScriptFromString:@"document.title"] stringByUnescapingHTML];
}

@end
