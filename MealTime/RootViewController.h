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
  PSTextField *_searchField;
  UIBarButtonItem *_compassButton;
  UIBarButtonItem *_cancelButton;
  UILabel *_currentLocationLabel;
  NSArray *_currentAddress;
  
  SearchTermController *_searchTermController;
  
  // This is used to reference cells
  // So that we can tell them to pause/resume animations
  NSMutableArray *_cellCache;
  
  MKReverseGeocoder *_reverseGeocoder;
  
  NSString *_sortBy;
  CGFloat _distance;
  NSString *_fetchQuery;
}

@property (nonatomic, retain) NSString *fetchQuery;

- (void)setupSearchTermController;

// Buttons
- (void)findMyLocation;
- (void)sort;
- (void)filter;

- (void)updateCurrentLocation;
- (void)locationUnchanged;
- (void)reverseGeocode;
- (void)sortResults;

@end
