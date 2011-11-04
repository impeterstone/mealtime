//
//  PlaceCell.m
//  MealTime
//
//  Created by Peter Shih on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaceCell.h"
#import "PSScrapeCenter.h"
#import "ASIHTTPRequest.h"
#import "PSNetworkQueue.h"
#import "PSDataCenter.h"
#import "PSDatabaseCenter.h"
#import "PSStarView.h"
#import "PSLocationCenter.h"

@implementation PlaceCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _place = nil;
    
    // Photo
    _photoView = [[PSURLCacheImageView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.width, [[self class] rowHeight])];
    _photoView.shouldAnimate = isMultitaskingSupported();
    _photoView.contentMode = UIViewContentModeScaleAspectFill;
    
    // Disclosure
    _disclosureView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure_indicator_white_bordered.png"]];
    _disclosureView.contentMode = UIViewContentModeCenter;
    _disclosureView.alpha = 0.8;
    
    // Labels
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.textAlignment = UITextAlignmentLeft;
    _nameLabel.font = [PSStyleSheet fontForStyle:@"placeTitle"];
    _nameLabel.textColor = [PSStyleSheet textColorForStyle:@"placeTitle"];
    _nameLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"placeTitle"];
    _nameLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"placeTitle"];
    
    _distanceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _distanceLabel.backgroundColor = [UIColor clearColor];
    _distanceLabel.textAlignment = UITextAlignmentRight;
    _distanceLabel.font = [PSStyleSheet fontForStyle:@"placeDistance"];
    _distanceLabel.textColor = [PSStyleSheet textColorForStyle:@"placeDistance"];
    _distanceLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"placeDistance"];
    _distanceLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"placeDistance"];
    
    _categoryLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _categoryLabel.backgroundColor = [UIColor clearColor];
    _categoryLabel.textAlignment = UITextAlignmentLeft;
    _categoryLabel.font = [PSStyleSheet fontForStyle:@"placeCategory"];
    _categoryLabel.textColor = [PSStyleSheet textColorForStyle:@"placeCategory"];
    _categoryLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"placeCategory"];
    _categoryLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"placeCategory"];

    _priceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _priceLabel.backgroundColor = [UIColor clearColor];
    _priceLabel.textAlignment = UITextAlignmentRight;
    _priceLabel.font = [PSStyleSheet fontForStyle:@"placePrice"];
    _priceLabel.textColor = [PSStyleSheet textColorForStyle:@"placePrice"];
    _priceLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"placePrice"];
    _priceLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"placePrice"];
    
    // Ribbon    
    _ribbonView = [[UIView alloc] initWithFrame:CGRectMake(self.contentView.width - 90, MARGIN_Y * 2, 90, 24)];
    
    UIImageView *ribbonImageView = [[[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"ribbon.png" withLeftCapWidth:34 topCapWidth:0]] autorelease];
    ribbonImageView.autoresizingMask = ~UIViewAutoresizingNone;
    ribbonImageView.frame = _ribbonView.bounds;
    
    _ribbonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _ribbonView.width - MARGIN_X, _ribbonView.height)];
    _ribbonLabel.backgroundColor = [UIColor clearColor];
    _ribbonLabel.textAlignment = UITextAlignmentRight;
    _ribbonLabel.font = [PSStyleSheet fontForStyle:@"placeRibbon"];
    _ribbonLabel.textColor = [PSStyleSheet textColorForStyle:@"placeRibbon"];
    _ribbonLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"placeRibbon"];
    _ribbonLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"placeRibbon"];
    _ribbonLabel.autoresizingMask = ~UIViewAutoresizingNone;
    
    [_ribbonView addSubview:ribbonImageView];
    [_ribbonView addSubview:_ribbonLabel];
    _ribbonView.alpha = 0.0;
    
    _starView = [[PSStarView alloc] initWithFrame:CGRectMake(MARGIN_X, MARGIN_Y * 2, _starView.width, _starView.height)];
    
    // Add subviews
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_disclosureView];
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_distanceLabel];
    [self.contentView addSubview:_categoryLabel];
    [self.contentView addSubview:_priceLabel];
    [self.contentView addSubview:_ribbonView];
    [self.contentView addSubview:_starView];
  }
  return self;
}

