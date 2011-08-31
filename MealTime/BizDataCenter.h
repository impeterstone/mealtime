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
- (void)fetchYelpReviewsForBiz:(NSString *)biz start:(NSInteger)start rpp:(NSInteger)rpp;

@end
