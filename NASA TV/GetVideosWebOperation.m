//
//  GetVideosWebOperation.m
//  NASA TV
//
//  Created by Pietro Rea on 7/7/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import "GetVideosWebOperation.h"
#import "AppDelegate.h"
#import "Video.h"

@interface GetVideosWebOperation ()

@property (strong, nonatomic) NSData* newsData;
@property (strong, nonatomic) NSURLSession* urlSession;
@property (strong, nonatomic) NSOperationQueue* parseQueue;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation GetVideosWebOperation

- (id)init {
    
    self = [super init];
    if (self) {
        
        AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
        self.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator;
        
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        self.urlSession = [NSURLSession sessionWithConfiguration:configuration
                                                        delegate:nil
                                                   delegateQueue:[NSOperationQueue mainQueue]];
        
        self.parseQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)startAsynchronous {
    
    NSString* baseURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"baseURLString"];
    NSString* urlString = [NSString stringWithFormat:@"%@%@", baseURLString, @"/videos.json"];
    NSURL* url = [NSURL URLWithString:urlString];
    
    __weak GetVideosWebOperation* weakSelf = self;
    NSURLSessionDataTask* dataTask = [self.urlSession dataTaskWithURL:url
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                        
                                                        if (error) {
                                                            if (weakSelf.failureBlock) weakSelf.failureBlock();
                                                        }
                                                        else {
                                                            [weakSelf parseVideosData:data];
                                                        }
                                                    }];
    
    [dataTask resume];
}

- (void)parseVideosData:(NSData *)jsonData {
    
    __weak GetVideosWebOperation* weakSelf = self;
    
    NSBlockOperation* blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        weakSelf.managedObjectContext = [[NSManagedObjectContext alloc] init];
        weakSelf.managedObjectContext.persistentStoreCoordinator = weakSelf.persistentStoreCoordinator;
        
        NSError* error;
        NSArray* jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
        if (error) NSLog(@"Parsing error");
        
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"Video"
                                                  inManagedObjectContext:weakSelf.managedObjectContext];
        
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = entity;
        
        NSMutableArray* videosArray = [[NSMutableArray alloc] initWithCapacity:jsonArray.count];
        NSArray* storedVideosArray = [weakSelf.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error) NSLog(@"Fetching error");
        
        BOOL hasNewEntries = NO;
        
        for (NSDictionary* videoDict  in jsonArray) {
            
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"videoID == %@", videoDict[@"videoID"]];
            Video* video = [[storedVideosArray filteredArrayUsingPredicate:predicate] lastObject];
            
            if (!video) {
                /* News item is new, create it in Core Data */
                video = [[Video alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
                hasNewEntries = YES;
            }
            
            [video setVideoID:videoDict[@"videoID"]];
            [video setTitle:videoDict[@"title"]];
            [video setUrl:videoDict[@"url"]];
            
            [videosArray addObject:video];
        }
        
        if ([weakSelf.managedObjectContext hasChanges]) {
            
            if (![weakSelf.managedObjectContext save:&error]) {
                NSLog(@"Managed object context could not save %@, %@", error, [error userInfo]);
            }
            else {
                if (weakSelf.successBlock) weakSelf.successBlock([videosArray copy], hasNewEntries);
            }
        }
    }];
    
    [self.parseQueue addOperation:blockOperation];
}

@end
