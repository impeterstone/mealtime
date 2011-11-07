//
//  RootViewController.m
//  MealTime
//
//  Created by Peter Shih on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"
#import "PlaceCell.h"
#import "PlaceDataCenter.h"
#import "DetailViewController.h"
#import "SearchTermController.h"
#import "PSLocationCenter.h"
#import "PSSearchCenter.h"
#import "ListViewController.h"
#import "InfoViewController.h"
#import "PSSearchField.h"
#import "PSReachabilityCenter.h"

@interface RootViewController (Private)
// View Setup
- (void)setupSearchTermController;
- (void)setupHeader;
- (void)setupToolbar;

// Actions
- (void)showLists;
- (void)showInfo;
- (void)centerAction;

// Utility
- (void)findMyLocation;
- (void)updateNumResults;

// Search
- (void)editingDidBegin:(UITextField *)textField;
- (void)editingDidEnd:(UITextField *)textField;
- (void)searchTermChanged:(UITextField *)textField;

// Notifications
- (void)locationAcquired:(NSNotification *)notification;

@end

@implementation RootViewController

@synthesize whatQuery = _whatQuery;
@synthesize whereQuery = _whereQuery;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [[PlaceDataCenter defaultCenter] setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationAcquired:) name:kLocationAcquired object:nil];
    
    _location = nil;
    
    // Search Variables
    _whatQuery = nil;
    _whereQuery = nil;
    _radiusFilter = 2; // 2 mi
    
    // Paging
    _pagingStart = 0;
    _pagingCount = 20;
    _pagingTotal = 20;
    _numResults = 0;
    _numShowing = 0;
    
    _isSearchActive = NO;
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  
  _whatField.delegate = nil;
  _whereField.delegate = nil;
  _whatTermController.delegate = nil;
  _whereTermController.delegate = nil;
  
  RELEASE_SAFELY(_headerView);
  RELEASE_SAFELY(_tabView);
  RELEASE_SAFELY(_centerButton);
  RELEASE_SAFELY(_whatField);
  RELEASE_SAFELY(_whereField);
  RELEASE_SAFELY(_radiusControl);
  RELEASE_SAFELY(_whatTermController);
  RELEASE_SAFELY(_whereTermController);
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationAcquired object:nil];
  [[PlaceDataCenter defaultCenter] setDelegate:nil];
  [_whatField removeFromSuperview];
  [_whereField removeFromSuperview];
  
  _whatField.delegate = nil;
  _whereField.delegate = nil;
  _whatTermController.delegate = nil;
  _whereTermController.delegate = nil;
  
  RELEASE_SAFELY(_location);
  RELEASE_SAFELY(_headerView);
  RELEASE_SAFELY(_tabView);
  RELEASE_SAFELY(_centerButton);
  RELEASE_SAFELY(_whatField);
  RELEASE_SAFELY(_whereField);
  RELEASE_SAFELY(_radiusControl);
  RELEASE_SAFELY(_whatTermController);
  RELEASE_SAFELY(_whereTermController);
  
  RELEASE_SAFELY(_whatQuery);
  RELEASE_SAFELY(_whereQuery);
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
  
  [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  if ([_whatField isFirstResponder]) {
    [_whatField resignFirstResponder];
  } else if ([_whereField isFirstResponder]) {
    [_whereField resignFirstResponder];
  }
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  // Nullview
  NSString *imgError = isDeviceIPad() ? @"nullview_error_pad.png" : @"nullview_error.png";
  NSString *imgEmpty = isDeviceIPad() ? @"nullview_noresults_pad.png" : @"nullview_noresults.png";
  [_nullView setLoadingTitle:@"Loading..."];
  [_nullView setLoadingSubtitle:@"Finding places for you"];
  [_nullView setEmptyImage:[UIImage imageNamed:imgEmpty]];
  [_nullView setErrorImage:[UIImage imageNamed:imgError]];
  [_nullView setIsFullScreen:YES];
  [_nullView setDelegate:self];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  if (isDeviceIPad()) {
    _tableView.rowHeight = 320.0;
  } else {
    _tableView.rowHeight = 160.0;
  }
  
  // Setup Header
  [self setupHeader];
  
  // Setup Toolbar
  [self setupToolbar];
  
  // Search Term Controller
  [self setupSearchTermController];
  
  // DataSource
  if (_viewHasLoadedOnce) {
    // If this view has already been loaded once, don't reload the datasource
    [self restoreDataSource];
  } else {
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#load"];
    [self findMyLocation];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

#pragma mark - View Setup
- (void)setupHeader {
  _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.0)];
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"bg_navbar.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]] autorelease];
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  bg.frame = _headerView.bounds;
  [_headerView addSubview:bg];
  
  // Search Bar
  CGFloat searchWidth = _headerView.width - 20;
  
  // WHAT
  _whatField = [[PSSearchField alloc] initWithFrame:CGRectMake(10, 7, searchWidth, 30)];
  //  _whatField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _whatField.delegate = self;
  _whatField.autocorrectionType = UITextAutocorrectionTypeNo;
  _whatField.placeholder = @"Find: e.g. pizza, Tony's Burgers";
  [_whatField addTarget:self action:@selector(searchTermChanged:) forControlEvents:UIControlEventEditingChanged];
  _whatField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _whatField.leftViewMode = UITextFieldViewModeAlways;
  UIImageView *mag = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_magnifier.png"]] autorelease];
  mag.contentMode = UIViewContentModeCenter;
  _whatField.leftView = mag;
  
  // WHERE
  _whereField = [[PSSearchField alloc] initWithFrame:CGRectMake(10, 7, searchWidth, 30)];
  _whereField.delegate = self;
  _whereField.autocorrectionType = UITextAutocorrectionTypeNo;
  _whereField.placeholder = @"Current Location";
  [_whereField addTarget:self action:@selector(searchTermChanged:) forControlEvents:UIControlEventEditingChanged];
  _whereField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _whereField.leftViewMode = UITextFieldViewModeAlways;
  UIImageView *where = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_where.png"]] autorelease];
  where.contentMode = UIViewContentModeCenter;
  _whereField.leftView = where;
  
  // RADIUS FILTER
  _radiusControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"1/2 mi", @"1 mi", @"2 mi", @"5 mi", nil]];
  _radiusControl.segmentedControlStyle = UISegmentedControlStyleBordered;
  _radiusControl.selectedSegmentIndex = _radiusFilter;
  _radiusControl.frame = CGRectMake(20, 7, searchWidth - 20, 30);
  
  [_headerView addSubview:_radiusControl];
  [_headerView addSubview:_whereField];
  [_headerView addSubview:_whatField];
  
  [self setupHeaderWithView:_headerView];
}

