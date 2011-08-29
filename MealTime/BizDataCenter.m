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

- (void)getProductsFromFixtures
{
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"products" ofType:@"json"];
  NSData *fixtureData = [NSData dataWithContentsOfFile:filePath];
  id fixtureResponse = [fixtureData JSONValue];
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
    [self.delegate dataCenterDidFinish:nil withResponse:fixtureResponse];
  }
}

- (void)fetchYelpPhotosForBiz:(NSString *)biz start:(NSString *)start rpp:(NSString *)rpp {
  //    http://lite.yelp.com/biz_photos/fTeiio1L2ZBIRdlzjdjAeg?rpp=-1
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz_photos/%@?start=%@&rpp=%@", biz, start, rpp];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
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
      [self updatePlacePhotosInDatabase:response forBiz:biz];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
          [self.delegate dataCenterDidFinish:[request autorelease] withResponse:[response autorelease]];
        }
      });
    });
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
      [self updatePlaceMapInDatabase:response forBiz:biz];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
          [self.delegate dataCenterDidFinish:[request autorelease] withResponse:[response autorelease]];
        }
      });
    });
  }];
  
  [request setFailedBlock:^{
    
  }];
  [request startAsynchronous];
}

- (void)fetchYelpBizForBiz:(NSString *)biz {
  // http://lite.yelp.com/biz/PDhfVvcVXgBinZf5I6s1KQ
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz/%@", biz];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
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
      [self updatePlaceBizInDatabase:response forBiz:biz];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
          [self.delegate dataCenterDidFinish:[request autorelease] withResponse:[response autorelease]];
        }
      });
    });
  }];
  
  [request setFailedBlock:^{
    
  }];
  [request startAsynchronous];
}

- (void)updatePlaceMapInDatabase:(NSDictionary *)place forBiz:(NSString *)biz {
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"UPDATE places SET address = ?, coordinates = ? WHERE biz = ?", [place objectForKey:@"address"], [place objectForKey:@"coordinates"], biz, nil];
}

- (void)updatePlaceBizInDatabase:(NSDictionary *)place forBiz:(NSString *)biz {
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"UPDATE places SET hours = ? WHERE biz = ?", [place objectForKey:@"hours"], biz, nil];
}

- (void)updatePlacePhotosInDatabase:(NSDictionary *)place forBiz:(NSString *)biz {
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"UPDATE places SET numphotos = ? WHERE biz = ?", [place objectForKey:@"numphotos"], biz, nil];
  
  // Create photos
  for (NSDictionary *photo in [place objectForKey:@"photos"]) {
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT OR REPLACE INTO photos (biz, src, caption) VALUES (?, ?, ?)", biz, [photo objectForKey:@"src"], [photo objectForKey:@"caption"], nil];
  }
}

- (NSArray *)selectPlacePhotosInDatabaseForBiz:(NSString *)biz {
  EGODatabaseResult *result = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"SELECT * FROM photos WHERE biz = ?", biz, nil];
  
  NSMutableArray *photos = [NSMutableArray array];
  for(EGODatabaseRow *row in result) {
    NSMutableDictionary *photo = [NSMutableDictionary dictionary];
    
    [photo setObject:[row stringForColumn:@"src"] forKey:@"src"];
    [photo setObject:[row stringForColumn:@"caption"] forKey:@"caption"];
    
    [photos addObject:photo];
  }
  
  return photos;
}

@end
