//
//  MapViewController.m
//  MealTime
//
//  Created by Peter Shih on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"
#import "PlaceAnnotation.h"
#import "PSLocationCenter.h"

#define BASE_RADIUS 0.0144927536 // 1 mile

@implementation MapViewController

- (id)initWithPlace:(NSDictionary *)place {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _place = place;
    _hasSetRegion = NO;
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
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  //    _mapRegion.center.latitude = [[_place objectForKey:@"latitude"] floatValue];
  //    _mapRegion.center.longitude = [[_place objectForKey:@"longitude"] floatValue];
  //    _mapRegion.span.latitudeDelta = 0.006;
  //    _mapRegion.span.longitudeDelta = 0.006;
  //    [_mapView setRegion:_mapRegion animated:NO];

}

- (void)loadView
{
  [super loadView];
  
  _navTitleLabel.text = [[_place objectForKey:@"address"] componentsJoinedByString:@" "];
  self.navigationItem.leftBarButtonItem = [UIBarButtonItem navBackButtonWithTarget:self action:@selector(back)];
  
  // Map
  _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 160.0)];
  _mapView.autoresizingMask = self.view.autoresizingMask;
  _mapView.delegate = self;
  _mapView.frame = self.view.bounds;
  _mapView.showsUserLocation = YES;
  [self.view addSubview:_mapView];
  [self loadMap];
  
  // Position the map so that all overlays and annotations are visible on screen.
  [self zoomToFitMapAnnotations:_mapView];
}

- (void)loadMap {
  NSArray *oldAnnotations = [_mapView annotations];
  [_mapView removeAnnotations:oldAnnotations];
  
  PlaceAnnotation *placeAnnotation = [[PlaceAnnotation alloc] initWithPlace:_place];
  [_mapView addAnnotation:placeAnnotation];
  [placeAnnotation release];
}

-(void)zoomToFitMapAnnotations:(MKMapView*)mapView
{
  if([mapView.annotations count] == 0)
    return;
  
  CLLocationCoordinate2D topLeftCoord;
  topLeftCoord.latitude = -90;
  topLeftCoord.longitude = 180;
  
  CLLocationCoordinate2D bottomRightCoord;
  bottomRightCoord.latitude = 90;
  bottomRightCoord.longitude = -180;
  
  for(PlaceAnnotation* annotation in mapView.annotations)
  {
    topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
    topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
    
    bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
    bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
  }
  
  MKCoordinateRegion region;
  region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
  region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
  region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 2; // Add a little extra space on the sides
  region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 2; // Add a little extra space on the sides
  
  region = [mapView regionThatFits:region];
  [mapView setRegion:region animated:YES];
}


//- (MKMapRect)mapRectForAnnotations:(NSArray*)annotations {
//  MKMapRect mapRect = MKMapRectNull;
//  
//  //annotations is an array with all the annotations I want to display on the map
//  for (id<MKAnnotation> annotation in annotations) { 
//    
//    MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
//    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
//    
//    if (MKMapRectIsNull(mapRect)) 
//    {
//      mapRect = pointRect;
//    } else 
//    {
//      mapRect = MKMapRectUnion(mapRect, pointRect);
//    }
//  }
//  
//  return mapRect;
//}

#pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
  if (!_hasSetRegion) {
    _hasSetRegion = YES;
    [self zoomToFitMapAnnotations:mapView];
  }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
  
  if ([annotation isKindOfClass:[MKUserLocation class]]) {
    return nil;
  }
  
  static NSString *placeAnnotationIdentifier = @"placeAnnotationIdentifier";
  
  MKPinAnnotationView *placePinView = (MKPinAnnotationView *)
  [mapView dequeueReusableAnnotationViewWithIdentifier:placeAnnotationIdentifier];
  if (!placePinView) {
    placePinView = [[[MKPinAnnotationView alloc]
                     initWithAnnotation:annotation reuseIdentifier:placeAnnotationIdentifier] autorelease];
    placePinView.pinColor = MKPinAnnotationColorRed;
    placePinView.animatesDrop = YES;
    placePinView.canShowCallout = YES;
    placePinView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
  } else {
    placePinView.annotation = annotation;
  }
  
  return  placePinView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Directions" message:[NSString stringWithFormat:@"Want to view driving directions to %@?", [_place objectForKey:@"name"]] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
  av.tag = kAlertDirections;
  [av show];
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
  [mapView selectAnnotation:[[mapView annotations] firstObject] animated:YES];
}

#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == alertView.cancelButtonIndex) return;
  
  if (alertView.tag == kAlertDirections) {
    CLLocationCoordinate2D currentLocation = [[PSLocationCenter defaultCenter] locationCoordinate];
    NSString *address = [[_place objectForKey:@"address"] componentsJoinedByString:@" "];
    NSString *mapsUrl = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%@", currentLocation.latitude, currentLocation.longitude, [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapsUrl]];
  }
}

@end