- (void)setupToolbar {
  CGFloat tabWidth = isDeviceIPad() ? 100 : 50;
  
  _tabView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 49.0)];
  
  // Left: List
  UIButton *list = [UIButton buttonWithFrame:CGRectMake(0, 0, tabWidth, 49) andStyle:@"detailTab" target:self action:@selector(showLists)];
  [list setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_left.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [list setImage:[UIImage imageNamed:@"icon_tab_list.png"] forState:UIControlStateNormal];
  [_tabView addSubview:list];
  
  // Center: Message
  _centerButton = [[UIButton buttonWithFrame:CGRectMake(tabWidth, 0, _tabView.width - (tabWidth * 2), 49) andStyle:@"filterButton" target:self action:@selector(centerAction)] retain];
  [_centerButton setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_center_selected.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
//  [_centerButton setImage:[UIImage imageNamed:@"powered_by_yelp.png"] forState:UIControlStateNormal];
  [_centerButton setTitle:@"Determining Your Location" forState:UIControlStateNormal];
//  _centerButton.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
//  _centerButton.titleLabel.textAlignment = UITextAlignmentCenter;
//  _centerButton.titleLabel.numberOfLines = 2;
  [_tabView addSubview:_centerButton];
  
  // Right: Info
  UIButton *info = [UIButton buttonWithFrame:CGRectMake(_tabView.width - tabWidth, 0, tabWidth, 49) andStyle:@"detailTab" target:self action:@selector(showInfo)];
  [info setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_right.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [info setImage:[UIImage imageNamed:@"icon_tab_info.png"] forState:UIControlStateNormal];
  [_tabView addSubview:info];
  
  [self setupFooterWithView:_tabView];
}

- (void)setupSearchTermController {
  _whatTermController = [[SearchTermController alloc] initWithContainer:@"what"];
  _whatTermController.delegate = self;
  //  _whatTermController.view.frame = self.view.bounds;
  _whatTermController.view.frame = CGRectMake(0, 44, self.view.width, self.view.height - 44);
  _whatTermController.view.alpha = 0.0;
  [self.view insertSubview:_whatTermController.view aboveSubview:_headerView];
  //  [self.view addSubview:_whatTermController.view];
  
  _whereTermController = [[SearchTermController alloc] initWithContainer:@"where"];
  _whereTermController.delegate = self;
//  _whereTermController.view.frame = self.view.bounds;
  _whereTermController.view.frame = CGRectMake(0, 44, self.view.width, self.view.height - 44)
  ;
  _whereTermController.view.alpha = 0.0;
  [self.view insertSubview:_whereTermController.view aboveSubview:_headerView];
//  [self.view addSubview:_whereTermController.view];
}

#pragma mark - Utility Methods
- (void)findMyLocation {
  if ([[PSReachabilityCenter defaultCenter] isNetworkReachable]) {
    [[PSLocationCenter defaultCenter] getMyLocation];
  } else {
    [self dataCenterDidFailWithError:nil andUserInfo:nil];
  }
}

- (void)updateNumResults {
  NSString *distanceTitle = nil;
  if (_numShowing > 0) {
    distanceTitle = [NSString stringWithFormat:@"Showing %d Places", _numShowing];
  } else {
    distanceTitle = [NSString stringWithFormat:@"No Places Found"];
  }
  [_centerButton setTitle:distanceTitle forState:UIControlStateNormal];
}

#pragma mark - Actions
- (void)showLists {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#showLists"];
  
  ListViewController *lvc = [[ListViewController alloc] initWithListMode:ListModeView];
  UINavigationController *lnc = [[[[NSBundle mainBundle] loadNibNamed:@"PSNavigationController" owner:self options:nil] lastObject] retain];
  lnc.viewControllers = [NSArray arrayWithObject:lvc];
  [self presentModalViewController:lnc animated:YES];
  [lvc release];
  [lnc release];
}

- (void)showInfo {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#info"];
  
  InfoViewController *ivc = [[InfoViewController alloc] initWithNibName:nil bundle:nil];
  UINavigationController *inc = [[[[NSBundle mainBundle] loadNibNamed:@"PSNavigationController" owner:self options:nil] lastObject] retain];
  inc.viewControllers = [NSArray arrayWithObject:ivc];
  inc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentModalViewController:inc animated:YES];
  [ivc release];
  [inc release];
}

- (void)centerAction {
  // Nothing for now
}

#pragma mark - Fetching Data
- (void)fetchDataSource {
  [[PlaceDataCenter defaultCenter] cancelRequests];
  
  BOOL isReload = (_pagingStart == 0);
  
  if (isReload) {
    // Update distance button label
    [_centerButton setTitle:[NSString stringWithFormat:@"Searching for Places"] forState:UIControlStateNormal];
    
    // Update location param
    _location = self.whereQuery ? [[NSString stringWithFormat:@"location=%@", [self.whereQuery stringByURLEncoding]] retain] : [[NSString stringWithFormat:@"ll=%f,%f", [[PSLocationCenter defaultCenter] latitude], [[PSLocationCenter defaultCenter] longitude], [[PSLocationCenter defaultCenter] accuracy]] retain];
  }
  
  // Configure Radius Filter
  // 1608m/mi
  // 8046 - 5mi
  // 4828 - 3mi
  // 3218 - 2mi
  NSInteger radius = 3218; // in meters
  switch (_radiusControl.selectedSegmentIndex) {
    case 0: // 0.5
      radius = 804;
      break;
    case 1: // 1.0
      radius = 1609;
      break;
    case 2: // 2.0
      radius = 3218;
      break;
    case 3: // 5.0
      radius = 8046;
      break;
    default: // 2.0
      radius = 3218;
      break;
  }
  
  // Localytics
  NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  self.whatQuery ? self.whatQuery : @"",
                                  @"what",
                                  self.whereQuery ? self.whereQuery : @"",
                                  @"where",
                                  _location,
                                  @"location",
                                  [NSNumber numberWithInteger:radius],
                                  @"radius",
                                  nil];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#fetch" attributes:localyticsDict];

  // Perform the fetch
  [[PlaceDataCenter defaultCenter] fetchPlacesForQuery:_whatQuery location:_location radius:radius offset:_pagingStart limit:_pagingCount];
}

