//
//  SavedViewController.h
//  MealTime
//
//  Created by Peter Shih on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTableViewController.h"

@interface SavedViewController : PSTableViewController {
  NSString *_sid;
  NSString *_listName;
  
  UIToolbar *_toolbar;
}

- (id)initWithSid:(NSString *)sid andListName:(NSString *)listName;

@end
