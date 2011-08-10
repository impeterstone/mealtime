//
//  DetailViewController.h
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSBaseViewController.h"

@class ProductViewController;
@class BusinessViewController;

@interface DetailViewController : PSBaseViewController {
  NSDictionary *_placeMeta;
  ProductViewController *_productViewController;
  BusinessViewController *_businessViewController;
}

@property (nonatomic, retain) NSDictionary *placeMeta;

@end
