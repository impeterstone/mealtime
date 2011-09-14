//
//  DetailViewController.m
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "BizDataCenter.h"
#import "ZoomViewController.h"
#import "MapViewController.h"
#import "WebViewController.h"
#import "PSLocationCenter.h"
#import "PlaceAnnotation.h"

#import "PSDatabaseCenter.h"

@interface DetailViewController (Private)

- (NSMutableDictionary *)loadPlaceFromDatabaseWithBiz:(NSString *)biz;

- (void)setupMap;
- (void)setupToolbar;
- (void)loadDetails;
- (void)loadMap;
- (void)showMap:(UITapGestureRecognizer *)gestureRecognizer;
- (void)call;
- (void)reviews;
- (void)directions;
- (void)toggleStar;

@end

@implementation DetailViewController

- (id)initWithPlace:(NSDictionary *)place {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _isSavedPlace = NO;
    NSMutableDictionary *cachedPlace = [self loadPlaceFromDatabaseWithBiz:[place objectForKey:@"biz"]];
    if (cachedPlace) {
      _isCachedPlace = YES;
      _place = [cachedPlace retain];
    } else {
      _isCachedPlace = NO;
      _place = [[NSMutableDictionary alloc] initWithDictionary:place];
    }
    
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
  RELEASE_SAFELY(_starButton);
  RELEASE_SAFELY(_hoursView);
  RELEASE_SAFELY(_addressView);
  RELEASE_SAFELY(_addressLabel);
  RELEASE_SAFELY(_hoursScrollView);
  RELEASE_SAFELY(_hoursLabel);
}

- (void)dealloc
{
  [[BizDataCenter defaultCenter] setDelegate:nil];
  RELEASE_SAFELY(_place);
  RELEASE_SAFELY(_imageSizeCache);
  
  RELEASE_SAFELY(_mapView);
  RELEASE_SAFELY(_toolbar);
  RELEASE_SAFELY(_starButton);
  RELEASE_SAFELY(_hoursView);
  RELEASE_SAFELY(_addressView);
  RELEASE_SAFELY(_addressLabel);
  RELEASE_SAFELY(_hoursScrollView);
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
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)loadView
{
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  // NavBar
  _navTitleLabel.text = [_place objectForKey:@"name"];
  
  // Favorite Star
  NSString *iconStar = nil;
  if (_isSavedPlace) {
    iconStar = @"icon_star_gold.png";
  } else {
    iconStar = @"icon_star_silver.png";
  }
  _starButton = [[UIBarButtonItem barButtonWithImage:[UIImage imageNamed:iconStar] withTarget:self action:@selector(toggleStar) width:40 height:30 buttonType:BarButtonTypeNormal] retain];
  _starButton.enabled = NO;
  
  self.navigationItem.rightBarButtonItem = _starButton;
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
  
  // Table Header View
  UIView *tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.width, mapHeight)] autorelease];

  // Map
  _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, _tableView.width, mapHeight)];
  _mapView.delegate = self;
  _mapView.zoomEnabled = NO;
  _mapView.scrollEnabled = NO;
  
  [_mapView addGradientLayerWithColors:[NSArray arrayWithObjects:(id)[RGBACOLOR(0, 0, 0, 0.8) CGColor], (id)[RGBACOLOR(0, 0, 0, 0.0) CGColor], (id)[RGBACOLOR(0, 0, 0, 0.0) CGColor], (id)[RGBACOLOR(0, 0, 0, 0.8) CGColor], (id)[RGBACOLOR(0, 0, 0, 1.0) CGColor], nil] andLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.6], [NSNumber numberWithFloat:0.85], [NSNumber numberWithFloat:0.99], [NSNumber numberWithFloat:1.0], nil]];

  UIImageView *disclosureView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure_indicator_white_bordered.png"]] autorelease];
  disclosureView.contentMode = UIViewContentModeCenter;
  disclosureView.alpha = 0.8;
  disclosureView.frame = CGRectMake(_mapView.width - disclosureView.width - 10, 0, disclosureView.width, _mapView.height);
  [_mapView addSubview:disclosureView];

  [tableHeaderView addSubview:_mapView];
  
  // Map Gesture
  UITapGestureRecognizer *mapTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMap:)] autorelease];
  mapTap.numberOfTapsRequired = 1;
  mapTap.delegate = self;
  [_mapView addGestureRecognizer:mapTap];
  
  // Address
  _addressView = [[UIView alloc] initWithFrame:CGRectMake(0, tableHeaderView.bottom - 30, tableHeaderView.width, 30)];
  _addressView.backgroundColor = [UIColor clearColor];
  UIImageView *abg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_caption.png"]] autorelease];
  abg.frame = _addressView.bounds;
  abg.autoresizingMask = ~UIViewAutoresizingNone;
  [_addressView addSubview:abg];
  [tableHeaderView addSubview:_addressView];
  
  // Address Label
  _addressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  _addressLabel.numberOfLines = 1;
  _addressLabel.backgroundColor = [UIColor clearColor];
  _addressLabel.textAlignment = UITextAlignmentCenter;
  _addressLabel.font = [PSStyleSheet fontForStyle:@"addressLabel"];
  _addressLabel.textColor = [PSStyleSheet textColorForStyle:@"addressLabel"];
  _addressLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"addressLabel"];
  _addressLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"addressLabel"];
  _addressLabel.frame = _addressView.bounds;
  [_addressView addSubview:_addressLabel];
  
  // Hours
  _hoursView = [[UIView alloc] initWithFrame:CGRectZero];
  _hoursView.frame = CGRectMake(0, 0, tableHeaderView.width, 30);
  _hoursView.backgroundColor = [UIColor clearColor];
