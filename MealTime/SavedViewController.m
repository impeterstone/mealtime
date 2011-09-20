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

@interface SavedViewController (Private)

- (void)setupToolbar;
- (void)share;
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
  RELEASE_SAFELY(_toolbar);
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)dealloc
{
  RELEASE_SAFELY(_toolbar);
  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_darkwood.jpg"]] autorelease];
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
  self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Done" withTarget:self action:@selector(dismiss) width:60.0 height:30.0 buttonType:BarButtonTypeBlue];
  _navTitleLabel.text = @"Starred Places";
  
  // Nullview
  [_nullView setLoadingTitle:@"Loading..."];
  [_nullView setLoadingSubtitle:@"Finding Starred Places"];
  [_nullView setEmptyTitle:@"No Starred Places"];
  [_nullView setEmptySubtitle:@"You haven't starred any places yet. To star a place tap on the star while viewing a place."];
  [_nullView setErrorTitle:@"Something Bad Happened"];
  [_nullView setErrorSubtitle:@"Hmm... Something didn't work.\nIt might be the network connection.\nTrying again might fix it."];
  [_nullView setEmptyImage:[UIImage imageNamed:@"nullview_empty.png"]];
  [_nullView setErrorImage:[UIImage imageNamed:@"nullview_error.png"]];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  if (isDeviceIPad()) {
    _tableView.rowHeight = 320.0;
  } else {
    _tableView.rowHeight = 160.0;
  }
  
  // Toolbar
  [self setupToolbar];
}

- (void)setupToolbar {
  _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44.0)];
  NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:1];
  
  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
  [toolbarItems addObject:[UIBarButtonItem barButtonWithTitle:@"Export via Email" withTarget:self action:@selector(share) width:300 height:30 buttonType:BarButtonTypeGray style:@"detailToolbarButton"]];
  [toolbarItems addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
  
  [_toolbar setItems:toolbarItems];
  [self setupFooterWithView:_toolbar];
}

- (void)share {
  if (![self dataIsAvailable]) {
    UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Whoops" message:@"Need something to export." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease];
    [av show];
    return;
  }
  
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
  [[PSMailCenter defaultCenter] controller:self sendMailTo:nil withSubject:@"MealTime: My Starred Places" andMessageBody:body];
}
                                           
- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - DataSource
- (void)loadDataSource {
  [super loadDataSource];
  
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSNumber *lat = [NSNumber numberWithFloat:[[PSLocationCenter defaultCenter] latitude]];
    NSNumber *lng = [NSNumber numberWithFloat:[[PSLocationCenter defaultCenter] longitude]];
    EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"SELECT *, distance(latitude, longitude, ?, ?) as cdistance FROM places WHERE saved = 1 ORDER BY cdistance ASC", lat, lng, nil];
    NSMutableArray *savedPlaces = [NSMutableArray arrayWithCapacity:1];
    for (EGODatabaseRow *row in res) {
      NSData *placeData = [row dataForColumn:@"data"];
      NSMutableDictionary *placeDict = [NSMutableDictionary dictionaryWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:placeData]];
      [placeDict setObject:[NSNumber numberWithDouble:[row doubleForColumn:@"cdistance"]] forKey:@"cdistance"];
      [savedPlaces addObject:placeDict];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [self dataSourceShouldLoadObjects:savedPlaces];
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

@end
