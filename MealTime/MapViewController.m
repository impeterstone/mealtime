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
  
  _navTitleLabel.text = [[_place objectForKey:@"address"] componentsJoinedByString:@" "];
  self.navigationItem.leftBarButtonItem = [UIBarButtonItem navBackButtonWithTarget:self action:@selector(back)];
  
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
  if ([_place objectForKey:@"latitude"] && [_place objectForKey:@"longitude"]) {
    _mapRegion.center.latitude = [[_place objectForKey:@"latitude"] floatValue];
    _mapRegion.center.longitude = [[_place objectForKey:@"longitude"] floatValue];
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

#pragma mark - MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
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
  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Directions" message:[NSString stringWithFormat:@"Would you like to view directions to %@?", [_place objectForKey:@"name"]] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
  av.tag = kAlertDirections;
  [av show];
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
  [mapView selectAnnotation:[[mapView annotations] lastObject] animated:YES];
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
