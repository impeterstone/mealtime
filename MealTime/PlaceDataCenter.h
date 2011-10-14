//
//  PlaceDataCenter.h
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSDataCenter.h"

@interface PlaceDataCenter : PSDataCenter {
  ASINetworkQueue *_placeQueue;
}

- (void)getPlacesFromFixtures;

- (void)fetchPlacesForQuery:(NSString *)query location:(NSString *)location radius:(NSString *)radius sortby:(NSString *)sortby openNow:(BOOL)openNow price:(NSInteger)price start:(NSInteger)start rpp:(NSInteger)rpp;

- (void)cancelRequests;

@end
