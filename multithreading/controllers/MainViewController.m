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

//@property(strong, nonatomic) NSMutableArray <NSDictionary *> *imagesToFetch;
@property(strong, nonatomic) NSMutableArray <NSDictionary *> *tableDataModel;

@property(strong, nonatomic) UITableView *tableView;

@end


@implementation MainViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.imagesToFetch = [NSMutableArray array];
    self.tableDataModel = [NSMutableArray array];
    
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
    
    [self fetchDataForTableView];
}

#pragma mark - UI Generators

- (void)fetchDataForTableView {
    for (int index = 0; index <= 60; index++) {
        [self fetchRandomImageData:^(NSData *imageData, NSString *url) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.tableDataModel.count inSection:0];
            
            [self.tableDataModel addObject:@{
                                             @"imageData": imageData,
                                             @"url": url
                                             }];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableDataModel.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellReuseId];
    NSDictionary *imageInfo = self.tableDataModel[indexPath.row];
    
    cell.textLabel.text = [imageInfo objectForKey:@"url"];
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    [cell.textLabel sizeToFit];
    
    UIImage *image = [UIImage imageWithData:[imageInfo objectForKey:@"imageData"]];
    UIImage *croppedImage = [self cropImage:image fromCenterWithSize:CGSizeMake(100.f, 100.f)];

    cell.imageView.image = croppedImage;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Network Requests

- (NSArray *)getRandomImagesToFetch {
    NSURL *url = [NSURL URLWithString:requestURL];
    NSData *jsonData = [NSData dataWithContentsOfURL:url];
    
    NSError *error = nil;
    NSArray *dataDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    return error ? nil : dataDictionary;
}

- (void)fetchRandomImageData:(void(^)(NSData *, NSString *))completion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(queue, ^{
        CGSize imageSize = [self generateRandomSize];
        NSString *url = [NSString stringWithFormat:@"https://picsum.photos/%i/%i", (int)imageSize.width, (int)imageSize.height];
        NSURL *requestURL = [NSURL URLWithString:url];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15.0];
        [request setHTTPMethod:@"HEAD"];
        NSURLResponse *response = nil;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        NSURL *finalURL = response.URL;
        
        NSData *imageData = [NSData dataWithContentsOfURL:finalURL];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(imageData, [finalURL absoluteString]);
        });
    });
}

#pragma mark - Utils

- (CGSize)generateRandomSize {
    int lowerBound = 100;
    int upperBound = 1000;
    
    int rndWidth = lowerBound + arc4random() % (upperBound - lowerBound);
    int rndHegiht = lowerBound + arc4random() % (upperBound - lowerBound);
    
    CGSize size = CGSizeMake(rndWidth, rndHegiht);
    
    return size;
}

- (UIImage *)cropImage:(UIImage *)image fromCenterWithSize:(CGSize)size{
    float imageWidth    = image.size.width;
    float imageHeight   = image.size.height;
    float scaleToWidth  = size.width;
    float scaleToHeight = size.height;
    
    CGRect cropRect       = CGRectMake((imageWidth/2 - scaleToWidth/2), (imageHeight/2 - scaleToHeight/2), scaleToWidth, scaleToHeight);
    CGImageRef imageRef   = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return croppedImage;
}

@end
