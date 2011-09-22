//
//  MapViewController.h
//  MealTime
//
//  Created by Peter Shih on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PSBaseViewController.h"

@interface MapViewController : PSBaseViewController <MKMapViewDelegate> {
  NSDictionary *_place;
  MKCoordinateRegion _mapRegion;
  
  // Views
  MKMapView *_mapView;
  
  BOOL _hasSetRegion;
}

- (id)initWithPlace:(NSDictionary *)place;
- (void)loadMap;
- (void)zoomToFitMapAnnotations:(MKMapView *)mapView;
//- (MKMapRect)mapRectForAnnotations:(NSArray*)annotations;

@end
