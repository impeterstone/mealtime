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

- (void)getPhotosFromFixturesForBiz:(NSString *)biz
{
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"photos" ofType:@"html"];
  NSData *fixtureData = [NSData dataWithContentsOfFile:filePath];
  NSString *responseString = [[NSString alloc] initWithData:fixtureData encoding:NSUTF8StringEncoding];
  
  dispatch_async([PSScrapeCenter sharedQueue], ^{
    NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString] retain];
    [responseString release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
      [userInfo setObject:biz forKey:@"biz"];
      [userInfo setObject:@"photos" forKey:@"requestType"];
      
      if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
        [self.delegate dataCenterDidFinishWithResponse:[response autorelease] andUserInfo:userInfo];
      }
    });
  });
}

- (void)getBizFromFixturesForBiz:(NSString *)biz
{
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"biz" ofType:@"html"];
  NSData *fixtureData = [NSData dataWithContentsOfFile:filePath];
  NSString *responseString = [[NSString alloc] initWithData:fixtureData encoding:NSUTF8StringEncoding];
  
  dispatch_async([PSScrapeCenter sharedQueue], ^{
    NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapeBizWithHTMLString:responseString] retain];
    [responseString release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
      [userInfo setObject:biz forKey:@"biz"];
      [userInfo setObject:@"biz" forKey:@"requestType"];
      
      if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
        [self.delegate dataCenterDidFinishWithResponse:[response autorelease] andUserInfo:userInfo];
      }
    });
  });
}

- (void)fetchYelpPhotosForBiz:(NSString *)biz start:(NSString *)start rpp:(NSString *)rpp {
  //    http://lite.yelp.com/biz_photos/fTeiio1L2ZBIRdlzjdjAeg?rpp=-1
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz_photos/%@?start=%@&rpp=%@", biz, start, rpp];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  request.numberOfTimesToRetryOnTimeout = 3;
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];

  // UserInfo
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
  [userInfo setObject:biz forKey:@"biz"];
  [userInfo setObject:@"photos" forKey:@"requestType"];
  [request setUserInfo:userInfo];
  
  [request setCompletionBlock:^{
    // GCD
    [request retain];
    NSString *responseString = [request.responseString copy];
    dispatch_async([PSScrapeCenter sharedQueue], ^{
      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString] retain];
      [responseString release];
      
      // Save to DB
      NSString *biz = [request.userInfo objectForKey:@"biz"];
      NSString *requestType = @"photos";
      NSString *requestData = [response JSONString];
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", biz, requestType, requestData, nil];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
          [self.delegate dataCenterDidFinishWithResponse:[response autorelease] andUserInfo:request.userInfo];
        }
      });
    });
  }];
  
  [request setFailedBlock:^{
    
  }];
  
  request.queuePriority = NSOperationQueuePriorityVeryHigh;
  [[PSNetworkQueue sharedQueue] addOperation:request];
//  [request startAsynchronous];
}

- (void)fetchYelpBizForBiz:(NSString *)biz {
  // http://lite.yelp.com/biz/PDhfVvcVXgBinZf5I6s1KQ
//  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz/%@", biz];
  // By default, just scrape 10 reviews to show
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://www.yelp.com/biz/%@?rpp=1&sort_by=relevance_desc", biz];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  request.numberOfTimesToRetryOnTimeout = 3;
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];

  // UserInfo
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
  [userInfo setObject:biz forKey:@"biz"];
  [userInfo setObject:@"biz" forKey:@"requestType"];
  [request setUserInfo:userInfo];
  
  [request setCompletionBlock:^{
    // GCD
    [request retain];
    NSString *responseString = [request.responseString copy];
    dispatch_async([PSScrapeCenter sharedQueue], ^{
      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapeBizWithHTMLString:responseString] retain];
      [responseString release];
      
      // Save to DB
      NSString *biz = [request.userInfo objectForKey:@"biz"];
      NSString *requestType = @"biz";
      NSString *requestData = [response JSONString];
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", biz, requestType, requestData, nil];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
          [self.delegate dataCenterDidFinishWithResponse:[response autorelease] andUserInfo:request.userInfo];
        }
      });
    });
  }];
  
  [request setFailedBlock:^{
    
  }];
  
  request.queuePriority = NSOperationQueuePriorityHigh;
  [[PSNetworkQueue sharedQueue] addOperation:request];  
//  [request startAsynchronous];
}

- (void)fetchYelpReviewsForBiz:(NSString *)biz start:(NSInteger)start rpp:(NSInteger)rpp {
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://www.yelp.com/biz/%@?rpp=%d&start=%d", biz, rpp, start];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  request.numberOfTimesToRetryOnTimeout = 3;
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  
  // UserInfo
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
  [userInfo setObject:biz forKey:@"biz"];
  [userInfo setObject:@"reviews" forKey:@"requestType"];
  [request setUserInfo:userInfo];
  
  [request setCompletionBlock:^{
    // GCD
    [request retain];
    NSString *responseString = [request.responseString copy];
    dispatch_async([PSScrapeCenter sharedQueue], ^{
      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapeReviewsWithHTMLString:responseString] retain];
      [responseString release];
      
      // Save to DB
      NSString *biz = [request.userInfo objectForKey:@"biz"];
      NSString *requestType = @"reviews";
      NSString *requestData = [response JSONString];
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", biz, requestType, requestData, nil];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [response release];
        // This call has no callback
      });
    });
  }];
  
  [request setFailedBlock:^{
    // If a review scrape failed, we should rescrape
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:biz];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }];
  
  request.queuePriority = NSOperationQueuePriorityLow;
  [[PSNetworkQueue sharedQueue] addOperation:request];
//  [request startAsynchronous];
}

#pragma mark - DEPRECATED
- (void)fetchYelpMapForBiz:(NSString *)biz {
  // DEPRECATED
  // http://lite.yelp.com/map/8Dg9wpIIO2AIM_qE9rniNQ
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/map/%@", biz];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  request.numberOfTimesToRetryOnTimeout = 3;
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  
  // UserInfo
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
  [userInfo setObject:biz forKey:@"biz"];
  [userInfo setObject:@"map" forKey:@"requestType"];
  [request setUserInfo:userInfo];
  
  [request setCompletionBlock:^{
    // GCD
    [request retain];
    NSString *responseString = [request.responseString copy];
    dispatch_async([PSScrapeCenter sharedQueue], ^{
      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapeMapWithHTMLString:responseString] retain];
      [responseString release];
      
      // Save to DB
      NSString *biz = [request.userInfo objectForKey:@"biz"];
      NSString *requestType = @"map";
      NSString *requestData = [response JSONString];
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", biz, requestType, requestData, nil];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
          [self.delegate dataCenterDidFinishWithResponse:[response autorelease] andUserInfo:request.userInfo];
        }
      });
    });
  }];
  
  [request setFailedBlock:^{
    
  }];
  
  [[PSNetworkQueue sharedQueue] addOperation:request];
  //  [request startAsynchronous];
}

@end
