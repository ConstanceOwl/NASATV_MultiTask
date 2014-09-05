//
//  GetNewsWebOperation.m
//  NASA TV
//
//  Created by Pietro Rea on 7/6/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import "GetNewsWebOperation.h"
#import "AppDelegate.h"
#import "News.h"

@interface GetNewsWebOperation ()

@property (strong, nonatomic) NSData* newsData;
@property (strong, nonatomic) NSURLSession* urlSession;
@property (strong, nonatomic) NSOperationQueue* parseQueue;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation GetNewsWebOperation

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
    NSString* urlString = [NSString stringWithFormat:@"%@%@", baseURLString, @"/news.json"];
    NSURL* url = [NSURL URLWithString:urlString];
    
    __weak GetNewsWebOperation* weakSelf = self;
    NSURLSessionDataTask* dataTask = [self.urlSession dataTaskWithURL:url
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                        
                                                        if (error) {
                                                            if (weakSelf.failureBlock) weakSelf.failureBlock();
                                                        }
                                                        else {
                                                            [weakSelf parseNewsData:data];
                                                        }
                                                    }];
    
    [dataTask resume];
}

- (void)parseNewsData:(NSData *)jsonData {
    
    __weak GetNewsWebOperation* weakSelf = self;
    
    NSBlockOperation* blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        weakSelf.managedObjectContext = [[NSManagedObjectContext alloc] init];
        weakSelf.managedObjectContext.persistentStoreCoordinator = weakSelf.persistentStoreCoordinator;
        
        NSError* error;
        NSArray* jsonArray = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&error];
        if (error) NSLog(@"Parsing error");
        
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"News"
                                                  inManagedObjectContext:weakSelf.managedObjectContext];
        
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = entity;
        
        NSMutableArray* newsArray = [[NSMutableArray alloc] initWithCapacity:jsonArray.count];
        NSArray* storedNewsItems = [weakSelf.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error) NSLog(@"Fetching error");
        
        BOOL hasNewEntries = NO;
        
        for (NSDictionary* newsDict  in jsonArray) {
            
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"newsID == %@", newsDict[@"id"]];
            News* newsItem = [[storedNewsItems filteredArrayUsingPredicate:predicate] lastObject];
            
            if (!newsItem) {
                /* News item is new, create it in Core Data */
                newsItem = [[News alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
                hasNewEntries = YES;
            }
            
            [newsItem setNewsID:newsDict[@"id"]];
            [newsItem setTitle:newsDict[@"title"]];
            [newsItem setSubtitle:newsDict[@"subtitle"]];
            
            [newsArray addObject:newsItem];
        }
        
        if ([weakSelf.managedObjectContext hasChanges]) {
            
            if (![weakSelf.managedObjectContext save:&error]) {
                NSLog(@"Managed object context could not save %@, %@", error, [error userInfo]);
            }
            else {
                if (weakSelf.successBlock) weakSelf.successBlock([newsArray copy], hasNewEntries);
            }
        }
    }];
    
    [self.parseQueue addOperation:blockOperation];
}

@end
