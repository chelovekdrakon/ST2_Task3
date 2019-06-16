//
//  DetailViewController.m
//  multithreading
//
//  Created by Фёдор Морев on 6/16/19.
//  Copyright © 2019 Fiodar. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property(strong, nonatomic) UIScrollView *scrollView;
@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.scrollView];
    
    CGSize navBarSize = self.navigationController.navigationBar.frame.size;
    CGRect rect = [[UIApplication sharedApplication] statusBarFrame];
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                                              [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:(navBarSize.height + rect.size.height)],
                                              [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
                                              [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
                                              ]];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.image];
    self.scrollView.contentSize = imageView.frame.size;
    [self.scrollView addSubview:imageView];
}

@end
