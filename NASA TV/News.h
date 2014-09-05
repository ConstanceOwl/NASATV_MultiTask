//
//  News.h
//  NASA TV
//
//  Created by Pietro Rea on 8/28/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface News : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * newsID;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * title;

@end
