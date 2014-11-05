//
//  LocationTableCell.m
//  ShareMySpot
//
//  Created by chris on 2/19/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import "LocationTableCell.h"

@implementation LocationTableCell

@synthesize nameLabel = _nameLabel;
@synthesize textLabel = _textLabel;
@synthesize timeLabel = _timeLabel;
@synthesize iconImage = _iconImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
