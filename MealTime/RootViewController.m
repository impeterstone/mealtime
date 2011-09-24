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
#import "ListViewController.h"
#import "InfoViewController.h"
#import "PSSearchField.h"
#import "PSOverlayImageView.h"

@interface RootViewController (Private)
// View Setup
- (void)setupHeader;
- (void)setupToolbar;

- (void)updateNumResults;

- (void)editingDidBegin:(UITextField *)textField;
- (void)editingDidEnd:(UITextField *)textField;

- (void)distanceSelectedWithIndex:(NSNumber *)selectedIndex inView:(UIView *)view;

- (void)changeDistance;
- (void)showLists;
- (void)showInfo;
- (void)searchNearby;
- (void)sortResults;

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
    
    _sortBy = [@"popularity" retain];
    _pagingStart = 0;
    _pagingCount = 10;
    _pagingTotal = 10;
    _whatQuery = nil;
    _whereQuery = nil;
    _numResults = 0;
    
    _isSearchActive = NO;
    
    _scrollCount = 0;
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_currentAddress);
  RELEASE_SAFELY(_headerView);
  RELEASE_SAFELY(_tabView);
  RELEASE_SAFELY(_distanceButton);
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
  RELEASE_SAFELY(_tabView);
  RELEASE_SAFELY(_distanceButton);
  RELEASE_SAFELY(_whatField);
  RELEASE_SAFELY(_whereField);
  RELEASE_SAFELY(_whatTermController);
  RELEASE_SAFELY(_whereTermController);
  
  RELEASE_SAFELY(_whatQuery);
  RELEASE_SAFELY(_whereQuery);
  RELEASE_SAFELY(_sortBy);
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
  
  // NUX
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownRootOverlay"]) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownRootOverlay"];
    NSString *imgName = isDeviceIPad() ? @"nux_overlay_root_pad.png" : @"nux_overlay_root.png";
    PSOverlayImageView *nuxView = [[[PSOverlayImageView alloc] initWithImage:[UIImage imageNamed:imgName]] autorelease];
    nuxView.alpha = 0.0;
    [[UIApplication sharedApplication].keyWindow addSubview:nuxView];
    [UIView animateWithDuration:0.4 animations:^{
      nuxView.alpha = 1.0;
    }];
  }
  
  [_cellCache makeObjectsPerformSelector:@selector(resumeAnimations)];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [_cellCache makeObjectsPerformSelector:@selector(pauseAnimations)];
  
  [_whatField resignFirstResponder];
  [_whereField resignFirstResponder];

}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  // Nullview
  [_nullView setLoadingTitle:@"Loading..."];
  [_nullView setLoadingSubtitle:@"Finding places for you"];
  [_nullView setEmptyTitle:@"No Places Found"];
  [_nullView setEmptySubtitle:@"Try increasing the search distance or try your search again."];
  [_nullView setErrorTitle:@"Something Bad Happened"];
  [_nullView setErrorSubtitle:@"Hmm... Something didn't work.\nIt might be the network connection.\nTrying again might fix it."];
  [_nullView setEmptyImage:[UIImage imageNamed:@"nullview_empty.png"]];
  [_nullView setErrorImage:[UIImage imageNamed:@"nullview_error.png"]];
  
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
  [self setupToolbar];
  
  // Search Term Controller
  [self setupSearchTermController];
  
  // DataSource
  if (_viewHasLoadedOnce) {
    // If this view has already been loaded once, don't reload the datasource
    [self restoreDataSource];
  } else {
    NSError *error;
    [[GANTracker sharedTracker] trackPageview:@"/root" withError:&error];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#load"];
    [self loadDataSource];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)setupHeader {
  _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.0)];
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"bg_navbar.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]] autorelease];
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  bg.frame = _headerView.bounds;
  [_headerView addSubview:bg];
  
  // Input Toolbar
