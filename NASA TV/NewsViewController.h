//
//  NewsViewController.h
//  NASA TV
//
//  Created by Pietro Rea on 7/3/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsViewController : UIViewController

- (void)populateDataWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end
