//
//  NoteViewController.m
//  MealTime
//
//  Created by Peter Shih on 9/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NoteViewController.h"
#import "PSDatabaseCenter.h"

@interface NoteViewController (Private)

- (void)dismiss;
@end

@implementation NoteViewController

- (id)initWithListSid:(NSString *)sid {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _sid = [sid copy];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  }
  return self;
}

- (void)viewDidUnload {
  [super viewDidUnload];
  
  RELEASE_SAFELY(_noteView);
}

- (void)dealloc {
  RELEASE_SAFELY(_sid);
  
  RELEASE_SAFELY(_noteView);
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
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

#pragma mark - View
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [_noteView becomeFirstResponder];
}

- (void)loadView {
  [super loadView];
  
  self.navigationItem.rightBarButtonItem = [UIBarButtonItem barButtonWithTitle:@"Done" withTarget:self action:@selector(dismiss) width:60.0 height:30.0 buttonType:BarButtonTypeBlue];
  
  _navTitleLabel.text = @"Notes";
  
  _noteView = [[PSTextView alloc] initWithFrame:self.view.bounds];
  _noteView.font = [PSStyleSheet fontForStyle:@"noteText"];
  _noteView.textColor = [PSStyleSheet textColorForStyle:@"noteText"];
  _noteView.autoresizingMask = self.view.autoresizingMask;
  _noteView.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:_noteView];
  
  // Set Note saved text
  NSString *query = @"SELECT notes FROM lists WHERE sid = ?";
  EGODatabaseResult *res = [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, _sid, nil];
  NSString *savedNote = [[[res rows] lastObject] stringForColumn:@"notes"];
  if ([savedNote length] > 0) {
    _noteView.text = savedNote;
  }
  
  [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"note#load"];
}

- (void)dismiss {
  // Save the note to the DB
  NSString *query = @"UPDATE lists SET notes = ? WHERE sid = ?";
  [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:query, _noteView.text, _sid, nil];
  
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIKeyboard
- (void)keyboardWillShow:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:YES];
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
  [self moveTextViewForKeyboard:aNotification up:NO]; 
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up {
  NSDictionary* userInfo = [aNotification userInfo];
  
  // Get animation info from userInfo
  NSTimeInterval animationDuration;
  UIViewAnimationCurve animationCurve;
  
  CGRect keyboardEndFrame;
  
  [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
  [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
  
  
  CGRect keyboardFrame = CGRectZero;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 30200
  // code for iOS below 3.2
  [[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardEndFrame];
  keyboardFrame = keyboardEndFrame;
#else
  // code for iOS 3.2 ++
  [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
  keyboardFrame = [UIScreen convertRect:keyboardEndFrame toView:self.view];
#endif  
  
  // Animate up or down
  //  NSString *dir = up ? @"up" : @"down";
  //  [UIView beginAnimations:dir context:nil];
  //  [UIView setAnimationDuration:animationDuration];
  //  [UIView setAnimationCurve:animationCurve];
  
  if (up) {
    self.view.height = self.view.height - keyboardFrame.size.height;
  } else {
    self.view.height = self.view.height + keyboardFrame.size.height;
  }
  
  //  [UIView commitAnimations];
}


@end
