//
//  PlaceCell.m
//  Spotlight
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaceCell.h"

#define CELL_HEIGHT 160.0

@implementation PlaceCell

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
    
    // Disclosure
    _disclosureView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure_indicator_white_bordered.png"]];
    _disclosureView.contentMode = UIViewContentModeCenter;
    _disclosureView.alpha = 0.8;
    
    // Labels
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _distanceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    _nameLabel.backgroundColor = [UIColor clearColor];
    _distanceLabel.backgroundColor = [UIColor clearColor];
    
    _nameLabel.textAlignment = UITextAlignmentLeft;
    _distanceLabel.textAlignment = UITextAlignmentRight;
    
    // Styling
    _nameLabel.font = [PSStyleSheet fontForStyle:@"cellTitle"];
    _distanceLabel.font = [PSStyleSheet fontForStyle:@"cellTitle"];
    _nameLabel.textColor = [PSStyleSheet textColorForStyle:@"cellTitle"];
    _distanceLabel.textColor = [PSStyleSheet textColorForStyle:@"cellTitle"];
    _nameLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"cellTitle"];
    _distanceLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"cellTitle"];
    _nameLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"cellTitle"];
    _distanceLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"cellTitle"];
    
    // Add subviews
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_disclosureView];
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_distanceLabel];
  }
  return self;
}

- (void)dealloc
{
  RELEASE_SAFELY(_distanceLabel);
  RELEASE_SAFELY(_nameLabel);
  RELEASE_SAFELY(_disclosureView);
  RELEASE_SAFELY(_photoView);
  [super dealloc];
}

#pragma mark - Layout
- (void)prepareForReuse
{
  [super prepareForReuse];
  _nameLabel.text = nil;
  _distanceLabel.text = nil;
  _photoView.image = nil;
  _photoView.urlPath = nil;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  // Set Frames
  _photoView.frame = CGRectMake(0, 0, self.contentView.width, CELL_HEIGHT);
  _disclosureView.frame = CGRectMake(self.contentView.width - _disclosureView.width - MARGIN_X, 0, _disclosureView.width, self.contentView.height);
  
  // Labels
  CGFloat top = self.contentView.height - 20 - MARGIN_Y;
  CGFloat left = MARGIN_X;
  CGFloat textWidth = self.contentView.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
  desiredSize = [UILabel sizeForText:_distanceLabel.text width:textWidth font:_distanceLabel.font numberOfLines:_distanceLabel.numberOfLines lineBreakMode:_distanceLabel.lineBreakMode];
  _distanceLabel.width = desiredSize.width;
  _distanceLabel.height = desiredSize.height;
  _distanceLabel.top = top;
  _distanceLabel.left = self.contentView.width - _distanceLabel.width - MARGIN_X;
  
  desiredSize = [UILabel sizeForText:_nameLabel.text width:(textWidth - _distanceLabel.width - MARGIN_X) font:_nameLabel.font numberOfLines:_nameLabel.numberOfLines lineBreakMode:_nameLabel.lineBreakMode];
  _nameLabel.width = desiredSize.width;
  _nameLabel.height = desiredSize.height;
  _nameLabel.top = top;
  _nameLabel.left = left;
  
  // Add Gradient Overlay
  [_photoView addGradientLayer];
}

#pragma mark - Fill and Height
+ (CGFloat)rowHeight {
  return CELL_HEIGHT;
}

- (void)fillCellWithObject:(id)object
{
  NSDictionary *place = (NSDictionary *)object;
  NSDictionary *metadata = [place objectForKey:@"metadata"];
  if (metadata) {
    _photoView.urlPath = [metadata objectForKey:@"picture"];
    [_photoView loadImageAndDownload:YES];
    
    _nameLabel.text = [metadata objectForKey:@"name"];
    _distanceLabel.text = @"0.54mi";
  }
}
  
@end
