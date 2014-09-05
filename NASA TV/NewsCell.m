//
//  NewsCell.m
//  NASA TV
//
//  Created by Pietro Rea on 7/3/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import "NewsCell.h"

@implementation NewsCell

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
