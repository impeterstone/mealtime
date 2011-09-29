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

- (void)dismiss;
- (void)newList;
- (void)editList;

@end

@implementation ListViewController

- (id)initWithListMode:(ListMode)listMode {
  return [self initWithListMode:listMode andBiz:nil];
}

- (id)initWithListMode:(ListMode)listMode andBiz:(NSString *)biz {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _listMode = listMode;
    _numLists = 0;
    if (biz) _biz = [biz copy];
    _selectedLists = [[NSMutableSet alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE_SAFELY(_biz);
  RELEASE_SAFELY(_selectedLists);
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

//  self.navigationItem.leftBarButtonItem = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"icon_plus.png"] withTarget:self action:@selector(newList) width:40 height:30 buttonType:BarButtonTypeNormal];
  // This should be an edit button
  self.navigationItem.leftBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Edit" withTarget:self action:@selector(editList) width:60.0 height:30.0 buttonType:BarButtonTypeNormal];
  _navTitleLabel.text = @"My Food Lists";
  
  // Nullview
  NSString *imgName = isDeviceIPad() ? @"nullview_empty_list_pad.png" : @"nullview_empty_list.png";
  [_nullView setLoadingTitle:@"Loading..."];
  [_nullView setLoadingSubtitle:@"Finding Your Food Lists"];
  [_nullView setEmptyImage:[UIImage imageNamed:imgName]];
  [_nullView setIsFullScreen:YES];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStyleGrouped andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  NSError *error;
  [[GANTracker sharedTracker] trackPageview:@"/list" withError:&error];
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"list#load"];
  
  [self loadDataSource];
}

- (void)setupTableHeader {
  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 64)] autorelease];
  UIButton *addButton = [UIButton buttonWithFrame:CGRectMake(10, 10, self.view.width - 20, 44) andStyle:@"listNewButton" target:self action:@selector(newList)];
  [addButton setBackgroundImage:[UIImage stretchableImageNamed:@"grouped_full_cell.png" withLeftCapWidth:6 topCapWidth:6] forState:UIControlStateNormal];
  [addButton setBackgroundImage:[UIImage stretchableImageNamed:@"grouped_full_cell_highlighted.png" withLeftCapWidth:6 topCapWidth:6] forState:UIControlStateHighlighted];
  [addButton setTitle:@"Create a New List" forState:UIControlStateNormal];
  [headerView addSubview:addButton];
  _tableView.tableHeaderView = headerView;
}

- (BOOL)dataIsAvailable {
  return YES;
}

#pragma mark - DataSource
- (void)loadDataSource {
  [super loadDataSource];
  
  // 'sid' is just a UUID that the client creates
  // it is passed to the server when syncing/sharing is ready
  // [NSString stringFromUUID];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // If mode is Add, find what lists this biz already belongs to
    NSMutableSet *existingListSids = nil;
    if (_listMode == ListModeAdd) {
      existingListSids = [NSMutableSet set];
      EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"SELECT list_sid FROM lists_places WHERE place_biz = ?", _biz, nil];
      for (EGODatabaseRow *row in res) {
        [existingListSids addObject:[row stringForColumn:@"list_sid"]];
      }
    }

    // Find all lists NON-EMPTY
//    EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"SELECT DISTINCT l.* FROM lists l JOIN lists_places lp ON l.sid = lp.list_sid ORDER BY timestamp DESC", nil];
    
    // Find all lists
    EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"SELECT * FROM lists ORDER BY position ASC", nil];
    NSMutableArray *lists = [[NSMutableArray arrayWithCapacity:1] retain];
    for (EGODatabaseRow *row in res) {
      NSDictionary *listDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                [row stringForColumn:@"sid"],
                                @"sid",
                                [row stringForColumn:@"name"],
                                @"name",
                                [NSNumber numberWithInt:[row intForColumn:@"position"]],
                                @"position",
                                [NSDate dateWithTimeIntervalSince1970:[row doubleForColumn:@"timestamp"]],
                                @"timestamp",
                                nil];
      [lists addObject:listDict];
      
      if (_listMode == ListModeAdd) {
        if ([existingListSids containsObject:[listDict objectForKey:@"sid"]]) {
          [_selectedLists addObject:listDict];
        }
      }
    }
    _numLists = [lists count];
    NSLog(@"list count: %d", _numLists);
    dispatch_async(dispatch_get_main_queue(), ^{
      [self dataSourceShouldLoadObjects:[NSMutableArray arrayWithObject:lists] shouldAnimate:YES];
      [lists release];
    });
  });
  
}

