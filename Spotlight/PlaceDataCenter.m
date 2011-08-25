//
//  PlaceDataCenter.m
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaceDataCenter.h"
#import "PSScrapeCenter.h"

@implementation PlaceDataCenter

+ (id)defaultCenter {
  static id defaultCenter = nil;
  if (!defaultCenter) {
    defaultCenter = [[self alloc] init];
  }
  return defaultCenter;
}

- (void)getPlacesFromFixtures
{
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"places" ofType:@"json"];
  NSData *fixtureData = [NSData dataWithContentsOfFile:filePath];
  id fixtureResponse = [fixtureData JSONValue];
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
    [self.delegate dataCenterDidFinish:nil withResponse:fixtureResponse];
  }
}

- (void)fetchYelpPlacesForAddress:(NSString *)address {
  NSLog(@"fetching places near: %@", address);
  NSString *urlEncodedAddress = [address stringByURLEncoding];
  
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/search?cflt=restaurants&rflt=all&sortby=composite&radius=3&find_loc=%@&rpp=50", urlEncodedAddress];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  
  [request setCompletionBlock:^{
    NSArray *response = [[PSScrapeCenter defaultCenter] scrapePlacesWithHTMLString:request.responseString];
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
      [self.delegate dataCenterDidFinish:request withResponse:response];
    }
  }];
  
  [request setFailedBlock:^{
    
  }];
  [request startAsynchronous];
}

@end