//
//  LocationTableCell.h
//  Snap Meet
//
//  Created by chris on 2/19/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocationTableCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;

@property (nonatomic, weak) IBOutlet UIImageView *iconImage;

@end
