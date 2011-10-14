//
//  BizDataCenter.h
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSDataCenter.h"

@interface BizDataCenter : PSDataCenter {
  ASINetworkQueue *_bizQueue;
}

- (void)getPhotosFromFixturesForBiz:(NSString *)biz;
- (void)getBizFromFixturesForBiz:(NSString *)biz;


- (void)fetchDetailsForPlace:(NSDictionary *)place;

- (void)requestForPhotosForPlace:(NSMutableDictionary *)place;
- (void)requestForBizForPlace:(NSMutableDictionary *)place;

- (void)fetchReviewsForAlias:(NSString *)alias start:(NSInteger)start rpp:(NSInteger)rpp;

- (void)cancelRequests;

@end
