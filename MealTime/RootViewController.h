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
#import "FilterViewController.h"

@class SearchTermController;
@class PSSearchField;

@interface RootViewController : PSTableViewController <MKReverseGeocoderDelegate, UITextFieldDelegate, SearchTermDelegate, UIActionSheetDelegate, FilterViewControllerDelegate> {
  UIView *_headerView;
  UIView *_tabView;
  UITextField *_whatField;
  UITextField *_whereField;
  UIButton *_filterButton;
  NSString *_location;
  
  NSArray *_currentAddress;
  
  NSMutableArray *_cachedItems;
  
  SearchTermController *_whatTermController;
  SearchTermController *_whereTermController;
  
  // This is used to reference cells
  // So that we can tell them to pause/resume animations
  NSInteger _scrollCount;
  
  MKReverseGeocoder *_reverseGeocoder;
  
  NSString *_sortBy;
  NSString *_whatQuery;
  NSString *_whereQuery;
  NSInteger _numResults;
  
  BOOL _isSearchActive;
}

@property (nonatomic, retain) NSString *whatQuery;
@property (nonatomic, retain) NSString *whereQuery;

- (void)setupSearchTermController;

// Buttons
- (void)findMyLocation;

- (void)updateCurrentLocation;
- (void)reverseGeocode;

- (void)searchTermChanged:(UITextField *)textField;
- (void)executeSearch;
- (void)dismissSearch;

@end
