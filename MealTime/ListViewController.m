//
//  ListViewController.m
//  MealTime
//
//  Created by Peter Shih on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ListViewController.h"
#import "PSDatabaseCenter.h"
#import "ListCell.h"
#import "SavedViewController.h"

@interface ListViewController (Private)

- (void)edit;
- (void)dismiss;
- (void)newList;

@end

@implementation ListViewController

- (id)initWithListMode:(ListMode)listMode {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _listMode = listMode;
  }
  return self;
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
  NSInteger section = indexPath.section;
  NSInteger row = indexPath.row;
  //  NSInteger numsections = [tableView numberOfSections];
  NSInteger numrows = [tableView numberOfRowsInSection:section];
  
  NSString *bgName = nil;
  UIImageView *backgroundView = nil;
  if (numrows == 1 && row == 0) {
    // single row
    bgName = selected ? @"grouped_full_cell_highlighted.png" : @"grouped_full_cell.png";
  } else if (numrows > 1 && row == 0) {
    // first row
    bgName = selected ? @"grouped_top_cell_highlighted.png" : @"grouped_top_cell.png";
  } else if (numrows > 1 && row == (numrows - 1)) {
    // last row
    bgName = selected ? @"grouped_bottom_cell_highlighted.png" : @"grouped_bottom_cell.png";
  } else {
    // middle row
    bgName = selected ? @"grouped_middle_cell_highlighted.png" : @"grouped_middle_cell.png";
  }
  backgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:bgName] stretchableImageWithLeftCapWidth:6 topCapHeight:6]] autorelease];
  backgroundView.autoresizingMask = ~UIViewAutoresizingNone;
  return backgroundView;
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Done" withTarget:self action:@selector(dismiss) width:60.0 height:30.0 buttonType:BarButtonTypeBlue];
  
  if (_listMode == ListModeView) {
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Edit" withTarget:self action:@selector(newList) width:60.0 height:30.0 buttonType:BarButtonTypeNormal];
  } else {
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Add" withTarget:self action:@selector(newList) width:60.0 height:30.0 buttonType:BarButtonTypeNormal];
  }
  _navTitleLabel.text = @"My Food Lists";
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStyleGrouped andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  NSError *error;
  [[GANTracker sharedTracker] trackPageview:@"/list" withError:&error];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"list#load"];
  
  [self loadDataSource];
}

#pragma mark - DataSource
- (void)loadDataSource {
  [super loadDataSource];
  
  // 'sid' is just a UUID that the client creates
  // it is passed to the server when syncing/sharing is ready
  // [NSString stringFromUUID];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"SELECT * FROM lists l JOIN lists_places lp ON l.sid = lp.list_sid ORDER BY timestamp DESC", nil];
    NSMutableArray *lists = [NSMutableArray arrayWithCapacity:1];
    for (EGODatabaseRow *row in res) {
      [lists addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        [row stringForColumn:@"sid"],
                        @"sid",
                        [row stringForColumn:@"name"],
                        @"name",
                        [NSDate dateWithTimeIntervalSince1970:[row doubleForColumn:@"timestamp"]],
                        @"timestamp",
                        nil]];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [self dataSourceShouldLoadObjects:lists];
    });
  });
  
}

- (void)dataSourceShouldLoadObjects:(id)objects {
  //
  // PREPARE DATASOURCE
  //
  
  BOOL isReload = YES;
  BOOL tableViewCellShouldAnimate = NO;
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

- (void)dataSourceDidLoad {
  [super dataSourceDidLoad];
}

#pragma mark - Actions
- (void)edit {
  
}

- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)newList {
  
}

#pragma mark - TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Class cellClass = [self cellClassAtIndexPath:indexPath];
  return [cellClass rowHeight];
}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *object = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  [cell fillCellWithObject:object];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  Class cellClass = [self cellClassAtIndexPath:indexPath];
  id cell = nil;
  NSString *reuseIdentifier = [cellClass reuseIdentifier];
  
  cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
    [_cellCache addObject:cell];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSDictionary *object = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  SavedViewController *svc = [[SavedViewController alloc] initWithSid:[object objectForKey:@"sid"] andListName:[object objectForKey:@"name"]];
  [self.navigationController pushViewController:svc animated:YES];
  [svc release];
}

- (Class)cellClassAtIndexPath:(NSIndexPath *)indexPath {
  return [ListCell class];
}

@end
