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

@interface RootViewController : PSTableViewController <MKReverseGeocoderDelegate, UITextFieldDelegate, ADBannerViewDelegate, UIActionSheetDelegate> {
  UIToolbar *_toolbar;
  PSTextField *_searchField;
  UIBarButtonItem *_compassButton;
  UIBarButtonItem *_cancelButton;
  UILabel *_currentLocationLabel;
  
  MKReverseGeocoder *_reverseGeocoder;
  
  NSString *_sortBy;
  CGFloat _distance;
  NSString *_fetchQuery;
}

@property (nonatomic, retain) NSString *fetchQuery;

// Buttons
- (void)findMyLocation;
- (void)sort;
- (void)filter;

- (void)reverseGeocode;
- (void)sortResults;
- (void)loadPlacesFromDatabase;

@end