#pragma mark - State Machine
- (BOOL)shouldLoadMore {
  return YES;
}

- (void)loadMore {
  [super loadMore];
  _pagingStart += _pagingCount;
  _pagingTotal += _pagingCount;
  [self fetchDataSource];
}

- (void)restoreDataSource {
  [super restoreDataSource];
  
  [self updateNumResults];
  _whatField.text = _whatQuery;
  _whereField.text = _whereQuery;
}

- (void)reloadDataSource {
  [super reloadDataSource];
  [self loadDataSource];
}

- (void)loadDataSource {
  BOOL isReload = (_pagingStart == 0);
  if (isReload) {
    _hasMore = NO;
    [self.items removeAllObjects];
    [self.tableView reloadData];
  }
  
  [super loadDataSource];
  [self fetchDataSource];
}

- (void)dataSourceDidLoad {
  BOOL isReload = YES;
  
  if (isReload) {
    [super dataSourceDidLoad];
  } else {
    [super dataSourceDidLoadMore];
  }
}

- (void)dataSourceDidLoadMore {
  [super dataSourceDidLoadMore];
}


#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinishWithResponse:(id)response andUserInfo:(NSDictionary *)userInfo {
  // Num showing
  _numShowing = [response objectForKey:@"showing"] ? [[response objectForKey:@"showing"] integerValue] : 0;
  
  // Num results
  _numResults = [response objectForKey:@"total"] ? [[response objectForKey:@"total"] integerValue] : 0;
  [self updateNumResults];
  DLog(@"Yelp got %d results, %d showing", _numResults, _numShowing);
  
  // Check hasMore
  if (_numResults > _pagingTotal) {
    _hasMore = YES;
  } else {
    _hasMore = NO;
  }
  
  // Make places mutable
  NSMutableArray *places = [NSMutableArray arrayWithArray:[response objectForKey:@"places"]];
  
  if (places && [places count] > 0) {
    BOOL isReload = (_pagingStart == 0);
    if (isReload) {
      [self dataSourceShouldLoadObjects:[NSMutableArray arrayWithObject:places] shouldAnimate:NO];
    } else {
      [self dataSourceShouldLoadMoreObjects:places forSection:0 shouldAnimate:YES];
    }
  } else {
    [_centerButton setTitle:@"GPS/Network Error" forState:UIControlStateNormal];
    [self dataSourceDidError];
  }
  
}

