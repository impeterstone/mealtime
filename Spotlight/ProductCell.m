//
//  ProductCell.m
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProductCell.h"

@implementation ProductCell

@synthesize photoView = _photoView;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _desiredWidth = 0.0;
    _desiredHeight = 0.0;
    
    // Photo
    _photoView = [[PSURLCacheImageView alloc] initWithFrame:CGRectZero];
    _photoView.shouldAnimate = YES;
    _photoView.delegate = self;
    _photoView.contentMode = UIViewContentModeScaleAspectFill;
    
    // Caption
    _captionView = [[UIView alloc] initWithFrame:CGRectZero];
    _captionView.backgroundColor = [UIColor clearColor];
    UIImageView *cbg = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_caption.png"]] autorelease];
    cbg.frame = _captionView.bounds;
    cbg.autoresizingMask = ~UIViewAutoresizingNone;
    [_captionView addSubview:cbg];
    
    // Labels
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _nameLabel.numberOfLines = 0;
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
  _nameLabel.text = nil;
  _descriptionLabel.text = nil;
  _desiredWidth = 0.0;
  _desiredHeight = 0.0;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  // Photo
   _photoView.frame = CGRectMake(0, 0, self.contentView.width, self.contentView.width);
  
//  if (_photoView.image) {
//    NSLog(@"yes");
//    CGFloat scaledHeight = floorf(_photoView.image.size.height / (_photoView.image.size.width / self.contentView.width));
//    _photoView.frame = CGRectMake(0, 0, self.contentView.width, scaledHeight);
//  } else {
//    NSLog(@"no");
//   _photoView.frame = CGRectMake(0, 0, self.contentView.width, 320);
//  }

//  if (_photoView.image.size.height > 0) {
//    CGFloat scaledHeight = floorf(_desiredHeight / (_desiredWidth / self.contentView.width));
//    _photoView.frame = CGRectMake(0, 0, self.contentView.width, scaledHeight);
//  } else {
//    _photoView.frame = CGRectMake(0, 0, self.contentView.width, _desiredHeight);
//  }
  
  // Caption Labels
  CGFloat textWidth = self.contentView.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
//  desiredSize = [UILabel sizeForText:_priceLabel.text width:textWidth font:_priceLabel.font numberOfLines:_priceLabel.numberOfLines lineBreakMode:_priceLabel.lineBreakMode];
//  _priceLabel.width = desiredSize.width;
//  _priceLabel.height = desiredSize.height;
//  _priceLabel.left = _captionView.width - _priceLabel.width - MARGIN_X;
//  _priceLabel.top = 0;
  
  desiredSize = [UILabel sizeForText:_nameLabel.text width:textWidth font:_nameLabel.font numberOfLines:_nameLabel.numberOfLines lineBreakMode:_nameLabel.lineBreakMode];
  _nameLabel.width = desiredSize.width;
  _nameLabel.height = desiredSize.height;
  _nameLabel.left = MARGIN_X;
  _nameLabel.top = MARGIN_Y;
  
  // Adjust caption Size
  _captionView.frame = CGRectMake(0, _photoView.bottom - desiredSize.height - (MARGIN_Y * 2), self.contentView.width, desiredSize.height + (MARGIN_Y * 2));
  
//  desiredSize = [UILabel sizeForText:_descriptionLabel.text width:textWidth font:_descriptionLabel.font numberOfLines:_descriptionLabel.numberOfLines lineBreakMode:_descriptionLabel.lineBreakMode];
//  _descriptionLabel.width = desiredSize.width;
//  _descriptionLabel.height = desiredSize.height;
//  _descriptionLabel.left = MARGIN_X + 2.0;
//  _descriptionLabel.top = _nameLabel.bottom - 2.0;
}

#pragma mark - Fill and Height
- (void)fillCellWithObject:(id)object
{
  NSDictionary *product = (NSDictionary *)object;
  _nameLabel.text = [product objectForKey:@"alt"];
  _photoView.urlPath = [product objectForKey:@"src"];
  [_photoView loadImageAndDownload:YES];
}

@end
