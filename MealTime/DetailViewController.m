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
#import "PSOverlayImageView.h"
#import "ListViewController.h"
#import "PSMailCenter.h"
#import "PSDatabaseCenter.h"

@interface DetailViewController (Private)

- (NSMutableDictionary *)loadPlaceFromDatabaseWithYid:(NSString *)yid;
- (void)deletePlaceFromDatabaseWithYid:(NSString *)yid;

- (void)setupMap;
- (void)setupToolbar;
- (void)loadDetails;
- (void)loadMap;
- (void)showMap:(UITapGestureRecognizer *)gestureRecognizer;
- (void)call;
- (void)yelp;
- (void)share;
- (void)directions;
- (void)showLists;

@end

@implementation DetailViewController

- (id)initWithPlace:(NSDictionary *)place {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _cachedTimestamp = nil;
    NSMutableDictionary *cachedPlace = [self loadPlaceFromDatabaseWithYid:[place objectForKey:@"yid"]];
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
  _mapView.delegate = nil;
  RELEASE_SAFELY(_mapView);
  RELEASE_SAFELY(_tabView);
  RELEASE_SAFELY(_hoursView);
  RELEASE_SAFELY(_addressView);
  RELEASE_SAFELY(_addressLabel);
  RELEASE_SAFELY(_hoursScrollView);
  RELEASE_SAFELY(_hoursLabel);
}

- (void)dealloc
{
  _mapView.delegate = nil;
  [[BizDataCenter defaultCenter] setDelegate:nil];
  RELEASE_SAFELY(_cachedTimestamp);
  RELEASE_SAFELY(_place);
  RELEASE_SAFELY(_imageSizeCache);
  
  RELEASE_SAFELY(_mapView);
  RELEASE_SAFELY(_tabView);
  RELEASE_SAFELY(_hoursView);
  RELEASE_SAFELY(_addressView);
  RELEASE_SAFELY(_addressLabel);
  RELEASE_SAFELY(_hoursScrollView);
  RELEASE_SAFELY(_hoursLabel);
  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  NSString *imgName = isDeviceIPad() ? @"bg_darkwood_pad.jpg" : @"bg_darkwood.jpg";
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:imgName]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  return bg;
}

- (UIView *)tableView:(UITableView *)tableView rowBackgroundViewForIndexPath:(NSIndexPath *)indexPath selected:(BOOL)selected {
  UIView *backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  backgroundView.autoresizingMask = ~UIViewAutoresizingNone;
  backgroundView.backgroundColor = selected ? CELL_SELECTED_COLOR : CELL_BACKGROUND_COLOR;
  return backgroundView;
}

#pragma mark - View
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
}

- (void)loadView
{
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  // NavBar
  _navTitleLabel.text = [_place objectForKey:@"name"];
  
  self.navigationItem.leftBarButtonItem = [UIBarButtonItem navBackButtonWithTarget:self action:@selector(back)];
  
//  self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"icon_nav_share.png"] withTarget:self action:@selector(share) width:40 height:30 buttonType:BarButtonTypeNormal];
  
  // Nullview
  NSString *img = isDeviceIPad() ? @"nullview_error_pad.png" : @"nullview_error.png";
  [_nullView setLoadingTitle:@"Loading..."];
  [_nullView setLoadingSubtitle:@"Finding photos of yummy food."];
  [_nullView setEmptyImage:[UIImage imageNamed:img]];
  [_nullView setErrorImage:[UIImage imageNamed:img]];
  [_nullView setIsFullScreen:YES];
  [_nullView setDelegate:self];
  
  // iAd
  //  _adView = [self newAdBannerViewWithDelegate:self];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  _tableView.rowHeight = self.tableView.width;
  
  // Map
  [self setupMap];
  
  // Toolbar
  [self setupToolbar];
  
  // DataSource
  if (_viewHasLoadedOnce) {
    // If this view has already been loaded once, don't reload the datasource
    [self restoreDataSource];
  } else {
    NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [_place objectForKey:@"yid"],
                                    @"yid",
                                    nil];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"detail#load" attributes:localyticsDict];
    
    [self loadDataSource];
  }
}

