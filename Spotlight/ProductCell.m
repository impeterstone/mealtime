//
//  ProductCell.m
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProductCell.h"

@implementation ProductCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Photo
    _photoView = [[PSURLCacheImageView alloc] initWithFrame:CGRectZero];
    _photoView.shouldAnimate = NO;
    _photoView.delegate = self;
    
    // Add subviews
    [self.contentView addSubview:_photoView];
  }
  return self;
}

- (void)dealloc
{
  RELEASE_SAFELY(_photoView);
  [super dealloc];
}

#pragma mark - Layout
- (void)prepareForReuse
{
  [super prepareForReuse];
  _photoView.image = nil;
  _photoView.urlPath = nil;
  _product = nil;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  NSDictionary *metadata = [_product objectForKey:@"metadata"];
  if (metadata) {
    NSDictionary *picture = [metadata objectForKey:@"picture"];
    CGFloat width = [[picture objectForKey:@"width"] floatValue];
    CGFloat height = [[picture objectForKey:@"height"] floatValue];
    CGFloat scaledHeight = floorf(height / (width / self.contentView.width));
    _photoView.frame = CGRectMake(0, 0, self.contentView.width, scaledHeight);
  }
}

#pragma mark - Fill and Height
+ (CGFloat)rowHeightForObject:(id)object expanded:(BOOL)expanded forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  NSDictionary *product = (NSDictionary *)object;
  NSDictionary *metadata = [product objectForKey:@"metadata"];
  if (metadata) {
    NSDictionary *picture = [metadata objectForKey:@"picture"];
    CGFloat width = [[picture objectForKey:@"width"] floatValue];
    CGFloat height = [[picture objectForKey:@"height"] floatValue];
    CGFloat scaledHeight = floorf(height / (width / [[self class] rowWidthForInterfaceOrientation:interfaceOrientation]));
    return scaledHeight;
  } else {
    return 160.0;
  }
}

- (void)fillCellWithObject:(id)object
{
  NSDictionary *product = (NSDictionary *)object;
  NSDictionary *metadata = [product objectForKey:@"metadata"];
  if (metadata) {
    NSDictionary *picture = [metadata objectForKey:@"picture"];
    _photoView.urlPath = [picture objectForKey:@"source"];
    [_photoView loadImageAndDownload:YES];
    
//    _nameLabel.text = [metadata objectForKey:@"name"];
//    _distanceLabel.text = @"0.54mi";
  }
  
  _product = product;
}

@end
