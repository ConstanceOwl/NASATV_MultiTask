//
//  PhotoViewController.m
//  NASA TV
//
//  Created by Pietro Rea on 7/10/13.
//  Copyright (c) 2013 Pietro Rea. All rights reserved.
//

#import "PhotoViewController.h"

@implementation PhotoViewController

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Miscellaneous

- (IBAction)closeButtonTapped:(id)sender {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


@end
