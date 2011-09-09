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
#import "ActionSheetPicker.h"

@interface RootViewController (Private)
// View Setup
- (void)setupHeader;
- (void)setupToolbar;

- (void)editingDidBegin:(UITextField *)textField;
- (void)editingDidEnd:(UITextField *)textField;

- (void)distanceSelectedWithIndex:(NSNumber *)selectedIndex inView:(UIView *)view;

@end

@implementation RootViewController

@synthesize whatQuery = _whatQuery;
@synthesize whereQuery = _whereQuery;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [[PlaceDataCenter defaultCenter] setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationAcquired) name:kLocationAcquired object:nil];
    
    _sortBy = [@"popularity" retain];
    _distance = 0.5;
    _pagingStart = 0;
    _pagingCount = 10;
    _pagingTotal = 10;
    _whatQuery = nil;
    _whereQuery = nil;
    _numResults = 0;
    
    _isSearchActive = NO;
    
    _cellCache = [[NSMutableArray alloc] init];
    _scrollCount = 0;
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_currentAddress);
  RELEASE_SAFELY(_headerView);
  RELEASE_SAFELY(_toolbar);
  RELEASE_SAFELY(_headerLabel);
  RELEASE_SAFELY(_whatField);
  RELEASE_SAFELY(_whereField);
  RELEASE_SAFELY(_whatTermController);
  RELEASE_SAFELY(_whereTermController);
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationAcquired object:nil];
  [[PlaceDataCenter defaultCenter] setDelegate:nil];
  [_whatField removeFromSuperview];
  [_whereField removeFromSuperview];
  
  RELEASE_SAFELY(_headerView);
  RELEASE_SAFELY(_toolbar);
  RELEASE_SAFELY(_headerLabel);
  RELEASE_SAFELY(_whatField);
  RELEASE_SAFELY(_whereField);
  RELEASE_SAFELY(_whatTermController);
  RELEASE_SAFELY(_whereTermController);
  
  RELEASE_SAFELY(_cellCache);
  RELEASE_SAFELY(_whatQuery);
  RELEASE_SAFELY(_whereQuery);
  RELEASE_SAFELY(_sortBy);
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
  
  [self.navigationController setNavigationBarHidden:YES animated:animated];
  
  [_cellCache makeObjectsPerformSelector:@selector(resumeAnimations)];
  
  [UIView animateWithDuration:0.4
                        delay:0.0
   
                      options:UIViewAnimationCurveEaseOut
                   animations:^{
                   }
                   completion:^(BOOL finished) {
                   }];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [_cellCache makeObjectsPerformSelector:@selector(pauseAnimations)];
  
  [_whatField resignFirstResponder];
  [_whereField resignFirstResponder];
  
  [UIView animateWithDuration:0.4
                        delay:0.0
   
                      options:UIViewAnimationCurveEaseOut
                   animations:^{
                   }
                   completion:^(BOOL finished) {
                   }];
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
//  _navTitleLabel.text = @"MealTime";
  
  [_nullView setLoadingTitle:@"Loading..." loadingSubtitle:@"Finding Restaurants" emptyTitle:@"Oh Noes" emptySubtitle:@"No Restaurants Found" image:[UIImage imageNamed:@"nullview_photos.png"]];
  
  // iAd
//  _adView = [self newAdBannerViewWithDelegate:self];
  
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
//  [self setupToolbar];
  
  // Search Term Controller
  [self setupSearchTermController];
  
  // Get initial location
  [self loadDataSource];
}

