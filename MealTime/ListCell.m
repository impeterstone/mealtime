//
//  ListCell.m
//  MealTime
//
//  Created by Peter Shih on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ListCell.h"

@implementation ListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.font = [PSStyleSheet fontForStyle:@"infoCellTitle"];
    self.textLabel.textColor = [PSStyleSheet textColorForStyle:@"infoCellTitle"];
    self.textLabel.shadowColor = [PSStyleSheet shadowColorForStyle:@"infoCellTitle"];
    self.textLabel.shadowOffset = [PSStyleSheet shadowOffsetForStyle:@"infoCellTitle"];
    
    self.detailTextLabel.backgroundColor = [UIColor clearColor];
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
  //  self.imageView.image = [UIImage imageNamed:@"icon_heart.png"];
  self.textLabel.text = [info objectForKey:@"name"];
//  self.detailTextLabel.text = [info objectForKey:@"subtitle"];
}

+ (CGFloat)rowHeight {
  return 44.0;
}

+ (CGFloat)rowHeightForObject:(id)object forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return 44.0;
}

@end