//  UIToolbar *tb = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)] autorelease];
//  NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:1];
//  [toolbarItems addObject:[UIBarButtonItem barButtonWithTitle:@"Cancel" withTarget:self action:@selector(dismissSearch) width:60 height:30 buttonType:BarButtonTypeNormal]];
//  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
//  // Status Label
//  _distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tb.width - 80, tb.height)];
//  _distanceLabel.backgroundColor = [UIColor clearColor];
//  _distanceLabel.textAlignment = UITextAlignmentCenter;
//  _distanceLabel.font = [PSStyleSheet fontForStyle:@"distanceLabel"];
//  _distanceLabel.textColor = [PSStyleSheet textColorForStyle:@"distanceLabel"];
//  _distanceLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"distanceLabel"];
//  _distanceLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"distanceLabel"];
//  _distanceLabel.text = [NSString stringWithFormat:@"Range: %.1f miles", _distance];
//  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithCustomView:_distanceLabel] autorelease]];
//  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
//  [toolbarItems addObject:[UIBarButtonItem barButtonWithTitle:@"Range" withTarget:self action:@selector(distance) width:60 height:30 buttonType:BarButtonTypeBlue]];
//  [tb setItems:toolbarItems];
  
  // Search Bar
  CGFloat searchWidth = _headerView.width - 20;
  
  _whatField = [[PSSearchField alloc] initWithFrame:CGRectMake(10, 7, searchWidth, 30)];
//  _whatField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _whatField.delegate = self;
  _whatField.autocorrectionType = UITextAutocorrectionTypeNo;
  _whatField.placeholder = @"What? (e.g. Pizza, Subway)";
  [_whatField addTarget:self action:@selector(searchTermChanged:) forControlEvents:UIControlEventEditingChanged];
  
//  _whatField.inputAccessoryView = tb;
  
    // Left/Right View
  _whatField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _whatField.leftViewMode = UITextFieldViewModeAlways;
  UIImageView *mag = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_magnifier.png"]] autorelease];
  mag.contentMode = UIViewContentModeCenter;
  _whatField.leftView = mag;
  
//  _whatField.rightViewMode = UITextFieldViewModeUnlessEditing;
//  UIButton *starButton = [UIButton buttonWithFrame:CGRectMake(0, 0, 20, 20) andStyle:nil target:self action:@selector(saved)];
//  [starButton setImage:[UIImage imageNamed:@"icon_star_silver.png"] forState:UIControlStateNormal];
//  _whatField.rightView = starButton;
  
  _whereField = [[PSSearchField alloc] initWithFrame:CGRectMake(10, 7, searchWidth, 30)];
  _whereField.delegate = self;
  _whereField.autocorrectionType = UITextAutocorrectionTypeNo;
  _whereField.placeholder = @"Where? (Current Location)";
  [_whereField addTarget:self action:@selector(searchTermChanged:) forControlEvents:UIControlEventEditingChanged];
  
//  _whereField.inputAccessoryView = tb;
  
  // Left/Right View
  _whereField.leftViewMode = UITextFieldViewModeAlways;
  UIImageView *where = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_where.png"]] autorelease];
  where.contentMode = UIViewContentModeCenter;
  _whereField.leftView = where;
  
  _whereField.rightViewMode = UITextFieldViewModeUnlessEditing;
  UIButton *distanceButton = [UIButton buttonWithFrame:CGRectMake(0, 0, 40, 16) andStyle:@"whereRightView" target:nil action:nil];
  [distanceButton setTitle:[NSString stringWithFormat:@"%.1fmi", [[NSUserDefaults standardUserDefaults] floatForKey:@"distanceRadius"]] forState:UIControlStateNormal];
  [distanceButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
  _whereField.rightView = distanceButton;
  
  _whereField.clearButtonMode = UITextFieldViewModeWhileEditing;
  
  [_headerView addSubview:_whereField];
  [_headerView addSubview:_whatField];
  
  [self setupHeaderWithView:_headerView];
}

