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

static NSLock *_placeLock = nil;

@implementation BizDataCenter

+ (void)initialize {
  _placeLock = [[NSLock alloc] init];
}

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

#pragma mark - Remote Fetch
- (void)fetchDetailsForPlace:(NSMutableDictionary *)place {
  // Load from server
  NSString *numPhotos = [place objectForKey:@"numphotos"];
  NSString *start = @"0";
  
  // Results per page
  NSString *rpp = nil;
  if (numPhotos && [numPhotos integerValue] <= 8) {
    rpp = numPhotos;
  } else {
    rpp = @"-1";
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSOperationQueue *detailsQueue = [[NSOperationQueue alloc] init];
    detailsQueue.maxConcurrentOperationCount = 2;
    
    [detailsQueue addOperationWithBlock:^{
      [self requestForPhotosForPlace:place start:start rpp:rpp];
    }];
    
    [detailsQueue addOperationWithBlock:^{
      [self requestForBizForPlace:place];
    }];
    
    [detailsQueue waitUntilAllOperationsAreFinished];
    [detailsQueue release];
    
    // Write this place to the local DB
    NSNumber *timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    NSData *placeData = [NSKeyedArchiver archivedDataWithRootObject:place];
    //    [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"BEGIN TRANSACTION"];
    [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"INSERT OR REPLACE INTO places (biz, data, timestamp) VALUES (?, ?, ?)" parameters:[NSArray arrayWithObjects:[place objectForKey:@"biz"], placeData, timestamp, nil]];
    //    [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"COMMIT"];
    
    dispatch_async(dispatch_get_main_queue(), ^{      
      if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
        [self.delegate dataCenterDidFinishWithResponse:nil andUserInfo:[NSDictionary dictionaryWithObject:place forKey:@"place"]];
      }
    });
  });
}

- (void)requestForPhotosForPlace:(NSMutableDictionary *)place start:(NSString *)start rpp:(NSString *)rpp {
  //    http://lite.yelp.com/biz_photos/fTeiio1L2ZBIRdlzjdjAeg?rpp=-1
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz_photos/%@?start=%@&rpp=%@", [place objectForKey:@"biz"], start, rpp];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  // Run this synchronously
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  [request startSynchronous];
  NSError *error = [request error];
  if (!error) {
    NSString *responseString = request.responseString;
    
    NSDictionary *response = [[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString];
    
    [_placeLock lock];
    @try {
      // Update place object
      if ([response objectForKey:@"photos"]) {
        [place setObject:[response objectForKey:@"photos"] forKey:@"photos"];
      }
    }
    @finally {
      [_placeLock unlock];
    }
    
    // Save to DB
    NSString *biz = [request.userInfo objectForKey:@"biz"];
    NSString *requestType = @"photos";
    NSString *requestData = [response JSONString];
    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", biz, requestType, requestData, nil];
  }
  
//  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
//  request.numberOfTimesToRetryOnTimeout = 3;
//  [request setUserAgent:USER_AGENT];
//  
//  [request setCompletionBlock:^{
//    // GCD
//    [request retain];
//    NSString *responseString = [request.responseString copy];
//
//    NSDictionary *response = [[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString];
//    [responseString release];
//    
//    // Update place object
//    if ([response objectForKey:@"photos"]) {
//      [place setObject:[response objectForKey:@"photos"] forKey:@"photos"];
//    }
//    
//    // Save to DB
//    NSString *biz = [request.userInfo objectForKey:@"biz"];
//    NSString *requestType = @"photos";
//    NSString *requestData = [response JSONString];
//    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", biz, requestType, requestData, nil];
//  }];
//  
//  [request setFailedBlock:^{
//    
//  }];
//  
//  request.queuePriority = NSOperationQueuePriorityVeryHigh;
  
}

- (void)requestForBizForPlace:(NSMutableDictionary *)place {
  // http://lite.yelp.com/biz/PDhfVvcVXgBinZf5I6s1KQ
//  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz/%@", biz];
  // By default, just scrape 10 reviews to show
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://www.yelp.com/biz/%@?rpp=1&sort_by=relevance_desc", [place objectForKey:@"biz"]];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  // Run this synchronously
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  [request startSynchronous];
  NSError *error = [request error];
  if (!error) {
    NSString *responseString = request.responseString;
    
    NSDictionary *response = [[PSScrapeCenter defaultCenter] scrapeBizWithHTMLString:responseString];
    
    [_placeLock lock];
    @try {
      // Update place object
      // Address
      if ([response objectForKey:@"address"]) {
        [place setObject:[response objectForKey:@"address"] forKey:@"address"];
      }
      if ([response objectForKey:@"latitude"]) {
        [place setObject:[response objectForKey:@"latitude"] forKey:@"latitude"];
      }
      if ([response objectForKey:@"longitude"]) {
        [place setObject:[response objectForKey:@"longitude"] forKey:@"longitude"];
      }
      // Update Hours
      if ([response objectForKey:@"hours"]) {
        [place setObject:[response objectForKey:@"hours"] forKey:@"hours"];
      }
      // Snippets
      if ([response objectForKey:@"snippets"]) {
        [place setObject:[response objectForKey:@"snippets"] forKey:@"snippets"];
      }
    }
    @finally {
      [_placeLock unlock];
    }

    // Save to DB
    NSString *biz = [request.userInfo objectForKey:@"biz"];
    NSString *requestType = @"biz";
    NSString *requestData = [response JSONString];
    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", biz, requestType, requestData, nil];
  }
  
  
//  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
//  request.numberOfTimesToRetryOnTimeout = 3;
//  [request setUserAgent:USER_AGENT];
//
//  [request setCompletionBlock:^{
//    // GCD
//    [request retain];
//    NSString *responseString = [request.responseString copy];
//
//    NSDictionary *response = [[PSScrapeCenter defaultCenter] scrapeBizWithHTMLString:responseString];
//    [responseString release];
//    
//    // Update place object
//    // Address
//    if ([response objectForKey:@"address"]) {
//      [place setObject:[response objectForKey:@"address"] forKey:@"address"];
//    }
//    if ([response objectForKey:@"latitude"]) {
//      [place setObject:[response objectForKey:@"latitude"] forKey:@"latitude"];
//    }
//    if ([response objectForKey:@"longitude"]) {
//      [place setObject:[response objectForKey:@"longitude"] forKey:@"longitude"];
//    }
//    // Update Hours
//    if ([response objectForKey:@"hours"]) {
//      [place setObject:[response objectForKey:@"hours"] forKey:@"hours"];
//    }
//    // Snippets
//    if ([response objectForKey:@"snippets"]) {
//      [place setObject:[response objectForKey:@"snippets"] forKey:@"snippets"];
//    }
//    
//    // Save to DB
//    NSString *biz = [request.userInfo objectForKey:@"biz"];
//    NSString *requestType = @"biz";
//    NSString *requestData = [response JSONString];
//    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", biz, requestType, requestData, nil];
//  }];
//  
//  [request setFailedBlock:^{
//    
//  }];
//  
//  request.queuePriority = NSOperationQueuePriorityHigh;
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
  
  request.queuePriority = NSOperationQueuePriorityVeryLow;
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
