//
//  InfoCell.m
//  MealTime
//
//  Created by Peter Shih on 9/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InfoCell.h"

@implementation InfoCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
//    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    self.textLabel.font = [PSStyleSheet fontForStyle:@"infoCellTitle"];
    self.textLabel.textColor = [PSStyleSheet textColorForStyle:@"infoCellTitle"];
    self.textLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"infoCellTitle"];
    self.textLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"infoCellTitle"];
    
    self.detailTextLabel.font = [PSStyleSheet fontForStyle:@"infoCellSubtitle"];
    self.detailTextLabel.textColor = [PSStyleSheet textColorForStyle:@"infoCellSubtitle"];
    self.detailTextLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"infoCellSubtitle"];
    self.detailTextLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"infoCellSubtitle"];
  }
  return self;
}

#pragma mark - Fill and Height
- (void)fillCellWithObject:(id)object
{
  NSDictionary *info = (NSDictionary *)object;
  
  self.textLabel.text = [info objectForKey:@"title"];
  self.detailTextLabel.text = [info objectForKey:@"subtitle"];
}

+ (CGFloat)rowHeight {
  return 44.0;
}

+ (CGFloat)rowHeightForObject:(id)object forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return 44.0;
}

@end
