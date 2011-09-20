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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
        [request release];
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
  
  NSOperationQueue *coverPhotoQueue = [[NSOperationQueue alloc] init];
  coverPhotoQueue.maxConcurrentOperationCount = 10;
  
  for (NSMutableDictionary *place in places) {
    [coverPhotoQueue addOperationWithBlock:^{
      [self fetchCoverPhotosForPlace:place placesToRemove:placesToRemove];
    }];
  }
  
  [coverPhotoQueue waitUntilAllOperationsAreFinished];
  [coverPhotoQueue release];
  
//  // Remove all places with no photos
  [places removeObjectsInArray:placesToRemove];
  [placesToRemove removeAllObjects];
  [placesToRemove release];
}

- (void)fetchCoverPhotosForPlace:(NSMutableDictionary *)place placesToRemove:(NSMutableArray *)placesToRemove {
  NSInteger numPhotosToFetch = isMultitaskingSupported() ? 3 : 1;
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz_photos/%@?rpp=%d", [place objectForKey:@"biz"], numPhotosToFetch];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  // Run this synchronously
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  [request startSynchronous];
  NSError *error = [request error];
  if (!error) {
    NSString *responseString = request.responseString;
    
    NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString] retain];

    [place setObject:[response objectForKey:@"numphotos"] forKey:@"numphotos"];
    
    if ([[response objectForKey:@"numphotos"] integerValue] > 0) {
      [place setObject:[response objectForKey:@"photos"] forKey:@"coverPhotos"];
    } else {
      [_placesToRemoveLock lock];
      @try {
        [placesToRemove addObject:place];
      }
      @finally {
        [_placesToRemoveLock unlock];
      }
    }
  } else {
    [_placesToRemoveLock lock];
    @try {
      [placesToRemove addObject:place];
    }
    @finally {
      [_placesToRemoveLock unlock];
    }
  }
  
//  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
//  request.numberOfTimesToRetryOnTimeout = 1;
//  [request setShouldContinueWhenAppEntersBackground:YES];
//  [request setUserAgent:USER_AGENT];
//  
//  [request setCompletionBlock:^{
//    // GCD
//    NSString *responseString = [request.responseString copy];
//    NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString] retain];
//    [responseString release];
//    [place setObject:[response objectForKey:@"numphotos"] forKey:@"numphotos"];
//    if ([[response objectForKey:@"numphotos"] integerValue] > 0) {
//      [place setObject:[response objectForKey:@"photos"] forKey:@"coverPhotos"];
//    } else {
//      //        [place setObject:[NSNull null] forKey:@"coverPhotos"];
//      [placesToRemove addObject:place];
//    }
//    [response release];
//    
//    NSLog(@"cover completed");
//  }];
//  
//  [request setFailedBlock:^{
//    //      [place setObject:[NSNull null] forKey:@"coverPhotos"];
//    [placesToRemove addObject:place];
//  }];
//  
//  [coverPhotoQueue addOperation:request];
//  //    [request startSynchronous];
}

@end