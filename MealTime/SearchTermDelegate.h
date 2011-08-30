//
//  SearchTermDelegate.h
//  PhotoTime
//
//  Created by Peter Shih on 7/13/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol SearchTermDelegate <NSObject>

@optional
- (void)searchTermSelected:(NSString *)searchTerm;
- (void)searchCancelled;

@end
