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
#import "PSMailCenter.h"
#import "UIDevice-Hardware.h"
#import "Crittercism.h"
#import "PSTutorialViewController.h"

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

#pragma mark - Setup
- (void)setupTableFooter {
  NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
  
  UILabel *copyright = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 40)] autorelease];
  copyright.backgroundColor = [UIColor clearColor];
  copyright.textAlignment = UITextAlignmentCenter;
  copyright.numberOfLines = 0;
  copyright.text = [NSString stringWithFormat:@"© Copyright 2011 Seven Minute Labs, Inc.\nVersion %@", version];
  copyright.font = [PSStyleSheet fontForStyle:@"copyrightLabel"];
  copyright.textColor = [PSStyleSheet textColorForStyle:@"copyrightLabel"];
  copyright.shadowColor = [PSStyleSheet shadowColorForStyle:@"copyrightLabel"];
  copyright.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"copyrightLabel"];
  _tableView.tableFooterView = copyright;
}

#pragma mark - View
- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Done" withTarget:self action:@selector(dismiss) width:60.0 height:30.0 buttonType:BarButtonTypeBlue];
  _navTitleLabel.text = @"MealTime";
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStyleGrouped andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
  [self loadDataSource];
}

#pragma mark - DataSource
- (void)loadDataSource {
  [super loadDataSource];
  
  // First Section
  NSMutableArray *first = [NSMutableArray array];
  NSDictionary *comments = [NSDictionary dictionaryWithObjectsAndKeys:@"Send Feedback", @"title", nil];
  NSDictionary *sendlove = [NSDictionary dictionaryWithObjectsAndKeys:@"Send Love", @"title", nil];
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
  
  // Third Section
  NSMutableArray *third = [NSMutableArray array];
  NSDictionary *howtouse = [NSDictionary dictionaryWithObjectsAndKeys:@"How to use MealTime", @"title", nil];
  [third addObject:howtouse];
  [self.items addObject:third];
  
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
//  if (section == 0) {
//    return @"Like MealTime? Please help us spread the word!";
//  }
//  else {
//    return nil;
//  }
//}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    UILabel *header = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 30)] autorelease];
    header.backgroundColor = [UIColor clearColor];
    header.textAlignment = UITextAlignmentCenter;
    header.numberOfLines = 0;
    header.text = @"Like MealTime? Please help us spread the word!";
    header.font = [PSStyleSheet fontForStyle:@"groupedSectionHeader"];
    header.textColor = [PSStyleSheet textColorForStyle:@"groupedSectionHeader"];
    header.shadowColor = [PSStyleSheet shadowColorForStyle:@"groupedSectionHeader"];
    header.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"groupedSectionHeader"];
    return header;
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
    [cell setAccessoryView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure_indicator_white.png"]] autorelease]];
    [_cellCache addObject:cell];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSDictionary *object = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  if ([[object objectForKey:@"title"] isEqualToString:@"Tell a Friend"]) {
    [[PSMailCenter defaultCenter] controller:self sendMailTo:nil withSubject:@"Check Out MealTime for iPhone and iPad" andMessageBody:@"You should check out MealTime for iPhone and iPad. It helps you find ratings and photos of yummy food around you!<br/><br/><a href=\"http://bit.ly/mealtimeapp\">Click Here to Download</a>"];  }
  if ([[object objectForKey:@"title"] isEqualToString:@"Send Love"]) {
    UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Write a Review" message:@"Your love makes us work harder. Review this app." delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles:@"Review", nil] autorelease];
    av.tag = kAlertSendLove;
    [av show];
  }
  if ([[object objectForKey:@"title"] isEqualToString:@"Send Feedback"]) {
    [Crittercism showCrittercism:self];
    
//    [[PSMailCenter defaultCenter] controller:self sendMailTo:[NSArray arrayWithObject:@"feedback@sevenminutelabs.com"] withSubject:@"MealTime Comments & Suggestions" andMessageBody:[NSString stringWithFormat:@"<br/><br/>--- Please write above this line ---<br/>App Version: %@<br/>iOS Version: %@<br/>HW Model: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], [[UIDevice currentDevice] systemVersion], [[UIDevice currentDevice] platformString]]];
  }
  
  // Links
  if (indexPath.section == 1) {
    [self openLink:[object objectForKey:@"link"]];
  }
  
  // How to use
  if (indexPath.section == 2) {
    PSTutorialViewController *tvc = [[PSTutorialViewController alloc] initWithNibName:nil bundle:nil];
    tvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:tvc animated:YES];
    [tvc release];
  }
}

- (Class)cellClassAtIndexPath:(NSIndexPath *)indexPath {
  return [InfoCell class];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == alertView.cancelButtonIndex) return;
  
  if (alertView.tag == kAlertSendLove) {
    [Appirater rateApp];
  }
}

@end
