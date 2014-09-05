//
//  VideoViewController.m
//  NASA TV
//
//  Created by Pietro Rea on 7/3/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import "VideoViewController.h"
#import "VideoDetailViewController.h"
#import "GetVideosWebOperation.h"
#import "AppDelegate.h"
#import "VideoCell.h"
#import "Video.h"

@interface VideoViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (assign, nonatomic) NSUInteger selectedIndex;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) NSArray* videos;
@property (strong, nonatomic) UIRefreshControl* refreshControl;
@property (strong, nonatomic) GetVideosWebOperation* getVideosWebOperation;

@end

@implementation VideoViewController

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
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshCollectionView:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self populateData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data

- (void)populateData {
    
    self.getVideosWebOperation = [[GetVideosWebOperation alloc] init];
    
    __weak VideoViewController* weakSelf = self;
    
    [self.getVideosWebOperation setSuccessBlock:^(NSArray* managedObjects) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
            NSEntityDescription* entity = [NSEntityDescription entityForName:@"Video"
                                                      inManagedObjectContext:appDelegate.managedObjectContext];
            
            NSArray* objectIDs = [managedObjects valueForKey:@"videoID"];
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"videoID in %@", objectIDs];
            
            NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"videoID"
                                                                           ascending:NO];
            
            NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
            fetchRequest.entity = entity;
            fetchRequest.predicate = predicate;
            fetchRequest.sortDescriptors = @[sortDescriptor];
            
            weakSelf.videos = [appDelegate.managedObjectContext
                               executeFetchRequest:fetchRequest
                               error:nil];
            
            [weakSelf.collectionView reloadData];
            [weakSelf.refreshControl endRefreshing];
        });
    }];
    
    [self.getVideosWebOperation setFailureBlock:^{
        [weakSelf.refreshControl endRefreshing];
    }];
    
    [self.getVideosWebOperation startAsynchronous];
}

- (void)refreshCollectionView:(id)sender {
    [self populateData];
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [self.videos count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    VideoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath:indexPath];
    Video* video = (Video *) self.videos[indexPath.row];
    cell.videoLabel.text = video.title;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath.row;
    [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(134, 134);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    //top, left, bottom, right
    return UIEdgeInsetsMake(-2, 17, 5, 17);
}

#pragma mark - UIStoryboard methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"toVideoDetailViewController"]) {
        VideoDetailViewController* viewController = (VideoDetailViewController*) segue.destinationViewController;
        viewController.video = self.videos[self.selectedIndex];
    }
}

@end
