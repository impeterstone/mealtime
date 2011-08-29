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

@implementation DetailViewController

- (id)initWithPlace:(NSDictionary *)place {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _place = [[NSMutableDictionary alloc] initWithDictionary:place];
    _imageSizeCache = [[NSMutableDictionary alloc] init];
    [[BizDataCenter defaultCenter] setDelegate:self];
    
    _isInfoShowing = NO;
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_ivc);
  RELEASE_SAFELY(_infoButton);
}

- (void)dealloc
{
  [[BizDataCenter defaultCenter] setDelegate:nil];
  RELEASE_SAFELY(_place);
  RELEASE_SAFELY(_imageSizeCache);
  
  RELEASE_SAFELY(_ivc);
  RELEASE_SAFELY(_infoButton);
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
  
  _navTitleLabel.text = [_place objectForKey:@"name"];
  
  [_nullView setLoadingTitle:@"Loading" loadingSubtitle:@"Finding Photos of Food" emptyTitle:@"Epic Fail" emptySubtitle:@"FFFFFUUUUUUUU" image:nil];
  
  // iAd
  _adView = [self newAdBannerViewWithDelegate:self];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  _tableView.rowHeight = self.tableView.width;
  
  // Nav Buttons
  _infoButton = [[UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"icon_info.png"] withTarget:self action:@selector(toggleInfo) width:40 height:30 buttonType:BarButtonTypeBlue] retain];
  self.navigationItem.rightBarButtonItem = _infoButton;
  
  
  _ivc = [[InfoViewController alloc] initWithPlace:_place];
  _ivc.parent = self;
  _ivc.view.frame = _tableView.bounds;
  [self.view insertSubview:_ivc.view atIndex:0];
  
  // Populate datasource
  [self loadDataSource];
}

- (void)toggleInfo {
  UIView *currentView = nil;
  UIView *newView = nil;
  UIViewAnimationOptions options;
  if (_isInfoShowing) {
    _isInfoShowing = NO;
    currentView = _ivc.view;
    newView = _tableView;
    _ivc.tableView.scrollsToTop = NO;
    self.tableView.scrollsToTop = YES;
    options = UIViewAnimationOptionTransitionFlipFromLeft;
  } else {
    _isInfoShowing = YES;
    currentView = _tableView;
    newView = _ivc.view;
    _ivc.tableView.scrollsToTop = YES;
    self.tableView.scrollsToTop = NO;
    options = UIViewAnimationOptionTransitionFlipFromRight;
  }
  
  [UIView transitionFromView:currentView
                      toView:newView
                    duration:0.6
                     options:options
                  completion:^(BOOL finished) {
                  }];
}

#pragma mark - State Machine
- (void)loadDataSource {
  [super loadDataSource];
//  [[BizDataCenter defaultCenter] getProductsFromFixtures];
  NSString *rpp = nil;
  
  if ([_place objectForKey:@"numphotos"] && [[_place objectForKey:@"numphotos"] integerValue] <= 8) {
    rpp = [_place objectForKey:@"numphotos"];
  } else {
    rpp = @"-1";
  }

  [[BizDataCenter defaultCenter] fetchYelpPhotosForBiz:[_place objectForKey:@"biz"] rpp:rpp];
  [[BizDataCenter defaultCenter] fetchYelpMapForBiz:[_place objectForKey:@"biz"]];
  [[BizDataCenter defaultCenter] fetchYelpBizForBiz:[_place objectForKey:@"biz"]];
  [self loadPhotosFromDatabase];
}

- (void)dataSourceDidLoad {
  [self.tableView reloadData];
  [super dataSourceDidLoad];
}

- (void)loadPhotosFromDatabase {
  // Load photos from DB
  NSArray *photos = [[BizDataCenter defaultCenter] selectPlacePhotosInDatabaseForBiz:[_place objectForKey:@"biz"]];
  [self.items removeAllObjects];
  
  // Put response into items (datasource)
  if ([photos count] > 0) {
    [self.items addObject:photos];
  }
  [self dataSourceDidLoad];
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response {
  // Match biz from request to current, make sure this request is still valid
  if (![[request.userInfo objectForKey:@"biz"] isEqualToString:[_place objectForKey:@"biz"]]) return;
  
  if ([[request.userInfo objectForKey:@"requestType"] isEqualToString:@"photos"]) {
    [self.items removeAllObjects];
    
    // Put response into items (datasource)
    NSArray *photos = [response objectForKey:@"photos"];
    if ([photos count] > 0) {
      [self.items addObject:photos];
    }

    [self dataSourceDidLoad];
  } else if ([[request.userInfo objectForKey:@"requestType"] isEqualToString:@"map"]) {
    // Update metadata
    if ([response objectForKey:@"address"]) {
      [_place setObject:[response objectForKey:@"address"] forKey:@"address"];
    }
    if ([response objectForKey:@"coordinates"]) {
      [_place setObject:[response objectForKey:@"coordinates"] forKey:@"coordinates"];
    }
    [_ivc loadMap];
  } else if ([[request.userInfo objectForKey:@"requestType"] isEqualToString:@"biz"]) {
    // Update Hours
    if ([response objectForKey:@"hours"]) {
      [_place setObject:[response objectForKey:@"hours"] forKey:@"hours"];
    }
    [_ivc loadMeta];
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

#pragma mark - ProductCellDelegate
//- (void)productCell:(ProductCell *)cell didLoadImage:(UIImage *)image {
//  // UNUSED
//  NSString *sizeString = NSStringFromCGSize(image.size);
//  NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
//  NSDictionary *product = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
//  [_imageSizeCache setValue:sizeString forKey:[product objectForKey:@"src"]];
//}

@end
