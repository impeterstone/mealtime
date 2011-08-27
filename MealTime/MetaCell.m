//
//  MetaCell.m
//  MealTime
//
//  Created by Peter Shih on 8/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MetaCell.h"

@implementation MetaCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.textLabel.font = [PSStyleSheet fontForStyle:@"metaText"];
    self.textLabel.textColor = [PSStyleSheet textColorForStyle:@"metaText"];
    self.textLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"metaText"];
    self.textLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"metaText"];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  // Labels
  CGFloat top = MARGIN_Y;
  CGFloat left = MARGIN_X;
  CGFloat textWidth = self.contentView.width - MARGIN_X * 2;
  CGSize desiredSize = CGSizeZero;
  
  desiredSize = [UILabel sizeForText:self.textLabel.text width:textWidth font:self.textLabel.font numberOfLines:self.textLabel.numberOfLines lineBreakMode:self.textLabel.lineBreakMode];
  self.textLabel.width = desiredSize.width;
  self.textLabel.height = desiredSize.height;
  self.textLabel.top = top;
  self.textLabel.left = left;
}

#pragma mark - Fill and Height
- (void)fillCellWithObject:(id)object
{
  NSString *meta = (NSString *)object;
  
  self.textLabel.text = meta;
}

+ (CGFloat)rowHeightForObject:(id)object forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  NSString *meta = (NSString *)object;
  
  CGFloat desiredHeight = 0;
  CGSize desiredSize = CGSizeZero;
  CGFloat textWidth = [[self class] rowWidthForInterfaceOrientation:interfaceOrientation] - MARGIN_X * 2;

  // Top margin
  desiredHeight += MARGIN_Y;
  
  desiredSize = [UILabel sizeForText:meta width:textWidth font:[PSStyleSheet fontForStyle:@"metaText"] numberOfLines:0 lineBreakMode:UILineBreakModeWordWrap];
  desiredHeight += desiredSize.height;
  
  // Bottom margin
  desiredHeight += MARGIN_Y;
  
  return desiredHeight;
}

@end
