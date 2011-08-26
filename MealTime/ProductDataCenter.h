//
//  ProductDataCenter.h
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSDataCenter.h"

@interface ProductDataCenter : PSDataCenter {
  
}

- (void)getProductsFromFixtures;
- (void)fetchYelpPhotosForBiz:(NSString *)biz rpp:(NSString *)rpp;

@end