- (void)setupToolbar {
  _tabView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 49.0)];
  
  UIButton *star = [UIButton buttonWithFrame:CGRectMake(0, 0, 50, 49) andStyle:@"detailTab" target:self action:@selector(showLists)];
  [star setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_left.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [star setImage:[UIImage imageNamed:@"tab_star.png"] forState:UIControlStateNormal];
  [_tabView addSubview:star];
  
  // Center
  _distanceButton = [UIButton buttonWithFrame:CGRectMake(50, 0, _tabView.width - 100, 49) andStyle:@"distanceButton" target:self action:@selector(changeDistance)];
  [_distanceButton setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_center_selected.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [_distanceButton setTitle:[NSString stringWithFormat:@"Searching within %.1f mi", [[NSUserDefaults standardUserDefaults] floatForKey:@"distanceRadius"]] forState:UIControlStateNormal];
  [_tabView addSubview:_distanceButton];
  
  UIButton *heart = [UIButton buttonWithFrame:CGRectMake(_tabView.width - 50, 0, 50, 49) andStyle:@"detailTab" target:self action:@selector(showInfo)];
  [heart setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_center.png" withLeftCapWidth:9 topCapWidth:0] forState:UIControlStateNormal];
  [heart setImage:[UIImage imageNamed:@"tab_heart.png"] forState:UIControlStateNormal];
  [_tabView addSubview:heart];
  
  [self setupFooterWithView:_tabView];
  
//  _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.0)];
//  
//  // Toolbar Items
//  NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:1];
//
//  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_star_silver.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showLists)] autorelease]];
//  
//  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
//  
//  _distanceButton = [[UIBarButtonItem barButtonWithTitle:[NSString stringWithFormat:@"Searching within %.1f miles", [[NSUserDefaults standardUserDefaults] floatForKey:@"distanceRadius"]] withTarget:self action:@selector(changeDistance) width:(_toolbar.width - 80) height:30 buttonType:BarButtonTypeGray style:@"detailToolbarButton"] retain];
//  [toolbarItems addObject:_distanceButton];
//  
//  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
//  
//  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_heart.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showInfo)] autorelease]];
//  
//  [_toolbar setItems:toolbarItems];
//  [self setupFooterWithView:_toolbar];
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

#pragma mark - Button Actios
- (void)findMyLocation {
  [[PSLocationCenter defaultCenter] getMyLocation];
}

- (void)showLists {
  NSError *error;
  [[GANTracker sharedTracker] trackEvent:@"root" action:@"lists" label:@"show" value:-1 withError:&error];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#showLists"];
  
  ListViewController *lvc = [[ListViewController alloc] initWithListMode:ListModeView];
  UINavigationController *lnc = [[UINavigationController alloc] initWithRootViewController:lvc];
  lnc.navigationBar.tintColor = RGBACOLOR(80, 80, 80, 1.0);
  [self presentModalViewController:lnc animated:YES];
  [lvc release];
  [lnc release];
}

- (void)showInfo {
  NSError *error;
  [[GANTracker sharedTracker] trackEvent:@"root" action:@"info" label:@"show" value:-1 withError:&error];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#info"];
  
  InfoViewController *ivc = [[InfoViewController alloc] initWithNibName:nil bundle:nil];
  UINavigationController *inc = [[UINavigationController alloc] initWithRootViewController:ivc];
  inc.navigationBar.tintColor = RGBACOLOR(80, 80, 80, 1.0);
  inc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentModalViewController:inc animated:YES];
  [ivc release];
  [inc release];
}

- (void)changeDistance {
  CGFloat distance = [[NSUserDefaults standardUserDefaults] floatForKey:@"distanceRadius"];
  NSInteger ind = 0;
  if (distance == 0.2) {
    ind = 0;
  } else if (distance == 0.5) {
    ind = 1;
  } else if (distance == 1.0) {
    ind = 2;
  } else if (distance == 3.0) {
    ind = 3;
  } else if (distance == 5.0) {
    ind = 4;
  } else if (distance == 10.0) {
    ind = 5;
  } else if (distance == 20.0) {
    ind = 6;
  }
  
  NSArray *data = [NSArray arrayWithObjects:@"1/4 mile", @"1/2 mile", @"1 mile", @"3 miles", @"5 miles", @"10 miles", @"20 miles", nil];
  [ActionSheetPicker displayActionPickerWithView:self.view data:data selectedIndex:ind target:self action:@selector(distanceSelectedWithIndex:inView:) title:@"Search Radius"];
}

- (void)distanceSelectedWithIndex:(NSNumber *)selectedIndex inView:(UIView *)view {
  CGFloat distance = 0.0;
  switch ([selectedIndex integerValue]) {
    case 0:
      distance = 0.2;
      break;
    case 1:
      distance = 0.5;
      break;
    case 2:
      distance = 1.0;
      break;
    case 3:
      distance = 3.0;
      break;
    case 4:
      distance = 5.0;
      break;
    case 5:
      distance = 10.0;
      break;
    case 6:
      distance = 20.0;
      break;
    default:
      distance = 0.5;
      break;
  }
  
  [[NSUserDefaults standardUserDefaults] setFloat:distance forKey:@"distanceRadius"];
  
  // Update Distance Label
  [(UIButton *)_whereField.rightView setTitle:[NSString stringWithFormat:@"%.1fmi", [[NSUserDefaults standardUserDefaults] floatForKey:@"distanceRadius"]] forState:UIControlStateNormal];
  
  NSError *error;
  [[GANTracker sharedTracker] trackEvent:@"root" action:@"changeDistance" label:[NSString stringWithFormat:@"%.1f", distance] value:-1 withError:&error];
  NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSString stringWithFormat:@"%.1f", distance],
                                  @"distance",
                                  nil];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#changeDistance" attributes:localyticsDict];
  
  // Fire a refetch
  _pagingStart = 0;
  [self loadDataSource];
}

