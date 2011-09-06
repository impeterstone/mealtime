//
//  DetailViewController.m
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "InfoViewController.h"
#import "BizDataCenter.h"
#import "ZoomViewController.h"
#import "MapViewController.h"
#import "WebViewController.h"
#import "PSLocationCenter.h"
#import "PlaceAnnotation.h"

@interface DetailViewController (Private)

- (void)setupMap;
- (void)setupToolbar;
- (void)loadDetails;
- (void)loadMap;
- (void)showMap:(UITapGestureRecognizer *)gestureRecognizer;
- (void)call;
- (void)reviews;
- (void)directions;

@end

@implementation DetailViewController

- (id)initWithPlace:(NSDictionary *)place {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _place = [[NSMutableDictionary alloc] initWithDictionary:place];
    _imageSizeCache = [[NSMutableDictionary alloc] init];
    [[BizDataCenter defaultCenter] setDelegate:self];
    
    _photoCount = 0;
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_mapView);
  RELEASE_SAFELY(_toolbar);
  RELEASE_SAFELY(_infoButton);
  RELEASE_SAFELY(_captionBg);
  RELEASE_SAFELY(_captionView);
  RELEASE_SAFELY(_addressLabel);
  RELEASE_SAFELY(_hoursLabel);
}

- (void)dealloc
{
  [[BizDataCenter defaultCenter] setDelegate:nil];
  RELEASE_SAFELY(_place);
  RELEASE_SAFELY(_imageSizeCache);
  
  RELEASE_SAFELY(_mapView);
  RELEASE_SAFELY(_toolbar);
  RELEASE_SAFELY(_infoButton);
  RELEASE_SAFELY(_captionBg);
  RELEASE_SAFELY(_captionView);
  RELEASE_SAFELY(_addressLabel);
  RELEASE_SAFELY(_hoursLabel);
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
  backgroundView.backgroundColor = CELL_BACKGROUND_COLOR;
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
  _infoButton = [[UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"icon_info.png"] withTarget:self action:@selector(toggleInfo) width:40 height:30 buttonType:BarButtonTypeBlue] retain];
  _infoButton.enabled = NO;
  self.navigationItem.rightBarButtonItem = _infoButton;
  self.navigationItem.leftBarButtonItem = [UIBarButtonItem navBackButtonWithTarget:self action:@selector(back)];
  
  [_nullView setLoadingTitle:@"Loading..." loadingSubtitle:@"Finding Photos of Food" emptyTitle:@"No Photos" emptySubtitle:@"This Place Has No Photos" image:nil];
  
  // iAd
//  _adView = [self newAdBannerViewWithDelegate:self];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  _tableView.rowHeight = self.tableView.width;
  
  // Map
  [self setupMap];
  
  // Toolbar
  [self setupToolbar];
  
  // Populate datasource
  [self loadDataSource];
}

- (void)setupMap {
  // Map
  CGFloat mapHeight = 0.0;
  if (isDeviceIPad()) {
    mapHeight = 400.0;
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
  UIView *tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.width, mapHeight)] autorelease];
  [tableHeaderView addSubview:_mapView];
  
  // Caption BG
  _captionBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_caption.png"]];
  _captionBg.frame = CGRectMake(0, tableHeaderView.bottom - 30, tableHeaderView.width, 30);
  _captionBg.autoresizingMask = ~UIViewAutoresizingNone;
  [tableHeaderView addSubview:_captionBg];
  
  // Caption
  _captionView = [[UIScrollView alloc] initWithFrame:CGRectZero];
  _captionView.showsVerticalScrollIndicator = NO;
  _captionView.showsHorizontalScrollIndicator = NO;
  _captionView.frame = CGRectMake(0, tableHeaderView.bottom - 30, tableHeaderView.width, 30);
  _captionView.backgroundColor = [UIColor clearColor];
  
  // Hours
  _hoursLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  _hoursLabel.numberOfLines = 1;
  _hoursLabel.backgroundColor = [UIColor clearColor];
  _hoursLabel.textAlignment = UITextAlignmentLeft;
  _hoursLabel.font = [PSStyleSheet fontForStyle:@"hoursLabel"];
  _hoursLabel.textColor = [PSStyleSheet textColorForStyle:@"hoursLabel"];
  _hoursLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"hoursLabel"];
  _hoursLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"hoursLabel"];
  _hoursLabel.frame = _captionView.bounds;
  
