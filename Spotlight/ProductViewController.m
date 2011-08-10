//
//  ProductViewController.m
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProductViewController.h"
#import "ProductCell.h"
#import "ProductDataCenter.h"

@implementation ProductViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [[ProductDataCenter defaultCenter] setDelegate:self];
  }
  return self;
}

- (void)dealloc
{
  [[ProductDataCenter defaultCenter] setDelegate:nil];
  [super dealloc];
}

#pragma mark - View
- (void)loadView
{
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  // Populate datasource
#warning fixtures being used
  [self loadDataSource];
}

#pragma mark - State Machine
- (void)loadDataSource {
  [super loadDataSource];
  [[ProductDataCenter defaultCenter] getProductsFromFixtures];
}

- (void)dataSourceDidLoad {
  [self.tableView reloadData];
  [super dataSourceDidLoad];
}

#pragma mark - PSDataCenterDelegate
- (void)dataCenterDidFinish:(ASIHTTPRequest *)request withResponse:(id)response {
  
  // Put response into items (datasource)
  NSArray *data = [response objectForKey:@"data"];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if ([_sectionTitles count] == 0) return nil;
  
  NSString *sectionTitle = nil;
  sectionTitle = [_sectionTitles objectAtIndex:section];
  if ([sectionTitle notNil]) {
    return sectionTitle;
  } else {
    return nil;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *product = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  return [ProductCell rowHeightForObject:product expanded:[self cellIsSelected:indexPath] forInterfaceOrientation:[self interfaceOrientation]];
}

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
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
