//
//  PlaceDataCenter.m
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaceDataCenter.h"
#import "PSScrapeCenter.h"
#import "PSDatabaseCenter.h"
#import "PSLocationCenter.h"

static NSLock *_placesToRemoveLock = nil;

@implementation PlaceDataCenter

+ (void)initialize {
  _placesToRemoveLock = [[NSLock alloc] init];
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
    _placeQueue = [[ASINetworkQueue alloc] init];
    [_placeQueue setSuspended:NO];
  }
  return self;
}

- (void)getPlacesFromFixtures
{
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"places" ofType:@"html"];
  NSData *fixtureData = [NSData dataWithContentsOfFile:filePath];
  NSString *responseString = [[NSString alloc] initWithData:fixtureData encoding:NSUTF8StringEncoding];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePlacesWithHTMLString:responseString] retain];
    [responseString release];
    
    // Save to DB
//    NSString *requestType = @"places";
//    NSString *requestData = [response JSONString];
//    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (type, data) VALUES (?, ?)", requestType, requestData, nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
        [self.delegate dataCenterDidFinishWithResponse:[response autorelease] andUserInfo:nil];
      }
    });
  });
}


#pragma mark - Remote Fetch
- (void)fetchPlacesForQuery:(NSString *)query location:(NSString *)location radius:(NSString *)radius offset:(NSInteger)offset limit:(NSInteger)limit {
  
  // sortby options
  // best_match
  // distance
  // rating
  
  // cflt options
  // restaurants
  // nightlife
  
  // If location is empty, use current location
  
  // Params
  
  NSString *offsetParam = [NSString stringWithFormat:@"offset=%d", offset];
  NSString *limitParam = [NSString stringWithFormat:@"limit=%d", limit];
  
  NSString *radiusParam = radius ? [NSString stringWithFormat:@"radius=%@", radius] : nil;
  NSString *termParam = query ? [NSString stringWithFormat:@"term=%@", [query stringByURLEncoding]] : nil;  
  
  // Construct URL
  NSMutableString *urlString = [NSMutableString string];
  [urlString appendFormat:@"%@/search?", API_BASE_URL];
//  [urlString appendString:@"http://m.yelp.com/search?"];
  [urlString appendString:location];
  if (termParam) {
    [urlString appendString:@"&"];
    [urlString appendString:termParam];
  }
  if (offsetParam) {
    [urlString appendString:@"&"];
    [urlString appendString:offsetParam];
  }
  if (limitParam) {
    [urlString appendString:@"&"];
    [urlString appendString:limitParam];
  }
  if (radiusParam) {
    [urlString appendString:@"&"];
    [urlString appendString:radiusParam];
  }
  
  NSURL *url = [NSURL URLWithString:urlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  request.numberOfTimesToRetryOnTimeout = 1;
//  [request setShouldContinueWhenAppEntersBackground:YES];
  [request addRequestHeader:@"Accept" value:@"application/json"];
  
//  [request setUserAgent:USER_AGENT];
  
  [request setCompletionBlock:^{
    // Check HTTP Status Code
    int responseCode = [request responseStatusCode];
    if (responseCode == 403) {
      // we got a 403, probably because of parameters, try and fall back
      [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"fetchPlaces403"];
      [[NSUserDefaults standardUserDefaults] setInteger:99 forKey:@"filterNumResults"];
      
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
  
  [_placeQueue addOperation:request];
//  [[PSNetworkQueue sharedQueue] addOperation:request];
}

- (void)cancelRequests {
  [_placeQueue cancelAllOperations];
}

@end