//  // Address Label
//  _addressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//  _addressLabel.numberOfLines = 1;
//  _addressLabel.backgroundColor = [UIColor clearColor];
//  _addressLabel.textAlignment = UITextAlignmentCenter;
//  _addressLabel.font = [PSStyleSheet fontForStyle:@"addressLabel"];
//  _addressLabel.textColor = [PSStyleSheet textColorForStyle:@"addressLabel"];
//  _addressLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"addressLabel"];
//  _addressLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"addressLabel"];
//  _addressLabel.frame = _captionView.bounds;
//  [_captionView addSubview:_addressLabel];
  
  [_captionView addSubview:_hoursLabel];
  [tableHeaderView addSubview:_captionView];  
  
  _tableView.tableHeaderView = tableHeaderView;
  _tableView.tableHeaderView.alpha = 0.0;
}

- (void)setupToolbar {
  _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.0)];
  NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:1];
  
  [toolbarItems addObject:[UIBarButtonItem barButtonWithTitle:@"Call" withTarget:self action:@selector(call) width:90 height:30 buttonType:BarButtonTypeSilver]];
  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
  [toolbarItems addObject:[UIBarButtonItem barButtonWithTitle:@"Directions" withTarget:self action:@selector(directions) width:100 height:30 buttonType:BarButtonTypeSilver]];
  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
  [toolbarItems addObject:[UIBarButtonItem barButtonWithTitle:@"Reviews" withTarget:self action:@selector(reviews) width:90 height:30 buttonType:BarButtonTypeSilver]];
  
  [_toolbar setItems:toolbarItems];
  [self setupFooterWithView:_toolbar];
}

#pragma mark - Actions
- (void)showMap:(UITapGestureRecognizer *)gestureRecognizer {
  MapViewController *mvc = [[MapViewController alloc] initWithPlace:_place];
  [self.navigationController pushViewController:mvc animated:YES];
  [mvc release];
}

- (void)call {  
  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@", [_place objectForKey:@"phone"]] message:[NSString stringWithFormat:@"Would you like to call %@?", [_place objectForKey:@"name"]] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
  av.tag = kAlertCall;
  [av show];
}

- (void)reviews {
  WebViewController *wvc = [[WebViewController alloc] initWithURLString:[NSString stringWithFormat:@"http://lite.yelp.com/biz/%@", [_place objectForKey:@"biz"]]];
  [self.navigationController pushViewController:wvc animated:YES];
  [wvc release];
}

- (void)directions {
  CLLocationCoordinate2D currentLocation = [[PSLocationCenter defaultCenter] locationCoordinate];
  NSString *address = [[_place objectForKey:@"address"] componentsJoinedByString:@" "];
  NSString *mapsUrl = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%@", currentLocation.latitude, currentLocation.longitude, [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapsUrl]];
}

#pragma mark - Load Data
- (void)loadMap {
  // zoom to place
  if ([_place objectForKey:@"latitude"] && [_place objectForKey:@"longitude"]) {
    _mapRegion.center.latitude = [[_place objectForKey:@"latitude"] floatValue];
    _mapRegion.center.longitude = [[_place objectForKey:@"longitude"] floatValue];
    _mapRegion.span.latitudeDelta = 0.006;
    _mapRegion.span.longitudeDelta = 0.006;
    [_mapView setRegion:_mapRegion animated:NO];
  }
  
  NSArray *oldAnnotations = [_mapView annotations];
  [_mapView removeAnnotations:oldAnnotations];
  
  PlaceAnnotation *placeAnnotation = [[PlaceAnnotation alloc] initWithPlace:_place];
  [_mapView addAnnotation:placeAnnotation];
  [placeAnnotation release];
}

