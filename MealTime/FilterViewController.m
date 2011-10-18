//
//  FilterViewController.m
//  MealTime
//
//  Created by Peter Shih on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FilterViewController.h"
#import "PSSearchField.h"

#define MARGIN_X 10.0
#define MARGIN_Y 10.0

@implementation FilterViewController

@synthesize delegate = _delegate;

- (id)initWithOptions:(NSDictionary *)options {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _options = [options copy];
    _filterChanged = NO;
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
}

- (void)dealloc {
  RELEASE_SAFELY(_options);
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

- (void)loadView {
  [super loadView];
  
  _curlView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 80)] autorelease];
  UITapGestureRecognizer *gr = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(done)] autorelease];
  gr.delegate = self;
  [_curlView addGestureRecognizer:gr];
  [self.view addSubview:_curlView];
  
  // Filter What?
//  _whatField = [[[PSSearchField alloc] initWithFrame:CGRectMake(10, 7, 300, 44) style:PSSearchFieldStyleCell] autorelease];
//  _whatField.delegate = self;
//  _whatField.autocorrectionType = UITextAutocorrectionTypeNo;
//  _whatField.returnKeyType = UIReturnKeyDone;
//  _whatField.placeholder = @"Filter by Name or Cuisine";
//  
//  // Left/Right View
//  _whatField.leftViewMode = UITextFieldViewModeAlways;
//  UIImageView *what = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_magnifier.png"]] autorelease];
//  what.contentMode = UIViewContentModeCenter;
//  _whatField.leftView = what;
//  _whatField.clearButtonMode = UITextFieldViewModeWhileEditing;
//  
//  [self.view addSubview:_whatField];
  
  // Sortby
  UISegmentedControl *sortby = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Smart", @"Distance", @"Rating", nil]] autorelease];
  sortby.segmentedControlStyle = UISegmentedControlStyleBordered;
  [sortby addTarget:self action:@selector(sortbyChanged:) forControlEvents:UIControlEventValueChanged];
  sortby.frame = CGRectMake(0, 0, 300, 44);
  [self.view addSubview:sortby];
  
  // Price
  UISegmentedControl *price = [[[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"All", @"$", @"$$", @"$$$", @"$$$$", nil]] autorelease];
  price.segmentedControlStyle = UISegmentedControlStyleBordered;
  [price addTarget:self action:@selector(priceChanged:) forControlEvents:UIControlEventValueChanged];
  price.frame = CGRectMake(0, 0, 300, 44);
  [self.view addSubview:price];
  
  // Open Now
  UIView *openNowView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 44)] autorelease];
  // bg
  UIImageView *onvbg = [[[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"grouped_full_cell.png" withLeftCapWidth:6 topCapWidth:6]] autorelease];
  onvbg.frame = openNowView.bounds;
  [openNowView addSubview:onvbg];
  
  // Switch
  UISwitch *openNowSwitch = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
  [openNowSwitch addTarget:self action:@selector(openNowChanged:) forControlEvents:UIControlEventValueChanged];
  openNowSwitch.left = openNowView.width -  openNowSwitch.width - 10;
  openNowSwitch.top = 9;
  [openNowView addSubview:openNowSwitch];
  
  // label
  UILabel *openNowLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  openNowLabel.frame = CGRectMake(10, 0, openNowView.width - openNowSwitch.width - 30, openNowView.height);
  openNowLabel.backgroundColor = [UIColor clearColor];
  openNowLabel.font = [PSStyleSheet fontForStyle:@"openNowLabel"];
  openNowLabel.textColor = [PSStyleSheet textColorForStyle:@"openNowLabel"];
  openNowLabel.text = @"Show Places Open Now";
  [openNowView addSubview:openNowLabel];
  [self.view addSubview:openNowView];
  
  // Highly Rated
  UIView *hrView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 44)] autorelease];
  // bg
  UIImageView *hrbg = [[[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"grouped_full_cell.png" withLeftCapWidth:6 topCapWidth:6]] autorelease];
  hrbg.frame = hrView.bounds;
  [hrView addSubview:hrbg];
  
  // Switch
  UISwitch *hrSwitch = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
  [hrSwitch addTarget:self action:@selector(highlyRatedChanged:) forControlEvents:UIControlEventValueChanged];
  hrSwitch.left = hrView.width - hrSwitch.width - 10;
  hrSwitch.top = 9;
  [hrView addSubview:hrSwitch];
  
  // label
  UILabel *hrLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  hrLabel.frame = CGRectMake(10, 0, hrView.width - hrSwitch.width - 30, hrView.height);
  hrLabel.backgroundColor = [UIColor clearColor];
  hrLabel.font = [PSStyleSheet fontForStyle:@"highlyRatedLabel"];
  hrLabel.textColor = [PSStyleSheet textColorForStyle:@"highlyRatedLabel"];
  hrLabel.text = @"Only Show Highly Rated";
  [hrView addSubview:hrLabel];
  [self.view addSubview:hrView];
  
  // Category
  UIButton *categoryButton = [UIButton buttonWithFrame:CGRectMake(0, 0, 300, 44) andStyle:@"filterDoneButton" target:self action:@selector(category)];
  [categoryButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_round_green.png" withLeftCapWidth:11 topCapWidth:22] forState:UIControlStateNormal];
  [self.view addSubview:categoryButton];
  _categoryButton = categoryButton;
  
  // Done Button
  UIButton *doneButton = [UIButton buttonWithFrame:CGRectMake(0, 0, 300, 44) andStyle:@"filterDoneButton" target:self action:@selector(done)];
  [doneButton setBackgroundImage:[UIImage stretchableImageNamed:@"button_round_blue.png" withLeftCapWidth:11 topCapWidth:22] forState:UIControlStateNormal];
  [doneButton setTitle:@"Apply Filters" forState:UIControlStateNormal];
  [self.view addSubview:doneButton];
  
  // Setup Default Selections
  sortby.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"filterSortBy"];
  price.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"filterPrice"];
  openNowSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"filterOpenNow"];
  hrSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"filterHighlyRated"];
  [categoryButton setTitle:[[NSUserDefaults standardUserDefaults] objectForKey:@"filterCategory"] forState:UIControlStateNormal];
