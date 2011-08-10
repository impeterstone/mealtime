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
    
    _nameLabel.font = TITLE_FONT;
    _distanceLabel.font = TITLE_FONT;
    
    _nameLabel.textColor = [UIColor whiteColor];
    _distanceLabel.textColor = [UIColor whiteColor];
    
    _nameLabel.textAlignment = UITextAlignmentLeft;
    _distanceLabel.textAlignment = UITextAlignmentRight;
    
    _nameLabel.shadowColor = [UIColor blackColor];
    _nameLabel.shadowOffset = CGSizeMake(0, -1);
    
    _distanceLabel.shadowColor = [UIColor blackColor];
    _distanceLabel.shadowOffset = CGSizeMake(0, -1);
    
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
  if (![[[_photoView.layer sublayers] lastObject] isKindOfClass:[CAGradientLayer class]]) {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = _photoView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor clearColor] CGColor], (id)[RGBACOLOR(0, 0, 0, 0.9) CGColor], (id)[RGBACOLOR(0, 0, 0, 1.0) CGColor], nil];
    gradient.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.6], [NSNumber numberWithFloat:0.99], [NSNumber numberWithFloat:1.0], nil];
    [_photoView.layer addSublayer:gradient];
  }
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
