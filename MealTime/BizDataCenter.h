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

- (void)getProductsFromFixtures;
- (void)fetchYelpPhotosForBiz:(NSString *)biz start:(NSString *)start rpp:(NSString *)rpp;
- (void)fetchYelpMapForBiz:(NSString *)biz;
- (void)fetchYelpBizForBiz:(NSString *)biz;

- (void)updatePlaceMapInDatabase:(NSDictionary *)place forBiz:(NSString *)biz ;
- (void)updatePlaceBizInDatabase:(NSDictionary *)place forBiz:(NSString *)biz;
- (void)updatePlacePhotosInDatabase:(NSDictionary *)place forBiz:(NSString *)biz;

- (NSArray *)selectPlacePhotosInDatabaseForBiz:(NSString *)biz;

@end