- (void)setupHeader {
  _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 60.0)];
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"bg_searchbar.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0]] autorelease];
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  bg.frame = _headerView.bounds;
  [_headerView addSubview:bg];
  
  // Search Bar
  CGFloat searchWidth = _headerView.width - 20 - 50;
  
  _whatField = [[UITextField alloc] initWithFrame:CGRectMake(10, 7, searchWidth, 30)];
  _whatField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  _whatField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _whatField.font = NORMAL_FONT;
  _whatField.delegate = self;
  _whatField.returnKeyType = UIReturnKeySearch;
  _whatField.leftViewMode = UITextFieldViewModeAlways;
  _whatField.leftView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_searchfield.png"]] autorelease];
  _whatField.borderStyle = UITextBorderStyleRoundedRect;
  _whatField.placeholder = @"What? (e.g. Pizza, Tea, Subway)";
  [_whatField addTarget:self action:@selector(searchTermChanged:) forControlEvents:UIControlEventEditingChanged];
  
  _whereField = [[UITextField alloc] initWithFrame:CGRectMake(10, 7, searchWidth, 30)];
  _whereField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  _whereField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _whereField.font = NORMAL_FONT;
  _whereField.delegate = self;
  _whereField.returnKeyType = UIReturnKeySearch;
  _whereField.leftViewMode = UITextFieldViewModeAlways;
  _whereField.leftView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_place.png"]] autorelease];
  
  UILabel *rightView = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 15)] autorelease];
  rightView.font = [PSStyleSheet fontForStyle:@"whereRightView"];
  rightView.textColor = [PSStyleSheet textColorForStyle:@"whereRightView"];
  rightView.shadowColor = [PSStyleSheet shadowColorForStyle:@"whereRightView"];
  rightView.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"whereRightView"];
  rightView.text = [NSString stringWithFormat:@"%.1f mi", _distance];
  rightView.textAlignment = UITextAlignmentRight;
  _whereField.rightViewMode = UITextFieldViewModeUnlessEditing;
  _whereField.rightView = rightView;
  _whereField.borderStyle = UITextBorderStyleRoundedRect;
  _whereField.placeholder = @"Where? (Current Location)";
  [_whereField addTarget:self action:@selector(searchTermChanged:) forControlEvents:UIControlEventEditingChanged];
  
  // Header Label
  _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, _headerView.width - 20, 16)];
  _headerLabel.backgroundColor = [UIColor clearColor];
  _headerLabel.textAlignment = UITextAlignmentCenter;
  _headerLabel.font = [PSStyleSheet fontForStyle:@"headerLabel"];
  _headerLabel.textColor = [PSStyleSheet textColorForStyle:@"headerLabel"];
  _headerLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"headerLabel"];
  _headerLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"headerLabel"];
  _headerLabel.text = @"Searching for places...";
  
  // Buttons
  _headerTopButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _headerTopButton.frame = CGRectMake(_headerView.width - 50, 7, 40, 30);
  [_headerTopButton setImage:[UIImage imageNamed:@"icon_star_gold.png"] forState:UIControlStateNormal];
  [_headerTopButton setBackgroundImage:[[UIImage imageNamed:@"navbar_normal_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal];
  [_headerTopButton setBackgroundImage:[[UIImage imageNamed:@"navbar_normal_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateHighlighted];
  [_headerTopButton addTarget:self action:@selector(saved) forControlEvents:UIControlEventTouchUpInside];
  
  _headerDistanceButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _headerDistanceButton.frame = CGRectMake(_headerView.width - 50, 7, 40, 30);
  [_headerDistanceButton setImage:[UIImage imageNamed:@"icon_distance.png"] forState:UIControlStateNormal];
  [_headerDistanceButton setBackgroundImage:[[UIImage imageNamed:@"navbar_normal_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal];
  [_headerDistanceButton setBackgroundImage:[[UIImage imageNamed:@"navbar_normal_highlighted_button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateHighlighted];
  [_headerDistanceButton addTarget:self action:@selector(distance) forControlEvents:UIControlEventTouchUpInside];
  
  [_headerView addSubview:_headerLabel];
  [_headerView addSubview:_headerDistanceButton];
  [_headerView addSubview:_headerTopButton];
  
  [_headerView addSubview:_whereField];
  [_headerView addSubview:_whatField];
  
  [self setupHeaderWithView:_headerView];
}

- (void)setupToolbar {
  _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.0)];
  NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:1];
  
  [toolbarItems addObject:[UIBarButtonItem barButtonWithTitle:@"Saved" withTarget:self action:@selector(saved) width:60 height:30 buttonType:BarButtonTypeSilver]];
  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
  
  UIView *titleView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, _toolbar.width - 60 - 60 - 40, _toolbar.height)] autorelease];
  titleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

  UIBarButtonItem *currentLocationItem = [[[UIBarButtonItem alloc] initWithCustomView:titleView] autorelease];
  [toolbarItems addObject:currentLocationItem];
  
  _filterButton = [UIBarButtonItem barButtonWithTitle:[NSString stringWithFormat:@"%.1f mi", _distance] withTarget:self action:@selector(distance) width:60 height:30 buttonType:BarButtonTypeSilver];
  
  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
  [toolbarItems addObject:_filterButton];
  
  [_toolbar setItems:toolbarItems];
  [self setupFooterWithView:_toolbar];
}

- (void)setupSearchTermController {
  _whatTermController = [[SearchTermController alloc] initWithContainer:@"what"];
  _whatTermController.delegate = self;
//  _whatTermController.view.frame = self.view.bounds;
  _whatTermController.view.frame = CGRectMake(0, 60, self.view.width, self.view.height - 60);
  _whatTermController.view.alpha = 0.0;
  [self.view insertSubview:_whatTermController.view aboveSubview:_headerView];
//  [self.view addSubview:_whatTermController.view];
  
  _whereTermController = [[SearchTermController alloc] initWithContainer:@"where"];
  _whereTermController.delegate = self;
//  _whereTermController.view.frame = self.view.bounds;
  _whereTermController.view.frame = CGRectMake(0, 60, self.view.width, self.view.height - 60)
  ;
  _whereTermController.view.alpha = 0.0;
  [self.view insertSubview:_whereTermController.view aboveSubview:_headerView];
//  [self.view addSubview:_whereTermController.view];
}

#pragma mark - Button Actios
- (void)findMyLocation {
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#findMyLocation"];
  [[PSLocationCenter defaultCenter] getMyLocation];
}

- (void)saved {
  [[[[UIAlertView alloc] initWithTitle:@"Oh Noes!" message:@"Broken for now..." delegate:nil cancelButtonTitle:@"Aww" otherButtonTitles:nil] autorelease] show];
  
//  UIActionSheet *as = [[[UIActionSheet alloc] initWithTitle:@"Sort Results" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Popularity", @"Distance", nil] autorelease];
//  as.tag = kSortActionSheet;
//  as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
//  [as showFromToolbar:_toolbar];
}

- (void)distance {
  NSArray *data = [NSArray arrayWithObjects:@"1/4 mile", @"1/2 mile", @"1 mile", @"3 miles", @"5 miles", @"10 miles", @"20 miles", nil];
  [ActionSheetPicker displayActionPickerWithView:self.view data:data selectedIndex:1 target:self action:@selector(distanceSelectedWithIndex:inView:) title:@"How Far Away?"];
}

- (void)distanceSelectedWithIndex:(NSNumber *)selectedIndex inView:(UIView *)view {
  switch ([selectedIndex integerValue]) {
    case 0:
      _distance = 0.2;
      break;
    case 1:
      _distance = 0.5;
      break;
    case 2:
      _distance = 1.0;
      break;
    case 3:
      _distance = 3.0;
      break;
    case 4:
      _distance = 5.0;
      break;
    case 5:
      _distance = 10.0;
      break;
    case 6:
      _distance = 20.0;
      break;
    default:
      _distance = 0.5;
      break;
  }
  
  // Update Distance Label
  [(UILabel *)[_whereField rightView] setText:[NSString stringWithFormat:@"%.1f mi", _distance]];
}

#pragma mark - Sort
- (void)sortResults {
  NSArray *results = [self.items objectAtIndex:0];
  NSArray *sortedResults = [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:_sortBy ascending:YES]]];
  [self.items replaceObjectAtIndex:0 withObject:sortedResults];
  [self.tableView reloadData];
}

#pragma mark - Fetching Data
- (void)fetchDataSource {
  BOOL isReload = (_pagingStart == 0) ? YES : NO;
  if (isReload) {
    NSString *where = [_whereField.text length] > 0 ? _whereField.text : @"Current Location";
    _headerLabel.text = [NSString stringWithFormat:@"Searching for places within %.1f mi of %@", _distance, where];
  }
  
#if USE_FIXTURES
  [[PlaceDataCenter defaultCenter] getPlacesFromFixtures];
#else
  [[PlaceDataCenter defaultCenter] fetchYelpPlacesForQuery:_whatQuery andAddress:_whereQuery distance:_distance start:_pagingStart rpp:_pagingCount];
#endif
}

#pragma mark - State Machine
- (BOOL)shouldLoadMore {
  return YES;
}

- (void)loadMore {
  [super loadMore];
  _pagingTotal += _pagingCount;
  _pagingStart += _pagingCount; // load another page
  
  if (_whereQuery) {
    [self fetchDataSource];
  } else {
    [self findMyLocation];
  }
}

- (void)loadDataSource {
  [super loadDataSource];
  if (_whereQuery) {
    [self fetchDataSource];
  } else {
    [self findMyLocation];
  }
}

- (void)dataSourceDidLoad {
  BOOL isReload = (_pagingStart == 0) ? YES : NO;
  
  if (isReload) {
    [super dataSourceDidLoad];
  } else {
    [super dataSourceDidLoadMore];
  }
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinishWithResponse:(id)response andUserInfo:(NSDictionary *)userInfo {
  // Check hasMore
  NSDictionary *paging = [response objectForKey:@"paging"];
  NSInteger currentPage = [[paging objectForKey:@"currentPage"] integerValue];
  NSInteger numPages = [[paging objectForKey:@"numPages"] integerValue];
  if (currentPage == numPages) {
    _hasMore = NO;
  } else {
    _hasMore = YES;
  }
  
  // Num results
  _numResults = [response objectForKey:@"numResults"] ? [[response objectForKey:@"numResults"] integerValue] : 0;
  NSString *where = [_whereField.text length] > 0 ? _whereField.text : @"Current Location";
  if (_numResults > 0) {
    _headerLabel.text = [NSString stringWithFormat:@"Found %d places within %.1f mi of %@", _numResults, _distance, where];
  } else {
    _headerLabel.text = [NSString stringWithFormat:@"Found %d places within %.1f mi of %@", _numResults, _distance, where];
  }
  
  //
  // PREPARE DATASOURCE
  //
  NSArray *places = [response objectForKey:@"places"];
  BOOL isReload = (_pagingStart == 0) ? YES : NO;
  BOOL tableViewCellShouldAnimate = isReload ? NO : YES;
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
  
  int rowStart = 0;
  if (isReload) {
    // This is a FRESH reload
    
    // We should scroll the table to the top
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    
    // Check to see if the first section is empty
    if ([[self.items objectAtIndex:0] count] == 0) {
      // empty section, insert
      [[self.items objectAtIndex:0] addObjectsFromArray:places];
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
      [[self.items objectAtIndex:0] addObjectsFromArray:places];
      for (int row = 0; row < [[self.items objectAtIndex:0] count]; row++) {
        [newIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
      }
    }
  } else {
    // This is a load more
    
    rowStart = [[self.items objectAtIndex:0] count]; // row starting offset for inserting
    [[self.items objectAtIndex:0] addObjectsFromArray:places];
    for (int row = rowStart; row < [[self.items objectAtIndex:0] count]; row++) {
      [newIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
    }
  }
  
  if (tableViewCellShouldAnimate) {
    //
    // BEGIN TABLEVIEW ANIMATION BLOCK
    //
    [_tableView beginUpdates];
    
    // These are the sections that need to be inserted
    if (sectionIndexSet) {
      [_tableView insertSections:sectionIndexSet withRowAnimation:UITableViewRowAnimationNone];
    }
    
    // These are the rows that need to be deleted
    if ([deleteIndexPaths count] > 0) {
      [_tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
    
    // These are the new rows that need to be inserted
    if ([newIndexPaths count] > 0) {
      [_tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [_tableView endUpdates];
    //
    // END TABLEVIEW ANIMATION BLOCK
    //
  } else {
    [_tableView reloadData];
  }
  
  [self dataSourceDidLoad];
}

- (void)dataCenterDidFailWithError:(NSError *)error andUserInfo:(NSDictionary *)userInfo {
  [super dataSourceDidLoad];
}

#pragma mark - Actions
- (void)locationAcquired {
  // 10330 N Wolfe Rd Cupertino, CA 95014
#if USE_FIXTURES
  
  // fetch Yelp Places
  _pagingStart = 0; // reset paging
  self.whereQuery = [_currentAddress componentsJoinedByString:@" "];
  [self fetchDataSource];
#else
  [self reverseGeocode];
#endif
}

- (void)reverseGeocode {
  if (_reverseGeocoder && _reverseGeocoder.querying) {
    return;
  } else {
    // NYC (Per Se): 40.76848, -73.98264
    // Paris: 48.86930, 2.37151
    // London (Gordon Ramsay): 51.48476, -0.16308
    // Alexanders: 37.32798, -122.01382
    // Bouchon: 38.40153, -122.36049
    CGFloat latitude = [[PSLocationCenter defaultCenter] latitude];
    CGFloat longitude = [[PSLocationCenter defaultCenter] longitude];
    
    _reverseGeocoder = [[MKReverseGeocoder alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];    
    _reverseGeocoder.delegate = self;
    [_reverseGeocoder start];
  }
}

#pragma mark - MKReverseGeocoderDelegate
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark {
  NSDictionary *address = placemark.addressDictionary;
  NSLog(@"add: %@", address);
  
  // Create some edge cases for weird stuff
  
  RELEASE_SAFELY(_currentAddress);
  _currentAddress = [[NSArray arrayWithObjects:[[address objectForKey:@"FormattedAddressLines"] objectAtIndex:0], [[address objectForKey:@"FormattedAddressLines"] objectAtIndex:1], nil] retain];
  
  [self updateCurrentLocation];
  
  _reverseGeocoder = nil;
  [geocoder release];
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
  DLog(@"Reverse Geocoding for lat: %f lng: %f FAILED!", geocoder.coordinate.latitude, geocoder.coordinate.longitude);
  
  _reverseGeocoder = nil;
  [geocoder release];
}

- (void)updateCurrentLocation {
  NSString *formattedAddress = [_currentAddress componentsJoinedByString:@" "];
  
  // fetch Yelp Places
  _pagingStart = 0; // reset paging
  self.whereQuery = formattedAddress;
  [self fetchDataSource];
}


#pragma mark - TableView
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//  return [NSString stringWithFormat:@"%d places within %.1f mile(s)", _numResults, _distance];
//}

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

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//  return [PlaceCell rowHeight];
//}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  NSMutableDictionary *place = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  [cell fillCellWithObject:place];
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

  // Reload dataSource
    _pagingStart = 0; // reset paging
  [self loadDataSource];
}

- (void)dismissSearch {
  _isSearchActive = NO;
  
  // Update Header
  [_headerTopButton setImage:[UIImage imageNamed:@"icon_star_gold.png"] forState:UIControlStateNormal];
  [_headerTopButton removeTarget:self action:@selector(dismissSearch) forControlEvents:UIControlEventTouchUpInside];
  [_headerTopButton addTarget:self action:@selector(saved) forControlEvents:UIControlEventTouchUpInside];
  
  // Animate Search Fields
  [UIView animateWithDuration:0.4
                   animations:^{
                     _headerLabel.alpha = 1.0;
                     _whatTermController.view.frame = CGRectMake(0, 60, self.view.width, self.view.height - 60);
                     _whereTermController.view.frame = CGRectMake(0, 60, self.view.width, self.view.height - 60);
                     _headerView.height = 60;
                     _whereField.top = 7;
                     _headerDistanceButton.top = 7;
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
    
    // Update Header
    [_headerTopButton setImage:[UIImage imageNamed:@"icon_cancel.png"] forState:UIControlStateNormal];
    [_headerTopButton removeTarget:self action:@selector(saved) forControlEvents:UIControlEventTouchUpInside];
    [_headerTopButton addTarget:self action:@selector(dismissSearch) forControlEvents:UIControlEventTouchUpInside];
    
    if ([textField isEqual:_whatField]) {
      [_whatTermController searchWithTerm:textField.text];
    } else {
      [_whereTermController searchWithTerm:textField.text];
    }
    
    // Animate Search Fields
    [UIView animateWithDuration:0.4
                     animations:^{
                       _headerLabel.alpha = 0.0;
                       _whatTermController.view.frame = CGRectMake(0, 80, self.view.width, self.view.height - 80);
                       _whereTermController.view.frame = CGRectMake(0, 80, self.view.width, self.view.height - 80);
                       _headerView.height = 80;
                       _whereField.top = 42;
                       _headerDistanceButton.top = 42;
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

#pragma mark - UIScrollViewDelegate
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//  [super scrollViewDidScroll:scrollView];
//  
//  if (_scrollCount == 0) {
//    _scrollCount++;
//    [_cellCache makeObjectsPerformSelector:@selector(pauseAnimations)];
//  }
//}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//  [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
//  
//  if (!decelerate && (_scrollCount == 1)) {
//    _scrollCount--;
//    [_cellCache makeObjectsPerformSelector:@selector(resumeAnimations)];
//  }
//  
//}
//
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//  [super scrollViewDidEndDecelerating:scrollView];
//  
//  if (_scrollCount == 1) {
//    _scrollCount--;
//    [_cellCache makeObjectsPerformSelector:@selector(resumeAnimations)];
//  }
//}

@end
