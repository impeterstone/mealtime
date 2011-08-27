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

#define CELL_HEIGHT 160.0

@implementation PlaceCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _place = nil;
    
    // Photo
    _photoView = [[PSURLCacheImageView alloc] initWithFrame:CGRectZero];
    _photoView.shouldAnimate = NO;
    _photoView.delegate = self;
    _photoView.contentMode = UIViewContentModeScaleAspectFill;
    _photoView.placeholderImage = [UIImage imageNamed:@"place_placeholder.png"];
    
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
    _categoryLabel.textAlignment = UITextAlignmentRight;
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
    _ribbonLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _ribbonLabel.backgroundColor = [UIColor clearColor];
    _ribbonLabel.textAlignment = UITextAlignmentRight;
    _ribbonLabel.font = [PSStyleSheet fontForStyle:@"placeRibbon"];
    _ribbonLabel.textColor = [PSStyleSheet textColorForStyle:@"placeRibbon"];
    _ribbonLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"placeRibbon"];
    _ribbonLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"placeRibbon"];
    
    _ribbonView = [[UIView alloc] initWithFrame:CGRectZero];
    UIImageView *ribbonImageView = [[[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"ribbon.png" withLeftCapWidth:34 topCapWidth:0]] autorelease];
    ribbonImageView.autoresizingMask = ~UIViewAutoresizingNone;
    ribbonImageView.frame = _ribbonView.bounds;
    _ribbonLabel.autoresizingMask = ~UIViewAutoresizingNone;
    _ribbonLabel.frame = _ribbonView.bounds;
    [_ribbonView addSubview:ribbonImageView];
    [_ribbonView addSubview:_ribbonLabel];
    
    // Add subviews
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_disclosureView];
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_distanceLabel];
    [self.contentView addSubview:_categoryLabel];
    [self.contentView addSubview:_priceLabel];
    [self.contentView addSubview:_ribbonView];
  }
  return self;
}

- (void)dealloc
{
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
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  // Set Frames
  _photoView.frame = CGRectMake(0, 0, self.contentView.width, CELL_HEIGHT);
  _disclosureView.frame = CGRectMake(self.contentView.width - _disclosureView.width - MARGIN_X, 0, _disclosureView.width, self.contentView.height);
  _ribbonView.frame = CGRectMake(self.contentView.width - 80, 10, 80, 24);
  
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
  [_photoView addGradientLayer];
}

#pragma mark - Fill and Height
+ (CGFloat)rowHeight {
  return CELL_HEIGHT;
}

- (void)fillCellWithObject:(id)object
{
  NSMutableDictionary *place = (NSMutableDictionary *)object;
  _place = place;
  id src = [place objectForKey:@"src"];
  if (src) {
    if (src == [NSNull null]) src = nil;
    _photoView.urlPath = src;
    [_photoView loadImageAndDownload:YES];
  } else {
    [self fetchYelpCoverPhotoForPlace:place];
  }
  _nameLabel.text = [place objectForKey:@"name"];
  _distanceLabel.text = [NSString stringWithFormat:@"%@ mi", [place objectForKey:@"distance"]];
  _categoryLabel.text = [place objectForKey:@"category"];
  _priceLabel.text = [place objectForKey:@"price"];
  _ribbonLabel.text = [NSString stringWithFormat:@"%@ reviews ", [place objectForKey:@"reviews"]];
}

- (void)fetchYelpCoverPhotoForPlace:(NSMutableDictionary *)place {
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz_photos/%@?rpp=1", [place objectForKey:@"biz"]];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  
  [request setCompletionBlock:^{
    if ([[_place objectForKey:@"biz"] isEqualToString:[place objectForKey:@"biz"]]) {
      NSDictionary *photoDict = [[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:request.responseString];

      // Num Photos
      NSString *numPhotos = [photoDict objectForKey:@"numPhotos"];
      [place setObject:numPhotos forKey:@"numPhotos"];
      
      // Array of photos
      NSArray *photos = [photoDict objectForKey:@"photos"];
      if ([[photos lastObject] objectForKey:@"src"]) {
        [place setObject:[[photos lastObject] objectForKey:@"src"] forKey:@"src"];
      } else {
        [place setObject:[NSNull null] forKey:@"src"];
      }
      
      _photoView.urlPath = [[photos lastObject] objectForKey:@"src"];
      [_photoView loadImageAndDownload:YES];
    }
  }];
  
  [request setFailedBlock:^{
    
  }];
  [request startAsynchronous];
}
  
@end
