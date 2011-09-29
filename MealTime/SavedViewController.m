//
//  SavedViewController.m
//  MealTime
//
//  Created by Peter Shih on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SavedViewController.h"
#import "PSDatabaseCenter.h"
#import "PSLocationCenter.h"
#import "PlaceCell.h"
#import "DetailViewController.h"
#import "PSMailCenter.h"
#import "PSDatabaseCenter.h"
#import "PSOverlayImageView.h"
#import "MapViewController.h"

@interface SavedViewController (Private)

- (void)setupToolbar;
- (void)share;
- (void)sort;
- (void)rename;
- (void)showMap;

@end

@implementation SavedViewController

@synthesize sortOrder = _sortOrder;
@synthesize sortDirection = _sortDirection;

- (id)initWithSid:(NSString *)sid andListName:(NSString *)listName {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _sid = [sid copy];
    _listName = [listName copy];
    self.sortOrder = @"cdistance";
    self.sortDirection = @"ASC";
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_tabView);
}

- (void)dealloc
{
  RELEASE_SAFELY(_sid);
  RELEASE_SAFELY(_listName);
  RELEASE_SAFELY(_sortOrder);
  
  RELEASE_SAFELY(_tabView);
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
  
  [_cellCache makeObjectsPerformSelector:@selector(resumeAnimations)];
  
  // NUX
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownSavedOverlay"]) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownSavedOverlay"];
    NSString *imgName = isDeviceIPad() ? @"nux_overlay_saved_pad.png" : @"nux_overlay_saved.png";
    PSOverlayImageView *nuxView = [[[PSOverlayImageView alloc] initWithImage:[UIImage imageNamed:imgName]] autorelease];
    nuxView.alpha = 0.0;
    [[UIApplication sharedApplication].keyWindow addSubview:nuxView];
    [UIView animateWithDuration:0.4 animations:^{
      nuxView.alpha = 1.0;
    }];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [_cellCache makeObjectsPerformSelector:@selector(pauseAnimations)];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  [self loadDataSource];
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  self.navigationItem.leftBarButtonItem = [UIBarButtonItem navBackButtonWithTarget:self action:@selector(back)];
  self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"icon_nav_globe"] withTarget:self action:@selector(showMap) width:40 height:30 buttonType:BarButtonTypeNormal];
  _navTitleLabel.text = _listName;
  
  // Nullview
  [_nullView setLoadingTitle:@"Loading..."];
  [_nullView setLoadingSubtitle:@"Finding Places"];
  [_nullView setEmptyTitle:@"This List is Empty"];
  [_nullView setEmptySubtitle:@"You haven't added any places to this list yet."];
  [_nullView setEmptyImage:[UIImage imageNamed:@"nullview_empty.png"]];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  if (isDeviceIPad()) {
    _tableView.rowHeight = 320.0;
  } else {
    _tableView.rowHeight = 160.0;
  }
  
  // Toolbar
  [self setupToolbar];
  
  NSError *error;
  [[GANTracker sharedTracker] trackPageview:@"/saved" withError:&error];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"saved#load"];
}

- (void)setupToolbar {
  CGFloat tabWidth = isDeviceIPad() ? 256 : 106;
  
  _tabView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 49.0)];
  
  UIButton *sort = [UIButton buttonWithFrame:CGRectMake(0, 0, tabWidth, 49) andStyle:@"detailTab" target:self action:@selector(sort)];
  [sort setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_left.png" withLeftCapWidth:8 topCapWidth:0] forState:UIControlStateNormal];
  [sort setImage:[UIImage imageNamed:@"icon_tab_sort.png"] forState:UIControlStateNormal];
  [_tabView addSubview:sort];
  
  UIButton *share = [UIButton buttonWithFrame:CGRectMake(tabWidth, 0, _tabView.width - (tabWidth * 2), 49) andStyle:@"detailTab" target:self action:@selector(share)];
  [share setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_center.png" withLeftCapWidth:8 topCapWidth:0] forState:UIControlStateNormal];
  [share setImage:[UIImage imageNamed:@"icon_tab_envelope.png"] forState:UIControlStateNormal];
  [_tabView addSubview:share];
  
  UIButton *rename = [UIButton buttonWithFrame:CGRectMake(_tabView.width - tabWidth, 0, tabWidth, 49) andStyle:@"detailTab" target:self action:@selector(rename)];
  [rename setBackgroundImage:[UIImage stretchableImageNamed:@"tab_btn_right.png" withLeftCapWidth:8 topCapWidth:0] forState:UIControlStateNormal];
  [rename setImage:[UIImage imageNamed:@"icon_tab_rename.png"] forState:UIControlStateNormal];
  [_tabView addSubview:rename];
  
  [self setupFooterWithView:_tabView];
  
//  _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.0)];
//  NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:1];
//  
//  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
//  [toolbarItems addObject:[UIBarButtonItem barButtonWithTitle:@"Export via Email" withTarget:self action:@selector(share) width:300 height:30 buttonType:BarButtonTypeGray style:@"detailToolbarButton"]];
//  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
//  
//  [_toolbar setItems:toolbarItems];
//  [self setupFooterWithView:_toolbar];
}

- (void)showMap {
//  UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Coming Soon" message:@"Map Mode Coming Soon" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease];
//  [av show];
  
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"saved#showMap"];
  
  MapViewController *mvc = [[MapViewController alloc] initWithPlaces:[self.items objectAtIndex:0]];
  [self.navigationController pushViewController:mvc animated:YES];
  [mvc release];
}

