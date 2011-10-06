//
//  PlaceCell.h
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCell.h"
#import "PSURLCacheImageView.h"

@class PSStarView;

@interface PlaceCell : PSCell <PSImageViewDelegate> {
  PSURLCacheImageView *_photoView;
  UIImageView *_disclosureView;
  
  // Ribbon
  UIView *_ribbonView;
  UILabel *_ribbonLabel;
  
  UILabel *_nameLabel;
  UILabel *_distanceLabel;
  UILabel *_categoryLabel;
  UILabel *_priceLabel;
  
  PSStarView *_starView;
  
  UIView *_scoreView;
  UILabel *_scoreLabel;
  
  NSDictionary *_place;
}

@end
