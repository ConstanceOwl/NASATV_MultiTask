//
//  NewsCell.h
//  NASA TV
//
//  Created by Pietro Rea on 7/3/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* title;
@property (strong, nonatomic) IBOutlet UILabel* subtitle;
@property (strong, nonatomic) IBOutlet UILabel* dateLabel;

@end
