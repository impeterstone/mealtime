//
//  SavedViewController.m
//  MealTime
//
//  Created by Peter Shih on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SavedViewController.h"
#import "PSDatabaseCenter.h"
#import "PlaceCell.h"
#import "DetailViewController.h"

@interface SavedViewController (Private)

- (void)dismiss;

@end

@implementation SavedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];

}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)dealloc
{
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
  
  [_cellCache makeObjectsPerformSelector:@selector(resumeAnimations)];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [_cellCache makeObjectsPerformSelector:@selector(pauseAnimations)];
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Done" withTarget:self action:@selector(dismiss) width:60.0 height:30.0 buttonType:BarButtonTypeBlue];
  _navTitleLabel.text = @"Saved Places";
  
  
  [_nullView setLoadingTitle:@"Loading..." loadingSubtitle:@"Finding Restaurants" emptyTitle:@"No Saved Places" emptySubtitle:@"You haven't saved any places yet" image:[UIImage imageNamed:@"nullview_photos.png"]];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  if (isDeviceIPad()) {
    _tableView.rowHeight = 320.0;
  } else {
    _tableView.rowHeight = 160.0;
  }
  
  [self loadDataSource];
}

- (void)help {
  
}
                                           
- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - DataSource
- (void)loadDataSource {
  [super loadDataSource];
  
  EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"SELECT * FROM places WHERE saved = 1"];
  
  NSMutableArray *savedPlaces = [NSMutableArray arrayWithCapacity:1];
  for (EGODatabaseRow *row in res) {
    NSData *placeData = [row dataForColumn:@"data"];
    [savedPlaces addObject:[NSKeyedUnarchiver unarchiveObjectWithData:placeData]];
  }
  
  _pagingStart = 0; // reset paging
  _hasMore = NO;
//  _numResults = [res count];
//  if (_numResults > 0) {
//    _statusLabel.text = [NSString stringWithFormat:@"Found %d saved places", _numResults];
//  } else {
//    _statusLabel.text = [NSString stringWithFormat:@"You have no saved places"];
//  }
  
  [self dataSourceShouldLoadObjects:savedPlaces];
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

@end