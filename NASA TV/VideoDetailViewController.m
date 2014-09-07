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
    
    self.moviePlayerViewController = [[MPMoviePlayerController alloc] initWithContentURL:self.videoURL];
    [self.moviePlayerViewController prepareToPlay];
    [self.moviePlayerViewController setControlStyle:MPMovieControlStyleDefault];
    
    [self.moviePlayerViewController.view setFrame:self.view.bounds];
    [self.view addSubview:self.moviePlayerViewController.view];
    
    [self.moviePlayerViewController play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.moviePlayerViewController stop];
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
            if (![[NSFileManager defaultManager] createDirectoryAtURL:_videosDerectoryPath withIntermediateDirectories:NO attributes:nil error:&error]) {
                
            }
        }
    }
    return _videosDerectoryPath;
}

#pragma mark - NSURLSessionDownloadTask methods
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    });
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
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.urlSession = [NSURLSession sessionWithConfiguration:config
                                                        delegate:self
                                                   delegateQueue:[NSOperationQueue mainQueue]];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.videoURL];
    
    self.downloadTask = [self.urlSession downloadTaskWithRequest:request];
    
    // 4
    [self.downloadTask resume];
}
@end
