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

@interface RootViewController : PSTableViewController <MKReverseGeocoderDelegate, UITextFieldDelegate, ADBannerViewDelegate, UIActionSheetDelegate, SearchTermDelegate> {
  UIToolbar *_toolbar;
  PSTextField *_whatField;
  PSTextField *_whereField;

  UILabel *_currentLocationLabel;
  NSArray *_currentAddress;
  
  SearchTermController *_searchTermController;
  
  // This is used to reference cells
  // So that we can tell them to pause/resume animations
  NSMutableArray *_cellCache;
  
  MKReverseGeocoder *_reverseGeocoder;
  
  NSString *_sortBy;
  CGFloat _distance;
  NSString *_whatQuery;
  NSString *_whereQuery;
}

@property (nonatomic, retain) NSString *whatQuery;
@property (nonatomic, retain) NSString *whereQuery;

- (void)setupSearchTermController;

// Buttons
- (void)findMyLocation;
- (void)sort;
- (void)filter;

- (void)updateCurrentLocation;
- (void)locationUnchanged;
- (void)reverseGeocode;
- (void)sortResults;

- (void)searchTermChanged:(UITextField *)textField;
- (void)searchWithTextField:(UITextField *)textField;
- (void)dismissSearch;

@end
