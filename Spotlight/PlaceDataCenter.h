//
//  PlaceDataCenter.h
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSDataCenter.h"

@interface PlaceDataCenter : PSDataCenter {
  
}

- (void)getPlacesFromFixtures;
- (void)fetchYelpPlacesForAddress:(NSString *)address;

@end
