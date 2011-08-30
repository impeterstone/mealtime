//
//  InfoViewController.m
//  MealTime
//
//  Created by Peter Shih on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InfoViewController.h"
#import "MapViewController.h"
#import "WebViewController.h"
#import "PlaceAnnotation.h"
#import "MetaCell.h"
#import "PSLocationCenter.h"
#import "PSFacebookCenter.h"

@implementation InfoViewController

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
  RELEASE_SAFELY(_detailButton);
}

- (void)dealloc
{
  RELEASE_SAFELY(_mapView);
  RELEASE_SAFELY(_detailButton);
  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_darkwood.jpg"]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  return bg;
}

- (UIView *)rowBackgroundView {
  UIView *backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  backgroundView.autoresizingMask = ~UIViewAutoresizingNone;
  backgroundView.backgroundColor = [UIColor whiteColor];
  return backgroundView;
}

- (UIView *)rowSelectedBackgroundView {
  UIView *selectedBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  selectedBackgroundView.autoresizingMask = ~UIViewAutoresizingNone;
  selectedBackgroundView.backgroundColor = CELL_SELECTED_COLOR;
  return selectedBackgroundView;
}

#pragma mark - View
- (void)loadView
{
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];

  // NavBar
  _navTitleLabel.text = [_place objectForKey:@"name"];
  self.navigationItem.leftBarButtonItem = [UIBarButtonItem navBackButtonWithTarget:self action:@selector(back)];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  // Map
  CGFloat mapHeight = 0.0;
  if (isDeviceIPad()) {
    mapHeight = 480.0;
  } else {
    mapHeight = 200.0;
  }
  _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, _tableView.width, mapHeight)];
  _mapView.delegate = self;
  _mapView.zoomEnabled = NO;
  _mapView.scrollEnabled = NO;
  
  UITapGestureRecognizer *mapTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMap:)] autorelease];
  mapTap.numberOfTapsRequired = 1;
  mapTap.delegate = self;
  [_mapView addGestureRecognizer:mapTap];
  
  // Table Header View
  UIView *tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.width, mapHeight + 40)] autorelease];
  
  UIView *actionView = [[[UIView alloc] initWithFrame:CGRectMake(0, mapHeight, _tableView.width, 40)] autorelease];
  actionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_actionbar.png"]];
  
  // Action Buttons
  UIButton *callButton = [UIButton buttonWithType:UIButtonTypeCustom];
  callButton.frame = CGRectMake(5, 5, floorf((self.view.width - 20) / 3), 29);
  [callButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateNormal];
  [callButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar_highlighted.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateHighlighted];
  [callButton setTitle:@"Call" forState:UIControlStateNormal];
  [callButton.titleLabel setFont:[PSStyleSheet fontForStyle:@"actionButton"]];
  [callButton setTitleColor:[PSStyleSheet textColorForStyle:@"actionButton"] forState:UIControlStateNormal];
  [callButton.titleLabel setShadowColor:[PSStyleSheet shadowColorForStyle:@"actionButton"]];
  [callButton.titleLabel setShadowOffset:[PSStyleSheet shadowOffsetForStyle:@"actionButton"]];
  [callButton addTarget:self action:@selector(call) forControlEvents:UIControlEventTouchUpInside];
  [actionView addSubview:callButton];
  
  UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
  shareButton.frame = CGRectMake(callButton.right + 5, 5, floorf((self.view.width - 20) / 3), 29);
  [shareButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateNormal];
  [shareButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar_highlighted.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateHighlighted];
  [shareButton setTitle:@"Share" forState:UIControlStateNormal];
  [shareButton.titleLabel setFont:[PSStyleSheet fontForStyle:@"actionButton"]];
  [shareButton setTitleColor:[PSStyleSheet textColorForStyle:@"actionButton"] forState:UIControlStateNormal];
  [shareButton.titleLabel setShadowColor:[PSStyleSheet shadowColorForStyle:@"actionButton"]];
  [shareButton.titleLabel setShadowOffset:[PSStyleSheet shadowOffsetForStyle:@"actionButton"]];
  [shareButton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
  [actionView addSubview:shareButton];
  
  UIButton *reviewsButton = [UIButton buttonWithType:UIButtonTypeCustom];
  reviewsButton.frame = CGRectMake(shareButton.right + 5, 5, floorf((self.view.width - 20) / 3), 29);
  [reviewsButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateNormal];
  [reviewsButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar_highlighted.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateHighlighted];
  [reviewsButton setTitle:@"Reviews" forState:UIControlStateNormal];
  [reviewsButton.titleLabel setFont:[PSStyleSheet fontForStyle:@"actionButton"]];
  [reviewsButton setTitleColor:[PSStyleSheet textColorForStyle:@"actionButton"] forState:UIControlStateNormal];
  [reviewsButton.titleLabel setShadowColor:[PSStyleSheet shadowColorForStyle:@"actionButton"]];
  [reviewsButton.titleLabel setShadowOffset:[PSStyleSheet shadowOffsetForStyle:@"actionButton"]];
  [reviewsButton addTarget:self action:@selector(reviews) forControlEvents:UIControlEventTouchUpInside];
  [actionView addSubview:reviewsButton];
  
  [tableHeaderView addSubview:_mapView];
  [tableHeaderView addSubview:actionView];
  _tableView.tableHeaderView = tableHeaderView;
  
  // Populate datasource
  [self loadDataSource];
  [self loadMap];
  [self loadMeta];
  
  [self dataSourceDidLoad];
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

- (void)loadMeta {
  [self.items removeAllObjects];
  
  // Sections
//  if ([[_place objectForKey:@"phone"] notNil]) {
//    [_sectionTitles addObject:@"Phone"];
//    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"phone"]]];
//  }
  
//  if ([[_place objectForKey:@"address"] notNil]) {
//    [_sectionTitles addObject:@"Address"];
//    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"address"]]];
//  }
  
  if ([[_place objectForKey:@"hours"] notNil]) {
    [_sectionTitles addObject:@"Hours"];
    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"hours"]]];
  }
  
  if ([[_place objectForKey:@"category"] notNil]) {
    [_sectionTitles addObject:@"Category"];
    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"category"]]];
  }
  
  if ([[_place objectForKey:@"price"] notNil]) {
    [_sectionTitles addObject:@"Price"];
    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"price"]]];
  }
  
  if ([[_place objectForKey:@"numreviews"] notNil]) {
    [_sectionTitles addObject:@"Review Count"];
    [self.items addObject:[NSArray arrayWithObject:[NSString stringWithFormat:@"%@ from Yelp", [_place objectForKey:@"numreviews"]]]];
  }
  
}

