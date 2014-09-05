//
//  Video.h
//  NASA TV
//
//  Created by Pietro Rea on 7/7/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Video : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * videoID;
@property (nonatomic, retain) NSNumber * availableOffline;

@end
