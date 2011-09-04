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
    
    _photoCount = 0;
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  RELEASE_SAFELY(_infoButton);
}

- (void)dealloc
{
  [[BizDataCenter defaultCenter] setDelegate:nil];
  RELEASE_SAFELY(_place);
  RELEASE_SAFELY(_imageSizeCache);
  
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
  
  // Populate datasource
  [self loadDataSource];
}

- (void)toggleInfo {
  // Info VC
  _ivc = [[InfoViewController alloc] initWithPlace:_place];
  [self.navigationController pushViewController:_ivc animated:YES];
  [_ivc release];
  
//  UIView *currentView = nil;
//  UIView *newView = nil;
//  UIViewAnimationOptions options;
//  if (_isInfoShowing) {
//    _isInfoShowing = NO;
//    currentView = _ivc.view;
//    newView = _tableView;
//    _ivc.tableView.scrollsToTop = NO;
//    self.tableView.scrollsToTop = YES;
//    options = UIViewAnimationOptionTransitionFlipFromLeft;
//  } else {
//    _isInfoShowing = YES;
//    currentView = _tableView;
//    newView = _ivc.view;
//    _ivc.tableView.scrollsToTop = YES;
//    self.tableView.scrollsToTop = NO;
//    options = UIViewAnimationOptionTransitionFlipFromRight;
//  }
//  
//  [UIView transitionFromView:currentView
//                      toView:newView
//                    duration:0.6
//                     options:options
//                  completion:^(BOOL finished) {
//                  }];
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
  
  // Load from server
  NSString *numPhotos = [_place objectForKey:@"numphotos"];
  NSString *start = @"0";
  
  // Results per page
  NSString *rpp = nil;
  if (numPhotos && [numPhotos integerValue] <= 8) {
    rpp = numPhotos;
  } else {
    rpp = @"-1";
  }
  
#if USE_FIXTURES
  [[BizDataCenter defaultCenter] getPhotosFromFixturesForBiz:[_place objectForKey:@"biz"]];
  [[BizDataCenter defaultCenter] getBizFromFixturesForBiz:[_place objectForKey:@"biz"]];
#else
  [[BizDataCenter defaultCenter] fetchYelpPhotosForBiz:[_place objectForKey:@"biz"] start:start rpp:rpp];
  [[BizDataCenter defaultCenter] fetchYelpBizForBiz:[_place objectForKey:@"biz"]];
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
  [super dataSourceDidLoad];
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinishWithResponse:(id)response andUserInfo:(NSDictionary *)userInfo {
  // Match biz from request to current, make sure this request is still valid
  if (![[userInfo objectForKey:@"biz"] isEqualToString:[_place objectForKey:@"biz"]]) return;
  
  if ([[userInfo objectForKey:@"requestType"] isEqualToString:@"photos"]) {
    [self.items removeAllObjects];
    
    // Put response into items (datasource)
    NSArray *photos = [response objectForKey:@"photos"];
    if ([photos count] > 0) {
      [self.items addObject:photos];
    }

    [self dataSourceDidLoad];
  } else if ([[userInfo objectForKey:@"requestType"] isEqualToString:@"biz"]) {
    // Address
    if ([response objectForKey:@"address"]) {
      [_place setObject:[response objectForKey:@"address"] forKey:@"address"];
    }
    if ([response objectForKey:@"latitude"]) {
      [_place setObject:[response objectForKey:@"latitude"] forKey:@"latitude"];
    }
    if ([response objectForKey:@"longitude"]) {
      [_place setObject:[response objectForKey:@"longitude"] forKey:@"longitude"];
    }
    // Update Hours
    if ([response objectForKey:@"hours"]) {
      [_place setObject:[response objectForKey:@"hours"] forKey:@"hours"];
    }
    // Snippets
    if ([response objectForKey:@"snippets"]) {
      [_place setObject:[response objectForKey:@"snippets"] forKey:@"snippets"];
    }
    
    _infoButton.enabled = YES;

    // Update Reviews
//    if ([response objectForKey:@"reviews"]) {
//      [_place setObject:[response objectForKey:@"reviews"] forKey:@"reviews"];
//    }
    
    // Load Meta
  }
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

#pragma mark - ProductCellDelegate
//- (void)productCell:(ProductCell *)cell didLoadImage:(UIImage *)image {
//  // UNUSED
//  NSString *sizeString = NSStringFromCGSize(image.size);
//  NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
//  NSDictionary *product = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
//  [_imageSizeCache setValue:sizeString forKey:[product objectForKey:@"src"]];
//}

@end
