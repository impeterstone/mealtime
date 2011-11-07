//
//  RootViewController.h
//  MealTime
//
//  Created by Peter Shih on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PSTableViewController.h"
#import "SearchTermDelegate.h"

@class SearchTermController;
@class PSSearchField;
@class ASIHTTPRequest;

@interface RootViewController : PSTableViewController <UITextFieldDelegate, SearchTermDelegate, UIActionSheetDelegate> {
  UIView *_headerView;
  UIView *_tabView;
  UITextField *_whatField;
  UITextField *_whereField;
  UISegmentedControl *_radiusControl;
  UIButton *_centerButton;
  
  NSString *_location;
  
  SearchTermController *_whatTermController;
  SearchTermController *_whereTermController;
  
  // This is used to reference cells
  // So that we can tell them to pause/resume animations
  
  NSString *_whatQuery;
  NSString *_whereQuery;
  NSInteger _radiusFilter;
  
  NSInteger _numResults;
  NSInteger _numShowing;
  
  ASIHTTPRequest *_activeRequest;
  
  BOOL _isSearchActive;
}

@property (nonatomic, retain) NSString *whatQuery;
@property (nonatomic, retain) NSString *whereQuery;

- (void)executeSearch;
- (void)dismissSearch;

@end
