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

@interface RootViewController : PSTableViewController <MKReverseGeocoderDelegate, UITextFieldDelegate, SearchTermDelegate> {
  UIView *_headerView;
  UIToolbar *_toolbar;
  PSSearchField *_whatField;
  UITextField *_whereField;
  UILabel *_statusLabel;
  UILabel *_distanceLabel;
  
  NSArray *_currentAddress;
  
  SearchTermController *_whatTermController;
  SearchTermController *_whereTermController;
  
  // This is used to reference cells
  // So that we can tell them to pause/resume animations
  NSInteger _scrollCount;
  
  MKReverseGeocoder *_reverseGeocoder;
  
  NSString *_sortBy;
  CGFloat _distance;
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
- (void)saved;
- (void)distance;

- (void)locationAcquired;
- (void)updateCurrentLocation;
- (void)reverseGeocode;
- (void)sortResults;

- (void)searchTermChanged:(UITextField *)textField;
- (void)executeSearch;
- (void)dismissSearch;

@end
