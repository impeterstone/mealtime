//
//  SavedViewController.h
//  MealTime
//
//  Created by Peter Shih on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTableViewController.h"

@interface SavedViewController : PSTableViewController <UIActionSheetDelegate> {
  NSString *_sid;
  NSString *_listName;
  NSString *_sortOrder;
  NSString *_sortDirection;
  
  UIView *_tabView;
}

@property (nonatomic, retain) NSString *sortOrder;
@property (nonatomic, retain) NSString *sortDirection;

- (id)initWithSid:(NSString *)sid andListName:(NSString *)listName;

@end