- (void)searchNearby {
  _whereField.text = nil;
  self.whereQuery = nil;
  _pagingStart = 0;
  [self loadDataSource];
}

- (void)updateNumResults {
//  NSString *where = [_whereField.text length] > 0 ? _whereField.text : @"Current Location";
  NSString *distanceTitle = nil;
  if (_numResults > 0) {
    distanceTitle = [NSString stringWithFormat:@"%d Places within %.1f mi", _numResults, [[NSUserDefaults standardUserDefaults] floatForKey:@"distanceRadius"]];
  } else {
    distanceTitle = [NSString stringWithFormat:@"No Places within %.1f mi", [[NSUserDefaults standardUserDefaults] floatForKey:@"distanceRadius"]];
  }
  [_distanceButton setTitle:distanceTitle forState:UIControlStateNormal];
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
    // Update distance button label
    [_distanceButton setTitle:[NSString stringWithFormat:@"Searching within %.1f mi", [[NSUserDefaults standardUserDefaults] floatForKey:@"distanceRadius"]] forState:UIControlStateNormal];
  }
  
  NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  self.whatQuery ? self.whatQuery : @"",
                                  @"what",
                                  self.whereQuery ? self.whereQuery : @"",
                                  @"where",
                                  [[NSUserDefaults standardUserDefaults] stringForKey:@"distanceRadius"],
                                  @"distance",
                                  [NSString stringWithFormat:@"%d", _pagingStart],
                                  @"pagingStart",
                                  [NSString stringWithFormat:@"%d", _pagingCount],
                                  @"pagingCount",
                                  [[PSLocationCenter defaultCenter] locationString],
                                  @"location",
                                  nil];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#fetch" attributes:localyticsDict];
  
#if USE_FIXTURES
  [[PlaceDataCenter defaultCenter] getPlacesFromFixtures];
#else
  [[PlaceDataCenter defaultCenter] fetchYelpPlacesForQuery:_whatQuery andAddress:_whereQuery distance:[[NSUserDefaults standardUserDefaults] floatForKey:@"distanceRadius"] start:_pagingStart rpp:_pagingCount];
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

- (void)restoreDataSource {
  [super restoreDataSource];
  
  [self updateNumResults];
  _whereField.text = _whereQuery;
  _whatField.text = _whatQuery;
}

