//
//  GetVideosWebOperation.h
//  NASA TV
//
//  Created by Pietro Rea on 7/7/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetVideosWebOperation : NSObject

@property (copy, nonatomic) void(^successBlock)(NSArray* result, BOOL hasNewEntries);
@property (copy, nonatomic) void(^failureBlock)(void);

- (void)startAsynchronous;

@end
