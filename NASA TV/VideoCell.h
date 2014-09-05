//
//  VideoCell.h
//  NASA TV
//
//  Created by Pietro Rea on 7/14/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *playIcon;
@property (strong, nonatomic) IBOutlet UILabel *videoLabel;


@end
