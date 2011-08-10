//
//  DetailViewController.m
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "ProductViewController.h"
#import "BusinessViewController.h"

@implementation DetailViewController

@synthesize placeMeta = _placeMeta;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  return self;
}

- (void)dealloc
{
  RELEASE_SAFELY(_businessViewController);
  RELEASE_SAFELY(_productViewController);
  RELEASE_SAFELY(_placeMeta);
  [super dealloc];
}

#pragma mark - View
- (void)loadView
{
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  // Populate the place header
  NSDictionary *placeMetaData = [self.placeMeta objectForKey:@"metadata"];
  if (placeMetaData) {
    _navTitleLabel.text = [placeMetaData objectForKey:@"name"];
  }
  
  // Product
  _productViewController = [[ProductViewController alloc] initWithNibName:nil bundle:nil];
  _productViewController.view.frame = self.view.bounds;
  [self.view addSubview:_productViewController.view];
  
  // Business Info
  _businessViewController = [[BusinessViewController alloc] initWithNibName:nil bundle:nil];
  _businessViewController.view.frame = self.view.bounds;
}

#pragma mark - State Machine
- (void)loadDataSource {
  [super loadDataSource];
}

- (void)dataSourceDidLoad {
  [super dataSourceDidLoad];
}

@end
