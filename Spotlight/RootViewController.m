//
//  RootViewController.m
//  Spotlight
//
//  Created by Peter Shih on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"
#import "PlaceCell.h"
#import "PlaceDataCenter.h"
#import "ProductViewController.h"
#import "PSLocationCenter.h"

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [[PlaceDataCenter defaultCenter] setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reverseGeocode) name:kLocationAcquired object:nil];
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_searchField);
  RELEASE_SAFELY(_compassButton);
  RELEASE_SAFELY(_cancelButton);
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationAcquired object:nil];
  [[PlaceDataCenter defaultCenter] setDelegate:nil];
  [_searchField removeFromSuperview];
  
  RELEASE_SAFELY(_searchField);
  RELEASE_SAFELY(_compassButton);
  RELEASE_SAFELY(_cancelButton);
  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_weave.png"]] autorelease];
  bg.frame = self.view.bounds;
  bg.autoresizingMask = ~UIViewAutoresizingNone;
  return bg;
}

#pragma mark - View
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  
  [UIView animateWithDuration:0.4
                        delay:0.0
   
                      options:UIViewAnimationCurveEaseOut
                   animations:^{
                     _searchField.alpha = 1.0;
                   }
                   completion:^(BOOL finished) {
                   }];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [_searchField resignFirstResponder];
  
  [UIView animateWithDuration:0.4
                        delay:0.0
   
                      options:UIViewAnimationCurveEaseOut
                   animations:^{
                     _searchField.alpha = 0.0;
                   }
                   completion:^(BOOL finished) {
                   }];
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  _navTitleLabel.text = @"Nom Nom Nom!";
  
  [_nullView setLoadingTitle:@"Loading..." loadingSubtitle:@"Finding Nearby Restaurants" emptyTitle:@"Fail" emptySubtitle:@"No Restaurants Found" image:nil];
  
  // iAd
//  _adView = [self newAdBannerViewWithDelegate:self];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  _tableView.rowHeight = 160.0;
  
  // Compass location finder
  _compassButton = [[UIBarButtonItem navButtonWithImage:[UIImage imageNamed:@"icon_compass.png"] withTarget:self action:@selector(findMyLocation) buttonType:NavButtonTypeBlue] retain];
  self.navigationItem.rightBarButtonItem = _compassButton;
  
  // Setup Search
  _searchField = [[PSTextField alloc] initWithFrame:CGRectMake(5, 26, 60, 30) withInset:CGSizeMake(30, 6)];
  _searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _searchField.font = NORMAL_FONT;
  _searchField.delegate = self;
  _searchField.returnKeyType = UIReturnKeySearch;
  _searchField.background = [UIImage stretchableImageNamed:@"bg_searchbar_textfield.png" withLeftCapWidth:30 topCapWidth:0];
  _searchField.placeholder = @"Address, City, State or Zip";
  [_searchField addTarget:self action:@selector(searchTermChanged:) forControlEvents:UIControlEventEditingChanged];
  
  [[[UIApplication sharedApplication] keyWindow] addSubview:_searchField];
  
  _cancelButton = [[UIBarButtonItem navButtonWithTitle:@"Cancel" withTarget:self action:@selector(cancelSearch) buttonType:NavButtonTypeSilver] retain];
  
  // Populate datasource
  [self loadDataSource];
}

#pragma mark - Find My Location
- (void)findMyLocation {
  [[PSLocationCenter defaultCenter] getMyLocation];
}

#pragma mark - State Machine
- (void)loadDataSource {
  [super loadDataSource];
  [self findMyLocation];
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

  NSArray *addressArray = [NSArray arrayWithObjects:[[address objectForKey:@"FormattedAddressLines"] objectAtIndex:0], [[address objectForKey:@"FormattedAddressLines"] objectAtIndex:1], nil];
  NSString *formattedAddress = [addressArray componentsJoinedByString:@" "];
  
  // fetch Yelp Places
  [[PlaceDataCenter defaultCenter] fetchYelpPlacesForAddress:formattedAddress];
  
  _reverseGeocoder = nil;
  [geocoder release];
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
  DLog(@"Reverse Geocoding for lat: %f lng: %f FAILED!", geocoder.coordinate.latitude, geocoder.coordinate.longitude);
  
  _reverseGeocoder = nil;
  [geocoder release];
}

- (void)dataSourceDidLoad {
  [self.tableView reloadData];
  [super dataSourceDidLoad];
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response {
  [self.items removeAllObjects];
  
  // Put response into items (datasource)
  NSArray *data = response;
  if ([data count] > 0) {
    [self.items addObject:data];
  }
  
  [self dataSourceDidLoad];
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
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSMutableDictionary *place = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  ProductViewController *pvc = [[ProductViewController alloc] initWithPlace:place];
  [self.navigationController pushViewController:pvc animated:YES];
  [pvc release];
}

#pragma mark - Search
- (void)cancelSearch {
  [UIView animateWithDuration:0.4
                   animations:^{
                     _searchField.width = 60;
                   }
                   completion:^(BOOL finished) {
                   }];
  
  self.navigationItem.rightBarButtonItem = _compassButton;
  [_searchField resignFirstResponder];
  _searchActive = NO;
}

- (void)searchTermChanged:(UITextField *)textField {
}

- (void)searchWithText:(NSString *)searchText {
  _searchActive = YES; 
  
  [_searchField resignFirstResponder];
  
  // Search Yelp with Address
  [[PlaceDataCenter defaultCenter] fetchYelpPlacesForAddress:searchText];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  self.navigationItem.rightBarButtonItem = _cancelButton;
  
  [UIView animateWithDuration:0.4
                   animations:^{
                     _searchField.width = self.view.width - 80;
                     //                     _searchTermController.view.alpha = 1.0;
                   }
                   completion:^(BOOL finished) {
                   }];
  
  return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {  
  //  _searchTermController.view.alpha = 0.0;
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  if (![textField isEditing]) {
    [textField becomeFirstResponder];
  }
  if ([textField.text length] == 0) {
    // Empty search
    [self cancelSearch];
  } else {
    [self searchWithText:textField.text];
  }
  
  return YES;
}

@end
