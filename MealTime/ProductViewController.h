//
//  ProductViewController.h
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTableViewController.h"
#import "ProductCell.h"

@interface ProductViewController : PSTableViewController <ProductCellDelegate> {
  NSDictionary *_place;
  NSMutableDictionary *_imageSizeCache;
}

- (id)initWithPlace:(NSDictionary *)place;

@end