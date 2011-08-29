//
//  ProductCell.h
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCell.h"
#import "PSURLCacheImageView.h"

@class ProductCell;

@protocol ProductCellDelegate <NSObject>

@optional
- (void)productCell:(ProductCell *)cell didLoadImage:(UIImage *)image;

@end

@interface ProductCell : PSCell <PSImageViewDelegate> {
  PSURLCacheImageView *_photoView;
  UIView *_captionView;
  
  UILabel *_nameLabel;
  UILabel *_priceLabel;
  UILabel *_descriptionLabel;

  CGFloat _desiredWidth;
  CGFloat _desiredHeight;
  
  id <ProductCellDelegate> _delegate;
}

@property (nonatomic, assign) PSURLCacheImageView *photoView;
@property (nonatomic, assign) id <ProductCellDelegate> delegate;

- (void)setShouldAnimate:(NSNumber *)shouldAnimate;

@end
