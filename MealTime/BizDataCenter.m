//
//  BizDataCenter.m
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BizDataCenter.h"
#import "PSScrapeCenter.h"
#import "PSDatabaseCenter.h"

@implementation BizDataCenter

+ (id)defaultCenter {
  static id defaultCenter = nil;
  if (!defaultCenter) {
    defaultCenter = [[self alloc] init];
  }
  return defaultCenter;
}

- (id)init {
  self = [super init];
  if (self) {
    _bizQueue = [[ASINetworkQueue alloc] init];
    [_bizQueue setSuspended:NO];
  }
  return self;
}

- (void)dealloc {
  [_bizQueue cancelAllOperations];
  RELEASE_SAFELY(_bizQueue);
  [super dealloc];
}

#pragma mark - Remote Fetch
- (void)fetchBusinessForYid:(NSString *)yid {
  NSMutableString *urlString = [NSMutableString string];
  [urlString appendFormat:@"%@/business/%@", API_BASE_URL, yid];
  NSURL *url = [NSURL URLWithString:urlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  request.numberOfTimesToRetryOnTimeout = 1;
//  [request setShouldContinueWhenAppEntersBackground:YES];
  [request addRequestHeader:@"Accept" value:@"application/json"];
  
  // UserInfo
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
  [userInfo setObject:@"business" forKey:@"requestType"];
  [request setUserInfo:userInfo];
  
  [request setCompletionBlock:^{
    // Check HTTP Status Code
    int responseCode = [request responseStatusCode];
    if (responseCode == 403) {
      // we got a 403, probably because of parameters, try and fall back
      [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"fetchBusiness403"];
      
      if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFailWithError:andUserInfo:)]) {
        [self.delegate dataCenterDidFailWithError:request.error andUserInfo:request.userInfo];
      }
    } else {
      NSDictionary *response = [request.responseData objectFromJSONData];
      
      if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
        [self.delegate dataCenterDidFinishWithResponse:response andUserInfo:request.userInfo];
      }
    }
  }];
  
  [request setFailedBlock:^{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFailWithError:andUserInfo:)]) {
      [self.delegate dataCenterDidFailWithError:request.error andUserInfo:request.userInfo];
    }
  }];
  
  [_bizQueue addOperation:request];
}

- (void)fetchPhotosForBiz:(NSString *)biz {
  NSMutableString *urlString = [NSMutableString string];
  [urlString appendFormat:@"http://www.yelp.com/biz_photos/%@?rpp=%d", biz, [[NSUserDefaults standardUserDefaults] integerForKey:@"filterNumPhotos"]];
  NSURL *url = [NSURL URLWithString:urlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  request.numberOfTimesToRetryOnTimeout = 1;
  //  [request setShouldContinueWhenAppEntersBackground:YES];
  
  // UserInfo
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
  [userInfo setObject:@"photos" forKey:@"requestType"];
  [request setUserInfo:userInfo];
  
  [request setCompletionBlock:^{
    // Check HTTP Status Code
    int responseCode = [request responseStatusCode];
    if (responseCode == 403) {
      // we got a 403, probably because of parameters, try and fall back
      [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"fetchPhotos403"];
      [[NSUserDefaults standardUserDefaults] setInteger:99 forKey:@"filterNumPhotos"];
      
      if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFailWithError:andUserInfo:)]) {
        [self.delegate dataCenterDidFailWithError:request.error andUserInfo:request.userInfo];
      }
    } else {
      // GCD
      NSDictionary *userInfo = [request.userInfo copy];
      NSString *responseString = [request.responseString copy];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString] retain];
        [responseString release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
          if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
            [self.delegate dataCenterDidFinishWithResponse:[response autorelease] andUserInfo:[userInfo autorelease]];
          }
        });
      });
    }
  }];
  
  [request setFailedBlock:^{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFailWithError:andUserInfo:)]) {
      [self.delegate dataCenterDidFailWithError:request.error andUserInfo:request.userInfo];
    }
  }];
  
  [_bizQueue addOperation:request];
}

- (void)cancelRequests {
  [_bizQueue cancelAllOperations];
}

@end
