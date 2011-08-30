//
//  SearchTermController.h
//  PhotoTime
//
//  Created by Peter Shih on 7/12/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTableViewController.h"
#import "SearchTermDelegate.h"

@interface SearchTermController : PSTableViewController {
  UITapGestureRecognizer *_dismissGesture;
  id <SearchTermDelegate> _delegate;
}

@property (nonatomic, assign) id <SearchTermDelegate> delegate;

- (void)searchWithTerm:(NSString *)term;

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up;

@end
