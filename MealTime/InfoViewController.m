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

@implementation InfoViewController

@synthesize parent = _parent;

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
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];

  _tableView.scrollsToTop = NO;
  
  // Map
  _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, _tableView.width, 160.0)];
  _mapView.delegate = self;
  _mapView.zoomEnabled = NO;
  _mapView.scrollEnabled = NO;
  
  UITapGestureRecognizer *mapTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMap:)] autorelease];
  mapTap.numberOfTapsRequired = 1;
  [_mapView addGestureRecognizer:mapTap];
  
  // Table Header View
  UIView *tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.width, 200)] autorelease];
  
  UIView *actionView = [[[UIView alloc] initWithFrame:CGRectMake(0, 160, _tableView.width, 40)] autorelease];
  actionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_actionbar.png"]];
  
  // Action Buttons
  UIButton *callButton = [UIButton buttonWithType:UIButtonTypeCustom];
  callButton.frame = CGRectMake(5, 5, 100, 29);
  [callButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateNormal];
  [callButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar_highlighted.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateHighlighted];
  [callButton setTitle:@"Call" forState:UIControlStateNormal];
  [callButton.titleLabel setFont:[PSStyleSheet fontForStyle:@"actionButton"]];
  [callButton setTitleColor:[PSStyleSheet textColorForStyle:@"actionButton"] forState:UIControlStateNormal];
  [callButton.titleLabel setShadowColor:[PSStyleSheet shadowColorForStyle:@"actionButton"]];
  [callButton.titleLabel setShadowOffset:[PSStyleSheet shadowOffsetForStyle:@"actionButton"]];
  [callButton addTarget:self action:@selector(call) forControlEvents:UIControlEventTouchUpInside];
  [actionView addSubview:callButton];
  
  UIButton *checkinButton = [UIButton buttonWithType:UIButtonTypeCustom];
  checkinButton.frame = CGRectMake(110, 5, 100, 29);
  [checkinButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateNormal];
  [checkinButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_actionbar_highlighted.png" withLeftCapWidth:7 topCapWidth:15] forState:UIControlStateHighlighted];
  [checkinButton setTitle:@"Check In" forState:UIControlStateNormal];
  [checkinButton.titleLabel setFont:[PSStyleSheet fontForStyle:@"actionButton"]];
  [checkinButton setTitleColor:[PSStyleSheet textColorForStyle:@"actionButton"] forState:UIControlStateNormal];
  [checkinButton.titleLabel setShadowColor:[PSStyleSheet shadowColorForStyle:@"actionButton"]];
  [checkinButton.titleLabel setShadowOffset:[PSStyleSheet shadowOffsetForStyle:@"actionButton"]];
  [checkinButton addTarget:self action:@selector(checkin) forControlEvents:UIControlEventTouchUpInside];
  [actionView addSubview:checkinButton];
  
  UIButton *reviewsButton = [UIButton buttonWithType:UIButtonTypeCustom];
  reviewsButton.frame = CGRectMake(215, 5, 100, 29);
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
  if ([_place objectForKey:@"phone"]) {
    [_sectionTitles addObject:@"Phone"];
    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"phone"]]];
  }
  
  if ([_place objectForKey:@"address"]) {
    [_sectionTitles addObject:@"Address"];
    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"address"]]];
  }
  
  if ([_place objectForKey:@"hours"]) {
    [_sectionTitles addObject:@"Hours"];
    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"hours"]]];
  }
  
  if ([_place objectForKey:@"category"]) {
    [_sectionTitles addObject:@"Category"];
    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"category"]]];
  }
  
  if ([_place objectForKey:@"price"]) {
    [_sectionTitles addObject:@"Price"];
    [self.items addObject:[NSArray arrayWithObject:[_place objectForKey:@"price"]]];
  }
  
  [self dataSourceDidLoad];
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

- (void)checkin {
  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Foursquare" message:[NSString stringWithFormat:@"Check in at %@?", [_place objectForKey:@"name"]] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
  av.tag = kAlertCheckin;
  [av show];
}

- (void)reviews {
  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Yelp Reviews" message:@"Want to read reviews on Yelp?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
  av.tag = kAlertReviews;
  [av show];
}

- (void)showMap:(UITapGestureRecognizer *)gestureRecognizer {
  MapViewController *mvc = [[MapViewController alloc] initWithPlace:_place];
  [_parent.navigationController pushViewController:mvc animated:YES];
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

#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == alertView.cancelButtonIndex) return;
  
  if (alertView.tag == kAlertCall) {
    NSString *phoneNumber = [[[_place objectForKey:@"phone"] componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
    NSString *telString = [NSString stringWithFormat:@"tel:%@", phoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:telString]];
  } else if (alertView.tag == kAlertReviews) {
    WebViewController *wvc = [[WebViewController alloc] initWithURLString:[NSString stringWithFormat:@"http://lite.yelp.com/biz/%@", [_place objectForKey:@"biz"]]];
    [_parent.navigationController pushViewController:wvc animated:YES];
    [wvc release];
  }
}

@end
