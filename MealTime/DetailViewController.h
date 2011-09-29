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

@interface DetailViewController : PSTableViewController <MKMapViewDelegate, UIGestureRecognizerDelegate, ProductCellDelegate> {
  UIView *_tabView;
  NSMutableDictionary *_place;
  NSMutableDictionary *_imageSizeCache;
  MKCoordinateRegion _mapRegion;
  
  // Views
  MKMapView *_mapView;
  UIView *_addressView;
  UILabel *_addressLabel;
  UIView *_hoursView;
  UIScrollView *_hoursScrollView;
  UILabel *_hoursLabel;
  
  NSInteger _photoCount;
  
  NSDate *_cachedTimestamp;
  BOOL _isCachedPlace;
  BOOL _hasNote;
}

- (id)initWithPlace:(NSDictionary *)place;

@end