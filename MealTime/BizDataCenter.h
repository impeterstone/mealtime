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
  
}

- (void)getPhotosFromFixturesForBiz:(NSString *)biz;
- (void)getBizFromFixturesForBiz:(NSString *)biz;

- (void)fetchDetailsForPlace:(NSDictionary *)place;

- (void)requestForPhotosForPlace:(NSMutableDictionary *)place start:(NSString *)start rpp:(NSString *)rpp;
- (void)requestForBizForPlace:(NSMutableDictionary *)place;


- (void)fetchYelpReviewsForBiz:(NSString *)biz start:(NSInteger)start rpp:(NSInteger)rpp;

// DEPRECATED
- (void)fetchYelpMapForBiz:(NSString *)biz;

@end
