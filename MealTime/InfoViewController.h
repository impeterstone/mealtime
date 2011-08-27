//
//  InfoViewController.h
//  MealTime
//
//  Created by Peter Shih on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PSTableViewController.h"

@interface InfoViewController : PSTableViewController <MKMapViewDelegate, UIAlertViewDelegate> {
  UIViewController *_parent;
  NSDictionary *_place;
  MKCoordinateRegion _mapRegion;
  
  // Views
  MKMapView *_mapView;
  UIBarButtonItem *_detailButton;
}

@property (nonatomic, assign) UIViewController *parent;

- (id)initWithPlace:(NSDictionary *)place;
- (void)toggleDetail;
- (void)loadMap;
- (void)showMap:(UITapGestureRecognizer *)gestureRecognizer;


- (void)call;
- (void)checkin;
- (void)reviews;

@end
