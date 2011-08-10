//
//  ProductCell.h
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCell.h"
#import "PSURLCacheImageView.h"

@interface ProductCell : PSCell <PSImageViewDelegate> {
  NSDictionary *_product;
  PSURLCacheImageView *_photoView;
  UIView *_captionView;
  
  UILabel *_nameLabel;
  UILabel *_priceLabel;
}

@end
