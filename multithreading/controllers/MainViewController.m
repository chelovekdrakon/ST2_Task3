//
//  MainViewController.m
//  multithreading
//
//  Created by Фёдор Морев on 6/15/19.
//  Copyright © 2019 Fiodar. All rights reserved.
//

#import "MainViewController.h"

NSString * const requestURL = @"https://picsum.photos/v2/list?limit=60";
NSString * const cellReuseId = @"image-cell";

@interface MainViewController () <UITableViewDelegate, UITableViewDataSource>

@property(strong, nonatomic) NSArray <NSDictionary *> *imagesToFetch;
@property(strong, nonatomic) NSMutableArray <UIImage *> *images;
@property(strong, nonatomic) NSMutableArray *tableDataModel;

@property(strong, nonatomic) UITableView *tableView;

@end


@implementation MainViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Multithread !_!,";
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellReuseId];
    self.tableView.tableFooterView = [UIView new];
    
    [self.view addSubview:self.tableView];
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGSize navBarSize = self.navigationController.navigationBar.frame.size;
    CGRect rect = [[UIApplication sharedApplication] statusBarFrame];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                                              [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:(navBarSize.height + rect.size.height)],
                                              [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
                                              [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
                                              ]];
}

#pragma mark - UI Generators

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableDataModel.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellReuseId];
    return cell;
}

#pragma mark - UITableViewDelegate

#pragma mark - Utils

- (CGSize)generateRandomSize {
    int lowerBound = 100;
    int upperBound = 1000;
    
    int rndWidth = lowerBound + arc4random() % (upperBound - lowerBound);
    int rndHegiht = lowerBound + arc4random() % (upperBound - lowerBound);
    
    CGSize size = CGSizeMake(rndWidth, rndHegiht);
    
    return size;
}

- (NSArray *)getRandomImagesToFetch {
    NSURL *url = [NSURL URLWithString:requestURL];
    NSData *jsonData = [NSData dataWithContentsOfURL:url];
    
    NSError *error = nil;
    NSArray *dataDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    return error ? nil : dataDictionary;
}

- (NSData *)fetchRandomImageData {
    CGSize imageSize = [self generateRandomSize];
    NSString *url = [NSString stringWithFormat:@"https://picsum.photos/%i/%i", (int)imageSize.width, (int)imageSize.height];
    NSURL *requestURL = [NSURL URLWithString:url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15.0];
    [request setHTTPMethod:@"HEAD"];
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    NSURL *finalURL = response.URL;
    
    NSData *imageData = [NSData dataWithContentsOfURL:finalURL];
    
    return imageData;
}

@end