//  UIImageView *hbg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_caption.png"]] autorelease];
//  hbg.frame = _hoursView.bounds;
//  hbg.autoresizingMask = ~UIViewAutoresizingNone;
//  [_hoursView addSubview:hbg];
  [tableHeaderView addSubview:_hoursView];
  
  // Hours
  _hoursScrollView = [[UIScrollView alloc] initWithFrame:_hoursView.bounds];
  _hoursScrollView.showsVerticalScrollIndicator = NO;
  _hoursScrollView.showsHorizontalScrollIndicator = NO;
  _hoursScrollView.scrollsToTop = NO;
  [_hoursView addSubview:_hoursScrollView];
  
  _hoursLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  _hoursLabel.numberOfLines = 0;
  _hoursLabel.backgroundColor = [UIColor clearColor];
  _hoursLabel.textAlignment = UITextAlignmentLeft;
  _hoursLabel.font = [PSStyleSheet fontForStyle:@"hoursLabel"];
  _hoursLabel.textColor = [PSStyleSheet textColorForStyle:@"hoursLabel"];
  _hoursLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"hoursLabel"];
  _hoursLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"hoursLabel"];
  _hoursLabel.frame = _hoursView.bounds;
  [_hoursScrollView addSubview:_hoursLabel];
  
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
  if (isYelpInstalled()) {
  // yelp:///biz/the-sentinel-san-francisco
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"yelp:///biz/%@", [_place objectForKey:@"biz"]]]];
  } else {
    WebViewController *wvc = [[WebViewController alloc] initWithURLString:[NSString stringWithFormat:@"http://lite.yelp.com/biz/%@", [_place objectForKey:@"biz"]]];
    [self.navigationController pushViewController:wvc animated:YES];
    [wvc release];
  }
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
  if ([[_place objectForKey:@"address"] notNil]) {
    _addressLabel.text = [[_place objectForKey:@"address"] componentsJoinedByString:@" "];
  } else {
    _addressLabel.text = @"No address listed";
  }
  
  if ([[_place objectForKey:@"hours"] notNil]) {
    _hoursLabel.text = [[_place objectForKey:@"hours"] componentsJoinedByString:@"\n"];
  } else {
    _hoursLabel.text = @"No hours listed";
  }
  
  CGSize desiredSize = [UILabel sizeForText:_hoursLabel.text width:INT_MAX font:_hoursLabel.font numberOfLines:_hoursLabel.numberOfLines lineBreakMode:_hoursLabel.lineBreakMode];
  _hoursLabel.width = desiredSize.width;
  _hoursLabel.height = desiredSize.height;
  _hoursLabel.left = 10;
  _hoursLabel.top = 5;
  
  _hoursView.frame = CGRectMake(0, 0, desiredSize.width + 20, desiredSize.height + 10);
  _hoursScrollView.frame = _hoursView.bounds;
  _hoursScrollView.contentSize = CGSizeMake(desiredSize.width + 20, desiredSize.height + 10);
}

- (void)toggleStar {
  NSString *iconStar = nil;
  if (_isSavedPlace) {
    _isSavedPlace = NO;
    iconStar = @"icon_star_silver.png";
  } else {
    _isSavedPlace = YES;
    iconStar = @"icon_star_gold.png";
  }
  [(UIButton *)_starButton.customView setImage:[UIImage imageNamed:iconStar] forState:UIControlStateNormal];
  [(UIButton *)_starButton.customView setImage:[UIImage imageNamed:iconStar] forState:UIControlStateHighlighted];
  
  NSNumber *isSavedPlace = [NSNumber numberWithBool:_isSavedPlace];
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"UPDATE places SET saved = ? WHERE biz = ?", isSavedPlace, [_place objectForKey:@"biz"], nil];
}

