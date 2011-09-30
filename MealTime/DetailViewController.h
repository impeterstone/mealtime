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
  NSMutableDictionary *_place;
  NSMutableDictionary *_imageSizeCache;
  NSDate *_cachedTimestamp;
  MKCoordinateRegion _mapRegion;
  NSInteger _photoCount;
  BOOL _isCachedPlace;
  
  // Views
  UIView *_tabView;
  MKMapView *_mapView;
  UIView *_addressView;
  UILabel *_addressLabel;
  UIView *_hoursView;
  UIScrollView *_hoursScrollView;
  UILabel *_hoursLabel;
}

- (id)initWithPlace:(NSDictionary *)place;

@end