//
//  ListViewController.h
//  MealTime
//
//  Created by Peter Shih on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTableViewController.h"

enum {
  ListModeView = 0,
  ListModeAdd = 1
};
typedef uint32_t ListMode;

@interface ListViewController : PSTableViewController {
  ListMode _listMode;
  NSString *_biz;
  NSMutableSet *_selectedLists;
}

- (id)initWithListMode:(ListMode)listMode;
- (id)initWithListMode:(ListMode)listMode andBiz:(NSString *)biz;

@end
