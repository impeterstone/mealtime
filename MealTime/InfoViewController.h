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

@interface InfoViewController : PSTableViewController <MKMapViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate> {
  NSDictionary *_place;
  MKCoordinateRegion _mapRegion;
  
  // Views
  MKMapView *_mapView;
  UIBarButtonItem *_detailButton;
}

- (id)initWithPlace:(NSDictionary *)place;
- (void)toggleDetail;
- (void)showMap:(UITapGestureRecognizer *)gestureRecognizer;

// Called from Detail
- (void)loadMap;
- (void)loadMeta;


- (void)call;
- (void)share;
- (void)reviews;

@end
