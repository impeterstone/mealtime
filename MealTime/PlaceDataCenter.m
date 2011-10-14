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
- (void)fetchPlacesForQuery:(NSString *)query location:(NSString *)location radius:(NSString *)radius sortby:(NSString *)sortby openNow:(BOOL)openNow price:(NSInteger)price start:(NSInteger)start rpp:(NSInteger)rpp {
  
  // sortby options
  // best_match
  // distance
  // rating
  
  // cflt options
  // restaurants
  // nightlife
  
  // If location is empty, use current location
  
  // Params
  
  NSString *startParam = [NSString stringWithFormat:@"start=%d", start];
  NSString *rppParam = [NSString stringWithFormat:@"rpp=%d", rpp];
  
  NSString *openNowParam = openNow ? [NSString stringWithFormat:@"open_now=%d", [NSDate minutesSinceBeginningOfWeek]] : nil;
//  NSString *sortbyParam = sortby ? [NSString stringWithFormat:@"sortby=%@", sortby] : nil;
  NSString *radiusParam = radius ? [NSString stringWithFormat:@"radius=%@", radius] : nil;
  if (query) {
    query = [NSString stringWithFormat:@"find_desc=%@", query];
  } else {
    query = @"find_desc=Restaurants";
  }
  
  NSString *queryParam = [NSString stringWithFormat:@"%@", [query stringByURLEncoding]];
  
//  NSString *priceParam = (price == 0) ? nil : [NSString stringWithFormat:@"attrs=RestaurantsPriceRange2.%d", price];
  
  // Construct URL
  NSMutableString *urlString = [NSMutableString string];
  [urlString appendString:@"http://m.yelp.com/search?"];
  [urlString appendString:location];
  [urlString appendString:@"&"];
  [urlString appendString:startParam];
  [urlString appendString:@"&"];
  [urlString appendString:rppParam];
  [urlString appendString:@"&"];
  [urlString appendString:queryParam];
  if (radiusParam) {
    [urlString appendString:@"&"];
    [urlString appendString:radiusParam];
  }
  if (openNowParam) {
    [urlString appendString:@"&"];
    [urlString appendString:openNowParam];
  }
//  if (sortbyParam) {
//    [urlString appendString:@"&"];
//    [urlString appendString:sortbyParam];
//  }
//  if (priceParam) {
//    [urlString appendString:@"&"];
//    [urlString appendString:priceParam];
//  }
  
  NSURL *url = [NSURL URLWithString:urlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  request.numberOfTimesToRetryOnTimeout = 1;
  [request setShouldContinueWhenAppEntersBackground:YES];
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
      // GCD
      [request retain];
      NSString *responseString = [request.responseString copy];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePlacesWithHTMLString:responseString] retain];
        [responseString release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
          if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
            [self.delegate dataCenterDidFinishWithResponse:[response autorelease] andUserInfo:request.userInfo];
          }
          [request release];
        });
      });
    }
  }];
  
  [request setFailedBlock:^{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFailWithError:andUserInfo:)]) {
      [self.delegate dataCenterDidFailWithError:request.error andUserInfo:request.userInfo];
    }
  }];
  
  [[PSNetworkQueue sharedQueue] addOperation:request];
}

@end