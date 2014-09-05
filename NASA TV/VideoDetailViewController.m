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

@interface VideoDetailViewController()

@property (strong, nonatomic) NSURL* videoURL;
@property (strong, nonatomic) MPMoviePlayerController* moviePlayerViewController;

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

@end