- (void)loadDataSource {
  BOOL isReload = (_pagingStart == 0) ? YES : NO;
  if (isReload) {
    _hasMore = NO;
    [self.items removeAllObjects];
    [self.tableView reloadData];
  }
  
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

- (void)dataSourceShouldLoadObjects:(id)objects {
  //
  // PREPARE DATASOURCE
  //
  
  BOOL isReload = (_pagingStart == 0) ? YES : NO;
  //  BOOL tableViewCellShouldAnimate = isReload ? NO : YES;
  BOOL tableViewCellShouldAnimate = YES;
  UITableViewRowAnimation rowAnimation = isReload ? UITableViewRowAnimationNone : UITableViewRowAnimationFade;
  
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
  } else {
    // This is a load more
    
    rowStart = [[self.items objectAtIndex:0] count]; // row starting offset for inserting
    [[self.items objectAtIndex:0] addObjectsFromArray:objects];
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
      [_tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:rowAnimation];
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
  [self updateNumResults];
  
  NSArray *places = [response objectForKey:@"places"];
  
  [self dataSourceShouldLoadObjects:places];
}

- (void)dataCenterDidFailWithError:(NSError *)error andUserInfo:(NSDictionary *)userInfo {
  [self dataSourceDidError];
}

#pragma mark - Actions
- (void)locationAcquired:(NSNotification *)notification {
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
    
    DLog(@"Attempting Reverse Geocode for lat: %f, lng: %f", latitude, longitude);
    
    _reverseGeocoder = [[MKReverseGeocoder alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];    
    _reverseGeocoder.delegate = self;
    [_reverseGeocoder start];
  }
}

#pragma mark - MKReverseGeocoderDelegate
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark {
  NSDictionary *address = placemark.addressDictionary;
  DLog(@"Reverse Geocode got address: %@", address);
  
  // Create some edge cases for weird stuff
  
  RELEASE_SAFELY(_currentAddress);
  _currentAddress = [[NSArray arrayWithObjects:[[address objectForKey:@"FormattedAddressLines"] objectAtIndex:0], [[address objectForKey:@"FormattedAddressLines"] objectAtIndex:1], nil] retain];
  
  [self updateCurrentLocation];
  
  _reverseGeocoder = nil;
  [geocoder release];
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
  DLog(@"Reverse Geocoding for lat: %f lng: %f FAILED!", geocoder.coordinate.latitude, geocoder.coordinate.longitude);
  
//  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"GPS" message:@"Error finding your location" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try Again", nil] autorelease];
//  av.tag = kAlertGPSError;
//  [av show];
  _reverseGeocoder = nil;
  [geocoder release];
  
  [self dataCenterDidFailWithError:nil andUserInfo:nil];
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
  
  NSError *error;
  [[GANTracker sharedTracker] trackEvent:@"root" action:@"search" label:[NSString stringWithFormat:@"what:%@,where:%@", self.whatQuery, self.whereQuery] value:-1 withError:&error];
  NSDictionary *localyticsDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  self.whatQuery ? self.whatQuery : @"",
                                  @"what",
                                  self.whereQuery ? self.whereQuery : @"",
                                  @"where",
                                  [[NSUserDefaults standardUserDefaults] stringForKey:@"distanceRadius"],
                                  @"distance",
                                  nil];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"root#search" attributes:localyticsDict];

  // Reload dataSource
    _pagingStart = 0; // reset paging
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
                     _whereField.top = 7;
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
    
    if ([textField isEqual:_whatField]) {
      [_whatTermController searchWithTerm:textField.text];
    } else {
      [_whereTermController searchWithTerm:textField.text];
    }
    
    // Animate Search Fields
    [UIView animateWithDuration:0.4
                     animations:^{
                       _whatTermController.view.frame = CGRectMake(0, 80, self.view.width, self.view.height - 80);
                       _whereTermController.view.frame = CGRectMake(0, 80, self.view.width, self.view.height - 80);
                       _headerView.height = 80;
                       _whereField.top = 42;
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

#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == alertView.cancelButtonIndex) return;
  
  if (alertView.tag == kAlertGPSError) {
    [self loadDataSource];
  }
  
}

@end
