//
//  NewsViewController.m
//  NASA TV
//
//  Created by Pietro Rea on 7/3/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import "NewsViewController.h"
#import "GetNewsWebOperation.h"
#import "AppDelegate.h"
#import "NewsCell.h"
#import "News.h"

@interface NewsViewController ()  <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView* tableView;

@property (strong, nonatomic) NSArray* newsEntries;
@property (strong, nonatomic) UIRefreshControl* refreshControl;
@property (strong, nonatomic) GetNewsWebOperation* getNewsWebOperation;

@end

@implementation NewsViewController

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
    [self.refreshControl addTarget:self action:@selector(refreshTableView:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self populateDataWithCompletionHandler:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data

- (void)populateDataWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    self.getNewsWebOperation = [[GetNewsWebOperation alloc] init];
    
    __weak NewsViewController* weakSelf = self;
    [self.getNewsWebOperation setSuccessBlock:^(NSArray* managedObjects, BOOL hasNewEntries) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
            NSEntityDescription* entity = [NSEntityDescription entityForName:@"News"
                                                      inManagedObjectContext:appDelegate.managedObjectContext];
            
            NSArray* objectIDs = [managedObjects valueForKey:@"newsID"];
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"newsID in %@", objectIDs];
            
            NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"newsID" ascending:NO];
            
            NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
            fetchRequest.entity = entity;
            fetchRequest.predicate = predicate;
            fetchRequest.sortDescriptors = @[sortDescriptor];
            
            weakSelf.newsEntries = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
            [weakSelf.tableView reloadData];
            [weakSelf.refreshControl endRefreshing];
            
            // 1
            /*
             *  Check if a completion handler was passed in. If there's no completion handler available it means that populateDataWithCompletionHandler: was called from within NewsViewController and you don't have to do anything with regards to background fetching.
             */
            if (completionHandler) {
                // 2
                /*
                 *  hasNewEntries is the second parameter passed in from GetNewsWebOperation's successBlock. If you inspect GetNewsWebOperation.m, you'll see that parseNewsData: checks the incoming news items against the ones already stored in Core Data to set this flag.
                 */
                if (hasNewEntries) {
                    completionHandler(UIBackgroundFetchResultNewData);
                    // 3
                    [UIApplication sharedApplication].applicationIconBadgeNumber++;
                } else {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
            }
        });
    }];
    
    [self.getNewsWebOperation setFailureBlock:^{
        [weakSelf.refreshControl endRefreshing];
        if (completionHandler) {
            completionHandler(UIBackgroundFetchResultFailed);
        }
    }];
    
    [self.getNewsWebOperation startAsynchronous];
}

- (void)refreshTableView:(id)sender {
    [self populateDataWithCompletionHandler:nil];
}

#pragma mark - UITableViewDelegate/DataSource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.newsEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"NewsCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"NewsCell"];
    }
    
    News* news = (News *) self.newsEntries[indexPath.row];
    
    cell.textLabel.text = news.title;
    cell.detailTextLabel.text = news.subtitle;

    return cell;
}


@end