- (void)loadDetails {
//  if ([[_place objectForKey:@"address"] notNil]) {
//    _addressLabel.text = [[_place objectForKey:@"address"] componentsJoinedByString:@" "];
//  }
  if ([[_place objectForKey:@"hours"] notNil]) {
    _hoursLabel.text = [[_place objectForKey:@"hours"] componentsJoinedByString:@", "];
  } else {
    _hoursLabel.text = @"No hours listed";
  }
  
  CGSize desiredSize = [UILabel sizeForText:_hoursLabel.text width:INT_MAX font:_hoursLabel.font numberOfLines:_hoursLabel.numberOfLines lineBreakMode:_hoursLabel.lineBreakMode];
  _hoursLabel.width = desiredSize.width;
  _hoursLabel.height = _captionView.height;
  _hoursLabel.left = 10;
  
  _captionView.contentSize = CGSizeMake(desiredSize.width + 20, _captionView.height);
}

- (void)toggleInfo {
  // Info VC
  _ivc = [[InfoViewController alloc] initWithPlace:_place];
  [self.navigationController pushViewController:_ivc animated:YES];
  [_ivc release];
}

#pragma mark - State Machine
- (BOOL)shouldLoadMore {
  return NO;
}

- (void)loadDataSource {
  [super loadDataSource];
  
  // Preload from database
  // No sense of order from server right now
//  [self loadPhotosFromDatabase];
  
  
#if USE_FIXTURES
  [[BizDataCenter defaultCenter] getPhotosFromFixturesForBiz:[_place objectForKey:@"biz"]];
  [[BizDataCenter defaultCenter] getBizFromFixturesForBiz:[_place objectForKey:@"biz"]];
#else
  // Combined call
  [[BizDataCenter defaultCenter] fetchDetailsForPlace:_place];
  
//  [[BizDataCenter defaultCenter] fetchYelpPhotosForBiz:[_place objectForKey:@"biz"] start:start rpp:rpp];
//  [[BizDataCenter defaultCenter] fetchYelpBizForBiz:[_place objectForKey:@"biz"]];
#endif
  
  // Get ALL reviews for this place
  if (![[NSUserDefaults standardUserDefaults] boolForKey:[_place objectForKey:@"biz"]]) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[_place objectForKey:@"biz"]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSInteger numReviews = [[_place objectForKey:@"numreviews"] notNil] ? [[_place objectForKey:@"numreviews"] integerValue] : 0;
    int i = 0;
    for (i = 0; i < numReviews; i = i + 400) {
      // Fire off requests for reviews 400 at a time
      [[BizDataCenter defaultCenter] fetchYelpReviewsForBiz:[_place objectForKey:@"biz"] start:i rpp:400];
    }
  }
}