//  _whatField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"filterWhat"];
  
  //
  // Layout subviews
  //
  CGFloat top = isDeviceIPad() ? 290 : 50;
  CGFloat left = isDeviceIPad() ? 234 : MARGIN_X;
  
  // Sort By Section
  UILabel *sbl = [UILabel labelWithText:@"Filter and Sort Results" style:@"filterSectionLabel"];
  sbl.top = top;
  sbl.left = left + 10;
  sbl.width = 300;
  sbl.height = 30.0;
  [self.view addSubview:sbl];
  
  top += sbl.height;
  
  // Fields
//  _whatField.top = top;
//  _whatField.left = left;
//  
//  top += _whatField.height + MARGIN_Y * 2;
  
  // Open Now
  openNowView.top = top;
  openNowView.left = left;
  
  top += openNowView.height + MARGIN_Y * 2;
  
  // Highly Rated
  hrView.top = top;
  hrView.left = left;
  
  top += hrView.height + MARGIN_Y * 2;
  
  sortby.top = top;
  sortby.left = left;
  
  top += sortby.height + MARGIN_Y * 2;
  
  price.top = top;
  price.left = left;

  top += price.height + MARGIN_Y * 2;
  
  // Category Button
  categoryButton.top = top;
  categoryButton.left = left;
  
  top += categoryButton.height + MARGIN_Y * 2;
  
  // Done Button
  doneButton.top = top;
  doneButton.left = left;
  
  [self updateState];
}

- (void)category {
  UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Filter by Category" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
  NSSet *categories = [_options objectForKey:@"categories"];
  if (categories && [categories count] > 0) {
    for (NSString *cat in [categories sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:nil ascending:YES]]]) {
      [as addButtonWithTitle:cat];
    }
    [as addButtonWithTitle:@"Cancel"];
    [as setCancelButtonIndex:[categories count]];
    [as showInView:self.view];
    [as autorelease];
  } else {
    return;
  }
}

- (void)done {
  // tell delegate
  if ((_filterChanged || _openNowChanged) && self.delegate && [self.delegate respondsToSelector:@selector(filter:didSelectWithOptions:reload:)]) {
    [self.delegate filter:self didSelectWithOptions:nil reload:_openNowChanged];
  }
  [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
//  if ([_whatField isFirstResponder]) return NO;
  
  if ([touch.view isEqual:_curlView]) {
    return YES;
  } else {
    return NO;
  }
}

#pragma mark - Segmented Value Changed
- (void)sortbyChanged:(UISegmentedControl *)segmentedControl {
  NSInteger currentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"filterSortBy"];
  if (currentIndex != segmentedControl.selectedSegmentIndex) {
    [[NSUserDefaults standardUserDefaults] setInteger:segmentedControl.selectedSegmentIndex forKey:@"filterSortBy"];
    _filterChanged = YES;
  }
}

- (void)priceChanged:(UISegmentedControl *)segmentedControl {
  NSInteger currentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"filterPrice"];
  if (currentIndex != segmentedControl.selectedSegmentIndex) {
    [[NSUserDefaults standardUserDefaults] setInteger:segmentedControl.selectedSegmentIndex forKey:@"filterPrice"];
    _filterChanged = YES;
  }
}

- (void)openNowChanged:(UISwitch *)aSwitch {
  BOOL currentValue = [[NSUserDefaults standardUserDefaults] boolForKey:@"filterOpenNow"];
  if (currentValue != aSwitch.on) {
    [[NSUserDefaults standardUserDefaults] setBool:aSwitch.on forKey:@"filterOpenNow"];
    _openNowChanged = YES;
  } else {
    _openNowChanged = NO;
  }
}

- (void)highlyRatedChanged:(UISwitch *)aSwitch {
  BOOL currentValue = [[NSUserDefaults standardUserDefaults] boolForKey:@"filterHighlyRated"];
  if (currentValue != aSwitch.on) {
    [[NSUserDefaults standardUserDefaults] setBool:aSwitch.on forKey:@"filterHighlyRated"];
    _filterChanged = YES;
  }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  if (![textField isEditing]) {
    [textField becomeFirstResponder];
  }
  
  // Update What filter
  if (![textField.text isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"filterWhat"]]) {
      [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:@"filterWhat"];
    _filterChanged = YES;
  }
  
  [textField resignFirstResponder];
  
  return YES;
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == actionSheet.cancelButtonIndex) return;
  
  NSString *selectedCategory = nil;
  selectedCategory = [actionSheet buttonTitleAtIndex:buttonIndex];
  DLog(@"selected category: %@", selectedCategory);
  
  [[NSUserDefaults standardUserDefaults] setObject:selectedCategory forKey:@"filterCategory"];
  [_categoryButton setTitle:selectedCategory forState:UIControlStateNormal];
  _filterChanged = YES;
}

#pragma mark - State Machine
- (BOOL)dataIsAvailable {
  return YES;
}

@end
