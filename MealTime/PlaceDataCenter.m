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
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"places" ofType:@"html"];
  NSData *fixtureData = [NSData dataWithContentsOfFile:filePath];
  NSString *responseString = [[NSString alloc] initWithData:fixtureData encoding:NSUTF8StringEncoding];
  
  dispatch_async([PSScrapeCenter sharedQueue], ^{
    NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePlacesWithHTMLString:responseString] retain];
    [responseString release];
    
    // Save to DB
    NSString *requestType = @"places";
    NSString *requestData = [response JSONString];
    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (type, data) VALUES (?, ?)", requestType, requestData, nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.delegate && [self.delegate respondsToSelector:@selector(dataCenterDidFinishWithResponse:andUserInfo:)]) {
        [self.delegate dataCenterDidFinishWithResponse:[response autorelease] andUserInfo:nil];
      }
    });
  });
}

- (void)fetchYelpPlacesForQuery:(NSString *)query andAddress:(NSString *)address distance:(CGFloat)distance start:(NSInteger)start rpp:(NSInteger)rpp {
  if (distance == 0.0) distance = 1.0;
  if (rpp == 0) rpp = 25;
  NSLog(@"fetching places near: %@ distance: %f, start: %d, rpp: %d", address, distance, start, rpp);
  NSString *urlEncodedAddress = [address stringByURLEncoding];
  NSString *urlEncodedQuery = query ? [query stringByURLEncoding] : @"";
  
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/search?find_desc=%@&cflt=restaurants&rflt=all&sortby=composite&find_loc=%@&radius=%f&start=%d&rpp=%d", urlEncodedQuery, urlEncodedAddress, distance, start, rpp];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  request.numberOfTimesToRetryOnTimeout = 3;
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  
  [request setCompletionBlock:^{
    // GCD
    [request retain];
    NSString *responseString = [request.responseString copy];
    dispatch_async([PSScrapeCenter sharedQueue], ^{
      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePlacesWithHTMLString:responseString] retain];
      [responseString release];
      
      // Download cover photos (synchronously in the current dispatch)
      // Iterate thru places, download photos metadata
      [self fetchYelpCoverPhotoForPlaces:[response objectForKey:@"places"]];
      
      // Save to DB
      NSString *requestType = @"places";
      NSString *requestData = [response JSONString];
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (type, data) VALUES (?, ?)", requestType, requestData, nil];
      
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

- (void)fetchYelpCoverPhotoForPlaces:(NSMutableArray *)places {
  NSMutableArray *placesToRemove = [[NSMutableArray alloc] initWithCapacity:1];
  
  ASINetworkQueue *coverPhotoQueue = [[ASINetworkQueue alloc] init];
  coverPhotoQueue.maxConcurrentOperationCount = 10;
  
  for (NSMutableDictionary *place in places) {
    NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz_photos/%@?rpp=3", [place objectForKey:@"biz"]];
    NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
    request.numberOfTimesToRetryOnTimeout = 1;
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setUserAgent:USER_AGENT];
    
    [request setCompletionBlock:^{
      // GCD
      NSString *responseString = [request.responseString copy];
      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString] retain];
      [responseString release];
      [place setObject:[response objectForKey:@"numphotos"] forKey:@"numphotos"];
      if ([[response objectForKey:@"numphotos"] integerValue] > 0) {
        [place setObject:[response objectForKey:@"photos"] forKey:@"coverPhotos"];
      } else {
//        [place setObject:[NSNull null] forKey:@"coverPhotos"];
        [placesToRemove addObject:place];
      }
      [response release];
      
      NSLog(@"cover completed");
    }];
    
    [request setFailedBlock:^{
//      [place setObject:[NSNull null] forKey:@"coverPhotos"];
      [placesToRemove addObject:place];
    }];

    [coverPhotoQueue addOperation:request];
    //    [request startSynchronous];
  }
  
  [coverPhotoQueue go];
  [coverPhotoQueue waitUntilAllOperationsAreFinished];
  
  // Remove all places with no photos
  [places removeObjectsInArray:placesToRemove];
  [placesToRemove removeAllObjects];
  [placesToRemove release];
}


#pragma mark - Database
- (void)insertPlaceInDatabase:(NSDictionary *)place {
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT OR REPLACE INTO places (biz, name, rating, phone, numreviews, price, category, distance, city, score, address, coordinates, hours, numphotos) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, (SELECT address FROM places WHERE biz = ?), (SELECT coordinates FROM places WHERE biz = ?), (SELECT hours FROM places WHERE biz = ?), (SELECT numphotos FROM places WHERE biz = ?))", [place objectForKey:@"biz"], [place objectForKey:@"name"], [place objectForKey:@"rating"], [place objectForKey:@"phone"], [place objectForKey:@"numreviews"], [place objectForKey:@"price"], [place objectForKey:@"category"], [place objectForKey:@"distance"], [place objectForKey:@"city"], [place objectForKey:@"score"], [place objectForKey:@"biz"], [place objectForKey:@"biz"], [place objectForKey:@"biz"], [place objectForKey:@"biz"], nil];
}

@end