- (void)setupMap {  
  // Map
  CGFloat mapHeight = 0.0;
  if (isDeviceIPad()) {
    mapHeight = 360.0;
  } else {
    mapHeight = 180.0;
  }
  
  // Table Header View
  UIView *tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.width, mapHeight + 30)] autorelease];
  
  // Map
  _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, _tableView.width, mapHeight)];
  _mapView.delegate = self;
  _mapView.zoomEnabled = NO;
  _mapView.scrollEnabled = NO;
  
  [_mapView addGradientLayerWithColors:[NSArray arrayWithObjects:(id)[RGBACOLOR(0, 0, 0, 0.8) CGColor], (id)[RGBACOLOR(0, 0, 0, 0.0) CGColor], nil] andLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0], nil]];
  
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
  _addressView = [[UIView alloc] initWithFrame:CGRectMake(0, mapHeight, tableHeaderView.width, 30)];
  _addressView.backgroundColor = [UIColor clearColor];
  UIImageView *abg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_section_header.png"]] autorelease];
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
  
  // Powered by Yelp
  UIImageView *pby = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"powered_by_yelp.png"]] autorelease];
  pby.left = tableHeaderView.width - pby.width;
  [tableHeaderView addSubview:pby];
  
  // Hours
  _hoursView = [[UIView alloc] initWithFrame:CGRectZero];
  _hoursView.userInteractionEnabled = NO;
  _hoursView.frame = CGRectMake(0, 0, tableHeaderView.width, 30);
  _hoursView.backgroundColor = [UIColor clearColor];
  //  UIImageView *hbg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_caption.png"]] autorelease];
  //  hbg.frame = _hoursView.bounds;
  //  hbg.autoresizingMask = ~UIViewAutoresizingNone;
  //  [_hoursView addSubview:hbg];
  [tableHeaderView addSubview:_hoursView];
  
  // Hours
  _hoursScrollView = [[UIScrollView alloc] initWithFrame:_hoursView.bounds];
  _hoursScrollView.userInteractionEnabled = NO;
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
  CGFloat tabWidth = isDeviceIPad() ? 150 : 64;
  
  _tabView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 49.0)];
  
  UIButton *call = [UIButton buttonWithFrame:CGRectMake(0, 0, tabWidth, 49) andStyle:@"detailTab" target:self action:@selector(call)];
  [call setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_left.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [call setImage:[UIImage imageNamed:@"icon_tab_phone.png"] forState:UIControlStateNormal];
  [_tabView addSubview:call];
  
  UIButton *directions = [UIButton buttonWithFrame:CGRectMake(tabWidth, 0, tabWidth, 49) andStyle:@"detailTab" target:self action:@selector(directions)];
  [directions setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_center.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [directions setImage:[UIImage imageNamed:@"icon_tab_directions.png"] forState:UIControlStateNormal];
  [_tabView addSubview:directions];
  
  UIButton *list = [UIButton buttonWithFrame:CGRectMake((tabWidth * 2), 0, _tabView.width - (tabWidth * 4), 49) andStyle:@"detailTab" target:self action:@selector(showLists)];
  [list setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_center_selected.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [list setImage:[UIImage imageNamed:@"icon_tab_list.png"] forState:UIControlStateNormal];
  [_tabView addSubview:list];
  
  UIButton *share = [UIButton buttonWithFrame:CGRectMake(_tabView.width - (tabWidth * 2), 0, tabWidth, 49) andStyle:@"detailTab" target:self action:@selector(share)];
  [share setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_center.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [share setImage:[UIImage imageNamed:@"icon_tab_envelope.png"] forState:UIControlStateNormal];
  [_tabView addSubview:share];
  
  UIButton *yelp = [UIButton buttonWithFrame:CGRectMake(_tabView.width - tabWidth, 0, tabWidth, 49) andStyle:@"detailTab" target:self action:@selector(yelp)];
  [yelp setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_right.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [yelp setImage:[UIImage imageNamed:@"icon_tab_yelp.png"] forState:UIControlStateNormal];	
  [_tabView addSubview:yelp];
  
  
  [self setupFooterWithView:_tabView];
  _footerView.top += _footerView.height; // hide footer
}

#pragma mark - Actions
- (void)showLists {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"detail#showLists"];
  
  ListViewController *lvc = [[ListViewController alloc] initWithListMode:ListModeAdd andBiz:[_place objectForKey:@"biz"]];
  UINavigationController *lnc = [[[[NSBundle mainBundle] loadNibNamed:@"PSNavigationController" owner:self options:nil] lastObject] retain];
  lnc.viewControllers = [NSArray arrayWithObject:lvc];
  [self presentModalViewController:lnc animated:YES];
  [lvc release];
  [lnc release];
}

- (void)showMap:(UITapGestureRecognizer *)gestureRecognizer {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"detail#showMap"];
  
  MapViewController *mvc = [[MapViewController alloc] initWithPlace:_place];
  [self.navigationController pushViewController:mvc animated:YES];
  [mvc release];
}

- (void)call {
  if ([_place objectForKey:@"phone"]) {
    UIAlertView *av = [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@", [_place objectForKey:@"phone"]] message:[NSString stringWithFormat:@"Would you like to call %@?", [_place objectForKey:@"name"]] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
    av.tag = kAlertCall;
    [av show];
  } else {
    UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"No Phone Number" message:[NSString stringWithFormat:@"%@ does not have a phone number listed.", [_place objectForKey:@"name"]] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease];
    [av show];
  }
}

- (void)yelp {
  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Yelp Reviews" message:@"Want to read reviews on Yelp?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
  av.tag = kAlertYelp;
  [av show];
}

- (void)directions {
  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Driving Directions" message:[NSString stringWithFormat:@"Want to view driving directions to %@?", [_place objectForKey:@"name"]] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
  av.tag = kAlertDirections;
  [av show];
}

- (void)share {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"detail#share"];
  
  // Construct Body
  //  The Codmother Fish and Chips
  //  4.5 star rating (70 reviews)
  //  Category: Fish & Chips
  //  Fisherman's Wharf
  //  2824 Jones St (Map)
  //  (b/t Beach St & Jefferson St)
  //  San Francisco, CA
  //  (415) 606-9349
  //  2.25 miles
  //  Price: $
  NSMutableString *body = [NSMutableString string];

  [body appendFormat:@"<a href=\"http://www.yelp.com/biz/%@\">%@</a><br/>", [_place objectForKey:@"yid"], [_place objectForKey:@"name"]];
  if ([_place objectForKey:@"address"]) [body appendFormat:@"%@<br/>", [_place objectForKey:@"address"]];
  if ([_place objectForKey:@"city"] && [_place objectForKey:@"state_code"] && [_place objectForKey:@"postal_code"]) [body appendFormat:@"%@, %@ %@<br/>", [_place objectForKey:@"city"], [_place objectForKey:@"state_code"], [_place objectForKey:@"postal_code"]];
  if ([_place objectForKey:@"phone"]) [body appendFormat:@"%@<br/>", [_place objectForKey:@"phone"]];
  [body appendFormat:@"Rating: %@", [_place objectForKey:@"rating"]];
  [[PSMailCenter defaultCenter] controller:self sendMailTo:nil withSubject:[NSString stringWithFormat:@"MealTime: %@", [_place objectForKey:@"name"]] andMessageBody:body];
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
  
  if ([_place objectForKey:@"formatted_address"]) {
    _addressLabel.text = [_place objectForKey:@"formatted_address"];
  } else {
    _addressLabel.text = @"No address listed";
  }
}

- (void)loadDetails {  
  if ([_place objectForKey:@"hours"] && [[_place objectForKey:@"hours"] count] > 0) {
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

- (NSMutableDictionary *)loadPlaceFromDatabaseWithYid:(NSString *)yid {
  EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"SELECT * FROM places WHERE yid = ?", yid, nil];
  
  if ([res count] > 0) {
    _cachedTimestamp = [[NSDate dateWithTimeIntervalSince1970:[[[res rows] lastObject] doubleForColumn:@"timestamp"]] retain];
    NSData *placeData = [[[res rows] lastObject] dataForColumn:@"data"];
    return [NSKeyedUnarchiver unarchiveObjectWithData:placeData];
  } else {
    return nil;
  }
}

- (void)deletePlaceFromDatabaseWithYid:(NSString *)yid {
    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"DELETE FROM places WHERE yid = ?", yid, nil];
}

#pragma mark - State Machine
- (BOOL)shouldLoadMore {
  return NO;
}

- (void)restoreDataSource {
  [super restoreDataSource];
  
  [self loadDetails];
  [self loadMap];
  
  _tableView.tableHeaderView.alpha = 1.0; // Show header now
}

- (void)reloadDataSource {
  [super reloadDataSource];
  [self loadDataSource];
}

- (void)loadDataSource {
  [super loadDataSource];
  
  [self loadMap];
  
  // Combined call
  if (!_isCachedPlace) {
    [[BizDataCenter defaultCenter] fetchBusinessForYid:[_place objectForKey:@"yid"]];
    [[BizDataCenter defaultCenter] fetchPhotosForBiz:[_place objectForKey:@"biz"]];
  } else {
    if (_cachedTimestamp && [[NSDate date] timeIntervalSinceDate:_cachedTimestamp] > WEEK_SECONDS) {
      [[BizDataCenter defaultCenter] fetchBusinessForYid:[_place objectForKey:@"yid"]];
      [[BizDataCenter defaultCenter] fetchPhotosForBiz:[_place objectForKey:@"biz"]];
    }
    
    NSArray *photos = [_place objectForKey:@"photos"];
    
    if (photos && [photos count] > 0) {
      [self dataSourceShouldLoadObjects:[NSMutableArray arrayWithObject:photos] shouldAnimate:NO];
    } else {
//      _isCachedPlace = NO;
//      [self deletePlaceFromDatabaseWithYid:[_place objectForKey:@"yid"]];
      _cachedTimestamp = [[NSDate distantFuture] retain];
      [self dataSourceDidError];
    }
  }
  
  // Get ALL reviews for this place
  // Only do this once, so check userDefaults
//  if (![[NSUserDefaults standardUserDefaults] boolForKey:[_place objectForKey:@"alias"]]) {
//    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[_place objectForKey:@"alias"]];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    
//    NSInteger numReviews = [[_place objectForKey:@"numReviews"] notNil] ? [[_place objectForKey:@"numReviews"] integerValue] : 0;
//    int i = 0;
//    for (i = 0; i < numReviews; i = i + 400) {
//      // Fire off requests for reviews 400 at a time
//      [[BizDataCenter defaultCenter] fetchReviewsForAlias:[_place objectForKey:@"alias"] start:i rpp:400];
//    }
//  }
}

- (void)dataSourceDidLoad {  
//  // NUX
//  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownDetailOverlay"]) {
//    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownDetailOverlay"];
//    NSString *imgName = isDeviceIPad() ? @"nux_overlay_detail_pad.png" : @"nux_overlay_detail.png";
//    PSOverlayImageView *nuxView = [[[PSOverlayImageView alloc] initWithImage:[UIImage imageNamed:imgName]] autorelease];
//    nuxView.alpha = 0.0;
//    [[UIApplication sharedApplication].keyWindow addSubview:nuxView];
//    [UIView animateWithDuration:0.4 animations:^{
//      nuxView.alpha = 1.0;
//    }];
//  }
  
  _tableView.tableHeaderView.alpha = 1.0; // Show header now
  
  [UIView animateWithDuration:0.4 animations:^{
    _footerView.top -= _footerView.height;
  }];
  
  // Store into SQLite
  NSNumber *timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
  NSData *placeData = [NSKeyedArchiver archivedDataWithRootObject:_place];
  [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"INSERT OR REPLACE INTO places (yid, biz, data, latitude, longitude, rating, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)" parameters:[NSArray arrayWithObjects:[_place objectForKey:@"yid"], [_place objectForKey:@"biz"], placeData, [_place objectForKey:@"latitude"], [_place objectForKey:@"longitude"], [_place objectForKey:@"rating"], timestamp, nil]];
  
  [super dataSourceDidLoad];
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinishWithResponse:(id)response andUserInfo:(NSDictionary *)userInfo {
  // Match place from request to current, make sure this request is still valid
  
  NSString *requestType = [userInfo objectForKey:@"requestType"];
  
  if ([requestType isEqualToString:@"photos"]) {
    NSArray *photos = [response objectForKey:@"photos"];
    if (photos && [photos count] > 0) {
      [_place setObject:photos forKey:@"photos"];
      
      [self dataSourceShouldLoadObjects:[NSMutableArray arrayWithObject:photos] shouldAnimate:NO];
    } else {
      [self dataSourceDidError];
    }
  } else if ([requestType isEqualToString:@"business"]) {
    // Load details of business
    if ([response objectForKey:@"phone"]) {
      [_place setObject:[response objectForKey:@"phone"] forKey:@"phone"];
    }
  }
}

- (void)dataCenterDidFailWithError:(NSError *)error andUserInfo:(NSDictionary *)userInfo {
  [self dataSourceDidError];
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
  NSDictionary *object = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  [cell fillCellWithObject:object];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ProductCell *cell = nil;
  NSString *reuseIdentifier = [ProductCell reuseIdentifier];
  
  cell = (ProductCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[ProductCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  ProductCell *cell = (ProductCell *)[tableView cellForRowAtIndexPath:indexPath];
  
  NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [_place objectForKey:@"biz"],
                                  @"biz",
                                  nil];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"detail#zoom" attributes:localyticsDict];
  
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

#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == alertView.cancelButtonIndex) return;
  
  if (alertView.tag == kAlertCall) {
    NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [_place objectForKey:@"biz"],
                                    @"biz",
                                    [_place objectForKey:@"phone"],
                                    @"phone",
                                    nil];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"detail#call" attributes:localyticsDict];
    
//    NSString *phoneNumber = [[[_place objectForKey:@"phone"] componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
//    NSString *telString = [NSString stringWithFormat:@"tel:%@", phoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[_place objectForKey:@"phone"]]];
  } else if (alertView.tag == kAlertYelp) {
    NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [_place objectForKey:@"biz"],
                                    @"biz",
                                    nil];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"detail#yelp" attributes:localyticsDict];

    // Always load Yelp's mobile site
    WebViewController *wvc = [[WebViewController alloc] initWithURLString:[NSString stringWithFormat:@"http://m.yelp.com/biz/%@", [_place objectForKey:@"yid"]]];
    [self.navigationController pushViewController:wvc animated:YES];
    [wvc release];
    
//    if (isYelpInstalled()) {
//      // yelp:///biz/the-sentinel-san-francisco
//      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"yelp:///biz/%@", [_place objectForKey:@"biz"]]]];
//    } else {
//      WebViewController *wvc = [[WebViewController alloc] initWithURLString:[NSString stringWithFormat:@"http://m.yelp.com/biz/%@", [_place objectForKey:@"biz"]]];
//      [self.navigationController pushViewController:wvc animated:YES];
//      [wvc release];
//    }
  } else if (alertView.tag == kAlertDirections) {
    NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [_place objectForKey:@"biz"],
                                    @"biz",
                                    [_place objectForKey:@"formatted_address"],
                                    @"formatted_address",
                                    nil];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"detail#directions" attributes:localyticsDict];
    
    CLLocationCoordinate2D currentLocation = [[PSLocationCenter defaultCenter] locationCoordinate];
    NSString *address = [_place objectForKey:@"formatted_address"];
    NSString *mapsUrl = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%@", currentLocation.latitude, currentLocation.longitude, [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapsUrl]];
  }
}

@end
