//
//  NoteViewController.h
//  MealTime
//
//  Created by Peter Shih on 9/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSBaseViewController.h"
#import "PSTextView.h"

@interface NoteViewController : PSBaseViewController {
  NSString *_sid;
  PSTextView *_noteView;
}

- (id)initWithListSid:(NSString *)sid;
- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up;

@end
