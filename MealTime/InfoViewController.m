//
//  InfoViewController.m
//  MealTime
//
//  Created by Peter Shih on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController (Private)

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

- (void)loadView {
  [super loadView];
  
  self.view.backgroundColor = [UIColor blackColor];
  self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Done" withTarget:self action:@selector(dismiss) width:60.0 height:30.0 buttonType:BarButtonTypeBlue];
  _navTitleLabel.text = @"MealTime";
  
  
//  UIImageView *logo = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"7ml_logo.png"]] autorelease];
//  logo.autoresizingMask = ~UIViewAutoresizingNone;
//  logo.center = self.view.center;
//  [self.view addSubview:logo];
}

- (void)dismiss {
  [self dismissModalViewControllerAnimated:YES];
}

@end
