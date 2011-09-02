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

@implementation PlaceCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.clipsToBounds = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _place = nil;
    
    // Photo
    _photoView = [[PSImageArrayView alloc] initWithFrame:CGRectZero];
    _photoView.shouldAnimate = YES;
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
    
    _scoreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _scoreLabel.backgroundColor = [UIColor clearColor];
    _scoreLabel.textAlignment = UITextAlignmentCenter;
    _scoreLabel.font = [PSStyleSheet fontForStyle:@"placeScore"];
    _scoreLabel.textColor = [PSStyleSheet textColorForStyle:@"placeScore"];
    _scoreLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"placeScore"];
    _scoreLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"placeScore"];
    
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
    _ribbonView.alpha = 0.0;
    
    _scoreView = [[UIView alloc] initWithFrame:CGRectZero];
    UIImageView *scoreImageView = [[[UIImageView alloc] initWithImage:[UIImage stretchableImageNamed:@"bg_pill.png" withLeftCapWidth:12 topCapWidth:0]] autorelease];
    scoreImageView.autoresizingMask = ~UIViewAutoresizingNone;
    scoreImageView.frame = _scoreView.bounds;
    _scoreLabel.autoresizingMask = ~UIViewAutoresizingNone;
    _scoreLabel.frame = _scoreView.bounds;
    [_scoreView addSubview:scoreImageView];
    [_scoreView addSubview:_scoreLabel];
    
    // Add subviews
    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_disclosureView];
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_distanceLabel];
    [self.contentView addSubview:_categoryLabel];
    [self.contentView addSubview:_priceLabel];
    [self.contentView addSubview:_scoreView];
    [self.contentView addSubview:_ribbonView];
  }
  return self;
}

- (void)dealloc
{
  RELEASE_SAFELY(_ribbonView);
  RELEASE_SAFELY(_ribbonLabel);
  RELEASE_SAFELY(_scoreView);
  RELEASE_SAFELY(_scoreLabel);
  RELEASE_SAFELY(_categoryLabel);
  RELEASE_SAFELY(_priceLabel);
  RELEASE_SAFELY(_distanceLabel);
  RELEASE_SAFELY(_nameLabel);
  RELEASE_SAFELY(_disclosureView);
  RELEASE_SAFELY(_photoView);
  [super dealloc];
}

- (void)setShouldAnimate:(NSNumber *)shouldAnimate {
  _photoView.shouldAnimate = [shouldAnimate boolValue];
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
  _scoreLabel.text = nil;
  _photoView.image = nil;
  [_photoView unloadImageArray];
  _photoView.urlPath = nil;
  _place = nil;
  _ribbonView.alpha = 0.0;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  // Set Frames
  _photoView.frame = CGRectMake(0, 0, self.contentView.width, [[self class] rowHeight]);
  _disclosureView.frame = CGRectMake(self.contentView.width - _disclosureView.width - MARGIN_X, 0, _disclosureView.width, self.contentView.height);
  _ribbonView.frame = CGRectMake(self.contentView.width - 80, MARGIN_Y * 2, 80, 24);
  
  _scoreView.frame = CGRectMake(MARGIN_X, MARGIN_Y * 2, 36, 24);
  
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
  id srcArray = [place objectForKey:@"srcArray"];
  if (srcArray) {
    if (srcArray == [NSNull null]) {
      [_photoView unloadImageArray];
      _photoView.image = _photoView.placeholderImage;
    } else {
      _ribbonLabel.text = [[place objectForKey:@"numphotos"] notNil] ? [NSString stringWithFormat:@"%@ photos ", [place objectForKey:@"numphotos"]] : @"0 photos ";
      _photoView.urlPathArray = [srcArray valueForKey:@"src"];
      [_photoView loadImageArray];
      _ribbonView.alpha = 1.0;
    }
  } else {
    [self fetchYelpCoverPhotoForPlace:place];
  }
  
  _nameLabel.text = [place objectForKey:@"name"];
  _distanceLabel.text = [NSString stringWithFormat:@"%@ mi", [place objectForKey:@"distance"]];
  _categoryLabel.text = [[place objectForKey:@"category"] notNil] ? [place objectForKey:@"category"] : @"Unknown Category";
  _priceLabel.text = [[place objectForKey:@"price"] notNil] ? [place objectForKey:@"price"] : nil;
//  NSString *freshOrRotten = nil;
//  if ([[place objectForKey:@"score"] floatValue] < 50) {
//    freshOrRotten = @"rotten";
//  } else {
//    freshOrRotten = @"fresh";
//  }
  
  _scoreLabel.text = [NSString stringWithFormat:@"%@", [place objectForKey:@"score"]];
  
//  _ribbonLabel.text = nil;
//  _ribbonLabel.text = [NSString stringWithFormat:@"%@%% %@ ", [place objectForKey:@"score"], freshOrRotten];
//  _ribbonLabel.text = [[place objectForKey:@"numreviews"] notNil] ? [NSString stringWithFormat:@"%@ reviews ", [place objectForKey:@"numreviews"]] : @"0 reviews ";
}

