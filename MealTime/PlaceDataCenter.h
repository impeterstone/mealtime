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
  
}

- (void)getPlacesFromFixtures;
- (void)fetchYelpPlacesForQuery:(NSString *)query andAddress:(NSString *)address distance:(CGFloat)distance start:(NSInteger)start rpp:(NSInteger)rpp;
- (void)fetchYelpCoverPhotoForPlaces:(NSMutableArray *)places;
- (void)fetchCoverPhotosForPlace:(NSMutableDictionary *)place placesToRemove:(NSMutableArray *)placesToRemove;

- (void)insertPlaceInDatabase:(NSDictionary *)place;

@end
