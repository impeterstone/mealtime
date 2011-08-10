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
    
    // Caption
    _captionView = [[UIView alloc] initWithFrame:CGRectZero];
    _captionView.backgroundColor = [UIColor clearColor];
    UIImageView *cbg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_caption.png"]] autorelease];
    cbg.frame = _captionView.bounds;
    cbg.autoresizingMask = ~UIViewAutoresizingNone;
    [_captionView addSubview:cbg];
    
    // Labels
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _priceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    _nameLabel.backgroundColor = [UIColor clearColor];
    _priceLabel.backgroundColor = [UIColor clearColor];
    
    _nameLabel.textAlignment = UITextAlignmentLeft;
    _priceLabel.textAlignment = UITextAlignmentRight;
    
    // Styling
    _nameLabel.font = [PSStyleSheet fontForStyle:@"cellTitle"];
    _priceLabel.font = [PSStyleSheet fontForStyle:@"cellPrice"];
    _nameLabel.textColor = [PSStyleSheet textColorForStyle:@"cellTitle"];
    _priceLabel.textColor = [PSStyleSheet textColorForStyle:@"cellPrice"];
    _nameLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"cellTitle"];
    _priceLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"cellPrice"];
    _nameLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"cellTitle"];
    _priceLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"cellPrice"];
    
    // Add subviews
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_captionView];
    
    // Caption subviews
    [_captionView addSubview:_nameLabel];
    [_captionView addSubview:_priceLabel];
  }
  return self;
}

- (void)dealloc
{
  RELEASE_SAFELY(_priceLabel);
  RELEASE_SAFELY(_nameLabel);
  RELEASE_SAFELY(_captionView);
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
  
  // Photo
  NSDictionary *metadata = [_product objectForKey:@"metadata"];
  if (metadata) {
    NSDictionary *picture = [metadata objectForKey:@"picture"];
    CGFloat width = [[picture objectForKey:@"width"] floatValue];
    CGFloat height = [[picture objectForKey:@"height"] floatValue];
    CGFloat scaledHeight = floorf(height / (width / self.contentView.width));
    _photoView.frame = CGRectMake(0, 0, self.contentView.width, scaledHeight);
  }
  
  // Caption
  _captionView.frame = CGRectMake(0, _photoView.bottom - 44, self.contentView.width, 44);
  
  // Caption Labels
  CGFloat top = MARGIN_Y;
  CGFloat left = MARGIN_X;
  CGFloat textWidth = _captionView.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
  desiredSize = [UILabel sizeForText:_priceLabel.text width:textWidth font:_priceLabel.font numberOfLines:_priceLabel.numberOfLines lineBreakMode:_priceLabel.lineBreakMode];
  _priceLabel.width = desiredSize.width;
  _priceLabel.height = desiredSize.height;
  _priceLabel.left = _captionView.width - _priceLabel.width - MARGIN_X;
  _priceLabel.top = floorf((_captionView.height - _priceLabel.height) / 2);
  
  desiredSize = [UILabel sizeForText:_nameLabel.text width:(textWidth - _priceLabel.width - MARGIN_X) font:_nameLabel.font numberOfLines:_nameLabel.numberOfLines lineBreakMode:_nameLabel.lineBreakMode];
  _nameLabel.width = desiredSize.width;
  _nameLabel.height = desiredSize.height;
  _nameLabel.left = left;
  _nameLabel.top = floorf((_captionView.height - _nameLabel.height) / 2);
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
    
    _nameLabel.text = [metadata objectForKey:@"name"];
    _priceLabel.text = [metadata objectForKey:@"price"];
  }
  
  _product = product;
}

@end
