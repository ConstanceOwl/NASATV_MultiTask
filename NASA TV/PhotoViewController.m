//
//  PhotoViewController.m
//  NASA TV
//
//  Created by Pietro Rea on 7/10/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import "PhotoViewController.h"
#import "AppDelegate.h"

@interface PhotoViewController () <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSString *photosDirectoryPath;

@end

@implementation PhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 1
    /**
     *  download an image from local MAMP server.
     */
    NSString *baseURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"baseURLString"];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@",baseURLString, @"/photos/dailyphoto.jpg"];
    
    NSURL *photoURL = [NSURL URLWithString:urlString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:photoURL];
    
    // 2
    /*
     *  Create a background NSURLSession.
     */
    NSString *sessionIdentifier = @"com.razeware.backgroundsession.dailyphoto";
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionIdentifier];
    
    self.urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    // 3
    self.downloadTask = [self.urlSession downloadTaskWithRequest:request];
    [self.downloadTask resume];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)photosDirectoryPath
{
    if (!_photosDirectoryPath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        
        _photosDirectoryPath = [paths[0] stringByAppendingPathComponent:@"com.razeware.photos"];
        
        BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:_photosDirectoryPath];
        
        if (!directoryExists) {
            NSError *error;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:_photosDirectoryPath
                                          withIntermediateDirectories:NO
                                                           attributes:nil
                                                                error:&error]) {
                
            }
        }
    }
    return _photosDirectoryPath;
}

#pragma mark - NSURLSessionDownloadTaskDelegate methods
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSString *lastPathComponent = [downloadTask.originalRequest.URL lastPathComponent];
    
    NSString *destinationPath = [self.photosDirectoryPath stringByAppendingPathComponent:lastPathComponent];
    
    NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:destinationPath];
    NSError *error;
    if (fileExists) {
        [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:&error];
    }
    
    BOOL copySuccessful = [[NSFileManager defaultManager] copyItemAtURL:location toURL:destinationURL error:&error];
    
    if (copySuccessful) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [UIImage imageWithContentsOfFile:[destinationURL path]];
            self.imageView.image = image;
        });
    } else {
        NSLog(@"Error: %@", error.localizedDescription);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    // 1
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    void(^completionHandler)(UIBackgroundFetchResult) = appDelegate.slientRemoteNotificationCompletionHandler;
    // 2
    if (error) {
        if (completionHandler) {
            completionHandler(UIBackgroundFetchResultFailed);
        }
        NSLog(@"Error : %@", error.localizedDescription);
    } else if (completionHandler) {
        [self postLocalNotification];
        completionHandler(UIBackgroundFetchResultNewData);
    }
    // 3
    appDelegate.slientRemoteNotificationCompletionHandler = nil;
}


- (void)postLocalNotification {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = @"Astronomy Picture of the Day Available";
    localNotification.applicationIconBadgeNumber ++;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

#pragma mark - Miscellaneous

- (IBAction)closeButtonTapped:(id)sender {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


@end
