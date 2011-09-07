//
//  DetailViewController.h
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PSTableViewController.h"
#import "ProductCell.h"

@class InfoViewController;

@interface DetailViewController : PSTableViewController <MKMapViewDelegate, UIGestureRecognizerDelegate, ProductCellDelegate> {
  UIToolbar *_toolbar;
  NSMutableDictionary *_place;
  NSMutableDictionary *_imageSizeCache;
  MKCoordinateRegion _mapRegion;
  
  // Views
  MKMapView *_mapView;
  InfoViewController *_ivc;
  UIBarButtonItem *_starButton;
  UIView *_addressView;
  UILabel *_addressLabel;
  UIView *_hoursView;
  UIScrollView *_hoursScrollView;
  UILabel *_hoursLabel;
  
  NSInteger _photoCount;
  
  BOOL _isCachedPlace;
  BOOL _isSavedPlace;
}

- (id)initWithPlace:(NSDictionary *)place;

@end