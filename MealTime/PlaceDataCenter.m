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

- (void)fetchYelpPlacesForAddress:(NSString *)address distance:(CGFloat)distance start:(NSInteger)start rpp:(NSInteger)rpp {
  if (distance == 0.0) distance = 1.0;
  if (rpp == 0) rpp = 25;
  NSLog(@"fetching places near: %@ distance: %f, start: %d, rpp: %d", address, distance, start, rpp);
  NSString *urlEncodedAddress = [address stringByURLEncoding];
  
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/search?cflt=restaurants&rflt=all&sortby=composite&find_loc=%@&radius=%f&start=%d&rpp=%d", urlEncodedAddress, distance, start, rpp];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  
  [request setCompletionBlock:^{
    // GCD
    [request retain];
    NSString *responseString = [request.responseString copy];
    dispatch_async([PSScrapeCenter sharedQueue], ^{
      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePlacesWithHTMLString:responseString] retain];
      [responseString release];
      
      // Save to DB
      NSString *requestType = @"places";
      NSString *requestData = [response JSONRepresentation];
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (type, data) VALUES (?, ?)", requestType, requestData, nil];
      
//      for (NSDictionary *place in [response objectForKey:@"places"]) {
//        [self insertPlaceInDatabase:place];
//      }
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
          [self.delegate dataCenterDidFinish:[request autorelease] withResponse:[response autorelease]];
        }
      });
    });
  }];
  
  [request setFailedBlock:^{
    
  }];
  
  [[PSNetworkQueue sharedQueue] addOperation:request];
//  [request startAsynchronous];
}

- (void)insertPlaceInDatabase:(NSDictionary *)place {
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT OR REPLACE INTO places (biz, name, rating, phone, numreviews, price, category, distance, city, score, address, coordinates, hours, numphotos) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, (SELECT address FROM places WHERE biz = ?), (SELECT coordinates FROM places WHERE biz = ?), (SELECT hours FROM places WHERE biz = ?), (SELECT numphotos FROM places WHERE biz = ?))", [place objectForKey:@"biz"], [place objectForKey:@"name"], [place objectForKey:@"rating"], [place objectForKey:@"phone"], [place objectForKey:@"numreviews"], [place objectForKey:@"price"], [place objectForKey:@"category"], [place objectForKey:@"distance"], [place objectForKey:@"city"], [place objectForKey:@"score"], [place objectForKey:@"biz"], [place objectForKey:@"biz"], [place objectForKey:@"biz"], [place objectForKey:@"biz"], nil];
}

@end