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
  NSArray *_places;
  NSDictionary *_place;
  MKCoordinateRegion _mapRegion;
  MKAnnotationView *_selectedAnnotationView;
  
  // Views
  MKMapView *_mapView;
  
  BOOL _hasSetRegion;
}

- (id)initWithPlaces:(NSArray *)places;
- (id)initWithPlace:(NSDictionary *)place;
- (void)loadMap;
- (void)zoomToFitMapAnnotations:(MKMapView *)mapView;
//- (MKMapRect)mapRectForAnnotations:(NSArray*)annotations;

@end