- (void)dataCenterDidFailWithError:(NSError *)error andUserInfo:(NSDictionary *)userInfo {
  [_centerButton setTitle:@"GPS/Network Error" forState:UIControlStateNormal];
  [self dataSourceDidError];
}

#pragma mark - Actions
- (void)locationAcquired:(NSNotification *)notification {
  [self loadDataSource];
}

#pragma mark - TableView
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//  return [NSString stringWithFormat:@"Showing %d Places", _numShowing];
//}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.width, 23)] autorelease];
  headerView.autoresizingMask = ~UIViewAutoresizingNone;
  headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_section_header.png"]];
  
  UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(MARGIN_X, 0, headerView.width - MARGIN_X * 2, headerView.height)] autorelease];
  headerLabel.backgroundColor = [UIColor clearColor];
  headerLabel.text = [NSString stringWithFormat:@"Showing %d Results from Yelp", _numShowing];
  headerLabel.font = [PSStyleSheet fontForStyle:@"rootSectionHeader"];
  headerLabel.textColor = [PSStyleSheet textColorForStyle:@"rootSectionHeader"];
  headerLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"rootSectionHeader"];
  headerLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"rootSectionHeader"];
  [headerView addSubview:headerLabel];
  
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 23.0;
}

// Setting table cell height instead
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//  return [PlaceCell rowHeight];
//}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  NSMutableDictionary *object = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  [cell fillCellWithObject:object];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  PlaceCell *cell = nil;
  NSString *reuseIdentifier = [PlaceCell reuseIdentifier];
  
  cell = (PlaceCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[PlaceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
    [_cellCache addObject:cell];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSMutableDictionary *place = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  DetailViewController *dvc = [[DetailViewController alloc] initWithPlace:place];
  [self.navigationController pushViewController:dvc animated:YES];
  [dvc release];
}

#pragma mark - Search
- (void)searchTermChanged:(UITextField *)textField {
  if ([textField isEqual:_whatField]) {
    [_whatTermController searchWithTerm:textField.text];
  } else {
    [_whereTermController searchWithTerm:textField.text];
  }
}

- (void)executeSearch {
  // Determine if this is a search around current location or a specific city  
  if ([_whereField.text length] > 0) {
    // Searching a Specific Location
  } else {
    // Searching Current Location
  }
  
  // Hide the search UI
  [self dismissSearch];
  
  // What
  if ([_whatField.text length] > 0) {
    // Store search term
    [[PSSearchCenter defaultCenter] addTerm:_whatField.text inContainer:@"what"];
    
    self.whatQuery = _whatField.text;
  } else {
    self.whatQuery = nil;
  }
  
  // Where
  if ([_whereField.text isEqualToString:@"Current Location"]) {
    // Current Location
    self.whereQuery = nil;
  } else if ([_whereField.text length] > 0) {
    // Store search term
    [[PSSearchCenter defaultCenter] addTerm:_whereField.text inContainer:@"where"];
    
    self.whereQuery = _whereField.text;;
  } else {
    // Current Location
    self.whereQuery = nil;
  }
  
  NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  self.whatQuery ? self.whatQuery : @"",
                                  @"what",
                                  self.whereQuery ? self.whereQuery : @"",
                                  @"where",
                                  nil];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#search" attributes:localyticsDict];

  // Reset paging and Reload dataSource
  [self resetPaging];
  [self loadDataSource];
}

