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

- (void)fetchBusinessForYid:(NSString *)yid;
- (void)fetchPhotosForBiz:(NSString *)biz;

- (void)cancelRequests;

@end
