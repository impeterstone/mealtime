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

- (void)getPhotosFromFixturesForBiz:(NSString *)biz
{
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"photos" ofType:@"html"];
  NSData *fixtureData = [NSData dataWithContentsOfFile:filePath];
  NSString *responseString = [[NSString alloc] initWithData:fixtureData encoding:NSUTF8StringEncoding];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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

- (void)fetchDetailsForPlace:(NSMutableDictionary *)place {  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self requestForBizForPlace:place];
    [self requestForPhotosForPlace:place];
    
    // Check to see if we actually got photos and bizDetails
    BOOL success = NO;
    if ([place objectForKey:@"biz"] && [place objectForKey:@"photos"]) {
      success = YES;
    }
    
    // Write this place to the local DB
    NSNumber *timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    NSData *placeData = [NSKeyedArchiver archivedDataWithRootObject:place];
    [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"BEGIN TRANSACTION"];
    [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"INSERT OR REPLACE INTO places (alias, biz, data, latitude, longitude, score, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)" parameters:[NSArray arrayWithObjects:[place objectForKey:@"alias"], [place objectForKey:@"biz"], placeData, [place objectForKey:@"latitude"], [place objectForKey:@"longitude"], [place objectForKey:@"score"], timestamp, nil]];
    
    // Save callhome entry
    NSString *requestType = @"biz";
    NSString *requestData = [place JSONString];
    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", [place objectForKey:@"biz"], requestType, requestData, nil];
    
    [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"COMMIT"];
    
    dispatch_async(dispatch_get_main_queue(), ^{      
      if (success) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
          [self.delegate dataCenterDidFinishWithResponse:nil andUserInfo:[NSDictionary dictionaryWithObject:place forKey:@"place"]];
        }
      } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFailWithError:andUserInfo:)]) {
          [self.delegate dataCenterDidFailWithError:nil andUserInfo:[NSDictionary dictionaryWithObject:place forKey:@"place"]];
        }
      }
    });
  });
}

- (void)requestForPhotosForPlace:(NSMutableDictionary *)place {
  // Make sure there is a biz
  // If there is no biz, that also means no photos
  if (![place objectForKey:@"biz"]) {
    [_placeLock lock];
    @try {
      // Update place object
        [place setObject:[NSArray array] forKey:@"photos"];
      
      // Update numPhotos
      [place setObject:[NSNumber numberWithInt:0] forKey:@"numPhotos"];
    }
    @finally {
      [_placeLock unlock];
    }
    
    return;
  }
  
  // Construct URL
  NSString *urlString = [NSString stringWithFormat:@"http://m.yelp.com/biz_photos/%@?rpp=%d", [place objectForKey:@"biz"], [[NSUserDefaults standardUserDefaults] integerForKey:@"filterNumPhotos"]];
  NSURL *url = [NSURL URLWithString:urlString];
  
  // Run this synchronously
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  request.userAgent = USER_AGENT;
  [request startSynchronous];
  NSError *error = [request error];
  if (!error) {
    // Check HTTP Status Code
    int responseCode = [request responseStatusCode];
    if (responseCode == 403) {
      // we got a 403, probably because of parameters, try and fall back
      [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"fetchPhotos403"];
      [[NSUserDefaults standardUserDefaults] setInteger:99 forKey:@"filterNumPhotos"];
    } else {
      NSString *responseString = request.responseString;
      
      NSDictionary *response = [[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString];
      
      [_placeLock lock];
      @try {
        // Update place object
        if ([response objectForKey:@"photos"]) {
          [place setObject:[response objectForKey:@"photos"] forKey:@"photos"];
        }
        // Update numPhotos
        if ([response objectForKey:@"numPhotos"]) {
          [place setObject:[response objectForKey:@"numPhotos"] forKey:@"numPhotos"];
        }
      }
      @finally {
        [_placeLock unlock];
      }
    }
  }
}

- (void)requestForBizForPlace:(NSMutableDictionary *)place {
  // Construct URL
  NSString *urlString = [NSString stringWithFormat:@"http://m.yelp.com/biz/%@?rpp=0", [place objectForKey:@"alias"]];
  NSURL *url = [NSURL URLWithString:urlString];
  
  // Run this synchronously
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  request.userAgent = USER_AGENT;
  [request startSynchronous];
  NSError *error = [request error];
  if (!error) {
    NSString *responseString = request.responseString;
    
    NSDictionary *response = [[PSScrapeCenter defaultCenter] scrapeBizWithHTMLString:responseString];
    
    [_placeLock lock];
    @try {
      // Update place object
      if ([response objectForKey:@"biz"]) {
        [place setObject:[response objectForKey:@"biz"] forKey:@"biz"];
      }
      
      // Update Hours
      if ([response objectForKey:@"hours"]) {
        [place setObject:[response objectForKey:@"hours"] forKey:@"hours"];
      }
      
      // Phone
      if ([response objectForKey:@"formattedPhone"]) {
        [place setObject:[response objectForKey:@"formattedPhone"] forKey:@"formattedPhone"];
      }
      if ([response objectForKey:@"phone"]) {
        [place setObject:[response objectForKey:@"phone"] forKey:@"phone"];
      }
      
      // Address
      if ([response objectForKey:@"address"]) {
        [place setObject:[response objectForKey:@"address"] forKey:@"address"];
      }
      if ([response objectForKey:@"formattedAddress"]) {
        [place setObject:[response objectForKey:@"formattedAddress"] forKey:@"formattedAddress"];
      }
      
      // Attrs (metadata)
      if ([response objectForKey:@"attrs"]) {
        [place setObject:[response objectForKey:@"attrs"] forKey:@"attrs"];
      }
    }
    @finally {
      [_placeLock unlock];
    }
  }
}

- (void)fetchReviewsForAlias:(NSString *)alias start:(NSInteger)start rpp:(NSInteger)rpp {
  // Construct URL
  NSString *urlString = [NSString stringWithFormat:@"http://m.yelp.com/biz/%@?rpp=%d&start=%d", alias, rpp, start];
  NSURL *url = [NSURL URLWithString:urlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  request.numberOfTimesToRetryOnTimeout = 1;
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  
  [request setCompletionBlock:^{
    // GCD
    [request retain];
    NSString *responseString = [request.responseString copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//    DISPATCH_QUEUE_PRIORITY_BACKGROUND iOS 4.3+ only
      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapeReviewsWithHTMLString:responseString] retain];
      [responseString release];
      
      // Save to DB
      NSString *requestType = @"reviews";
      NSString *requestData = [response JSONString];
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", alias, requestType, requestData, nil];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [response release];
        [request release];
      });
    });
  }];
  
  [request setFailedBlock:^{
    // If a review scrape failed, we should rescrape
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:alias];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }];
  
  request.queuePriority = NSOperationQueuePriorityVeryLow;
  [_bizQueue addOperation:request];
//  [[PSNetworkQueue sharedQueue] addOperation:request];
}

- (void)cancelRequests {
  [_bizQueue cancelAllOperations];
}

@end
