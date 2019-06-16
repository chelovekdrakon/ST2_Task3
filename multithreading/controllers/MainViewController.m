//
//  MainViewController.m
//  multithreading
//
//  Created by Фёдор Морев on 6/15/19.
//  Copyright © 2019 Fiodar. All rights reserved.
//

#import "MainViewController.h"
#import "DetailViewController.h"

int const cellAmount = 60;
NSString * const requestURL = @"https://picsum.photos/v2/list?limit=60";
NSString * const cellReuseId = @"image-cell";
NSString * const defaultText = @"Image is being uploading";

@interface MainViewController () <UITableViewDelegate, UITableViewDataSource>

//@property(strong, nonatomic) NSMutableArray <NSDictionary *> *imagesToFetch;
@property(strong, nonatomic) NSMutableArray <NSMutableDictionary *> *tableDataModel;
@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) UIImage *placeholderImage;
@property(strong, nonatomic) NSOperationQueue *customQueue;

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
    
    self.placeholderImage = [UIImage imageNamed:@"image_placeholder"];
    
    for (int index = 0; index < cellAmount; index++) {
        NSMutableDictionary *imageInfo = [@{
                                      @"defaultImage": self.placeholderImage,
                                      @"defaultText": defaultText
                                      } mutableCopy];
        
        [self.tableDataModel addObject:imageInfo];
    }
    
    self.customQueue = [[NSOperationQueue alloc] init];
    
    [self fetchDataForTableView];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.customQueue.isSuspended) {
        [self.customQueue setSuspended:NO];
    }
}

#pragma mark - UI Generators

- (void)fetchDataForTableView {
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    NSOperation *lastTask = nil;
    
    for (int index = 0; index < cellAmount; index++) {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            NSDictionary *imageData = [self fetchRandomImageData];
            
            NSOperation *finalOperation = [NSBlockOperation blockOperationWithBlock:^{
                NSMutableDictionary *imageInfo = self.tableDataModel[index];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                
                UIImage *image = [UIImage imageWithData:[imageData objectForKey:@"data"]];
                UIImage *croppedImage = [self cropImage:image fromCenterWithSize:CGSizeMake(100.f, 100.f)];
                
                [imageInfo setDictionary:@{
                                           @"url": [imageData objectForKey:@"url"],
                                           @"image": image,
                                           @"imageData": [imageData objectForKey:@"data"],
                                           @"croppedImage": croppedImage
                                           }];
                
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            }];
            
            [mainQueue addOperation:finalOperation];
        }];
        
        if (lastTask) {
            [operation addDependency:lastTask];
        }
        
        lastTask = operation;
        
        [self.customQueue addOperation:operation];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableDataModel.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellReuseId forIndexPath:indexPath];
    NSDictionary *imageInfo = self.tableDataModel[indexPath.row];
    
    NSString *downloadUrl = [imageInfo objectForKey:@"url"];
    
    if (downloadUrl) {
        cell.textLabel.text = downloadUrl;
        cell.imageView.image = [imageInfo objectForKey:@"croppedImage"];
    } else {
        cell.textLabel.text = [imageInfo objectForKey:@"defaultText"];
        cell.imageView.image = [imageInfo objectForKey:@"defaultImage"];
    }
    
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    [cell.textLabel sizeToFit];
    
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.customQueue setSuspended:YES];
    
    NSDictionary *imageInfo = self.tableDataModel[indexPath.row];
    UIImage *image = [imageInfo objectForKey:@"image"];
    
    if (!image) {
        image = [imageInfo objectForKey:@"defaultImage"];
    }
    
    DetailViewController *vc = [DetailViewController new];
    vc.image = image;
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Network Requests

- (NSArray *)getRandomImagesToFetch {
    NSURL *url = [NSURL URLWithString:requestURL];
    NSData *jsonData = [NSData dataWithContentsOfURL:url];
    
    NSError *error = nil;
    NSArray *dataDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    return error ? nil : dataDictionary;
}

- (NSDictionary *)fetchRandomImageData {
    CGSize imageSize = [self generateRandomSize];
    NSString *url = [NSString stringWithFormat:@"https://picsum.photos/%i/%i", (int)imageSize.width, (int)imageSize.height];
    NSURL *requestURL = [NSURL URLWithString:url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15.0];
    [request setHTTPMethod:@"HEAD"];
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    NSURL *finalURL = response.URL;
    
    NSData *imageData = [NSData dataWithContentsOfURL:finalURL];

    return @{
             @"data": imageData,
             @"url": [finalURL absoluteString]
             };
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
    
    CGRect cropRect       = CGRectMake((imageWidth / 2 - scaleToWidth / 2),
                                       (imageHeight / 2 - scaleToHeight / 2),
                                       scaleToWidth,
                                       scaleToHeight);
    CGImageRef imageRef   = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return croppedImage;
}

@end