- (void)dealloc
{
  RELEASE_SAFELY(_starView);
  RELEASE_SAFELY(_ribbonView);
  RELEASE_SAFELY(_ribbonLabel);
  RELEASE_SAFELY(_categoryLabel);
  RELEASE_SAFELY(_priceLabel);
  RELEASE_SAFELY(_distanceLabel);
  RELEASE_SAFELY(_nameLabel);
  RELEASE_SAFELY(_disclosureView);
  RELEASE_SAFELY(_photoView);
  [super dealloc];
}

- (void)setShouldAnimate:(NSNumber *)shouldAnimate {
  [super setShouldAnimate:shouldAnimate];
  _photoView.shouldAnimate = _cellShouldAnimate && isMultitaskingSupported();
}

#pragma mark - Layout
- (void)prepareForReuse
{
  [super prepareForReuse];
  _ribbonLabel.text = nil;
  _nameLabel.text = nil;
  _distanceLabel.text = nil;
  _categoryLabel.text = nil;
  _priceLabel.text = nil;
  _photoView.image = nil;
  _photoView.urlPath = nil;
  _place = nil;
  _ribbonView.alpha = 0.0;
  [_starView setRating:0.0];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  _disclosureView.frame = CGRectMake(self.contentView.width - _disclosureView.width - MARGIN_X, 0, _disclosureView.width, self.contentView.height);
  
  // Labels
  CGFloat top = self.contentView.height - 40 - MARGIN_Y;
  CGFloat left = MARGIN_X;
  CGFloat textWidth = self.contentView.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
  // Line 1
  desiredSize = [UILabel sizeForText:_priceLabel.text width:textWidth font:_priceLabel.font numberOfLines:_priceLabel.numberOfLines lineBreakMode:_priceLabel.lineBreakMode];
  _priceLabel.width = desiredSize.width;
  _priceLabel.height = desiredSize.height;
  _priceLabel.top = top;
  _priceLabel.left = self.contentView.width - _priceLabel.width - MARGIN_X;
  
  desiredSize = [UILabel sizeForText:_nameLabel.text width:(textWidth - _priceLabel.width - MARGIN_X) font:_nameLabel.font numberOfLines:_nameLabel.numberOfLines lineBreakMode:_nameLabel.lineBreakMode];
  _nameLabel.width = desiredSize.width;
  _nameLabel.height = desiredSize.height;
  _nameLabel.top = top;
  _nameLabel.left = left;
  
  top += 20;
    
  // Line 2
  desiredSize = [UILabel sizeForText:_distanceLabel.text width:textWidth font:_distanceLabel.font numberOfLines:_distanceLabel.numberOfLines lineBreakMode:_distanceLabel.lineBreakMode];
  _distanceLabel.width = desiredSize.width;
  _distanceLabel.height = desiredSize.height;
  _distanceLabel.top = top;
  _distanceLabel.left = self.contentView.width - _distanceLabel.width - MARGIN_X;
  
  desiredSize = [UILabel sizeForText:_categoryLabel.text width:(textWidth - _distanceLabel.width - MARGIN_X) font:_categoryLabel.font numberOfLines:_categoryLabel.numberOfLines lineBreakMode:_categoryLabel.lineBreakMode];
  _categoryLabel.width = desiredSize.width;
  _categoryLabel.height = desiredSize.height;
  _categoryLabel.top = top;
  _categoryLabel.left = left;
;
  
  // Add Gradient Overlay
//  [_photoView addGradientLayer];
  [_photoView addGradientLayerWithColors:[NSArray arrayWithObjects:
                                          (id)[RGBACOLOR(0, 0, 0, 0.70) CGColor],
                                          (id)[RGBACOLOR(0, 0, 0, 0.40) CGColor],
                                          (id)[RGBACOLOR(0, 0, 0, 0.15) CGColor],
                                          (id)[RGBACOLOR(0, 0, 0, 0.10) CGColor],
                                          (id)[RGBACOLOR(0, 0, 0, 0.20) CGColor],
                                          (id)[RGBACOLOR(0, 0, 0, 0.40) CGColor],
                                          (id)[RGBACOLOR(0, 0, 0, 0.80) CGColor],
                                          (id)[RGBACOLOR(0, 0, 0, 1.00) CGColor],
                                          nil]
                            andLocations:[NSArray arrayWithObjects:
                                          [NSNumber numberWithFloat:0.0],
                                          [NSNumber numberWithFloat:0.15],
                                          [NSNumber numberWithFloat:0.3],
                                          [NSNumber numberWithFloat:0.45],
                                          [NSNumber numberWithFloat:0.7],
                                          [NSNumber numberWithFloat:0.80],
                                          [NSNumber numberWithFloat:0.99],
                                          [NSNumber numberWithFloat:1.0],
                                          nil]];
}

