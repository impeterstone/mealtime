//
//  BusinessViewController.m
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BusinessViewController.h"

@implementation BusinessViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  return self;
}

- (void)dealloc
{
  [super dealloc];
}

#pragma mark - View
- (void)loadView
{
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  // Table
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

#pragma mark - State Machine
- (void)loadDataSource {
  [super loadDataSource];
}

- (void)dataSourceDidLoad {
  [super dataSourceDidLoad];
}

@end