- (void)fetchYelpCoverPhotoForPlace:(NSMutableDictionary *)place {
  NSString *yelpUrlString = [NSString stringWithFormat:@"http://lite.yelp.com/biz_photos/%@?rpp=3", [place objectForKey:@"biz"]];
  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
  
  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
  request.numberOfTimesToRetryOnTimeout = 1;
  [request setShouldContinueWhenAppEntersBackground:YES];
  [request setUserAgent:USER_AGENT];
  
  [request setCompletionBlock:^{
    // GCD
    NSString *responseString = [request.responseString copy];
    dispatch_async([PSScrapeCenter sharedQueue], ^{
      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapePhotosWithHTMLString:responseString] retain];
      [responseString release];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [place setObject:[response objectForKey:@"numphotos"] forKey:@"numphotos"];
        if ([[response objectForKey:@"numphotos"] integerValue] > 0) {
          // randomObject - causes too many reloading of pictures
          NSString *src = [[[response objectForKey:@"photos"] firstObject] objectForKey:@"src"];
          [place setObject:src forKey:@"src"];
          
          NSArray *srcArray = [response objectForKey:@"photos"];
          [place setObject:srcArray forKey:@"srcArray"];
          
          // Only update the image if cell hasn't been reused
          if ([[place objectForKey:@"biz"] isEqualToString:[_place objectForKey:@"biz"]]) {
            _photoView.urlPathArray = [srcArray valueForKey:@"src"];
            [_photoView loadImageArray];

            _ribbonLabel.text = [[place objectForKey:@"numphotos"] notNil] ? [NSString stringWithFormat:@"%@ photos ", [place objectForKey:@"numphotos"]] : @"0 photos ";
            _ribbonView.alpha = 1.0;
          }
        } else {
          if ([[place objectForKey:@"biz"] isEqualToString:[_place objectForKey:@"biz"]]) {
            [_photoView unloadImageArray];
            _photoView.image = _photoView.placeholderImage;
          }
          [place setObject:[NSNull null] forKey:@"src"];
          [place setObject:[NSNull null] forKey:@"srcArray"];
        }
        [response release];
      });
    });
  }];
  
  [request setFailedBlock:^{
    
  }];
  
  [[PSNetworkQueue sharedQueue] addOperation:request];
//  [request startAsynchronous];
}

//- (void)fetchYelpBizForPlace:(NSMutableDictionary *)place {
//  NSString *yelpUrlString = [NSString stringWithFormat:@"http://www.yelp.com/biz/%@?rpp=1&sort_by=relevance_desc", [_place objectForKey:@"biz"]];
//  NSURL *yelpUrl = [NSURL URLWithString:yelpUrlString];
//  
//  __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:yelpUrl];
//  [request setShouldContinueWhenAppEntersBackground:YES];
//  [request setUserAgent:USER_AGENT];
//  
//  // UserInfo
//  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
//  
//  [request setCompletionBlock:^{
//    // GCD
//    NSString *responseString = [request.responseString copy];
//    dispatch_async([PSScrapeCenter sharedQueue], ^{
//      NSDictionary *response = [[[PSScrapeCenter defaultCenter] scrapeBizWithHTMLString:responseString] retain];
//      [responseString release];
//      
//      // Save to DB
//      NSString *biz = [request.userInfo objectForKey:@"biz"];
//      NSString *requestType = @"biz";
//      NSString *requestData = [response JSONRepresentation];
//      [[[PSDatabaseCenter defaultCenter] database] executeQueryWithParameters:@"INSERT INTO requests (biz, type, data) VALUES (?, ?, ?)", biz, requestType, requestData, nil];
//      
//      dispatch_async(dispatch_get_main_queue(), ^{
//        if ([[response objectForKey:@"photos"] count] > 0) {
//          NSArray *srcArray = [[response objectForKey:@"photos"] subarrayWithRange:NSMakeRange(0, 4)];
//          [place setObject:srcArray forKey:@"srcArray"];
//          
//          // Only update the image if cell hasn't been reused
//          if ([[place objectForKey:@"biz"] isEqualToString:[_place objectForKey:@"biz"]]) {
//            
//          }
//          
//        }
//        
//        
//        
//        if ([[response objectForKey:@"numphotos"] integerValue] > 0) {
//          
//          // Only update the image if cell hasn't been reused
//          if ([[place objectForKey:@"biz"] isEqualToString:[_place objectForKey:@"biz"]]) {
//            _photoView.urlPathArray = [srcArray valueForKey:@"src"];
//            [_photoView loadImageArray];
//            
//            _ribbonLabel.text = [[place objectForKey:@"numphotos"] notNil] ? [NSString stringWithFormat:@"%@ photos ", [place objectForKey:@"numphotos"]] : @"0 photos ";
//            _ribbonView.alpha = 1.0;
//          }
//        } else {
//          if ([[place objectForKey:@"biz"] isEqualToString:[_place objectForKey:@"biz"]]) {
//            [_photoView unloadImageArray];
//            _photoView.image = _photoView.placeholderImage;
//          }
//          [place setObject:[NSNull null] forKey:@"src"];
//          [place setObject:[NSNull null] forKey:@"srcArray"];
//        }
//        [response release];
//      });
//    });
//  }];
//  
//  [request setFailedBlock:^{
//    
//  }];
//  
//  request.queuePriority = NSOperationQueuePriorityHigh;
//  [[PSNetworkQueue sharedQueue] addOperation:request];
//}
  
- (void)resumeAnimations {
  [_photoView resumeAnimations];
}

- (void)pauseAnimations {
  [_photoView pauseAnimations];
}
@end
