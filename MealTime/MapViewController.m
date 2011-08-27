//
//  MapViewController.m
//  MealTime
//
//  Created by Peter Shih on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"
#import "PlaceAnnotation.h"

@implementation MapViewController

- (id)initWithPlace:(NSDictionary *)place {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _place = place;
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_mapView);
}

- (void)dealloc
{
  
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
  _mapView.autoresizingMask = self.view.autoresizingMask;
  _mapView.delegate = self;
  _mapView.frame = self.view.bounds;
  [self.view addSubview:_mapView];
  [self loadMap];
}

- (void)loadMap {
  // zoom to place
  if ([_place objectForKey:@"coordinates"]) {
    NSArray *coords = [[_place objectForKey:@"coordinates"] componentsSeparatedByString:@","];
    _mapRegion.center.latitude = [[coords objectAtIndex:0] floatValue];
    _mapRegion.center.longitude = [[coords objectAtIndex:1] floatValue];
    _mapRegion.span.latitudeDelta = 0.003;
    _mapRegion.span.longitudeDelta = 0.003;
    [_mapView setRegion:_mapRegion animated:NO];
  }
  
  NSArray *oldAnnotations = [_mapView annotations];
  [_mapView removeAnnotations:oldAnnotations];
  
  PlaceAnnotation *placeAnnotation = [[PlaceAnnotation alloc] initWithPlace:_place];
  [_mapView addAnnotation:placeAnnotation];
  [placeAnnotation release];
}

@end
