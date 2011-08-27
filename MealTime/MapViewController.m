//
//  MapViewController.m
//  MealTime
//
//  Created by Peter Shih on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"

@implementation MapViewController

- (id)initWithPlace:(NSDictionary *)place {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _place = [place copy];
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_mapView);
}

- (void)dealloc
{
  RELEASE_SAFELY(_place);
  
  RELEASE_SAFELY(_mapView);
  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_darkwood.jpg"]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  return bg;
}

#pragma mark - View
- (void)loadView
{
  [super loadView];
  
  // Map
  _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 160.0)];
  _mapView.delegate = self;
  _mapView.frame = self.view.bounds;
  [self.view addSubview:_mapView];
  [self loadMap];
}

- (void)loadMap {
  // zoom to place
  _mapRegion.center.latitude = 37.32798;
  _mapRegion.center.longitude = -122.01382;
  _mapRegion.span.latitudeDelta = 0.01;
  _mapRegion.span.longitudeDelta = 0.01;
  
  [_mapView setRegion:_mapRegion animated:NO];
  NSArray *oldAnnotations = [_mapView annotations];
  //  [_mapView removeAnnotations:oldAnnotations];
  //  [_mapView addAnnotation:message];
}

@end