- (NSMutableDictionary *)loadPlaceFromDatabaseWithBiz:(NSString *)biz {
  EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"SELECT * FROM places WHERE biz = ?", biz, nil];
  
  if ([res count] > 0) {
    NSData *placeData = [[[res rows] lastObject] dataForColumn:@"data"];
    _isSavedPlace = (BOOL)[[[res rows] lastObject] boolForColumn:@"saved"];
    return [NSKeyedUnarchiver unarchiveObjectWithData:placeData];
  } else {
    _isSavedPlace = NO;
    return nil;
  }
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

#else
  // Combined call
  if (!_isCachedPlace) {
    [[BizDataCenter defaultCenter] fetchDetailsForPlace:_place];
  } else {
    [self dataSourceShouldLoadObjects:[_place objectForKey:@"photos"]];
  }
  
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
#endif
}

- (void)dataSourceDidLoad {  
  [self loadDetails];
  [self loadMap];
  
  _starButton.enabled = YES;
  _tableView.tableHeaderView.alpha = 1.0; // Show header now
  
  [super dataSourceDidLoad];
}

- (void)dataSourceShouldLoadObjects:(id)objects {
  //
  // PREPARE DATASOURCE
  //
  
  /**
   SECTIONS
   If an existing section doesn't exist, create one
   */
  
  NSIndexSet *sectionIndexSet = nil;
  
  int sectionStart = 0;
  if ([self.items count] == 0) {
    // No section created yet, make one
    [self.items addObject:[NSMutableArray arrayWithCapacity:1]];
    sectionIndexSet = [NSIndexSet indexSetWithIndex:sectionStart];
  }
  
  /**
   ROWS
   Determine if this is a refresh/firstload or a load more
   */
  
  // Table Row Insert/Delete/Update indexPaths
  NSMutableArray *newIndexPaths = [NSMutableArray arrayWithCapacity:1];
  NSMutableArray *deleteIndexPaths = [NSMutableArray arrayWithCapacity:1];
  //  NSMutableArray *updateIndexPaths = [NSMutableArray arrayWithCapacity:1];
  
  // This is a FRESH reload
  // NOTE: THIS TABLE DOES NOT SUPPORT LOAD MORE
  
  // We should scroll the table to the top
  [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
  
  // Check to see if the first section is empty
  if ([[self.items objectAtIndex:0] count] == 0) {
    // empty section, insert
    [[self.items objectAtIndex:0] addObjectsFromArray:objects];
    for (int row = 0; row < [[self.items objectAtIndex:0] count]; row++) {
      [newIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
    }
  } else {
    // section has data, delete and reinsert
    for (int row = 0; row < [[self.items objectAtIndex:0] count]; row++) {
      [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
    }
    [[self.items objectAtIndex:0] removeAllObjects];
    // reinsert
    [[self.items objectAtIndex:0] addObjectsFromArray:objects];
    for (int row = 0; row < [[self.items objectAtIndex:0] count]; row++) {
      [newIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
    }
  }
  
  //
  // DONT ANIMATE, JUST RELOAD
  //
  [_tableView reloadData];
  
  //
  // BEGIN TABLEVIEW ANIMATION BLOCK
  // NOTE: Animating LARGE sets of data will call
  // cellForRowAtIndexPath for ALL rows
  // causing massive lag, this is a bug with UITableView
  // So for initial large sets of data, just use reloadData
  //
//  [_tableView beginUpdates];
//  
//  // These are the sections that need to be inserted
//  if (sectionIndexSet) {
//    [_tableView insertSections:sectionIndexSet withRowAnimation:UITableViewRowAnimationNone];
//  }
//  
//  // These are the rows that need to be deleted
//  if ([deleteIndexPaths count] > 0) {
//    [_tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationNone];
//  }
//  
//  // These are the new rows that need to be inserted
//  if ([newIndexPaths count] > 0) {
//    [_tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationFade];
//  }
//  
//  [_tableView endUpdates];
  //
  // END TABLEVIEW ANIMATION BLOCK
  //
  
  [self dataSourceDidLoad];
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinishWithResponse:(id)response andUserInfo:(NSDictionary *)userInfo {
  // Match place from request to current, make sure this request is still valid
  if (![[userInfo objectForKey:@"place"] isEqual:_place]) return;
  
  [self dataSourceShouldLoadObjects:[_place objectForKey:@"photos"]];
}

- (void)dataCenterDidFailWithError:(NSError *)error andUserInfo:(NSDictionary *)userInfo {
#warning need to build full screen error
  // Show a full screen error here
  [super dataSourceDidLoad];
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
    placePinView.canShowCallout = NO;
  } else {
    placePinView.annotation = annotation;
  }
  
  return placePinView;
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