- (void)dismissSearch {
  _isSearchActive = NO;
  
  // Animate Search Fields
  [UIView animateWithDuration:0.4
                   animations:^{
                     _whatTermController.view.frame = CGRectMake(0, 44, self.view.width, self.view.height - 44);
                     _whereTermController.view.frame = CGRectMake(0, 44, self.view.width, self.view.height - 44);
                     _headerView.height = 44;
                     _nullView.hidden = NO;
                     _whereField.top = 7;
                     _radiusControl.top = 7;
                   }
                   completion:^(BOOL finished) {
                   }];
  
  [_whatField resignFirstResponder];
  [_whereField resignFirstResponder];
}

#pragma mark - SearchTermDelegate
- (void)searchTermSelected:(NSString *)searchTerm inContainer:(NSString *)container {
  if ([container isEqualToString:@"what"]) {
    _whatField.text = searchTerm;
  } else {
    _whereField.text = searchTerm;
  }
}

- (void)searchCancelled {
  _whatField.text = _whatQuery;
  _whereField.text = _whereQuery;
  [self dismissSearch];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  if (!_isSearchActive) {
    _isSearchActive = YES;
    
    if ([textField isEqual:_whatField]) {
      [_whatTermController searchWithTerm:textField.text];
    } else {
      [_whereTermController searchWithTerm:textField.text];
    }
    
    // Animate Search Fields
    [UIView animateWithDuration:0.4
                     animations:^{
                       _whatTermController.view.frame = CGRectMake(0, 116, self.view.width, self.view.height - 116);
                       _whereTermController.view.frame = CGRectMake(0, 116, self.view.width, self.view.height - 116);
                       _headerView.height = 116;
                       _nullView.hidden = YES;
                       _whereField.top = 42;
                       _radiusControl.top = 79;
                     }
                     completion:^(BOOL finished) {
                     }];
  }
  
  if ([textField isEqual:_whatField]) {
    [self.view bringSubviewToFront:_whatTermController.view];
    _whatTermController.view.alpha = 1.0;
  } else {
    [self.view bringSubviewToFront:_whereTermController.view];
    _whereTermController.view.alpha = 1.0;
  }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  if ([textField isEqual:_whatField]) {
    _whatTermController.view.alpha = 0.0;
  } else {
    _whereTermController.view.alpha = 0.0;
  }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  if (![textField isEditing]) {
    [textField becomeFirstResponder];
  }
  
  [self executeSearch];
  
  return YES;
}

@end