- (void)rename {
  TSAlertView *alertView = [[[TSAlertView alloc] initWithTitle:@"Rename List" message:@"Give your list a new name!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Rename", nil] autorelease];
  alertView.tag = kAlertRenameList;
  alertView.style = TSAlertViewStyleInput;
  alertView.buttonLayout = TSAlertViewButtonLayoutNormal;
  alertView.inputTextField.placeholder = _listName;
  [alertView show];
}

- (void)sort {
  UIActionSheet *as = [[[UIActionSheet alloc] initWithTitle:@"Sort List" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Distance", @"Rating", nil] autorelease];
  [as showInView:self.view];
}

- (void)share {
  if (![self dataIsAvailable]) {
    UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Need something in this list first." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease];
    [av show];
    return;
  }
  
  NSError *error;
  [[GANTracker sharedTracker] trackEvent:@"star" action:@"export" label:nil value:-1 withError:&error];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"star#export"];
  
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
  for (NSDictionary *place in [self.items objectAtIndex:0]) {
    // Score
    NSString *score = nil;
    NSInteger metaScore = [[place objectForKey:@"score"] integerValue];
    if (metaScore > 90) {
      score = @"A+";
    } else if (metaScore > 80) {
      score = @"A";
    } else if (metaScore > 70) {
      score = @"A-";
    } else if (metaScore > 60) {
      score = @"B+";
    } else if (metaScore > 50) {
      score = @"B";
    } else if (metaScore > 40) {
      score = @"B-";
    } else if (metaScore > 30) {
      score = @"C+";
    } else if (metaScore > 20) {
      score = @"C";
    } else if (metaScore >= 10) {
      score = @"C-";
    } else {
      score = @"F";
    }

    [body appendString:@"<br/>"];
    [body appendFormat:@"<a href=\"http://www.yelp.com/biz/%@\">%@</a><br/>", [place objectForKey:@"biz"], [place objectForKey:@"name"]];
    [body appendFormat:@"%@<br/>", [[place objectForKey:@"address"] componentsJoinedByString:@"<br/>"]];
    if ([[place objectForKey:@"phone"] notNil]) [body appendFormat:@"%@<br/>", [place objectForKey:@"phone"]];
    [body appendFormat:@"Price: %@, Score: %@<br/>", [place objectForKey:@"price"], score];
//    [body appendString:@"<br/>"];
  }
  [[PSMailCenter defaultCenter] controller:self sendMailTo:nil withSubject:[NSString stringWithFormat:@"MealTime: %@", _listName] andMessageBody:body];
}

#pragma mark - DataSource
- (void)reloadDataSource {
  [super reloadDataSource];
  [self loadDataSource];
}

- (void)loadDataSource {
  [super loadDataSource];
  
  
//  SELECT p.*
//  FROM places p
//  JOIN lists_places lp
//  ON p.biz = lp.place_biz
//  AND lp.list_sid = '59CFBF7C-52B5-4833-8B08-25147B5A728B'
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSNumber *lat = [NSNumber numberWithFloat:[[PSLocationCenter defaultCenter] latitude]];
    NSNumber *lng = [NSNumber numberWithFloat:[[PSLocationCenter defaultCenter] longitude]];
    NSString *query = [NSString stringWithFormat:@"SELECT p.*, distance(latitude, longitude, ?, ?) as cdistance FROM places p JOIN lists_places lp ON p.biz = lp.place_biz AND lp.list_sid = ? ORDER BY %@ %@", self.sortOrder, self.sortDirection];
    EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, lat, lng, _sid, nil];
    
    NSMutableArray *savedPlaces = [NSMutableArray arrayWithCapacity:1];
    for (EGODatabaseRow *row in res) {
      NSData *placeData = [row dataForColumn:@"data"];
      NSMutableDictionary *placeDict = [NSMutableDictionary dictionaryWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:placeData]];
      [placeDict setObject:[NSString stringWithFormat:@"%.2f", [row doubleForColumn:@"cdistance"]] forKey:@"cdistance"];
      [savedPlaces addObject:placeDict];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
    [self dataSourceShouldLoadObjects:[NSMutableArray arrayWithObject:savedPlaces] shouldAnimate:YES];
    });
  });
  
//  _numResults = [res count];
//  if (_numResults > 0) {
//    _statusLabel.text = [NSString stringWithFormat:@"Found %d saved places", _numResults];
//  } else {
//    _statusLabel.text = [NSString stringWithFormat:@"You have no saved places"];
//  }
  
}

- (void)dataSourceDidLoad {
  [super dataSourceDidLoad];
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

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == actionSheet.cancelButtonIndex) return;
  
  switch (buttonIndex) {
    case 0: // distance
      self.sortOrder = @"cdistance";
      self.sortDirection = @"ASC";
      break;
    case 1: // rating
      self.sortOrder = @"score";
      self.sortDirection = @"DESC";
      break;
    default:
      break;
  }
  [self reloadDataSource];
}

#pragma mark - AlertView
- (void)alertView:(TSAlertView *)alertView didDismissWithButtonIndex: (NSInteger) buttonIndex {
  if (buttonIndex == alertView.cancelButtonIndex) return;
  
  if (alertView.tag == kAlertRenameList) {
    NSString *newListName = alertView.inputTextField.text;
    if ([newListName length] > 0) {
      NSString *query = @"UPDATE lists SET name = ? WHERE sid = ?";
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, newListName, _sid, nil];
      RELEASE_SAFELY(_listName);
      _listName = [newListName copy];
      _navTitleLabel.text = _listName;
    }
  }
}
@end
