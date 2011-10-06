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
- (void)filterDidSelectWithOptions:(NSDictionary *)options sender:(id)sender;

@end

@interface FilterViewController : PSBaseViewController <UIGestureRecognizerDelegate, UITextFieldDelegate> {
  PSSearchField *_whatField; // just a pointer
  
  BOOL _filterChanged;
  id <FilterViewControllerDelegate> _delegate;
}

@property (nonatomic, assign) id <FilterViewControllerDelegate> delegate;

- (id)initWithOptions:(NSDictionary *)options;

@end
