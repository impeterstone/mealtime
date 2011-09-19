//
//  InfoViewController.m
//  MealTime
//
//  Created by Peter Shih on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InfoViewController.h"
#import "InfoCell.h"
#import "WebViewController.h"
#import "Appirater.h"

@interface InfoViewController (Private)

- (void)sendMailTo:(NSArray *)recipients withSubject:(NSString *)subject andMessageBody:(NSString *)messageBody;
- (void)openLink:(NSString *)link;
- (void)dismiss;

@end


@implementation InfoViewController

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

- (void)dealloc
{

  [super dealloc];
}

#pragma mark - View Config
- (UIView *)backgroundView {
  UIImageView *bg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]] autorelease];
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

#pragma mark - Setup
- (void)setupTableFooter {
  UILabel *copyright = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 20)] autorelease];
  copyright.backgroundColor = [UIColor clearColor];
  copyright.textAlignment = UITextAlignmentCenter;
  copyright.numberOfLines = 0;
  copyright.text = @"© Copyright 2011 Seven Minute Labs, Inc.";
  copyright.font = [PSStyleSheet fontForStyle:@"copyrightLabel"];
  copyright.textColor = [PSStyleSheet textColorForStyle:@"copyrightLabel"];
  copyright.shadowColor = [PSStyleSheet shadowColorForStyle:@"copyrightLabel"];
  copyright.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"copyrightLabel"];
  _tableView.tableFooterView = copyright;
}

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Done" withTarget:self action:@selector(dismiss) width:60.0 height:30.0 buttonType:BarButtonTypeBlue];
  _navTitleLabel.text = @"MealTime";
  
  
//  UIImageView *logo = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"7ml_logo.png"]] autorelease];
//  logo.autoresizingMask = ~UIViewAutoresizingNone;
//  logo.center = self.view.center;
//  [self.view addSubview:logo];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStyleGrouped andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  [self loadDataSource];
}

- (void)loadDataSource {
  [super loadDataSource];
  
  // First Section
  NSMutableArray *first = [NSMutableArray array];
  NSDictionary *comments = [NSDictionary dictionaryWithObjectsAndKeys:@"Comments? Suggestions?", @"title", nil];
  NSDictionary *sendlove = [NSDictionary dictionaryWithObjectsAndKeys:@"Love the app? Send us love!", @"title", nil];
  NSDictionary *share = [NSDictionary dictionaryWithObjectsAndKeys:@"Tell a Friend", @"title", nil];
  [first addObject:comments];
  [first addObject:sendlove];
  [first addObject:share];
  [self.items addObject:first];
  
  // Second Section
  NSMutableArray *second = [NSMutableArray array];
  NSDictionary *aboutsml = [NSDictionary dictionaryWithObjectsAndKeys:@"About Seven Minute Labs", @"title", @"http://sevenminutelabs.com/about", @"link", nil];
  NSDictionary *terms = [NSDictionary dictionaryWithObjectsAndKeys:@"Terms & Conditions", @"title", @"http://sevenminutelabs.com/terms", @"link", nil];
  NSDictionary *privacy = [NSDictionary dictionaryWithObjectsAndKeys:@"Privacy Policy", @"title", @"http://sevenminutelabs.com/privacy", @"link", nil];
  [second addObject:aboutsml];
  [second addObject:terms];
  [second addObject:privacy];
  [self.items addObject:second];
  
  [self.tableView reloadData];
}

- (void)dataSourceDidLoad {
  [super dataSourceDidLoad];
}

- (BOOL)dataIsAvailable {
  return YES; // force static data
}

- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

- (void)sendMailTo:(NSArray *)recipients withSubject:(NSString *)subject andMessageBody:(NSString *)messageBody {
  if([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    mailVC.mailComposeDelegate = self;
		mailVC.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    if (recipients) {
      [mailVC setToRecipients:recipients];
    }
		[mailVC setSubject:subject];
		[mailVC setMessageBody:messageBody isHTML:NO];
		[self presentModalViewController:mailVC animated:YES];
		[mailVC release];
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Mail Accounts Found", @"No Mail Accounts Found") message:NSLocalizedString(@"You must setup a Mail account before using this feature", @"You must setup a Mail account before using this feature") delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

- (void)openLink:(NSString *)link {
  WebViewController *wvc = [[WebViewController alloc] initWithURLString:link];
  [self.navigationController pushViewController:wvc animated:YES];
  [wvc release];
}

#pragma mark MFMailCompose
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
  [controller dismissModalViewControllerAnimated:YES];
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
  
  if ([[object objectForKey:@"title"] isEqualToString:@"Tell a Friend"]) {
    [self sendMailTo:nil withSubject:@"MealTime" andMessageBody:@"You should check out MealTime for the iPhone and iPad. It helps you find ratings and pictures of food at restaurants near you!\n\nhttp://itunes.apple.com/us/app/mealtime/id466579899?ls=1&mt=8"];
  }
  if ([[object objectForKey:@"title"] isEqualToString:@"Love the app? Send us love!"]) {
    [Appirater rateApp];
  }
  if ([[object objectForKey:@"title"] isEqualToString:@"Comments? Suggestions?"]) {
    [self sendMailTo:[NSArray arrayWithObject:@"feedback@sevenminutelabs.com"] withSubject:@"MealTime Comments & Suggestions" andMessageBody:nil];
  }
  
  // Links
  if (indexPath.section == 1) {
    [self openLink:[object objectForKey:@"link"]];
  }
}

- (Class)cellClassAtIndexPath:(NSIndexPath *)indexPath {
#warning fix this later
  return [InfoCell class];
}

@end