- (void)dataSourceDidLoad {
  [super dataSourceDidLoad];
}

#pragma mark - Actions
- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)editList {
  [(UIButton *)self.navigationItem.leftBarButtonItem.customView setSelected:!_tableView.editing];
  [_tableView setEditing:!_tableView.editing animated:YES];
}

- (void)newList {
  TSAlertView *alertView = [[[TSAlertView alloc] initWithTitle:@"New List" message:@"e.g. Favorite Pizza Joints" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil] autorelease];
  alertView.style = TSAlertViewStyleInput;
  alertView.buttonLayout = TSAlertViewButtonLayoutNormal;
  [alertView show];
}

#pragma mark - TableView
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 30)] autorelease];
    headerView.backgroundColor = [UIColor clearColor];
    UILabel *header = [[[UILabel alloc] initWithFrame:CGRectMake(20, 0, headerView.width - 40, headerView.height)] autorelease];
    header.backgroundColor = [UIColor clearColor];
    header.textAlignment = UITextAlignmentLeft;
    header.numberOfLines = 0;
    header.text = @"On My iPhone";
    header.font = [PSStyleSheet fontForStyle:@"listSectionHeader"];
    header.textColor = [PSStyleSheet textColorForStyle:@"listSectionHeader"];
    header.shadowColor = [PSStyleSheet shadowColorForStyle:@"listSectionHeader"];
    header.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"listSectionHeader"];
    [headerView addSubview:header];
    return headerView;
  } else {
    return nil;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return 30.0;
  } else {
    return 0.0;
  }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  if (section == 0) {
    UILabel *footer = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 30)] autorelease];
    footer.backgroundColor = [UIColor clearColor];
    footer.textAlignment = UITextAlignmentCenter;
    footer.numberOfLines = 0;
    footer.text = @"These lists are stored on your iPhone.";
    footer.font = [PSStyleSheet fontForStyle:@"groupedSectionFooter"];
    footer.textColor = [PSStyleSheet textColorForStyle:@"groupedSectionFooter"];
    footer.shadowColor = [PSStyleSheet shadowColorForStyle:@"groupedSectionFooter"];
    footer.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"groupedSectionFooter"];
    return footer;
  } else {
    return nil;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  if (section == 0) {
    return 30.0;
  } else {
    return 0.0;
  }
}

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
    if (_listMode == ListModeView) {
      [cell setAccessoryView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure_indicator_white.png"]] autorelease]];
//      [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    [_cellCache addObject:cell];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  
  NSDictionary *object = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  if (_listMode == ListModeView) {
    SavedViewController *svc = [[SavedViewController alloc] initWithSid:[object objectForKey:@"sid"] andListName:[object objectForKey:@"name"]];
    [self.navigationController pushViewController:svc animated:YES];
    [svc release];
  } else {
    // Toggle 'selected' state
    BOOL isSelected = ![self cellIsSelected:indexPath withObject:object];
    
    if (isSelected) {
      [_selectedLists addObject:object];
      [cell setAccessoryView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_check.png"]] autorelease]];
//      cell.accessoryType = UITableViewCellAccessoryCheckmark;
      
      // Update DB
      NSString *sid = [object objectForKey:@"sid"];
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO lists_places (list_sid, place_biz) VALUES (?, ?)", sid, _biz, nil];
    } else {
      [_selectedLists removeObject:object];
      [cell setAccessoryView:nil];
//      cell.accessoryType = UITableViewCellAccessoryNone;
      
      // Update DB
//      DELETE FROM lists_places WHERE list_sid = '85057A84-BFFB-4D42-8DBE-8BCEF351641B' AND place_biz = 'cyTlYYW6q8w8LBXwTZ-Ifw'
      NSString *sid = [object objectForKey:@"sid"];
      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"DELETE FROM lists_places WHERE list_sid = ? AND place_biz = ?", sid, _biz, nil];
    }
  }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
  
  if (_listMode == ListModeAdd) {
    NSDictionary *object = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if ([self cellIsSelected:indexPath withObject:object]) {
      [cell setAccessoryView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_check.png"]] autorelease]];
//      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
      [cell setAccessoryView:nil];
//      cell.accessoryType = UITableViewCellAccessoryNone;
    }
  }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // remove from database
    id object = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *sid = [object objectForKey:@"sid"];
    NSString *query = @"DELETE FROM lists WHERE sid = ?";
    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, sid, nil];
    
    // remove from dataSource
    [[self.items objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    // Check if the section is empty
    if ([[self.items objectAtIndex:indexPath.section] count] == 0) {
      [self.items removeObjectAtIndex:indexPath.section];
      [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    }
  }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
  id sourceObject = [[[self.items objectAtIndex:sourceIndexPath.section] objectAtIndex:sourceIndexPath.row] retain];
  id destinationObject = [[[self.items objectAtIndex:destinationIndexPath.section] objectAtIndex:destinationIndexPath.row] retain];
  
  [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"BEGIN TRANSACTION"];
  
  NSString *query = @"UPDATE lists SET position = ? WHERE sid = ?";
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, [destinationObject objectForKey:@"position"], [sourceObject objectForKey:@"sid"], nil];
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, [sourceObject objectForKey:@"position"], [destinationObject objectForKey:@"sid"], nil];
  
  [[[PSDatabaseCenter defaultCenter] database] executeQuery:@"COMMIT"];
  
  [[self.items objectAtIndex:sourceIndexPath.section] removeObjectAtIndex:sourceIndexPath.row];
  [[self.items objectAtIndex:destinationIndexPath.section] insertObject:sourceObject atIndex:destinationIndexPath.row];
  [sourceObject release];
  [destinationObject release];
  
}

- (Class)cellClassAtIndexPath:(NSIndexPath *)indexPath {
  return [ListCell class];
}

- (BOOL)cellIsSelected:(NSIndexPath *)indexPath withObject:(id)object {
  return [_selectedLists containsObject:object];
}

#pragma mark - AlertView
- (void)alertView:(TSAlertView *)alertView didDismissWithButtonIndex: (NSInteger) buttonIndex {
  if (buttonIndex == alertView.cancelButtonIndex) return;
  
  NSString *listName = alertView.inputTextField.text;
  if ([listName length] > 0) {
    // Create a list
    
    // Get the largest position from DB
    NSString *maxQuery = @"SELECT MAX(position) AS maxpos FROM lists";
    EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQuery:maxQuery];
    int newpos = [[[res rows] lastObject] intForColumn:@"maxpos"] + 1;
    
    NSNumber *position = [NSNumber numberWithInt:newpos];
    
    NSString *sid = [NSString stringFromUUID];
    NSNumber *timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    NSString *query = [NSString stringWithFormat:@"INSERT INTO lists (sid, name, position, timestamp) VALUES (?, ?, ?, ?)", maxQuery];
    [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, sid, listName, position, timestamp, nil];
    
    NSDictionary *listDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              sid,
                              @"sid",
                              listName,
                              @"name",
                              position,
                              @"position",
                              timestamp,
                              @"timestamp",
                              nil];
    
    if ([self.items count] == 0) {
      // no section, insert one
      [self.items addObject:[NSMutableArray array]];
      [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [[self.items objectAtIndex:0] addObject:listDict];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([[self.items objectAtIndex:0] count] - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
  } else {
    // error empty listName
  }
}

@end
