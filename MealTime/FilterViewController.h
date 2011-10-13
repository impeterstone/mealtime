//
//  FilterViewController.h
//  MealTime
//
//  Created by Peter Shih on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSBaseViewController.h"

@class PSSearchField;

@protocol FilterViewControllerDelegate <NSObject>

@optional
- (void)filter:(id)sender didSelectWithOptions:(NSDictionary *)options reload:(BOOL)reload;

@end

@interface FilterViewController : PSBaseViewController <UIGestureRecognizerDelegate, UITextFieldDelegate> {
//  PSSearchField *_whatField; // just a pointer
  UIView *_curlView; // just a pointer
  
  BOOL _filterChanged;
  BOOL _openNowChanged;
  id <FilterViewControllerDelegate> _delegate;
}

@property (nonatomic, assign) id <FilterViewControllerDelegate> delegate;

- (id)initWithOptions:(NSDictionary *)options;

@end
