//
//  PlaceCell.h
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCell.h"
#import "PSURLCacheImageView.h"

@interface PlaceCell : PSCell <PSImageViewDelegate> {
  PSURLCacheImageView *_photoView;
  UIImageView *_disclosureView;
  
  UILabel *_nameLabel;
  UILabel *_distanceLabel;
  
  NSDictionary *_place;
}

- (void)fetchYelpCoverPhotoForPlace:(NSMutableDictionary *)place;

@end