#pragma mark - Fill and Height
+ (CGFloat)rowHeight {
  if (isDeviceIPad()) {
    return 320.0;
  } else {
    return 160.0;
  }
}

- (void)fillCellWithObject:(id)object
{
  NSMutableDictionary *place = (NSMutableDictionary *)object;
  _place = place;
  
  _photoView.urlPath = [place objectForKey:@"cover_photo"];
  [_photoView loadImageAndDownload:YES];
  
//  _ribbonLabel.text = [[place objectForKey:@"numReviews"] notNil] ? [NSString stringWithFormat:@"%@ mentions", [_place objectForKey:@"numReviews"]] : @"No Mentions";
  
  // Show highly rated ribbon
//  DLog(@"score: %g", [[place objectForKey:@"score"] doubleValue]);

  if ([[place objectForKey:@"review_count"] integerValue] > HIGHLY_RATED_REVIEWS && [[place objectForKey:@"rating"] doubleValue] > HIGHLY_RATED_RATING) {
    _ribbonLabel.text = @"Highly Rated";
    _ribbonView.alpha = 1.0;
  } else {
    _ribbonView.alpha = 0.0;
  }
  
  _nameLabel.text = [place objectForKey:@"name"];
  
//  if ([place objectForKey:@"cdistance"]) {
//    _distanceLabel.text = [NSString stringWithFormat:@"%@ mi", [place objectForKey:@"cdistance"]];
//  } else {
//    _distanceLabel.text = [NSString stringWithFormat:@"%@ mi", [place objectForKey:@"distance"]];
//  }
  
  _categoryLabel.text = [[place objectForKey:@"categories"] notNil] ? [place objectForKey:@"categories"] : @"Unknown Category";
  _priceLabel.text = [[place objectForKey:@"price"] notNil] ? [place objectForKey:@"price"] : nil;
  
  CGFloat lat = RADIANS([[place objectForKey:@"latitude"] floatValue]);
  CGFloat lng = RADIANS([[place objectForKey:@"longitude"] floatValue]);
  CGFloat curLat = RADIANS([[PSLocationCenter defaultCenter] latitude]);
  CGFloat curLng = RADIANS([[PSLocationCenter defaultCenter] longitude]);
  CGFloat distance = acos(sin(lat) * sin(curLat) + cos(lat) * cos(curLat) * cos(curLng - lng)) * 3959;
  
  _distanceLabel.text = [NSString stringWithFormat:@"%.1f mi", distance];
  
  
  // This is a fix for rating sometimes not being a number
  if ([[place objectForKey:@"rating"] respondsToSelector:@selector(floatValue)]) {
    [_starView setRating:[[place objectForKey:@"rating"] floatValue]];
  } else {
    [_starView setRating:0.0];
  }
  
//  _ribbonLabel.text = nil;
//  _ribbonLabel.text = [NSString stringWithFormat:@"%@%% %@ ", [place objectForKey:@"score"], freshOrRotten];
//  _ribbonLabel.text = [[place objectForKey:@"numreviews"] notNil] ? [NSString stringWithFormat:@"%@ reviews ", [place objectForKey:@"numreviews"]] : @"0 reviews ";
}

@end
