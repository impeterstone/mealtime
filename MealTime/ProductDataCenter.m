//
//  ProductDataCenter.m
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProductDataCenter.h"
#import "PSScrapeCenter.h"

@implementation ProductDataCenter

+ (id)defaultCenter {
  static id defaultCenter = nil;
  if (!defaultCenter) {
    defaultCenter = [[self alloc] init];
  }
  return defaultCenter;
}

- (void)getProductsFromFixtures
{
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"products" ofType:@"json"];
  NSData *fixtureData = [NSData dataWithContentsOfFile:filePath];
  id fixtureResponse = [fixtureData JSONValue];
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
    [self.delegate dataCenterDidFinish:nil withResponse:fixtureResponse];
  }
}

- (void)fetchYelpPhotosForBiz:(NSString *)biz rpp:(NSString *)rpp {
  //    http://lite.yelp.com/biz_photos/fTeiio1L2ZBIRdlzjdjAeg?rpp=-1
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz_photos/%@?rpp=%@", biz, rpp];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  [request setUserInfo:[NSDictionary dictionaryWithObject:@"photos" forKey:@"requestType"]];
  
  [request setCompletionBlock:^{
    NSDictionary *response = [[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:request.responseString];
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
      [self.delegate dataCenterDidFinish:request withResponse:response];
    }
  }];
  
  [request setFailedBlock:^{
    
  }];
  [request startAsynchronous];
}

- (void)fetchYelpMapForBiz:(NSString *)biz {
  // http://lite.yelp.com/map/8Dg9wpIIO2AIM_qE9rniNQ
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/map/%@", biz];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  [request setUserInfo:[NSDictionary dictionaryWithObject:@"map" forKey:@"requestType"]];
  
  [request setCompletionBlock:^{
    NSDictionary *response = [[PSScrapeCenter defaultCenter] scrapeMapWithHTMLString:request.responseString];
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
      [self.delegate dataCenterDidFinish:request withResponse:response];
    }
  }];
  
  [request setFailedBlock:^{
    
  }];
  [request startAsynchronous];
}

@end
