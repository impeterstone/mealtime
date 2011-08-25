//
//  ProductViewController.m
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProductViewController.h"
//#import "ProductCell.h"
#import "ProductDataCenter.h"
#import "ZoomViewController.h"

@implementation ProductViewController

- (id)initWithPlace:(NSDictionary *)place {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _place = [place copy];
    _imageSizeCache = [[NSMutableDictionary alloc] init];
    [[ProductDataCenter defaultCenter] setDelegate:self];
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
}

- (void)dealloc
{
  [[ProductDataCenter defaultCenter] setDelegate:nil];
  RELEASE_SAFELY(_place);
  RELEASE_SAFELY(_imageSizeCache);
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
- (void)loadView
{
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  _navTitleLabel.text = [_place objectForKey:@"name"];
  
  [_nullView setLoadingTitle:@"Loading..." loadingSubtitle:@"Finding Photos of Food" emptyTitle:@"Epic Fail" emptySubtitle:@"FFFFFUUUUUUUU" image:nil];
  
  // iAd
  _adView = [self newAdBannerViewWithDelegate:self];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  _tableView.rowHeight = self.tableView.width;
  
  // Populate datasource
  [self loadDataSource];
}

#pragma mark - State Machine
- (void)loadDataSource {
  [super loadDataSource];
//  [[ProductDataCenter defaultCenter] getProductsFromFixtures];
  [[ProductDataCenter defaultCenter] fetchYelpPhotosForBiz:[_place objectForKey:@"biz"]];
}

- (void)dataSourceDidLoad {
  [self.tableView reloadData];
  [super dataSourceDidLoad];
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response {
  // Put response into items (datasource)
  NSArray *data = response;
  [self.items addObject:data];

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
