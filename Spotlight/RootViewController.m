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
#import "ASIHTTPRequest.h"

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [[PlaceDataCenter defaultCenter] setDelegate:self];
  }
  return self;
}

- (void)dealloc
{
  [[PlaceDataCenter defaultCenter] setDelegate:nil];
  [super dealloc];
}

#pragma mark - View
- (void)loadView
{
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  _navTitleLabel.text = @"Nom Nom Nom!";
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  _tableView.rowHeight = 160.0;
  
  // Populate datasource
#warning fixtures being used
  [self loadDataSource];
}

#pragma mark - State Machine
- (void)loadDataSource {
  [super loadDataSource];
//  [[PlaceDataCenter defaultCenter] getPlacesFromFixtures];

  [self reverseGeocode];

//    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"yelpphotos" ofType:@"html"]];
//  NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"yelpplaces50" ofType:@"html"]];
//  NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
  
//  [self scrapePhotos];
//  [self scrapePlaces];
  
//  [self fetchYelpCoverPhotoForBiz:@"fTeiio1L2ZBIRdlzjdjAeg"];

}

- (void)reverseGeocode {
  // NYC (Per Se): 40.76848, -73.98264
  // Paris: 48.86930, 2.37151
  // London (Gordon Ramsay): 51.48476, -0.16308
  // Alexanders: 37.32798, -122.01382
  // Bouchon: 38.40153, -122.36049
  CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(37.32798, -122.01382);
  MKReverseGeocoder *rg = [[MKReverseGeocoder alloc] initWithCoordinate:coord];
  rg.delegate = self;
  [rg start];
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
}



- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
  DLog(@"Reverse Geocoding for lat: %f lng: %f FAILED!", geocoder.coordinate.latitude, geocoder.coordinate.longitude);
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

@end