- (void)dataSourceDidLoad {
  [self.tableView reloadData];
  [super dataSourceDidLoad];
}

#pragma mark - Button Actions
- (void)call {  
  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@", [_place objectForKey:@"phone"]] message:[NSString stringWithFormat:@"Would you like to call %@?", [_place objectForKey:@"name"]] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
  av.tag = kAlertCall;
  [av show];
}

- (void)share {
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 FB_APP_ID, @"app_id",
                                 @"http://www.seveminutelabs.com", @"link",
                                 @"http://fbrell.com/f8.jpg", @"picture",
                                 @"I'm using MealTime!", @"name",
                                 @"I'm Awesome!", @"description",
                                 nil];
  
  [[PSFacebookCenter defaultCenter] showDialog:@"feed" andParams:params];
  
  return;
}

- (void)reviews {
  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Yelp Reviews" message:@"Want to read reviews on Yelp?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
  av.tag = kAlertReviews;
  [av show];
}

- (void)showMap:(UITapGestureRecognizer *)gestureRecognizer {
  MapViewController *mvc = [[MapViewController alloc] initWithPlace:_place];
  [self.navigationController pushViewController:mvc animated:YES];
  [mvc release];
}

- (void)toggleDetail {
  [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)dataIsAvailable {
  return YES;
}

- (BOOL)dataIsLoading {
  return NO;
}

#pragma mark - TableView
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if ([_sectionTitles count] == 0) return nil;
  
  NSString *sectionTitle = nil;
  sectionTitle = [_sectionTitles objectAtIndex:section];
  if ([sectionTitle notNil]) {
    return sectionTitle;
  } else {
    return nil;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSString *meta = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  return [MetaCell rowHeightForObject:meta forInterfaceOrientation:[self interfaceOrientation]];
}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  NSString *meta = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  [cell fillCellWithObject:meta];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  MetaCell *cell = nil;
  NSString *reuseIdentifier = [MetaCell reuseIdentifier];
  
  cell = (MetaCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[MetaCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  if ([touch.view isKindOfClass:[MKPinAnnotationView class]]) {
    return NO;
  } else {
    return YES;
  }
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
  
  if (alertView.tag == kAlertCall) {
    NSString *phoneNumber = [[[_place objectForKey:@"phone"] componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
    NSString *telString = [NSString stringWithFormat:@"tel:%@", phoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:telString]];
  } else if (alertView.tag == kAlertReviews) {
    WebViewController *wvc = [[WebViewController alloc] initWithURLString:[NSString stringWithFormat:@"http://lite.yelp.com/biz/%@", [_place objectForKey:@"biz"]]];
    [self.navigationController pushViewController:wvc animated:YES];
    [wvc release];
  } else if (alertView.tag == kAlertDirections) {
    CLLocationCoordinate2D currentLocation = [[PSLocationCenter defaultCenter] locationCoordinate];
    NSString *address = [_place objectForKey:@"address"];
    NSString *mapsUrl = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%@", currentLocation.latitude, currentLocation.longitude, [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapsUrl]];
  }
}

@end
