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
    _photoView.shouldAnimate = YES;
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
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.textAlignment = UITextAlignmentLeft;
    _nameLabel.font = [PSStyleSheet fontForStyle:@"productTitle"];
    _nameLabel.textColor = [PSStyleSheet textColorForStyle:@"productTitle"];
    _nameLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"productTitle"];
    _nameLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"productTitle"];
    
    _priceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _priceLabel.backgroundColor = [UIColor clearColor];
    _priceLabel.textAlignment = UITextAlignmentRight;
    _priceLabel.font = [PSStyleSheet fontForStyle:@"productPrice"];
    _priceLabel.textColor = [PSStyleSheet textColorForStyle:@"productPrice"];
    _priceLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"productPrice"];
    _priceLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"productPrice"];
    
    _descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _descriptionLabel.backgroundColor = [UIColor clearColor];
    _descriptionLabel.textAlignment = UITextAlignmentRight;
    _descriptionLabel.font = [PSStyleSheet fontForStyle:@"productSubtitle"];
    _descriptionLabel.textColor = [PSStyleSheet textColorForStyle:@"productSubtitle"];
    _descriptionLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"productSubtitle"];
    _descriptionLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"productSubtitle"];
    
    // Add subviews
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_captionView];
    
    // Caption subviews
    [_captionView addSubview:_nameLabel];
    [_captionView addSubview:_priceLabel];
    [_captionView addSubview:_descriptionLabel];
  }
  return self;
}

- (void)dealloc
{
  RELEASE_SAFELY(_descriptionLabel);
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
  _nameLabel.text = nil;
  _descriptionLabel.text = nil;
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
  CGFloat textWidth = _captionView.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
  desiredSize = [UILabel sizeForText:_priceLabel.text width:textWidth font:_priceLabel.font numberOfLines:_priceLabel.numberOfLines lineBreakMode:_priceLabel.lineBreakMode];
  _priceLabel.width = desiredSize.width;
  _priceLabel.height = desiredSize.height;
  _priceLabel.left = _captionView.width - _priceLabel.width - MARGIN_X;
  _priceLabel.top = 0;
  
  desiredSize = [UILabel sizeForText:_nameLabel.text width:(textWidth - _priceLabel.width - MARGIN_X) font:_nameLabel.font numberOfLines:_nameLabel.numberOfLines lineBreakMode:_nameLabel.lineBreakMode];
  _nameLabel.width = desiredSize.width;
  _nameLabel.height = desiredSize.height;
  _nameLabel.left = MARGIN_X;
  _nameLabel.top = 0;
  
  desiredSize = [UILabel sizeForText:_descriptionLabel.text width:textWidth font:_descriptionLabel.font numberOfLines:_descriptionLabel.numberOfLines lineBreakMode:_descriptionLabel.lineBreakMode];
  _descriptionLabel.width = desiredSize.width;
  _descriptionLabel.height = desiredSize.height;
  _descriptionLabel.left = MARGIN_X + 2.0;
  _descriptionLabel.top = _nameLabel.bottom - 2.0;
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
    _priceLabel.text = [NSString stringWithFormat:@"$%@", [metadata objectForKey:@"price"]];
    _descriptionLabel.text = [metadata objectForKey:@"description"];
  }
  
  _product = product;
}

@end
