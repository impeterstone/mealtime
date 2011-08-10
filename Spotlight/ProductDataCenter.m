//
//  ProductDataCenter.m
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProductDataCenter.h"

@implementation ProductDataCenter

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

@end
