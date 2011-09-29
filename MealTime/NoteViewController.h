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
  NSMutableDictionary *_place;
  PSTextView *_noteView;
}

- (id)initWithPlace:(NSDictionary *)place;
- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up;

@end
