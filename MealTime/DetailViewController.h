//
//  DetailViewController.h
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTableViewController.h"
#import "ProductCell.h"

@class InfoViewController;

@interface DetailViewController : PSTableViewController <ProductCellDelegate> {
  NSMutableDictionary *_place;
  NSMutableDictionary *_imageSizeCache;
  
  // Views
  InfoViewController *_ivc;
  UIBarButtonItem *_infoButton;
  
  BOOL _isInfoShowing;
}

- (id)initWithPlace:(NSDictionary *)place;
- (void)toggleInfo;

- (void)loadPhotosFromDatabase;

@end