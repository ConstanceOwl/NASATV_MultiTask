//
//  VideoDetailViewController.m
//  NASA TV
//
//  Created by Pietro Rea on 7/7/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import "AppDelegate.h"
#import "VideoDetailViewController.h"
#import <MediaPlayer/MPMoviePlayerController.h>

@interface VideoDetailViewController() <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURL* videoURL;
@property (strong, nonatomic) MPMoviePlayerController* moviePlayerViewController;

@property (strong, nonatomic) NSURLSession *urlSession;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic) NSString *videosDerectoryPath;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
- (IBAction)downloadButtonTapped:(id)sender;

@end

@implementation VideoDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

    }
    
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.progressView.progress = 0.0f;
    self.progressView.hidden = YES;
    
    // 1
    /*
     *  Recall that you had to update the availableOffline property when the download finished successfully. You have to unbox this BOOL because Core Data save it as an NSNumber
     */
    BOOL videoAvailableOffline = [self.video.availableOffline boolValue];
    NSURL *playbackVideoURL;
    
    // 2
    if (videoAvailableOffline) {
        self.downloadButton.enabled = NO;
        self.downloadButton.title = @"Downloaded";
        
        // play local content if available
        NSString *lastPathComponent = [self.videoURL lastPathComponent];
        
        NSString *videoPath = [self.videosDerectoryPath stringByAppendingString:lastPathComponent];
        playbackVideoURL = [NSURL fileURLWithPath:videoPath];
    } else {
        self.downloadButton.enabled = YES;
        playbackVideoURL = self.videoURL;
    }
    
    self.moviePlayerViewController = [[MPMoviePlayerController alloc] initWithContentURL:playbackVideoURL];
    [self.moviePlayerViewController prepareToPlay];
    [self.moviePlayerViewController setControlStyle:MPMovieControlStyleDefault];
    
    [self.moviePlayerViewController.view setFrame:self.view.bounds];
    [self.view addSubview:self.moviePlayerViewController.view];
    
    [self.moviePlayerViewController play];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBackgroundTransfer:) name:@"BackgroundTransferNotification" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.moviePlayerViewController stop];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Getters and setters

- (void)setVideo:(Video *)video {
    
    if (_video != video) {
        _video = video;
        
        NSString* baseURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"baseURLString"];
        NSString* urlString = [NSString stringWithFormat:@"%@%@", baseURLString, self.video.url];
        self.videoURL = [NSURL URLWithString:urlString];
    }
}

- (NSString *)videosDerectoryPath
{
    if (!_videosDerectoryPath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _videosDerectoryPath = [paths[0] stringByAppendingPathComponent:@"com.razeware.videos"];
        BOOL directoryExists = [[NSFileManager defaultManager] fileExistsAtPath:_videosDerectoryPath];
        
        if (!directoryExists) {
            NSError *error;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:_videosDerectoryPath withIntermediateDirectories:NO attributes:nil error:&error]) {
                
            }
        }
    }
    return _videosDerectoryPath;
}

#pragma mark - NSURLSessionDownloadTask methods
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"download url is %@",location);
    // 1
    NSString *lastPathComponent = [downloadTask.originalRequest.URL lastPathComponent];
    
    // 2
    NSString *destinationPath = [self.videosDerectoryPath stringByAppendingPathComponent:lastPathComponent];
    
    NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
    
    // 3
    NSError *error;
    BOOL copySuccessful = [[NSFileManager defaultManager] copyItemAtURL:location toURL:destinationURL error:&error];
    if (!copySuccessful) {
        
    }
    
    // 4
    dispatch_async(dispatch_get_main_queue(), ^{
        self.video.availableOffline = @(YES);
        NSManagedObjectContext *moc = self.video.managedObjectContext;
        NSError *error;
        [moc save:&error];
        if (error) {
            NSLog(@"Core Data error");
        }
        
        // 5
        self.progressView.hidden = YES;
        self.downloadButton.title = @"Downloaded";
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        NSString *lastPathComponent = [task.originalRequest.URL lastPathComponent];
        NSString *filePath = [self.videosDerectoryPath stringByAppendingPathComponent:lastPathComponent];
        
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

- (IBAction)downloadButtonTapped:(id)sender {
    
    // 1
    /*
     *  this property indecate a video has already been downloaded and prevents you from downloading it twice
     */
    if ([self.video.availableOffline boolValue]) {
        return;
    }
    
    // 2
    /*
     *  disable the download button while the download operation is in progress to prevent launching a duplicate NSURLSessionDownloadTask;
     */
    self.downloadButton.enabled = NO;
    self.progressView.hidden = NO;
    
    // 3
    /*
     *  set up NSURLSession config
     */
    if (!self.urlSession) {
        NSString *sessionID = [@"com.razeware.backgroundsession." stringByAppendingFormat:@"%ld",(long)[self.video.videoID integerValue]];
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionID];
        
        self.urlSession = [NSURLSession sessionWithConfiguration:config
                                                        delegate:self
                                                   delegateQueue:[NSOperationQueue mainQueue]];
        
        
        
//        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
//        self.urlSession = [NSURLSession sessionWithConfiguration:config
//                                                        delegate:self
//                                                   delegateQueue:[NSOperationQueue mainQueue]];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.videoURL];
    
    self.downloadTask = [self.urlSession downloadTaskWithRequest:request];
    
    // 4
    [self.downloadTask resume];
}

#pragma mark - Background Transfers
- (void)handleBackgroundTransfer:(NSNotification *)notification
{
    // 1
    /*
     *  Unpack the NSURLSession identifier from the notification's userInfo dictionary.
     */
    NSString *sessionIdentifier = notification.userInfo[@"sessionIdentifier"];
    
    NSArray *components = [sessionIdentifier componentsSeparatedByString:@"."];
    
    NSString *videoID = [components lastObject];
    
    // 2
    /*
     *  if there are multiple downloads in progress, each one will have a VideoDetailViewController instance. Since it's possible that the video on the screen is not the same one identified in the notification, check that they match before continuing.
     */
    if ([self.video.videoID integerValue] == [videoID integerValue]) {
        // 3
        /*
         *  Perform the UI updates on the main thread.
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadButton.title = @"Downloaded";
            self.progressView.hidden = YES;
            
            void(^completionHandler)(void) = notification.userInfo[@"completionHandler"];
            
            if (completionHandler) {
                completionHandler();
            }
        });
    }
}

@end