- (void)dataSourceDidLoad {
  if ([self dataIsAvailable]) {
    [[self.tableView visibleCells] makeObjectsPerformSelector:@selector(setShouldAnimate:) withObject:[NSNumber numberWithBool:NO]];
  }
  [self.tableView reloadData];
  if ([self dataIsAvailable]) {
    [[self.tableView visibleCells] makeObjectsPerformSelector:@selector(setShouldAnimate:) withObject:[NSNumber numberWithBool:YES]];
  }
  
  [self loadDetails];
  [self loadMap];
  _tableView.tableHeaderView.alpha = 1.0; // Show header now
  [super dataSourceDidLoad];
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinishWithResponse:(id)response andUserInfo:(NSDictionary *)userInfo {
  // Match place from request to current, make sure this request is still valid
  if (![[userInfo objectForKey:@"place"] isEqual:_place]) return;
  
  [self.items removeAllObjects];
  NSArray *photos = [_place objectForKey:@"photos"];
  if ([photos count] > 0) {
    [self.items addObject:photos];
  }
  
  [self dataSourceDidLoad];
}

- (void)dataCenterDidFailWithError:(NSError *)error andUserInfo:(NSDictionary *)userInfo {
  if ([[userInfo objectForKey:@"requestType"] isEqualToString:@"photos"]) {
    [super dataSourceDidLoad];
  }
}

#pragma mark - TableView
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.width, 30)] autorelease];
//  headerView.autoresizingMask = ~UIViewAutoresizingNone;
//  headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_section_header.png"]];
//  return headerView;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//  return 30.0;
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//  if ([_sectionTitles count] == 0) return nil;
//  
//  NSString *sectionTitle = nil;
//  sectionTitle = [_sectionTitles objectAtIndex:section];
//  if (![sectionTitle notNil]) return nil;
//  
//  UIView *sectionHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 26)] autorelease];
//  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_section_header.png"]] autorelease];
//  bg.frame = sectionHeaderView.bounds;
//  bg.autoresizingMask = ~UIViewAutoresizingNone;
//  [sectionHeaderView addSubview:bg];
//
////  sectionHeaderView.backgroundColor = SECTION_HEADER_COLOR;
//  
//  UILabel *sectionHeaderLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 310, 24)] autorelease];
//  sectionHeaderLabel.backgroundColor = [UIColor clearColor];
//  sectionHeaderLabel.text = sectionTitle;
//  sectionHeaderLabel.textColor = [UIColor whiteColor];
//  sectionHeaderLabel.shadowColor = [UIColor blackColor];
//  sectionHeaderLabel.shadowOffset = CGSizeMake(0, 1);
//  sectionHeaderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
//  [sectionHeaderView addSubview:sectionHeaderLabel];
//  
//  return sectionHeaderView;
//}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//  if ([_sectionTitles count] == 0) return nil;
//  
//  NSString *sectionTitle = nil;
//  sectionTitle = [_sectionTitles objectAtIndex:section];
//  if ([sectionTitle notNil]) {
//    return sectionTitle;
//  } else {
//    return nil;
//  }
//}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//  NSDictionary *product = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
//  NSString *sizeString = [_imageSizeCache objectForKey:[product objectForKey:@"src"]];
//  if (sizeString) {
//    CGSize size = CGSizeFromString(sizeString);
//    CGFloat scaledHeight = floorf(size.height / (size.width / self.tableView.width));
//    return scaledHeight;
//  } else {
//    return self.tableView.width;
//  }
//}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *product = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  [cell fillCellWithObject:product];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ProductCell *cell = nil;
  NSString *reuseIdentifier = [ProductCell reuseIdentifier];
  
  cell = (ProductCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[ProductCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
    cell.delegate = self;
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  ProductCell *cell = (ProductCell *)[tableView cellForRowAtIndexPath:indexPath];
  
  ZoomViewController *zvc = [[ZoomViewController alloc] init];
  [self presentModalViewController:zvc animated:YES];
  zvc.imageView.image = cell.photoView.image;
  [zvc release];
}

#pragma mark - UIGestureRecognizerDelegate
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
//  if ([touch.view isKindOfClass:[MKPinAnnotationView class]]) {
//    return NO;
//  } else {
//    return YES;
//  }
//}

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
  } else {
    placePinView.annotation = annotation;
  }
  
  return  placePinView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
  [mapView selectAnnotation:[[mapView annotations] lastObject] animated:YES];
}

#pragma mark - ProductCellDelegate
//- (void)productCell:(ProductCell *)cell didLoadImage:(UIImage *)image {
//  // UNUSED
//  NSString *sizeString = NSStringFromCGSize(image.size);
//  NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
//  NSDictionary *product = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
//  [_imageSizeCache setValue:sizeString forKey:[product objectForKey:@"src"]];
//}

@end
